
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/place.dart';
import '../screens/place_detail_screen.dart';



String _norm(String s) {
  return s
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}



List<String> _splitTags(Iterable<dynamic>? xs) {
  if (xs == null) return const <String>[];
  final out = <String>[];
  for (final raw in xs) {
    if (raw == null) continue;
    final s = raw.toString().trim();
    if (s.isEmpty) continue;
    final parts = s
        .split(RegExp(r'[,;|]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    out.addAll(parts);
  }
  return out;
}

bool _containsNorm(String? haystack, String needle) {
  if (haystack == null || haystack.isEmpty) return false;
  return _norm(haystack).contains(_norm(needle));
}

bool _equalsAnyNorm(Iterable<String> xs, String needle) {
  final n = _norm(needle);
  for (final x in xs) {
    if (_norm(x) == n) return true;
  }
  return false;
}

bool _containsAnyNorm(Iterable<String> xs, String needle) {
  final n = _norm(needle);
  for (final x in xs) {
    if (_norm(x).contains(n)) return true;
  }
  return false;
}



class ParsedQuery {
  final List<String> terms;   
  final List<String> subcats; 
  final String original;      
  ParsedQuery({required this.terms, required this.subcats, required this.original});
}

ParsedQuery _parseQuery(String q) {
  final src = q.trim();
  if (src.isEmpty) return ParsedQuery(terms: [], subcats: [], original: q);

  
  final tokens = <String>[];
  final reg = RegExp(r'"([^"]+)"|(\S+)');
  for (final m in reg.allMatches(src)) {
    final phrase = m.group(1);
    final single = m.group(2);
    tokens.add((phrase ?? single ?? '').trim());
  }

  final terms = <String>[];
  final subcats = <String>[];

  for (final t in tokens) {
    if (t.startsWith('@') && t.length > 1) {
      subcats.add(t.substring(1)); 
    } else {
      terms.add(t);
    }
  }
  return ParsedQuery(terms: terms, subcats: subcats, original: q);
}




bool _matchesTextOrTags(Place p, String term) {
  
  final textHit = _containsNorm(p.name, term) ||
      _containsNorm(p.description, term) ||
      _containsNorm(p.address, term);
  if (textHit) return true;

  
  final subs = _splitTags(p.subcategories);
  final cats = _splitTags(p.categories);
  final both = <String>[...subs, ...cats];

  return _containsAnyNorm(both, term);
}





bool _matchesSubcats(Place p, List<String> qSubcats, {required String originalQuery}) {
  if (qSubcats.isEmpty) return true;

  final subs = _splitTags(p.subcategories);
  final cats = _splitTags(p.categories);
  final both = <String>[...subs, ...cats];

  
  final normList = both.map(_norm).toList();

  for (final raw in qSubcats) {
    final needle = _norm(raw);
    final inQuotes = RegExp('"@?${RegExp.escape(raw)}"').hasMatch(originalQuery);

    final hasExact = normList.contains(needle);
    final hasContains = hasExact ? true : normList.any((e) => e.contains(needle));

    final ok = inQuotes ? (hasExact || hasContains) : hasContains;
    if (!ok) return false;
  }
  return true;
}

bool _matchesPlace(Place p, String query) {
  final parsed = _parseQuery(query);

  
  final termsOk = parsed.terms.every((t) => _matchesTextOrTags(p, t));
  if (!termsOk) return false;

  
  final subcatsOk = _matchesSubcats(p, parsed.subcats, originalQuery: parsed.original);
  if (!subcatsOk) return false;

  return true;
}



class SearchService {
  Future<List<Place>> search(String query) async {
    final box = Hive.box<Place>('places');
    final items = box.values.toList(growable: false);

    if (query.trim().isEmpty) {
      final all = [...items]..sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
      return all;
    }

    final res = <Place>[];
    for (final p in items) {
      if (_matchesPlace(p, query)) {
        res.add(p);
      }
    }

    
    res.sort((a, b) {
      final an = _norm(a.name ?? '');
      final bn = _norm(b.name ?? '');
      final qn = _norm(query);
      final aExact = an == qn;
      final bExact = bn == qn;
      if (aExact != bExact) return aExact ? -1 : 1;
      return an.compareTo(bn);
    });

    return res;
  }
}



class SearchView extends StatefulWidget {
  final String? initialQuery;
  const SearchView({Key? key, this.initialQuery}) : super(key: key);

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _service = SearchService();
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Place> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialQuery ?? '';
    _runSearch(immediate: true);
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _runSearch);
  }

  Future<void> _runSearch({bool immediate = false}) async {
    final q = _controller.text;
    setState(() => _loading = true);
    try {
      final list = await _service.search(q);
      if (!mounted) return;
      setState(() => _results = list);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openPlace(Place p) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: p)),
    );
  }

  Widget _tile(Place p) {
    final imgs = p.imageUrl ?? const <String>[];
    Widget leading;
    if (imgs.isNotEmpty) {
      final src = imgs.first;
      if (src.startsWith('http')) {
        leading = ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            src,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
          ),
        );
      } else {
        leading = ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            src,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
          ),
        );
      }
    } else {
      leading = const CircleAvatar(child: Icon(Icons.place_outlined));
    }

    final cats = (() {
      final subs = _splitTags(p.subcategories);
      if (subs.isNotEmpty) return subs.join(' · ');
      final cs = _splitTags(p.categories);
      return cs.join(' · ');
    })();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: leading,
      title: Text(
        p.name ?? 'Без названия',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        cats,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _openPlace(p),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск'),
        backgroundColor: const Color(0xff8ddeff),
        foregroundColor: const Color(0xff000E6B),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Найти место, @подкатегорию или "фразу"',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    _runSearch(immediate: true);
                  },
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.transparent),
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _runSearch(immediate: true),
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _results.isEmpty && !_loading
                ? const Center(child: Text('Ничего не найдено'))
                : ListView.separated(
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _tile(_results[i]),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade100,
    );
  }
}

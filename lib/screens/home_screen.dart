// lib/screens/home_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/root_shell_host.dart';
import '../screens/direction_screen.dart';
import '../models/place.dart';
import '../services/place_service.dart';
import '../services/likes_service.dart';
import '../widgets/kt_place_card.dart';
import '../services/search_service.dart';
import 'article_screen.dart';
// --- ДАННЫЕ ДЛЯ СЛАЙДОВ БАННЕРА ---
final List<Map<String, String>> bannerItems = [
  {
    'imagePath': 'assets/images/banner_1.jpg',
    'text': 'Открой Казахстан вместе с нами!',
  },
  {
    'imagePath': 'assets/images/banner_2.jpg',
    'text': 'Новые туры по Алматинской области',
  },
  {
    'imagePath': 'assets/images/banner_3.jpg',
    'text': 'Горнолыжные курорты ждут тебя!',
  },
];


enum Season { winter, spring, summer, autumn }
enum DayTime { morning, day, evening, night }

class HomeScreen extends StatefulWidget {
  final DateTime? testDate;
  const HomeScreen({super.key, this.testDate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _placeService = PlaceService();
  final _likes = LikesService();

  Timer? _tick;
  late DayTime _currentDayTime;

  @override
  void initState() {
    super.initState();
    _currentDayTime = _getDayTime(widget.testDate ?? DateTime.now());
    if (widget.testDate == null) {
      _tick = Timer.periodic(const Duration(minutes: 1), (_) {
        final dt = _getDayTime(DateTime.now());
        if (dt != _currentDayTime) {
          // Этот setState обновляет только фон, и это нормально
          setState(() => _currentDayTime = dt);
        }
      });
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  DayTime _getDayTime(DateTime now) {
    final h = now.hour;
    if (h >= 6 && h < 12) return DayTime.morning;
    if (h < 18) return DayTime.day;
    if (h < 22) return DayTime.evening;
    return DayTime.night;
  }

  Season _getSeason(DateTime now) {
    switch (now.month) {
      case 12: case 1: case 2: return Season.winter;
      case 3: case 4: case 5: return Season.spring;
      case 6: case 7: case 8: return Season.summer;
      default: return Season.autumn;
    }
  }

  BoxDecoration _decorationForTime(DayTime dt) {
    switch (dt) {
      case DayTime.morning:
        return const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFBBC8C8), Color(0xFF5E9F9A), Color(0xFFDDBDAA)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        );
      case DayTime.day:
        return const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFA9C9EC), Color(0xFFC6D7EB), Color(0xFFD4AC77), Color(0xFFD4AC77)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        );
      case DayTime.evening:
        return const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF61556A), Color(0xFF7E80A5), Color(0xFFE6BFB2)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        );
      case DayTime.night:
        return const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF6B75AD), Color(0xFF324476), Color(0xFF11213B)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        );
    }
  }

  static const List<String> _allSubcategories = ['Горы', 'Кемпинг', 'Парки', 'Озёра', 'Каньоны', 'Национальные парки', 'Реки', 'Смотровые площадки', 'Мечети', 'Музеи', 'Исторические памятники', 'Пляжи', 'Фестивали', 'Пешие маршруты', 'Веломаршруты', 'Кинотеатры', 'Концертные залы', 'Рестораны', 'Кафе', 'Ночная экскурсия', 'Утренняя экскурсия', 'Вечерняя программа'];
  static const Map<String, IconData> _subcategoryIcons = {'Горы': Icons.terrain, 'Кемпинг': Icons.local_fire_department, 'Парки': Icons.park, 'Озёра': Icons.water, 'Каньоны': Icons.filter_hdr, 'Национальные парки': Icons.emoji_nature, 'Реки': Icons.water, 'Смотровые площадки': Icons.remove_red_eye, 'Мечети': Icons.account_balance, 'Музеи': Icons.museum, 'Исторические памятники': Icons.history_edu, 'Пляжи': Icons.beach_access, 'Фестивали': Icons.celebration, 'Пешие маршруты': Icons.directions_walk, 'Веломаршруты': Icons.directions_bike, 'Кинотеатры': Icons.theaters, 'Концертные залы': Icons.music_note, 'Рестораны': Icons.restaurant, 'Кафе': Icons.local_cafe, 'Ночная экскурсия': Icons.nights_stay, 'Утренняя экскурсия': Icons.wb_sunny, 'Вечерняя программа': Icons.event};
  static IconData _iconForSubcategory(String name) => _subcategoryIcons[name] ?? Icons.place_outlined;

  List<String> get dynamicSubcategories {
    final now = widget.testDate ?? DateTime.now();
    final season = _getSeason(now);
    final dt = _getDayTime(now);
    final Set<String> pool = <String>{};
    void addAll(Iterable<String> items) {
      for (final s in items) { if (_allSubcategories.contains(s)) pool.add(s); }
    }
    final indoorCulture = <String>['Музеи', 'Исторические памятники', 'Мечети', 'Кинотеатры', 'Концертные залы', 'Кафе', 'Рестораны'];
    final summerDay = <String>['Пляжи', 'Озёра', 'Кемпинг', 'Пешие маршруты', 'Веломаршруты', 'Национальные парки', 'Горы', 'Реки', 'Смотровые площадки', 'Парки', 'Каньоны'];
    final autumnDay = <String>['Парки', 'Смотровые площадки', 'Пешие маршруты', 'Каньоны', 'Исторические памятники', 'Музеи', 'Кафе', 'Рестораны'];
    final springDay = <String>['Парки', 'Пешие маршруты', 'Смотровые площадки', 'Горы', 'Национальные парки', 'Реки', 'Озёра', 'Каньоны'];
    final nightLeisure = <String>['Ночная экскурсия', 'Вечерняя программа', 'Кафе', 'Рестораны', 'Кинотеатры', 'Концертные залы', 'Фестивали'];

    switch (season) {
      case Season.winter:
        switch (dt) {
          case DayTime.night: addAll(nightLeisure); break;
          case DayTime.evening: addAll(['Вечерняя программа', ...indoorCulture, 'Фестивали']); break;
          case DayTime.morning: case DayTime.day: addAll(indoorCulture); addAll(['Утренняя экскурсия']); break;
        }
        break;
      case Season.summer:
        switch (dt) {
          case DayTime.morning: case DayTime.day: addAll(summerDay); addAll(['Утренняя экскурсия']); break;
          case DayTime.evening: addAll(['Вечерняя программа', 'Фестивали', 'Смотровые площадки', 'Кафе', 'Рестораны', 'Озёра']); break;
          case DayTime.night: addAll(nightLeisure); break;
        }
        break;
      case Season.spring:
        switch (dt) {
          case DayTime.morning: case DayTime.day: addAll(springDay); addAll(['Утренняя экскурсия']); break;
          case DayTime.evening: addAll(['Вечерняя программа', ...indoorCulture, 'Фестивали']); break;
          case DayTime.night: addAll(nightLeisure); break;
        }
        break;
      case Season.autumn:
        switch (dt) {
          case DayTime.morning: case DayTime.day: addAll(autumnDay); addAll(['Утренняя экскурсия']); break;
          case DayTime.evening: addAll(['Вечерняя программа', ...indoorCulture]); break;
          case DayTime.night: addAll(['Ночная экскурсия', ...indoorCulture]); break;
        }
        break;
    }
    if (pool.isEmpty) addAll(['Парки', 'Музеи', 'Кафе', 'Рестораны', 'Пешие маршруты', 'Горы', 'Озёра', 'Смотровые площадки', 'Веломаршруты']);
    return pool.toList()..shuffle();
  }

  Stream<List<Place>> _popularPlacesStream({int limit = 4, Duration window = const Duration(days: 30)}) {
    final since = Timestamp.fromDate(DateTime.now().subtract(window));
    final placesBox = Hive.box<Place>('places');
    return FirebaseFirestore.instance.collection('likes').where('createdAt', isGreaterThan: since).snapshots().map((qs) {
      final counts = <String, int>{};
      for (final d in qs.docs) {
        final pid = (d.data()['placeId'] ?? '') as String;
        if (pid.isEmpty) continue;
        counts[pid] = (counts[pid] ?? 0) + 1;
      }
      final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final ids = sorted.take(limit).map((e) => e.key);
      final result = <Place>[];
      for (final id in ids) {
        final p = placesBox.get(id);
        if (p != null) result.add(p);
      }
      return result;
    });
  }

  Widget _buildDirectionsButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff8ddeff), foregroundColor: const Color(0xff000E6B), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 4),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DirectionsScreen())),
          icon: const Icon(Icons.map_outlined),
          label: const Text('Открыть направления', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  void _openSearchBySubcategory(BuildContext context, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    // ВСЕГДА без кавычек, даже если есть пробелы
    // Также уберём любые случайные кавычки внутри строк
    final query = '@${trimmed.replaceAll('"', '')}';

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SearchView(initialQuery: query)),
    );
  }
  Widget _buildCategories() {
    final cats = dynamicSubcategories;
    return Container(
      height: 70,
      margin: const EdgeInsets.only(top: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final name = cats[index];
          return GestureDetector(
            onTap: () => _openSearchBySubcategory(context, name),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), color: Colors.white.withOpacity(0.85), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 3))]),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(radius: 14, backgroundColor: const Color(0xff2A5CAA), child: Icon(_iconForSubcategory(name), size: 16, color: Colors.white)),
                  const SizedBox(width: 8),
                  Text(name, style: const TextStyle(color: Color(0xff000E6B), fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text("Куда лучше пойти сейчас?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff000E6B))),
        ),
        _buildCategories(),
      ],
    );
  }
  Widget _buildArticlesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Интересные статьи', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff000E6B))),
        ),
        SizedBox(
          height: 220,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('articles').orderBy('publishedAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Статей пока нет.'));
              final articles = snapshot.data!.docs;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: articles.length,
                itemBuilder: (context, index) {
                  final article = articles[index];
                  final articleData = article.data();
                  final title = articleData['title'] ?? 'Без заголовка';
                  final imageUrl = articleData['coverImageUrl'] ?? '';

                  // ▼▼▼ ОБЕРНУЛИ КАРТОЧКУ В HERO ▼▼▼
                  return Hero(
                    tag: 'article_image_${article.id}',
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArticleScreen(articleId: article.id))),
                      child: Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: 14),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: Colors.white.withOpacity(0.85), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 4))]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(18)), child: imageUrl.isNotEmpty ? Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity) : Container(color: Colors.grey.shade300, child: const Icon(Icons.article, size: 40, color: Colors.grey)))),
                            Expanded(flex: 2, child: Padding(padding: const EdgeInsets.all(12.0), child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xff2A5CAA)), maxLines: 2, overflow: TextOverflow.ellipsis))),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
  Widget _popularHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text('Популярные места', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xff000E6B), fontWeight: FontWeight.bold))],
      ),
    );
  }

  Widget _buildPopularPlaces() {
    // фиксированная высота под карточку -> убирает RenderFlex overflow
    const double cardHeight = 220;
    const double cardWidth  = 130;

    return SizedBox(
      height: cardHeight,
      child: StreamBuilder<List<Place>>(
        stream: _popularPlacesStream(limit: 4, window: const Duration(days: 30)),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 3));
          }
          final data = snap.data ?? const <Place>[];
          if (data.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Ещё нет популярных мест — ставьте лайки на страницах мест.'),
              ),
            );
          }

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final place = data[i];
              return SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: KtPlaceCard(place: place),
              );
            },
          );
        },
      ),
    );
  }


  Widget _buildNews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(children: [Icon(Icons.article_outlined, color: Color(0xff000E6B)), SizedBox(width: 8), Text("Новости", style: TextStyle(color: Color(0xff000E6B), fontSize: 20, fontWeight: FontWeight.bold))]),
        ),
        SizedBox(
          height: 160,
          child: FutureBuilder<List<Map<String, String>>>(
            future: NewsService().fetchNews(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Нет новостей"));
              final news = snapshot.data!;
              return ListView.separated(
                scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: news.length,
                separatorBuilder: (_,  __) => const SizedBox(width: 14),
                itemBuilder: (context, i) {
                  final n = news[i];
                  return SizedBox(
                    width: 260,
                    child: GestureDetector(
                      onTap: () async {
                        final urlStr = n["link"];
                        if (urlStr == null || urlStr.isEmpty) return;
                        final url = Uri.parse(urlStr);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } else {
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Не удалось открыть ссылку: $urlStr')));
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: Offset(0, 4))],
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                            if (n["imageUrl"] != null && n["imageUrl"]!.isNotEmpty)
                            ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      child: Image.network(
                        n["imageUrl"]!,
                        width: double.infinity,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                      Text(n["date"] ?? "", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 6),
                      Text(
                        n["title"] ?? "",
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xff2A5CAA)),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Align(
                          alignment: Alignment.bottomRight,
                          child: Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xff2A5CAA))
                      ),],))],)
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ), 
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = widget.testDate ?? DateTime.now();
    final dayTime = widget.testDate != null ? _getDayTime(now) : _currentDayTime;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      decoration: _decorationForTime(dayTime),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: RootShellHost.bottomGap),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ▼▼▼ ИСПОЛЬЗУЕМ НАШ НОВЫЙ ИЗОЛИРОВАННЫЙ ВИДЖЕТ ▼▼▼
                BannerSlider(bannerItems: bannerItems),
                _buildCategoriesSection(),
                _buildDirectionsButton(context),
                _popularHeader(context),
                _buildPopularPlaces(),
                _buildArticlesSection(),
                const SizedBox(height: 16),
                _buildNews(),
                const SizedBox(height: 70),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NewsService {
  Future<List<Map<String, String>>> fetchNews() async {
    try {
      final res = await http.get(Uri.parse("https://us-central1-steppe-compas.cloudfunctions.net/getNews"));
      if (res.statusCode == 200) {
        final document = parser.parse(res.body);

        final items = document.querySelectorAll("div.news-item, div.item_news, div[class*=news]");
        return items.take(5).map((e) {
          final titleEl = e.querySelector("a.title-link, a[href][class*=title], .news-title a, h3 a, h2 a");
          final dateEl = e.querySelector(".news-date, .date, time, .entry-date");
          final imageEl = e.querySelector('img');
          final imageUrl = imageEl != null ? (imageEl.attributes['src'] ?? '') : '';
          String link = "";
          if (titleEl != null) {
            final href = titleEl.attributes["href"];
            if (href != null) {
              if (href.startsWith("http")) {
                link = href;
              } else if (href.startsWith("/")) {
                link = "https://travelpress.kz$href";
              } else {
                link = "https://travelpress.kz/news/kazakhstan/$href";
              }
            }
          }
          return {
            "title": titleEl?.text.trim() ?? "Без заголовка",
            "date": dateEl?.text.trim() ?? "",
            "link": link,
            "imageUrl": imageUrl,          };
        }).toList();
      }
      print('Failed to load news: ${res.statusCode}');
      return [];
    } catch (e) {
      print('Error fetching news: $e');
      return [];
    }
  }
}

// ===================================================================
// ▼▼▼ НАШ НОВЫЙ ИЗОЛИРОВАННЫЙ ВИДЖЕТ ДЛЯ СЛАЙДЕРА ▼▼▼
// ===================================================================
class BannerSlider extends StatefulWidget {
  final List<Map<String, String>> bannerItems;
  const BannerSlider({super.key, required this.bannerItems});

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  int _currentCarouselPage = 0;
  late final PageController _pageController;
  Timer? _autoplayTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoplay();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoplayTimer?.cancel();
    super.dispose();
  }

  void _startAutoplay() {
    _autoplayTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      int nextPage = _currentCarouselPage + 1;
      if (nextPage >= widget.bannerItems.length) {
        nextPage = 0;
      }
      _pageController.animateToPage(nextPage, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bannerItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: SizedBox(
          height: 250.0,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: widget.bannerItems.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentCarouselPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = widget.bannerItems[index];
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        item['imagePath']!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(color: Colors.blueGrey.shade100, child: const Center(child: Icon(Icons.broken_image, color: Colors.blueGrey, size: 50)));
                        },
                      ),
                      Positioned(
                        bottom: 16.0, left: 16.0, right: 16.0,
                        child: Text(
                          item['text']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Lobster',
                            fontSize: 26,
                            color: Colors.white,
                            shadows: [Shadow(blurRadius: 8.0, color: Colors.black87, offset: Offset(2.0, 2.0))],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                },
              ),
              Positioned(
                bottom: 8.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: widget.bannerItems.asMap().entries.map((entry) {
                    return GestureDetector(
                      onTap: () => _pageController.animateToPage(entry.key, duration: const Duration(milliseconds: 300), curve: Curves.linear),
                      child: Container(
                        width: 8.0,
                        height: 8.0,
                        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(_currentCarouselPage == entry.key ? 0.9 : 0.4)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
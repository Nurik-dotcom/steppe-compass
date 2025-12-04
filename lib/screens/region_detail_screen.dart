

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../widgets/root_shell_host.dart';
import '../models/region.dart';
import '../models/place.dart';
import 'place_detail_screen.dart';
import '../widgets/kt_place_card.dart';

enum _Tab { attractions, restaurants, hotels }

const Set<String> _restSynonyms = {'ресторан', 'рестораны', 'кафе', 'restaurant', 'restaurants', 'cafe', 'coffee', 'coffee shop'};
const Set<String> _hotelSynonyms = {'отель', 'отели', 'гостиница', 'гостиницы', 'hotel', 'hotels', 'guesthouse', 'hostel', 'guest house'};
const _kBeige = Color(0xFFF5F5DC);

String _norm(String? s) => (s ?? '').trim().toLowerCase();

extension _PlaceCategoryTags on Place {
  Set<String> _allCategoryTagsLower() {
    final allTags = <String>{};
    for (final c in categories) { allTags.add(_norm(c)); }
    for (final s in subcategories) { allTags.add(_norm(s)); }
    allTags.remove('');
    return allTags;
  }
  bool _isRestaurantOrCafe() => _allCategoryTagsLower().any(_restSynonyms.contains);
  bool _isHotel() => _allCategoryTagsLower().any(_hotelSynonyms.contains);
}

class RegionDetailScreen extends StatelessWidget {
  final Region region;
  const RegionDetailScreen({Key? key, required this.region}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBeige,
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                expandedHeight: 280.0,
                floating: false,
                pinned: true,
                stretch: true,
                backgroundColor: _kBeige,
                surfaceTintColor: _kBeige,
                automaticallyImplyLeading: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(region.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2, color: Colors.black54)])),
                  centerTitle: true,
                  titlePadding: const EdgeInsets.only(left: 48, right: 48, bottom: 16),
                  collapseMode: CollapseMode.pin,
                  background: _RegionHeader(region: region),
                ),
              ),
              

              SliverToBoxAdapter(
                child: Container(
                  color: _kBeige,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Text(
                    region.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      
                      fontFamily: 'Nunito', 
                      fontSize: 15,
                      height: 1.6,
                      color: Colors.black.withOpacity(0.8), 
                    ),
                    textAlign: TextAlign.left, 
                    
                  ),
                ),
              ),
              SliverPersistentHeader(
                delegate: _SliverTabBarDelegate(
                  const TabBar(
                    isScrollable: true,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: TextStyle(fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.w700, fontSize: 16),
                    unselectedLabelStyle: TextStyle(fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.w600, fontSize: 16),
                    tabs: [Tab(text: 'Достопримечательности'), Tab(text: 'Рестораны'), Tab(text: 'Отели')],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            children: [
              _PlacesListForRegion(regionId: region.id, tab: _Tab.attractions),
              _PlacesListForRegion(regionId: region.id, tab: _Tab.restaurants),
              _PlacesListForRegion(regionId: region.id, tab: _Tab.hotels),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _SliverTabBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: _kBeige, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 4))]), child: _tabBar);
  }
  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}

class _RegionHeader extends StatelessWidget {
  final Region region;
  const _RegionHeader({Key? key, required this.region}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final imageUrl = region.imageUrl;
    Widget image;
    if (imageUrl.isEmpty) { image = _placeholder(context); }
    else if (imageUrl.startsWith('http')) { image = Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder(context)); }
    else { image = Image.asset(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder(context)); }
    return Stack(fit: StackFit.expand, children: [image, Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.6), Colors.transparent], stops: const [0.0, 0.5], begin: Alignment.topCenter, end: Alignment.bottomCenter))))]);
  }
  Widget _placeholder(BuildContext context) => Container(color: Theme.of(context).colorScheme.surfaceVariant, child: Center(child: Icon(Icons.landscape_outlined, size: 64, color: Theme.of(context).colorScheme.outline)));
}

enum _SortType { byPopularity, byName }

class _PlacesListForRegion extends StatefulWidget {
  final String regionId;
  final _Tab tab;
  const _PlacesListForRegion({Key? key, required this.regionId, required this.tab}) : super(key: key);
  @override
  State<_PlacesListForRegion> createState() => _PlacesListForRegionState();
}

class _PlacesListForRegionState extends State<_PlacesListForRegion> {
  _SortType _currentSort = _SortType.byPopularity;
  late Future<Map<String, int>> _likeCountsFuture;

  @override
  void initState() {
    super.initState();
    _likeCountsFuture = _fetchLikeCounts();
  }

  
  Future<Map<String, int>> _fetchLikeCounts() async {
    final counts = <String, int>{};
    try {
      
      
      final querySnapshot = await FirebaseFirestore.instance
          .collection('likes')
          .where('createdAt', isGreaterThan: DateTime.now().subtract(const Duration(days: 365)))
          .get();

      for (final doc in querySnapshot.docs) {
        final placeId = doc.data()['placeId'] as String?;
        if (placeId != null) {
          counts[placeId] = (counts[placeId] ?? 0) + 1;
        }
      }
    } catch (e) {
      debugPrint("Error fetching like counts: $e");
    }
    return counts;
  }

  bool _filter(Place p) {
    if (p.regionId != widget.regionId) return false;
    final isRest = p._isRestaurantOrCafe();
    final isHotel = p._isHotel();
    switch (widget.tab) {
      case _Tab.attractions: return !isRest && !isHotel;
      case _Tab.restaurants: return isRest && !isHotel;
      case _Tab.hotels: return isHotel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final placesBox = Hive.box<Place>('places');

    
    return ValueListenableBuilder(
      valueListenable: placesBox.listenable(),
      builder: (context, Box<Place> box, _) {
        final items = box.values.where(_filter).toList();

        final msg = switch (widget.tab) {
          _Tab.attractions => 'В этом регионе пока нет достопримечательностей.',
          _Tab.restaurants => 'В этом регионе пока нет ресторанов/кафе.',
          _Tab.hotels => 'В этом регионе пока нет отелей/гостиниц.',
        };
        if (items.isEmpty) return _EmptyState(title: 'Нет данных', subtitle: msg);

        
        return FutureBuilder<Map<String, int>>(
          future: _likeCountsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final likeCounts = snapshot.data ?? {};

            
            if (_currentSort == _SortType.byPopularity) {
              items.sort((a, b) => (likeCounts[b.id] ?? 0).compareTo(likeCounts[a.id] ?? 0));
            } else {
              items.sort((a, b) => a.name.compareTo(b.name));
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text("Сортировать:", style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(width: 8),
                      DropdownButton<_SortType>(
                        value: _currentSort,
                        items: const [
                          DropdownMenuItem(value: _SortType.byPopularity, child: Text("По популярности")),
                          DropdownMenuItem(value: _SortType.byName, child: Text("По алфавиту")),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _currentSort = value);
                        },
                        underline: const SizedBox(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(12, 8, 12, 140.0),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Divider(height: 24, thickness: 0.5, indent: 16, endIndent: 16, color: Colors.black.withOpacity(0.1)),
                    itemBuilder: (context, i) {
                      final place = items[i];
                      return InkWell(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place))),
                        child: KtPlaceCard(place: place),
                      ).animate().fade(duration: 500.ms, delay: (100 * i).ms).slideY(begin: 0.2, curve: Curves.easeOut);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  const _EmptyState({Key? key, required this.title, required this.subtitle}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.place_outlined, size: 48, color: t.disabledColor), const SizedBox(height: 12), Text(title, style: t.textTheme.titleMedium?.copyWith(fontFamily: 'PlayfairDisplay')), const SizedBox(height: 8), Text(subtitle, textAlign: TextAlign.center, style: t.textTheme.bodyMedium?.copyWith(fontFamily: 'PlayfairDisplay', color: t.hintColor))])));
  }
}
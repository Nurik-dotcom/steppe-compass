import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/place.dart';
import '../services/favorites_service.dart';
import '../services/auth_service.dart';
import 'place_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
enum _DayTime { morning, day, evening, night }

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String _userId = 'guest';
  late Box<Place> _places;

  Timer? _tick;
  late _DayTime _currentDayTime;

  @override
  void initState() {
    super.initState();
    _places = Hive.box<Place>('places');
    _loadUser();

    _currentDayTime = _getDayTime(DateTime.now());
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      final dt = _getDayTime(DateTime.now());
      if (dt != _currentDayTime) {
        setState(() => _currentDayTime = dt);
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _loadUser() async {
    // Используем прямой доступ к текущему пользователю Firebase
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user != null) {
      // В FavoritesService лучше использовать uid, а не email, т.к. он уникален
      setState(() => _userId = user.uid);
    }
  }

  _DayTime _getDayTime(DateTime now) {
    final h = now.hour;
    if (h >= 6 && h < 12) return _DayTime.morning;
    if (h < 18) return _DayTime.day;
    if (h < 22) return _DayTime.evening;
    return _DayTime.night;
  }

  BoxDecoration _decorationForTime(_DayTime dt) {
    switch (dt) {
      case _DayTime.morning:
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFBBC8C8),
              Color(0xFF5E9F9A),
              Color(0xFFDDBDAA),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );
      case _DayTime.day:
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFA9C9EC),
              Color(0xFFC6D7EB),
              Color(0xFFD3BEA3),
              Color(0xFFD4AC77),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );
      case _DayTime.evening:
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF61556A),
              Color(0xFF7E80A5),
              Color(0xFFE6BFB2),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );
      case _DayTime.night:
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF6B75AD),
              Color(0xFF324476),
              Color(0xFF11213B),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      decoration: _decorationForTime(_currentDayTime),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            decoration: _decorationForTime(_currentDayTime),
            child: const SafeArea(
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite, color: Colors.white, size: 26),
                    SizedBox(width: 10),
                    Text(
                      "Избранное",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: ValueListenableBuilder(
          valueListenable: FavoritesService.listenable(_userId),
          builder: (_, __, ___) {
            final ids = FavoritesService.all(_userId);
            final items = ids.map((id) => _places.get(id)).whereType<Place>().toList();

            if (items.isEmpty) {
              return const Center(
                child: Text(
                  'Список избранного пуст.',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, i) {
                final p = items[i];
                final img = (p.imageUrl.isNotEmpty) ? p.imageUrl.first : null;

                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: p)),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withOpacity(0.85),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                          child: img == null
                              ? Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.photo, size: 40, color: Colors.grey),
                          )
                              : (img.startsWith('http')
                              ? Image.network(img,
                              width: 100, height: 100, fit: BoxFit.cover)
                              : Image.asset(img,
                              width: 100, height: 100, fit: BoxFit.cover)),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (p.description != null && p.description!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      p.description!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.redAccent, size: 28),
                          onPressed: () => FavoritesService.toggle(_userId, p.id),
                          tooltip: 'Убрать из избранного',
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

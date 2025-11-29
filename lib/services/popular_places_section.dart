import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/place.dart';
import '../widgets/kt_place_card.dart';

enum PopularFilter { likes, comments }

class PopularPlacesSection extends StatefulWidget {
  const PopularPlacesSection({super.key});

  @override
  State<PopularPlacesSection> createState() => _PopularPlacesSectionState();
}

class _PopularPlacesSectionState extends State<PopularPlacesSection> {
  PopularFilter _filter = PopularFilter.likes;

  late final Stream<List<Place>> _placesStream;

  @override
  void initState() {
    super.initState();

    // один стрим на все времена — НИКАКИХ смен стрима при переключении
    _placesStream = FirebaseFirestore.instance
        .collection('place')
        .snapshots()
        .map(
          (snap) => snap.docs
          .map((d) => Place.fromJson({'id': d.id, ...d.data()}))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double cardHeight = 220;
    const double cardWidth = 130;

    return SizedBox(
      height: cardHeight + 56,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- переключатель лайки / комментарии ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('По лайкам'),
                  selected: _filter == PopularFilter.likes,
                  onSelected: (_) {
                    setState(() => _filter = PopularFilter.likes);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('По комментариям'),
                  selected: _filter == PopularFilter.comments,
                  onSelected: (_) {
                    setState(() => _filter = PopularFilter.comments);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // --- сами популярные места ---
          Expanded(
            child: StreamBuilder<List<Place>>(
              stream: _placesStream, // один и тот же стрим
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 3),
                  );
                }

                final places = snap.data ?? const <Place>[];
                if (places.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Ещё нет популярных мест — ставьте лайки и пишите отзывы.',
                    ),
                  );
                }

                // 🔥 ЛОКАЛЬНАЯ сортировка, БЕЗ нового запроса к Firestore
                final sorted = [...places];
                sorted.sort((a, b) {
                  if (_filter == PopularFilter.likes) {
                    return b.likesCount.compareTo(a.likesCount);
                  } else {
                    return b.commentsCount.compareTo(a.commentsCount);
                  }
                });

                final top = sorted.take(8).toList();

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: top.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final place = top[i];
                    return SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: KtPlaceCard(place: place),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

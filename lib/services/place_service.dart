
import 'dart:math';
import 'package:hive/hive.dart';
import '../models/place.dart';
import 'likes_service.dart';

class PlaceService {
  final Box<Place> _placesBox = Hive.box<Place>('places');
  final LikesService _likes = LikesService();

  
  List<Place> getTopLikedPlacesSync({int limit = 4, bool onlyWithLikes = true}) {
    final all = _placesBox.values.toList(growable: false);
    if (all.isEmpty) return const [];

    
    final Map<String, int> likes = {
      for (final p in all) p.id: _likes.getLikesCount(p.id),
    };

    
    final filtered = onlyWithLikes
        ? all.where((p) => (likes[p.id] ?? 0) > 0).toList()
        : all.toList();

    if (filtered.isEmpty) return const [];

    
    filtered.sort((a, b) {
      final lb = likes[b.id] ?? 0;
      final la = likes[a.id] ?? 0;
      if (lb != la) return lb.compareTo(la);
      return (a.name).compareTo(b.name); 
    });

    
    return filtered.take(min(limit, filtered.length)).toList(growable: false);
  }

  
  Future<List<Place>> getTopLikedPlaces({int limit = 4, bool onlyWithLikes = true}) async {
    return getTopLikedPlacesSync(limit: limit, onlyWithLikes: onlyWithLikes);
  }
}

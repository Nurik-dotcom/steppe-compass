import 'package:cloud_firestore/cloud_firestore.dart';

class PlaceStatsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Пересчёт ВСЕХ мест (для админской кнопки)
  Future<void> recalcPlaceStats() async {
    final placesSnap = await _db.collection('place').get();

    for (final placeDoc in placesSnap.docs) {
      final placeId = placeDoc.id;
      await recalcSinglePlace(placeId);
    }

    print('Полный пересчёт статистики мест завершён');
  }

  /// Лёгкий пересчёт ТОЛЬКО одного места (по placeId)
  Future<void> recalcSinglePlace(String placeId) async {
    // лайки
    final likesSnap = await _db
        .collection('likes')
        .where('placeId', isEqualTo: placeId)
        .get();
    final likesCount = likesSnap.size;

    // отзывы
    final reviewsSnap = await _db
        .collection('reviews')
        .where('placeId', isEqualTo: placeId)
        .get();
    final commentsCount = reviewsSnap.size;

    await _db.collection('place').doc(placeId).update({
      'likesCount': likesCount,
      'commentsCount': commentsCount,
    });

    print('Обновлена статистика для места $placeId: '
        'likes=$likesCount, comments=$commentsCount');
  }
}

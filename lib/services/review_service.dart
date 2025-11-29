import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kazakhstan_travel/services/place_stat_service.dart';
import '../models/review.dart';


class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final CollectionReference<Map<String, dynamic>> _reviewsCollection;

  ReviewService() {
    _reviewsCollection = _db.collection('reviews');
  }

  /// Отправляет новый отзыв в Firebase + обновляет статистику места
  Future<void> postReview(PlaceReview review) async {
    try {
      // 1. создаём отзыв
      await _reviewsCollection.add(review.toJson());

      // 2. лёгкий пересчёт статистики ТОЛЬКО для этого места
      await PlaceStatsService().recalcSinglePlace(review.placeId);
    } catch (e) {
      print("Ошибка при отправке отзыва или пересчёте статистики: $e");
      rethrow;
    }
  }

  /// Получает 5 самых новых отзывов для конкретного места
  Stream<List<PlaceReview>> getReviewsForPlace(String placeId, {int limit = 5}) {
    final query = _reviewsCollection
        .where('placeId', isEqualTo: placeId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return PlaceReview.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }
}

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
      await _reviewsCollection.add(review.toJson());
      await PlaceStatsService().recalcSinglePlace(review.placeId);
    } catch (e) {
      print("Ошибка при отправке отзыва или пересчёте статистики: $e");
      rethrow;
    }
  }

  /// Стрим последних N отзывов для места
  Stream<List<PlaceReview>> getReviewsForPlace(String placeId, {int limit = 5}) {
    final query = _reviewsCollection
        .where('placeId', isEqualTo: placeId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => PlaceReview.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  /// 🔥 Живой счётчик количества отзывов для места
  Stream<int> watchReviewCount(String placeId) {
    return _reviewsCollection
        .where('placeId', isEqualTo: placeId)
    // если есть модерация, можешь добавить:
    // .where('isApproved', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}

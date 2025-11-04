// lib/services/review_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';

class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final CollectionReference<Map<String, dynamic>> _reviewsCollection;

  ReviewService() {
    _reviewsCollection = _db.collection('reviews');
  }

  /// Отправляет новый отзыв в Firebase
  Future<void> postReview(PlaceReview review) async {
    try {
      // Конвертируем наш объект в Map и отправляем в Firestore
      await _reviewsCollection.add(review.toJson());
    } catch (e) {
      // Обработка ошибок
      print("Ошибка при отправке отзыва: $e");
      rethrow;
    }
  }

  /// Получает 5 самых новых отзывов для конкретного места
  Stream<List<PlaceReview>> getReviewsForPlace(String placeId, {int limit = 5}) {
    // Создаем запрос:
    // 1. Фильтруем по 'placeId'
    // 2. Сортируем по 'createdAt' в порядке убывания (новые вверху)
    // 3. Ограничиваем выборку (limit)
    final query = _reviewsCollection
        .where('placeId', isEqualTo: placeId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    // snapshots() возвращает Stream, который автоматически обновляется
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // Преобразуем каждый документ в наш объект PlaceReview
        return PlaceReview.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }
}
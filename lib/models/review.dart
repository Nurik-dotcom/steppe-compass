// lib/models/review.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PlaceReview {
  final String id;
  final String placeId;
  final String userId;
  final String authorName;
  final String? authorPhotoUrl; // <-- ДОБАВЛЕНО ЭТО ПОЛЕ
  final String text;
  final int rating;
  final Timestamp createdAt;

  PlaceReview({
    required this.id,
    required this.placeId,
    required this.userId,
    required this.authorName,
    this.authorPhotoUrl, // <-- ДОБАВЛЕНО В КОНСТРУКТОР
    required this.text,
    required this.rating,
    required this.createdAt,
  });

  // Преобразование из JSON (Map от Firestore) в объект PlaceReview
  factory PlaceReview.fromJson(Map<String, dynamic> json, String id) {
    return PlaceReview(
      id: id,
      placeId: json['placeId'] ?? '',
      userId: json['userId'] ?? '',
      authorName: json['authorName'] ?? 'Аноним',
      authorPhotoUrl: json['authorPhotoUrl'] as String?, // <-- ДОБАВЛЕНО
      text: json['text'] ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] ?? Timestamp.now(),
    );
  }

  // Преобразование объекта PlaceReview в Map для Firestore
  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'userId': userId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl, // <-- ДОБАВЛЕНО
      'text': text,
      'rating': rating,
      'createdAt': createdAt,
    };
  }
}
// lib/services/firebase_data_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/place.dart';

class FirebaseDataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<int> syncPlacesFromFirestore() async {
    try {
      // ▼▼▼ ИЗМЕНЕНИЕ №1: Правильное имя коллекции 'place' ▼▼▼
      final collectionRef = _db.collection('place');

      final snapshot = await collectionRef.get();

      // ▼▼▼ ИЗМЕНЕНИЕ №2: Оставляем оригинальное имя бокса 'places' для совместимости ▼▼▼
      final placesBox = Hive.box<Place>('places');

      await placesBox.clear();

      if (snapshot.docs.isEmpty) {
        debugPrint('[FirebaseDataService] Коллекция "place" пуста или не найдена.');
        return 0;
      }

      final Map<String, Place> placesToCache = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        // Убеждаемся, что ID документа Firebase используется как ID объекта,
        // если он не был задан в самом документе.
        data['id'] = data['id'] ?? doc.id;
        final place = Place.fromJson(data);
        placesToCache[place.id] = place;
      }

      await placesBox.putAll(placesToCache);

      debugPrint('[FirebaseDataService] Успешно синхронизировано ${placesToCache.length} мест из Firestore в Hive.');

      return placesToCache.length;

    } catch (e) {
      debugPrint('[FirebaseDataService] Произошла ошибка при синхронизации мест: $e');
      return 0;
    }
  }
}
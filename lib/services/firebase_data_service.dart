// lib/services/firebase_data_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/place.dart';

/// Этот сервис отвечает за синхронизацию данных из Firebase Firestore
/// в локальную базу данных Hive, которая используется как кэш.
class FirebaseDataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Загружает все документы из коллекции 'places' в Firestore,
  /// преобразует их в объекты [Place] и сохраняет в Hive box 'places'.
  ///
  /// Этот метод полностью перезаписывает все данные в боксе 'places',
  /// чтобы обеспечить консистентность с удаленной базой данных.
  Future<int> syncPlacesFromFirestore() async {
    try {
      // 1. Получаем ссылку на коллекцию 'places' в Firestore.
      //    Убедитесь, что название коллекции в вашей базе данных Firebase именно такое.
      final collectionRef = _db.collection('place');

      // 2. Выполняем запрос на получение всех документов из коллекции.
      final snapshot = await collectionRef.get();

      // 3. Открываем Hive box для мест.
      final placesBox = Hive.box<Place>('place');

      // 4. Полностью очищаем локальный кэш перед синхронизацией.
      //    Это гарантирует, что удаленные в Firebase места также исчезнут из кэша.
      await placesBox.clear();

      if (snapshot.docs.isEmpty) {
        debugPrint('[FirebaseDataService] Коллекция "places" пуста или не найдена.');
        return 0;
      }

      // 5. Проходим по каждому документу, создаем объект Place и добавляем его в Map для пакетной записи.
      final Map<String, Place> placesToCache = {};
      for (final doc in snapshot.docs) {
        // Используем фабричный конструктор Place.fromJson для создания объекта.
        // ID документа Firebase становится ID нашего объекта.
        final data = doc.data();
        data['id'] = doc.id; // Убеждаемся, что ID документа используется
        final place = Place.fromJson(data);
        placesToCache[place.id] = place;
      }

      // 6. Используем putAll для эффективной пакетной записи всех данных в Hive.
      await placesBox.putAll(placesToCache);

      debugPrint('[FirebaseDataService] Успешно синхронизировано ${placesToCache.length} мест из Firestore в Hive.');

      // 7. Возвращаем количество синхронизированных объектов.
      return placesToCache.length;

    } catch (e) {
      debugPrint('[FirebaseDataService] Произошла ошибка при синхронизации мест: $e');
      // В случае ошибки возвращаем 0.
      return 0;
    }
  }
}
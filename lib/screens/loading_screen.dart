// lib/screens/loading_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // <-- ДОБАВЛЕНО
import 'root_shell.dart';
import '../services/firebase_data_service.dart';
import '../services/json_import_service.dart';

// ▼▼▼ ДОБАВЛЕНЫ ВСЕ ИМПОРТЫ, КОТОРЫЕ МЫ УБРАЛИ ИЗ MAIN ▼▼▼
import '../models/user.dart';
import '../models/place.dart';
import '../models/region.dart';
import '../services/favorites_service.dart';
import '../services/likes_service.dart';
// ▲▲▲ КОНЕЦ ДОБАВЛЕННЫХ ИМПОРТОВ ▲▲▲


class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  String _loadingText = 'Подготовка данных...'; // Текст для отображения статуса

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Запускаем загрузку данных и навигацию
    _initializeAndNavigate();
  }

  /// Запускает и загрузку данных, и минимальную задержку
  Future<void> _initializeAndNavigate() async {
    // 1. Процесс минимальной задержки
    final delay = Future.delayed(const Duration(milliseconds: 2500));

    // 2. Процесс загрузки данных (теперь включает ВООБЩЕ ВСЁ)
    final dataLoadingProcess = _loadData();

    // Ожидаем завершения ОБОИХ процессов.
    await Future.wait([delay, dataLoadingProcess]);

    // После завершения переходим на главный экран
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const RootShell()),
      );
    }
  }

  /// ▼▼▼ ЭТОТ МЕТОД ТЕПЕРЬ ВЫПОЛНЯЕТ ВСЮ РАБОТУ ▼▼▼
  Future<void> _loadData() async {
    try {

      setState(() => _loadingText = 'Инициализация сервисов...');
      debugPrint('[LoadingScreen] Начинаем инициализацию сервисов...');
      await FavoritesService.init();
      await LikesService.init();

      debugPrint('[LoadingScreen] Регистрируем адаптеры...');
      try { Hive.registerAdapter(UserAdapter()); } catch (_) {}
      try { Hive.registerAdapter(PlaceAdapter()); } catch (_) {}
      try { Hive.registerAdapter(RegionAdapter()); } catch (_) {}

      setState(() => _loadingText = 'Открытие локального хранилища...');
      debugPrint('[LoadingScreen] Открываем боксы Hive...');
      await Hive.openBox<User>('users');
      await Hive.openBox('session');
      await Hive.openBox<Place>('places');
      await Hive.openBox<Region>('regions');
      debugPrint('[LoadingScreen] Боксы открыты.');

      // --- Этап 2: Загрузка и Синхронизация Данных ---
      setState(() => _loadingText = 'Загрузка данных...');
      final seeder = JsonSeedService();
      await seeder.seedIfNeeded(onLog: (m) => debugPrint(m));
      debugPrint('[LoadingScreen] Проверка сидинга завершена.');

      setState(() => _loadingText = 'Синхронизация с сервером...');
      final firebaseService = FirebaseDataService();
      final placesCount = await firebaseService.syncPlacesFromFirestore();
      debugPrint('[LoadingScreen] Firestore synced: $placesCount');

    } catch (e) {
      debugPrint("[LoadingScreen] КРИТИЧЕСКАЯ ОШИБКА во время загрузки данных: $e");
      if (mounted) {
        setState(() => _loadingText = 'Ошибка: $e');
      }
      // В случае ошибки, мы можем либо показать экран ошибки,
      // либо (как сейчас) просто продолжить работу с кэшированными данными.
    }
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EAD6), // Ваш фоновый цвет
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _controller,
              child: const Icon(
                Icons.explore,
                size: 64.0,
                color: Color(0xFF0EAD6B),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _loadingText, // Используем переменную состояния
              style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 16,
                  color: Color(0xFF0EAD6B)
              ),
            ),
          ],
        ),
      ),
    );
  }
}
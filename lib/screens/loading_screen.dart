// lib/screens/loading_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'root_shell.dart';
import 'login_screen.dart';
import '../services/firebase_data_service.dart';
import '../services/json_import_service.dart';
import '../models/user.dart';
import '../models/place.dart';
import '../models/region.dart';
import '../services/favorites_service.dart';
import '../services/likes_service.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  String _loadingText = 'Подготовка данных...';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    final delay = Future.delayed(const Duration(milliseconds: 2500));
    final dataLoadingProcess = _loadData();

    await Future.wait([delay, dataLoadingProcess]);

    // ✅ После загрузки — проверка авторизации
    final user = fb.FirebaseAuth.instance.currentUser;
    if (!mounted) return;

    if (user == null) {
      debugPrint('[LoadingScreen] Пользователь не авторизован — переход на LoginScreen');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      debugPrint('[LoadingScreen] Авторизован как ${user.email}');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RootShell()),
      );
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() => _loadingText = 'Инициализация сервисов...');
      await FavoritesService.init();
      await LikesService.init();

      Hive.registerAdapter(UserAdapter());
      Hive.registerAdapter(PlaceAdapter());
      Hive.registerAdapter(RegionAdapter());

      setState(() => _loadingText = 'Открытие локального хранилища...');
      await Hive.openBox<User>('users');
      await Hive.openBox('session');
      await Hive.openBox<Place>('places');
      await Hive.openBox<Region>('regions');

      setState(() => _loadingText = 'Загрузка данных...');
      final seeder = JsonSeedService();
      await seeder.seedIfNeeded(onLog: debugPrint);

      setState(() => _loadingText = 'Синхронизация с сервером...');
      final firebaseService = FirebaseDataService();
      await firebaseService.syncPlacesFromFirestore();

    } catch (e) {
      debugPrint('[LoadingScreen] Ошибка загрузки: $e');
      if (mounted) setState(() => _loadingText = 'Ошибка: $e');
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
      backgroundColor: const Color(0xFFF0EAD6),
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
              _loadingText,
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 16,
                color: Color(0xFF0EAD6B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

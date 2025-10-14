import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'widgets/connectivity_wrapper.dart';
import 'firebase_options.dart';
import 'models/user.dart';
import 'models/place.dart';
import 'models/region.dart';
import 'services/favorites_service.dart';
import 'services/likes_service.dart';
import 'services/json_import_service.dart';

import 'screens/loading_screen.dart';
import 'screens/login_screen.dart';
import 'screens/root_shell.dart';
import 'screens/direction_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/admin_panel_screen.dart';
import 'screens/debug_data_screen.dart';

Future<void> main() async {
  // ▼▼▼ ВСЯ ИНИЦИАЛ-ЗАГРУЗКА ТЕПЕРЬ ЗДЕСЬ, КАК И ДОЛЖНО БЫТЬ ▼▼▼
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  await FavoritesService.init();
  await LikesService.init();

  try { Hive.registerAdapter(UserAdapter()); } catch (_) {}
  try { Hive.registerAdapter(PlaceAdapter()); } catch (_) {}
  try { Hive.registerAdapter(RegionAdapter()); } catch (_) {}

  await Hive.openBox<User>('users');
  await Hive.openBox('session');
  await Hive.openBox<Place>('places');
  await Hive.openBox<Region>('regions');

  final seeder = JsonSeedService();
  await seeder.seedIfNeeded(onLog: (m) => debugPrint(m));
  // ▲▲▲ КОНЕЦ БЛОКА ИНИЦИАЛИЗАЦИИ ▲▲▲

  runApp(const KazakhstanTravelApp());
}

class KazakhstanTravelApp extends StatelessWidget {
  const KazakhstanTravelApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kazakhstan Travel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),
      routes: {
        '/directions': (_) => const DirectionsScreen(),
        '/profile': (_) => const UserProfileScreen(),
        '/admin': (_) => const AdminPanelScreen(),
        '/debug': (_) => const DebugDataScreen(),
      },
      home: const ConnectivityWrapper(
        child: AuthGate(),
      ),
    );
  }
}

/// Этот виджет решает, куда направить пользователя

class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // Переменная для хранения подписки на поток аутентификации
  late final StreamSubscription<fb.User?> _authSubscription;
  // Переменная для хранения текущего статуса пользователя
  fb.User? _currentUser;
  // Флаг, чтобы показать индикатор загрузки только при самом первом запуске
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // В момент создания виджета мы подписываемся на поток authStateChanges
    _authSubscription = fb.FirebaseAuth.instance.authStateChanges().listen((fb.User? user) {
      // Когда приходит новое событие (вход или выход), мы вызываем setState
      setState(() {
        _currentUser = user; // Обновляем текущего пользователя
        _isInitialized = true; // Отмечаем, что первая проверка прошла
      });
    });
  }

  @override
  void dispose() {
    // Когда виджет уничтожается, очень важно отписаться от потока,
    // чтобы избежать утечек памяти
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Пока мы не получили первое событие, показываем крутилку
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Если после инициализации пользователя нет — показываем экран входа
    if (_currentUser == null) {
      return const LoginScreen();
    }
    // Если пользователь есть — показываем экран загрузки
    else {
      return const LoadingScreen();
    }
  }
}

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kazakhstan_travel/services/favorites_service.dart';

import 'firebase_options.dart';
import 'models/place.dart';
import 'models/region.dart';
import 'models/user.dart';
import 'screens/loading_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Инициализируем дефолтное Firebase-приложение
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Инициализируем Hive ОДИН раз
  await Hive.initFlutter();

  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(PlaceAdapter());
  Hive.registerAdapter(RegionAdapter());

  // ⚠️ если не хочешь каждый запуск чистить места — убери эту строку
  // await Hive.deleteBoxFromDisk('places');

  await Hive.openBox<Place>('places');
  await Hive.openBox<User>('users');
  await Hive.openBox('session');
  await Hive.openBox<Region>('regions');

  await FavoritesService.init();

  // 🔒 блокируем ориентацию только на мобильных
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  runApp(const SteppeCompassApp());
}

class SteppeCompassApp extends StatelessWidget {
  const SteppeCompassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Steppe Compass',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0EAD6B),
        fontFamily: 'PlayfairDisplay',
      ),
      home: const LoadingScreen(),
    );
  }
}

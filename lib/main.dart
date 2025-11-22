import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'screens/loading_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Инициализируем Firebase только   при отсутствии других приложений
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      name: 'steppe-compass',
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    // Используем уже инициализированный экземпляр
    await Firebase.app();
  }


  // ✅ инициализируем Hive
  await Hive.initFlutter();

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
      home: const LoadingScreen(), // Твой экран инициализации
    );
  }
}

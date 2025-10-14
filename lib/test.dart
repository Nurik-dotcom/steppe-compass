import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  String message;
  try {
    // Закрываем все открытые боксы одной командой
    await Hive.close();

    // Полностью удаляем все данные Hive
    await Hive.deleteFromDisk();

    message = '✅ Hive очищен: все боксы удалены.';
  } catch (e) {
    message = '❌ Не удалось очистить Hive: $e';
  }

  runApp(_WipeDoneApp(message: message));
}

class _WipeDoneApp extends StatelessWidget {
  final String message;
  const _WipeDoneApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '$message\n\nТеперь закрой приложение и запусти обычный main.dart.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'root_shell.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Запускаем навигацию на главный экран
    _navigateToHome();
  }

  /// Эта функция просто ждет 2.5 секунды и переходит дальше
  Future<void> _navigateToHome() async {
    // Ждем, чтобы пользователь успел увидеть анимацию
    await Future.delayed(const Duration(milliseconds: 2500));

    // После завершения задержки переходим на главный экран
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const RootShell()),
      );
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
            const Text(
              'Подготовка данных...',
              style: TextStyle(
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


import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  bool _obscureText = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  
  void _show(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _log(Object e, [StackTrace? st]) {
    debugPrint('[AUTH][REGISTER] $e');
    if (st != null) debugPrintStack(stackTrace: st);
  }

  String _humanizeAuthError(Object e) {
    if (e is fb.FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Этот email уже используется.';
        case 'invalid-email':
          return 'Некорректный email.';
        case 'operation-not-allowed':
          return 'Метод входа отключён в консоли Firebase.';
        case 'weak-password':
          return 'Слабый пароль (минимум 6 символов).';
        case 'network-request-failed':
          return 'Нет соединения с сетью. Проверьте интернет.';
        default:
          return 'Ошибка: ${e.code}';
      }
    }
    if (e is TimeoutException) return 'Сервер не ответил. Попробуйте ещё раз.';
    return 'Не удалось зарегистрироваться.';
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    
    if (email.isEmpty || password.isEmpty) {
      _show(context, 'Пожалуйста, введите email и пароль.');
      return;
    }
    if (!email.contains('@')) {
      _show(context, 'Некорректный email.');
      return;
    }
    if (password.length < 6) {
      _show(context, 'Пароль должен быть не короче 6 символов.');
      return;
    }

    setState(() => _loading = true);

    try {
      
      
      await _authService
          .register(email, password)
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;
    } on fb.FirebaseAuthException catch (e, st) {
      _log('FirebaseAuthException: ${e.code} ${e.message}', st);
      _show(context, _humanizeAuthError(e));
    } on TimeoutException catch (e, st) {
      _log('Timeout: $e', st);
      _show(context, 'Сервер не ответил. Попробуйте ещё раз.');
    } catch (e, st) {
      _log('Unknown register error: $e', st);
      _show(context, _humanizeAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const blueKazakhstan = Color(0xFF0F92AE);
    const yellowKazakhstan = Color(0xFFFFD54F);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [blueKazakhstan, yellowKazakhstan],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset("assets/images/yurt.png", height: 120),
                const SizedBox(height: 16),
                const Text(
                  'Создайте аккаунт',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Присоединяйтесь к миру туризма в Казахстане',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 32),

                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.email),
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          enabled: !_loading,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock),
                            labelText: 'Пароль',
                            border: const OutlineInputBorder(),
                            // Добавляем иконку-переключатель
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText ? Icons.visibility : Icons.visibility_off,
                              ),
                              // При нажатии меняем состояние и перерисовываем экран
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                          ),
                          // Привязываем видимость текста к нашей переменной
                          obscureText: _obscureText,
                          enabled: !_loading,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: blueKazakhstan,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _loading ? null : _register,
                            child: _loading
                                ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text(
                              'Зарегистрироваться',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Уже есть аккаунт? Войти',
                            style: TextStyle(fontSize: 16, color: blueKazakhstan),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../services/auth_service.dart';
import 'loading_screen.dart';
import 'register_screen.dart';
import 'home_screen.dart'; // если где-то используешь — можно оставить
import 'root_shell.dart'; // <-- добавили импорт

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
        case 'user-not-found':
          return 'Пользователь не найден.';
        case 'wrong-password':
          return 'Неверный пароль.';
        case 'network-request-failed':
          return 'Нет соединения с сетью.';
        default:
          return 'Ошибка: ${e.code}';
      }
    }
    if (e is TimeoutException) return 'Сервер не ответил. Попробуйте ещё раз.';
    return 'Не удалось выполнить операцию.';
  }

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  void _show(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
  void _log(Object e, [StackTrace? st]) {
    debugPrint('[AUTH] $e');
    if (st != null) debugPrintStack(stackTrace: st);
  }
  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _show(context, 'Введите email и пароль.');
      return;
    }

    setState(() => _loading = true);
    try {
      // ВАЖНО: пусть AuthService.login бросает исключение при ошибке.
      final ok = await _authService
          .login(email, password)
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoadingScreen()),
            (_) => false,
      );

    } on fb.FirebaseAuthException catch (e, st) {
      _log('FirebaseAuthException: ${e.code} ${e.message}', st);
      _show(context, _humanizeAuthError(e));
    } on TimeoutException catch (e, st) {
      _log('Timeout: $e', st);
      _show(context, 'Сервер не ответил. Попробуйте ещё раз.');
    } on HiveError catch (e, st) {
      _log('HiveError: $e', st);
      _show(context, 'Локальное хранилище (Hive) дало ошибку.');
    } catch (e, st) {
      _log('Unknown auth error: $e', st);
      _show(context, 'Не удалось войти: $e');
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
                  'Вход',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Рады видеть вас снова!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 32),

                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.email),
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                            enabled: !_loading,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Введите email';
                              if (!v.contains('@')) return 'Некорректный email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscure,
                            onFieldSubmitted: (_) => _loading ? null : _login(),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock),
                              labelText: 'Пароль',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                onPressed: _loading ? null : () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            enabled: !_loading,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Введите пароль';
                              if (v.length < 6) return 'Минимум 6 символов';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                backgroundColor: blueKazakhstan,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _loading ? null : _login,
                              child: _loading
                                  ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                                  : const Text(
                                'Войти',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                            child: const Text(
                              'Нет аккаунта? Зарегистрироваться',
                              style: TextStyle(fontSize: 16, color: blueKazakhstan),
                            ),
                          ),
                        ],
                      ),
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

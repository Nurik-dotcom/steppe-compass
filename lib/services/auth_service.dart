// lib/services/auth_service.dart
import 'package:hive/hive.dart';
import '../models/user.dart'; // Ваша обновленная Hive-модель User

// Firebase
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

class AuthService {
  final fb.FirebaseAuth _fa = fb.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  fb.User? get firebaseUser => _fa.currentUser;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  Future<Box> _sessionBox() async => Hive.openBox('session');

  /// Записывает данные пользователя в локальную сессию Hive.
  Future<void> _writeSession({
    required String email,
    required String displayName,
    required bool isAdmin,
  }) async {
    final session = await _sessionBox();
    await session.put(
      'user',
      // Пароль больше не храним
      User(email: email, displayName: displayName, isAdmin: isAdmin),
    );
  }

  /// Читает пользователя из локальной сессии Hive.
  Future<User?> _sessionUser() async {
    final session = await _sessionBox();
    return session.get('user') as User?;
  }

  /// Загружает профиль из Firestore и сохраняет его в локальную сессию.
  Future<bool> _pullRemoteProfileToSession() async {
    final fb.User? u = _fa.currentUser;
    if (u == null) return false;

    final snap = await _userDoc(u.uid).get();
    if (!snap.exists) return false;

    final data = snap.data()!;
    final email = (data['email'] as String?) ?? u.email ?? '';
    final displayName = (data['displayName'] as String?) ?? u.displayName ?? '';
    final role = (data['role'] as String?) ?? 'user';
    final isAdmin = role == 'admin';

    await _writeSession(
      email: email,
      displayName: displayName,
      isAdmin: isAdmin,
    );
    return true;
  }

  // ================== ПУБЛИЧНЫЕ МЕТОДЫ ==================

  /// Регистрация через Firebase.
  Future<void> register(String email, String password, {bool isAdmin = false}) async {
    try {
      final fb.UserCredential res;
      final fb.User? cur = _fa.currentUser;

      if (cur != null && cur.isAnonymous) {
        final cred = fb.EmailAuthProvider.credential(email: email, password: password);
        res = await cur.linkWithCredential(cred);
      } else {
        res = await _fa.createUserWithEmailAndPassword(email: email, password: password);
      }

      final user = res.user;
      if (user == null) throw Exception("Не удалось создать пользователя");

      // Создаем профиль в Firestore
      await _userDoc(user.uid).set({
        'email': email,
        'displayName': '', // Изначально имя пустое
        'photoUrl': null,
        'role': isAdmin ? 'admin' : 'user',
        'provider': 'password',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Записываем в локальную сессию
      await _writeSession(
        email: email,
        displayName: '',
        isAdmin: isAdmin,
      );
    } on fb.FirebaseAuthException {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  /// Вход через Firebase.
  Future<void> login(String email, String password) async {
    try {
      await _fa.signInWithEmailAndPassword(email: email, password: password);

      // После успешного входа подтягиваем актуальные данные в сессию
      await _pullRemoteProfileToSession();

    } on fb.FirebaseAuthException {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  /// Выход: Firebase signOut + очистка локальной session.
  Future<void> logout() async {
    await _fa.signOut();
    final session = await _sessionBox();
    await session.clear();
  }

  // ================== Методы настроек ==================

  /// Обновляет имя и фото пользователя в Firebase Auth и Firestore.
  Future<void> updateUserProfile({
    required String displayName,
    String? photoUrl,
  }) async {
    final u = _fa.currentUser;
    if (u == null) throw Exception('Пользователь не авторизован');

    // 1. Обновляем профиль в Firebase Authentication
    await u.updateDisplayName(displayName);
    if (photoUrl != null) {
      await u.updatePhotoURL(photoUrl);
    }

    // 2. Обновляем данные в нашей базе Firestore
    await _userDoc(u.uid).set({
      'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 3. Обновляем локальную сессию, чтобы UI сразу обновился
    await _pullRemoteProfileToSession();
  }

  /// Проверка пароля (reauthenticate).
  Future<bool> verifyPassword(String email, String currentPassword) async {
    try {
      final fb.User? u = _fa.currentUser;
      if (u == null) return false;

      final cred = fb.EmailAuthProvider.credential(email: email, password: currentPassword);
      await u.reauthenticateWithCredential(cred);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Смена email.
  Future<void> updateEmail({
    required String currentEmail,
    required String currentPassword,
    required String newEmail,
  }) async {
    final ok = await verifyPassword(currentEmail, currentPassword);
    if (!ok) throw Exception('Неверный текущий пароль');

    final u = _fa.currentUser;
    if (u == null) throw Exception('Пользователь не найден');

    // Используем правильный, современный метод
    await u.verifyBeforeUpdateEmail(newEmail);
  }

  /// Смена пароля.
  Future<void> updatePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final ok = await verifyPassword(email, currentPassword);
    if (!ok) throw Exception('Неверный текущий пароль');

    final u = _fa.currentUser;
    if (u == null) throw Exception('Пользователь не найден');
    await u.updatePassword(newPassword);
  }
}

import 'package:hive/hive.dart';
import '../models/user.dart'; 


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

class AuthService {
  final fb.FirebaseAuth _fa = fb.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  fb.User? get firebaseUser => _fa.currentUser;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  Future<Box> _sessionBox() async => Hive.openBox('session');

  
  Future<void> _writeSession({
    required String email,
    required String displayName,
    required bool isAdmin,
  }) async {
    final session = await _sessionBox();
    await session.put(
      'user',
      
      User(email: email, displayName: displayName, isAdmin: isAdmin),
    );
  }

  
  Future<User?> _sessionUser() async {
    final session = await _sessionBox();
    return session.get('user') as User?;
  }

  
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

      
      await _userDoc(user.uid).set({
        'email': email,
        'displayName': '', 
        'photoUrl': null,
        'role': isAdmin ? 'admin' : 'user',
        'provider': 'password',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      
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

  
  Future<void> login(String email, String password) async {
    try {
      await _fa.signInWithEmailAndPassword(email: email, password: password);

      
      await _pullRemoteProfileToSession();

    } on fb.FirebaseAuthException {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  
  Future<void> logout() async {
    await _fa.signOut();
    final session = await _sessionBox();
    await session.clear();
  }

  

  
  Future<void> updateUserProfile({
    required String displayName,
    String? photoUrl,
  }) async {
    final u = _fa.currentUser;
    if (u == null) throw Exception('Пользователь не авторизован');

    
    await u.updateDisplayName(displayName);
    if (photoUrl != null) {
      await u.updatePhotoURL(photoUrl);
    }

    
    await _userDoc(u.uid).set({
      'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    
    await _pullRemoteProfileToSession();
  }

  
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



  /// Смена email (без подтверждения по почте).
  /// Смена email (С ОБЯЗАТЕЛЬНЫМ ПОДТВЕРЖДЕНИЕМ)
  /// В новых версиях Firebase мгновенная смена без письма невозможна из приложения.
  Future<void> updateEmail({
    required String currentEmail,
    required String currentPassword,
    required String newEmail,
  }) async {
    // 1. Проверяем текущий пароль
    final ok = await verifyPassword(currentEmail, currentPassword);
    if (!ok) throw Exception('Неверный текущий пароль');

    final u = _fa.currentUser;
    if (u == null) throw Exception('Пользователь не найден');

    // 2. Отправляем письмо для подтверждения на НОВУЮ почту
    // Метод updateEmail был удален в версии 6.0.0, теперь только так:
    await u.verifyBeforeUpdateEmail(newEmail);

    // 3. В этот момент мы НЕ обновляем Firestore, так как почта фактически еще не сменилась.
    // Она сменится сама в Auth, когда юзер кликнет по ссылке.
    // Чтобы обновить Firestore, нужно либо слушать userChanges(), либо полагаться на то,
    // что юзер перезайдет в приложение.
  }

  
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
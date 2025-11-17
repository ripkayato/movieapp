// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // ── РЕГИСТРАЦИЯ ─────────────────────────────────────
  Future<String?> registerWithEmail({
    required String email,
    required String password,
    required String nickname,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = cred.user!.uid;

      // 1. Сохраняем профиль
      await _firestore.collection('users').doc(userId).set({
        'nickname': nickname,
        'email': email,
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Подколлекция my_movies создаётся автоматически при первом документе
      //    (хак с __init__ удалён — он вызывал ошибку reserved ID)

      // 3. Сохраняем FCM-токен (для пушей)
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      }

      // 4. Отправляем письмо подтверждения
      try {
        await cred.user!.sendEmailVerification();
      } catch (e) {
        print('Ошибка отправки verification email: $e');
        // Не прерываем регистрацию, но логируем
      }

      return 'success';
    } on FirebaseAuthException catch (e) {
      return _errorMessage(e);
    } catch (e) {
      print('Регистрация ошибка: $e');
      return 'Неизвестная ошибка';
    }
  }

  // ── ВХОД ─────────────────────────────────────────────
  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _auth.currentUser?.reload();

      if (!_auth.currentUser!.emailVerified) {
        await _auth.signOut();
        return 'email_not_verified';
      }

      // Обновляем токен при входе
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      }

      return 'success';
    } on FirebaseAuthException catch (e) {
      return _errorMessage(e);
    } catch (e) {
      return 'Неизвестная ошибка';
    }
  }

  // ── ПРОВЕРКА EMAIL ───────────────────────────────────
  Future<String?> verifyEmail() async {
    if (_auth.currentUser == null) return 'no_user';

    await _auth.currentUser!.reload();
    if (_auth.currentUser!.emailVerified) {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update({'emailVerified': true});
      return 'success';
    }
    return 'email_not_verified';
  }

  // ── НИКНЕЙМ ─────────────────────────────────────────
  Future<String?> getUserNickname() async {
    if (_auth.currentUser == null) return null;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      return doc.data()?['nickname'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateNickname(String newNickname) async {
    if (_auth.currentUser == null) return;
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .set({'nickname': newNickname}, SetOptions(merge: true));
  }

  // ── ВЫХОД ───────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
  }

  bool get isLoggedIn => _auth.currentUser != null;

  // ── РУССКИЕ ОШИБКИ ───────────────────────────────────
  String _errorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Неверный email';
      case 'user-disabled':
        return 'Аккаунт отключён';
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'email-already-in-use':
        return 'Email уже занят';
      case 'weak-password':
        return 'Пароль слишком слабый (мин. 6 символов)';
      case 'too-many-requests':
        return 'Слишком много попыток. Подождите';
      default:
        return 'Ошибка: ${e.message}';
    }
  }
}
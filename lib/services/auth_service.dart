import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Authentication'ı sarmalayan basit servis. Uygulamanın geri
/// kalanı doğrudan FirebaseAuth ile konuşmak yerine bu sınıfı kullanır —
/// böylece hata mesajları tek yerden Türkçeleştirilir ve ileride
/// (Google ile giriş gibi) yeni yöntemler eklemek kolaylaşır.
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;
  static bool get isLoggedIn => _auth.currentUser != null;

  /// Giriş durumu değiştiğinde (giriş/çıkış) tetiklenen akış.
  static Stream<User?> get userChanges => _auth.authStateChanges();

  /// Yeni hesap oluşturur. Başarılıysa null, hata varsa Türkçe bir mesaj
  /// döner (ekranda doğrudan gösterilebilir).
  static Future<String?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(displayName.trim());
      await credential.user?.reload();
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e.code);
    } catch (_) {
      return 'Beklenmeyen bir hata oluştu. Tekrar dener misin?';
    }
  }

  /// Var olan hesapla giriş yapar. Başarılıysa null, hata varsa Türkçe bir
  /// mesaj döner.
  static Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e.code);
    } catch (_) {
      return 'Beklenmeyen bir hata oluştu. Tekrar dener misin?';
    }
  }

  static Future<void> signOut() => _auth.signOut();

  static String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Bu e-posta adresiyle zaten bir hesap var — giriş yapmayı dene.';
      case 'invalid-email':
        return 'E-posta adresi geçersiz görünüyor.';
      case 'weak-password':
        return 'Şifre çok zayıf, en az 6 karakter olmalı.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      case 'network-request-failed':
        return 'İnternet bağlantısı yok gibi görünüyor.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı, biraz sonra tekrar dene.';
      default:
        return 'Bir şeyler ters gitti ($code). Tekrar dener misin?';
    }
  }
}

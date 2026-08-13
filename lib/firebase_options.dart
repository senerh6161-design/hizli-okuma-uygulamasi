// Bu dosya normalde `flutterfire configure` komutuyla otomatik üretilir.
// Bu ortamda Flutter CLI çalıştıramadığımız için, Firebase Console'dan
// indirilen google-services.json'daki değerlerle elle oluşturuldu.
// Şu an sadece Android için yapılandırılmış durumda — iOS/Web eklenirse
// buraya ilgili platformların FirebaseOptions'ları eklenmeli (ideal olanı,
// o zaman `flutterfire configure` çalıştırıp bu dosyayı yeniden üretmek).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions henüz web için yapılandırılmadı. '
        'Web desteği eklemek istersen Firebase Console\'dan bir Web uygulaması '
        'kaydedip bu dosyayı güncellememiz gerekir.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions henüz iOS için yapılandırılmadı. '
          'Firebase Console\'dan bir iOS uygulaması kaydedip bu dosyayı '
          'güncellememiz gerekir.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions bu platform için desteklenmiyor.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAEVsA-M4-p5sN7mlle_Q_8wJDO12JBxto',
    appId: '1:73071692267:android:42a7724e8e4f0afb3131ae',
    messagingSenderId: '73071692267',
    projectId: 'hizliokumalab',
    storageBucket: 'hizliokumalab.firebasestorage.app',
  );
}

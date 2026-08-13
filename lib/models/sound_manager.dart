import 'package:flutter/services.dart';
import 'settings_manager.dart';

/// Basit ama "tatmin edici" geri bildirim sesleri ve titreşimler sağlar.
///
/// Bilinçli olarak harici ses dosyası ya da ek paket KULLANMAZ: Flutter'ın
/// yerleşik sistem sesi (SystemSound) ve dokunsal geri bildirim
/// (HapticFeedback) API'lerine dayanır. Böylece internet bağlantısı ya da
/// ekstra kurulum gerekmeden, oyunlardaki "click/ödül" hissine yakın bir
/// deneyim sunar. Ayarlar sayfasındaki "Ses Efektleri" anahtarı kapalıysa
/// hiçbir şey çalmaz.
class SoundManager {
  static void _click() {
    if (!SettingsManager.isSoundOn) return;
    SystemSound.play(SystemSoundType.click);
  }

  /// Doğru cevap anı — kısa ve net.
  static void playCorrect() {
    _click();
    if (SettingsManager.isSoundOn) HapticFeedback.lightImpact();
  }

  /// Bir egzersiz/test tamamlandığında — biraz daha belirgin kutlama hissi.
  static void playSuccess() {
    _click();
    if (SettingsManager.isSoundOn) HapticFeedback.mediumImpact();
  }

  /// Yeni bir başarım (rozet) açıldığında — en "tatmin edici" olan geri
  /// bildirim.
  static void playAchievement() {
    _click();
    if (SettingsManager.isSoundOn) HapticFeedback.heavyImpact();
  }

  /// Yanlış cevap — cezalandırıcı olmayan, nazik bir dokunuş.
  static void playGentleTap() {
    if (SettingsManager.isSoundOn) HapticFeedback.selectionClick();
  }
}

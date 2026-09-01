import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'settings_manager.dart';

/// Basit ama "tatmin edici" geri bildirim sesleri ve titreşimler sağlar.
///
/// Çoğu geri bildirim Flutter'ın yerleşik sistem sesi (SystemSound) ve
/// dokunsal geri bildirim (HapticFeedback) API'lerine dayanır — ekstra
/// kurulum gerekmeden "click/ödül" hissi verir. Baloncuk patlaması gibi
/// özel bir ses gerektiğinde (playPop) AudioManager'ın kullandığı
/// audioplayers paketiyle gerçek bir ses dosyası çalınır. Ayarlar
/// sayfasındaki "Ses Efektleri" anahtarı kapalıysa hiçbiri çalmaz.
class SoundManager {
  static final AudioPlayer _sfxPlayer = AudioPlayer()
    ..setPlayerMode(PlayerMode.lowLatency);

  static void _click() {
    if (!SettingsManager.isSoundOn) return;
    SystemSound.play(SystemSoundType.click);
  }

  /// Baloncuk patlaması gibi "tık" değil gerçek bir efekt gereken yerlerde
  /// (ör. Sayı Avı'nda bulunan sayı silinirken) kullanılıyor.
  static Future<void> playPop() async {
    if (!SettingsManager.isSoundOn) return;
    if (SettingsManager.isSoundOn) HapticFeedback.lightImpact();
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/pop.wav'));
    } catch (e) {
      debugPrint('SoundManager: pop sesi çalınamadı: $e');
    }
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

  /// Vurgu bir kutucuktan diğerine geçerken duyulan kısa "tık" — ör. Dört
  /// Yönlü Tarama'da vurgu ilerledikçe.
  static void playTick() {
    _click();
    if (SettingsManager.isSoundOn) HapticFeedback.selectionClick();
  }
}

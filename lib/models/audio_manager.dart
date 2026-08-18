import 'package:audioplayers/audioplayers.dart';
import 'settings_manager.dart';

/// Okuma ekranlarında çalınan, kendi ürettiğimiz (telifsiz) sakin arka plan
/// tonu. SettingsManager.isBackgroundMusicOn kapalıysa hiç çalmaz.
class AudioManager {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isPlaying = false;

  static Future<void> startAmbient() async {
    if (!SettingsManager.isBackgroundMusicOn) return;
    if (_isPlaying) return;
    _isPlaying = true;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(0.5);
      await _player.play(AssetSource('audio/calm_ambient.wav'));
    } catch (_) {
      // Ses cihazda/platformda çalışmazsa sessizce yok say — arka plan
      // müziği bir "olursa iyi olur" özelliğidir, egzersizi engellemez.
      _isPlaying = false;
    }
  }

  static Future<void> stopAmbient() async {
    if (!_isPlaying) return;
    _isPlaying = false;
    try {
      await _player.stop();
    } catch (_) {}
  }
}

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'settings_manager.dart';

/// Okuma ekranlarında çalınan fon müziği parçaları. 'calm' kendi ürettiğimiz
/// (telifsiz) sentetik ton; 'motivational' ve 'inspiration' telifsiz
/// (Pixabay) kaynaklardan indirilip projeye eklenmiş gerçek müzik parçaları.
class BackgroundTrack {
  final String id;
  final String label;
  final String asset;
  const BackgroundTrack(this.id, this.label, this.asset);
}

const List<BackgroundTrack> kBackgroundTracks = [
  BackgroundTrack('calm', '🎶 Sakin Ton', 'audio/calm_ambient.wav'),
  BackgroundTrack('motivational', '🎵 Motivasyon', 'audio/bg_motivational.mp3'),
  BackgroundTrack('inspiration', '🎵 İlham', 'audio/bg_inspiration.wav'),
  BackgroundTrack('rain', '🌧️ Yağmur', 'audio/bg_rain.mp3'),
];

BackgroundTrack trackById(String id) =>
    kBackgroundTracks.firstWhere((t) => t.id == id, orElse: () => kBackgroundTracks.first);

/// SettingsManager.isBackgroundMusicOn kapalıysa hiç çalmaz. Hangi parçanın
/// çalınacağı SettingsManager.backgroundMusicTrack ile belirlenir.
class AudioManager {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isPlaying = false;
  static String? _currentTrackId;

  static Future<void> startAmbient() async {
    if (!SettingsManager.isBackgroundMusicOn) return;
    final trackId = SettingsManager.backgroundMusicTrack;
    if (_isPlaying && _currentTrackId == trackId) return;
    _isPlaying = true;
    _currentTrackId = trackId;
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(0.5);
      await _player.play(AssetSource(trackById(trackId).asset));
    } catch (e) {
      // Ses cihazda/platformda çalışmazsa exercise'i engellemeden devam et,
      // ama nedeni konsola yaz ki "ses gelmiyor" sorunları teşhis edilebilsin.
      debugPrint('AudioManager: "$trackId" parçası çalınamadı: $e');
      _isPlaying = false;
      _currentTrackId = null;
    }
  }

  /// Kullanıcı okumaya başlamadan ÖNCE parça değiştirirse (fon müziği zaten
  /// çalıyorsa) yeni seçimle sorunsuz devam etsin diye.
  static Future<void> switchTrackIfPlaying() async {
    if (!_isPlaying) return;
    _isPlaying = false;
    await startAmbient();
  }

  static Future<void> stopAmbient() async {
    if (!_isPlaying) return;
    _isPlaying = false;
    _currentTrackId = null;
    try {
      await _player.stop();
    } catch (_) {}
  }
}

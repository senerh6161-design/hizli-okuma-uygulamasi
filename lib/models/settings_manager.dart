import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ayarlar sayfasındaki tercihleri cihazda kalıcı tutar.
/// ProgressManager ile aynı desen: statik alanlar + init() + save().
///
/// Not: Kullanıcı kimliği (giriş/çıkış) artık burada DEĞİL — gerçek
/// hesaplar için `AuthService` (Firebase Authentication) kullanılıyor.
/// Bu sınıf sadece cihaza özgü tercihleri tutar.
class SettingsManager {
  static SharedPreferences? _prefs;

  static bool isFocusRed = true;
  static bool isSoundOn = false;
  static bool isReminderOn = true;
  static TimeOfDay reminderTime = const TimeOfDay(hour: 20, minute: 0);

  // Okuma teması: 'default' | 'blue' | 'green'. Anlama Testi'ndeki metin
  // kutusunun arka plan/rengini belirler (dinlendirici mavi/yeşil seçenekleri).
  static String readingTheme = 'default';

  static const _kFocusRed = 'settings_focus_red';
  static const _kSoundOn = 'settings_sound_on';
  static const _kReminderOn = 'settings_reminder_on';
  static const _kReminderHour = 'settings_reminder_hour';
  static const _kReminderMinute = 'settings_reminder_minute';
  static const _kReadingTheme = 'settings_reading_theme';

  /// main() içinde, runApp'ten ÖNCE bir kere çağrılmalı:
  ///   await SettingsManager.init();
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final prefs = _prefs!;

    isFocusRed = prefs.getBool(_kFocusRed) ?? true;
    isSoundOn = prefs.getBool(_kSoundOn) ?? false;
    isReminderOn = prefs.getBool(_kReminderOn) ?? true;
    readingTheme = prefs.getString(_kReadingTheme) ?? 'default';

    final hour = prefs.getInt(_kReminderHour) ?? 20;
    final minute = prefs.getInt(_kReminderMinute) ?? 0;
    reminderTime = TimeOfDay(hour: hour, minute: minute);
  }

  static Future<void> save() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setBool(_kFocusRed, isFocusRed);
    await prefs.setBool(_kSoundOn, isSoundOn);
    await prefs.setBool(_kReminderOn, isReminderOn);
    await prefs.setInt(_kReminderHour, reminderTime.hour);
    await prefs.setInt(_kReminderMinute, reminderTime.minute);
    await prefs.setString(_kReadingTheme, readingTheme);
  }

  /// Anlama Testi okuma ekranının arka plan rengi. 'blue' ve 'green'
  /// seçenekleri bilinçli olarak düşük doygunlukta ve dinlendirici seçildi.
  static Color get readingBackgroundColor {
    switch (readingTheme) {
      case 'blue':
        return const Color(0xFFEFF6FF);
      case 'green':
        return const Color(0xFFECFDF5);
      default:
        return Colors.white;
    }
  }

  static Color get readingBorderColor {
    switch (readingTheme) {
      case 'blue':
        return const Color(0xFFBFDBFE);
      case 'green':
        return const Color(0xFFA7F3D0);
      default:
        return const Color(0xFFE2E8F0);
    }
  }

  static Color get readingAccentColor {
    switch (readingTheme) {
      case 'blue':
        return const Color(0xFF2563EB);
      case 'green':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF4F46E5);
    }
  }
}

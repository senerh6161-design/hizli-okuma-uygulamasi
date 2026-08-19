import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'achievement.dart';
import '../services/leaderboard_service.dart';

class ProgressManager {
  static SharedPreferences? _prefs;

  // Uygulama geneli canlı veriler.
  // Not: Artık sahte/başlangıç verisiyle değil, gerçek (ve yeni kullanıcıda
  // sıfır) değerlerle başlıyor. init() çağrıldığında cihazda kayıtlı bir
  // değer varsa onunla değiştiriliyor.
  static int wpm = 0;
  static int comprehensionRate = 0;
  static int attentionSuccess = 0;
  static int completedExercises = 0;
  static int currentLevel = 1;
  static double levelProgress = 0.0;

  // Anlama testi performansına göre hızlı okuma temposunu ölçekleyen
  // çarpan. 1.0 = değişiklik yok. Anlama Testi'nde %90+ alınca artar,
  // %70'in altına düşünce azalır. LevelPage bunu WPM hesabına çarpan
  // olarak uyguluyor.
  static double speedAdjustment = 1.0;

  // Günlük seri (streak) takibi.
  static int currentStreak = 0;
  static int longestStreak = 0;
  static String? lastActiveDate; // 'yyyy-MM-dd' formatında

  // Bugün tamamlanan egzersiz/test sayısı (liderlik tablosu için). Her gün
  // sıfırlanır — streak'ten bağımsız, gün içinde yapılan HER egzersizde
  // artar (streak günde sadece bir kez sayılır, bu sayaç değil).
  static int todayCompletedCount = 0;
  static String? todayCountDate; // 'yyyy-MM-dd' formatında

  // WPM Testi'nden ölçülen kişisel taban hız. null ise henüz test
  // yapılmamış demektir ve LevelPage okul yaş grubunun varsayılan
  // hızını (schoolLevel.defaultWpm) kullanır. Test yapılınca bu değer
  // schoolLevel.defaultWpm'in YERİNE geçer.
  static int? personalWpmBaseline;

  // Açılmış başarım rozetlerinin id'leri.
  static Set<String> unlockedAchievementIds = {};

  static List<Map<String, String>> history = [];

  static const _kWpm = 'progress_wpm';
  static const _kComprehension = 'progress_comprehension';
  static const _kAttention = 'progress_attention';
  static const _kCompleted = 'progress_completed';
  static const _kLevel = 'progress_level';
  static const _kLevelProgress = 'progress_level_progress';
  static const _kSpeedAdj = 'progress_speed_adjustment';
  static const _kStreak = 'progress_streak';
  static const _kLongestStreak = 'progress_longest_streak';
  static const _kLastActiveDate = 'progress_last_active_date';
  static const _kPersonalWpm = 'progress_personal_wpm';
  static const _kAchievements = 'progress_achievements';
  static const _kHistory = 'progress_history';
  static const _kTodayCount = 'progress_today_count';
  static const _kTodayCountDate = 'progress_today_count_date';

  /// main() içinde, runApp'ten ÖNCE bir kere çağrılmalı:
  ///   await ProgressManager.init();
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final prefs = _prefs!;

    // clamp(0, 900): eski bir WPM hesaplama hatasından (bkz. LevelPage
    // _startSession) cihazda kalmış olabilecek imkansız değerleri (ör.
    // 7800) yükleme anında düzeltir.
    wpm = (prefs.getInt(_kWpm) ?? 0).clamp(0, 900);
    comprehensionRate = prefs.getInt(_kComprehension) ?? 0;
    attentionSuccess = prefs.getInt(_kAttention) ?? 0;
    completedExercises = prefs.getInt(_kCompleted) ?? 0;
    currentLevel = prefs.getInt(_kLevel) ?? 1;
    levelProgress = prefs.getDouble(_kLevelProgress) ?? 0.0;
    speedAdjustment = prefs.getDouble(_kSpeedAdj) ?? 1.0;
    currentStreak = prefs.getInt(_kStreak) ?? 0;
    longestStreak = prefs.getInt(_kLongestStreak) ?? 0;
    lastActiveDate = prefs.getString(_kLastActiveDate);
    personalWpmBaseline = prefs.getInt(_kPersonalWpm);
    unlockedAchievementIds = (prefs.getStringList(_kAchievements) ?? []).toSet();
    todayCountDate = prefs.getString(_kTodayCountDate);
    todayCompletedCount = prefs.getInt(_kTodayCount) ?? 0;

    // Kayıtlı "bugün" tarihi artık dünse (uygulama gün değişiminden sonra
    // ilk kez açılıyorsa), sayaç sıfırlanır.
    final todayKey = _dateKey(DateTime.now());
    if (todayCountDate != todayKey) {
      todayCompletedCount = 0;
      todayCountDate = todayKey;
    }

    final historyJson = prefs.getString(_kHistory);
    if (historyJson != null && historyJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(historyJson) as List;
        history = decoded
            .map((e) => Map<String, String>.from(e as Map))
            .toList();
      } catch (_) {
        history = [];
      }
    } else {
      history = [];
    }
  }

  static Future<void> _persist() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setInt(_kWpm, wpm);
    await prefs.setInt(_kComprehension, comprehensionRate);
    await prefs.setInt(_kAttention, attentionSuccess);
    await prefs.setInt(_kCompleted, completedExercises);
    await prefs.setInt(_kLevel, currentLevel);
    await prefs.setDouble(_kLevelProgress, levelProgress);
    await prefs.setDouble(_kSpeedAdj, speedAdjustment);
    await prefs.setInt(_kStreak, currentStreak);
    await prefs.setInt(_kLongestStreak, longestStreak);
    if (lastActiveDate != null) {
      await prefs.setString(_kLastActiveDate, lastActiveDate!);
    }
    if (personalWpmBaseline != null) {
      await prefs.setInt(_kPersonalWpm, personalWpmBaseline!);
    } else {
      await prefs.remove(_kPersonalWpm);
    }
    await prefs.setStringList(_kAchievements, unlockedAchievementIds.toList());
    await prefs.setString(_kHistory, jsonEncode(history));
    await prefs.setInt(_kTodayCount, todayCompletedCount);
    if (todayCountDate != null) {
      await prefs.setString(_kTodayCountDate, todayCountDate!);
    }
  }

  static String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // Bugün için aktivite kaydı düşer. Dünden devam ediyorsa seriyi artırır,
  // araya gün girmişse seriyi sıfırdan başlatır, bugün zaten sayıldıysa
  // hiçbir şey yapmaz (aynı gün içinde birden fazla egzersiz seriyi
  // birden fazla artırmasın diye). Ayrıca "bugün tamamlanan egzersiz"
  // sayacını (liderlik tablosu için) HER çağrıda artırır — bu sayaç
  // streak'ten bağımsızdır — ve giriş yapılmışsa bu değeri Firestore'a
  // (gerçek, cihazlar arası liderlik tablosuna) yazar.
  static void _registerDailyActivity() {
    final now = DateTime.now();
    final todayKey = _dateKey(now);

    if (todayCountDate != todayKey) {
      todayCompletedCount = 0;
      todayCountDate = todayKey;
    }
    todayCompletedCount += 1;

    // Giriş yapılmamışsa ya da internet yoksa sessizce başarısız olur —
    // yerel ilerleme her durumda kaydedilmeye devam eder, liderlik
    // tablosu senkronu sadece "iyi olursa iyi" (best-effort) bir ekstra.
    LeaderboardService.updateTodayCount(todayCompletedCount).catchError((_) {});

    if (lastActiveDate == todayKey) {
      return;
    }

    if (lastActiveDate != null) {
      final yesterdayKey = _dateKey(now.subtract(const Duration(days: 1)));
      if (lastActiveDate == yesterdayKey) {
        currentStreak += 1;
      } else {
        currentStreak = 1;
      }
    } else {
      currentStreak = 1;
    }

    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }

    lastActiveDate = todayKey;
  }

  // Achievement.all listesindeki her rozeti kontrol eder, henüz açılmamış
  // ama şartı sağlanmış olanları açar ve YENİ açılanları döner (UI bunu
  // kutlama göstermek için kullanabilir).
  static List<Achievement> _checkNewAchievements() {
    final newlyUnlocked = <Achievement>[];
    for (final achievement in Achievement.all) {
      if (!unlockedAchievementIds.contains(achievement.id) && achievement.isUnlocked()) {
        unlockedAchievementIds.add(achievement.id);
        newlyUnlocked.add(achievement);
      }
    }
    return newlyUnlocked;
  }

  // Egzersiz tamamlandığında çağrılacak metot.
  // Artık yeni açılan başarımları LİSTE olarak döndürüyor — mevcut çağrı
  // yerlerinde bu değeri kullanmasan da (statement olarak çağırsan da)
  // kod sorunsuz derlenir.
  static List<Achievement> addCompletedExercise({
    required String type,
    required String result,
    int? newWpm,
  }) {
    completedExercises++;

    // 900 üstü gerçekçi bir okuma hızı değil (bkz. LevelPage._roundWpm
    // aralığı) — eski bir hesaplama hatasından kalma şişirilmiş rekorların
    // kalıcı olarak takılı kalmasını da önler.
    if (newWpm != null && newWpm.clamp(0, 900) > wpm) {
      wpm = newWpm.clamp(0, 900);
    }

    // İlerleme çubuğunu artır
    levelProgress += 0.10;
    if (levelProgress >= 1.0) {
      levelProgress = 0.20;
      currentLevel++; // Seviye atladı!
    }

    // Geçmişe ekle (en fazla son 50 kayıt tutulur)
    history.insert(0, {
      'title': type,
      'result': result,
      'date': 'Şimdi',
    });
    if (history.length > 50) {
      history = history.sublist(0, 50);
    }

    _registerDailyActivity();
    final newlyUnlocked = _checkNewAchievements();

    _persist();
    return newlyUnlocked;
  }

  /// Anlama Testi bittiğinde çağrılır. Gerçek doğru/toplam soru sayısını
  /// alır, comprehensionRate'i günceller VE speedAdjustment'i ayarlar:
  ///   %90+ doğru  -> tempo bir sonraki turda artar (maks x1.3)
  ///   %70 altı    -> tempo bir sonraki turda azalır (min x0.7)
  ///   %70-89 arası -> tempo sabit kalır (zaten dengedesin demektir)
  /// Yeni açılan başarımları da döner.
  static List<Achievement> recordComprehensionResult({
    required int correct,
    required int total,
    String title = 'Anlama Testi',
  }) {
    if (total <= 0) return [];
    final scorePercent = ((correct / total) * 100).round();

    // Hareketli ortalama: yeni sonuç ağırlıklı ama geçmiş tamamen silinmiyor.
    comprehensionRate = comprehensionRate == 0
        ? scorePercent
        : (((comprehensionRate * 0.5) + (scorePercent * 0.5))).round();

    if (scorePercent >= 90) {
      speedAdjustment = (speedAdjustment + 0.10).clamp(0.7, 1.3);
    } else if (scorePercent < 70) {
      speedAdjustment = (speedAdjustment - 0.15).clamp(0.7, 1.3);
    }
    // %70-89 arası: speedAdjustment sabit kalır.

    completedExercises++;
    history.insert(0, {
      'title': title,
      'result': '%$scorePercent doğru',
      'date': 'Şimdi',
    });
    if (history.length > 50) {
      history = history.sublist(0, 50);
    }

    _registerDailyActivity();
    final newlyUnlocked = _checkNewAchievements();

    _persist();
    return newlyUnlocked;
  }

  /// Dikkat/odak gerektiren bir egzersiz (Dairesel Sıralama, Dikkat Soruları,
  /// Şehir Anagramı, Kelimelerle Saklambaç, Kelime Akışı vb.) bittiğinde
  /// çağrılır. attentionSuccess'i hareketli ortalama olarak günceller —
  /// bu alan daha önce hiçbir egzersiz tarafından güncellenmiyordu ve
  /// İlerleme sayfasında hep %0 görünüyordu.
  static void recordAttentionScore(int percent) {
    final clamped = percent.clamp(0, 100);
    attentionSuccess = attentionSuccess == 0
        ? clamped
        : (((attentionSuccess * 0.5) + (clamped * 0.5))).round();
    _persist();
  }

  /// WPM Testi bittiğinde çağrılır. Ölçülen kişisel taban hızı kaydeder;
  /// bundan sonra LevelPage bu değeri schoolLevel.defaultWpm YERİNE kullanır.
  static void setPersonalWpmBaseline(int wpm) {
    personalWpmBaseline = wpm.clamp(60, 900).toInt();
    _persist();
  }

  // İlerlemeyi tamamen sıfırlama metodu
  static void resetProgress() {
    wpm = 0;
    comprehensionRate = 0;
    attentionSuccess = 0;
    completedExercises = 0;
    currentLevel = 1;
    levelProgress = 0.0;
    speedAdjustment = 1.0;
    currentStreak = 0;
    longestStreak = 0;
    lastActiveDate = null;
    unlockedAchievementIds = {};
    personalWpmBaseline = null;
    todayCompletedCount = 0;
    todayCountDate = null;
    history.clear();
    _persist();
  }
}

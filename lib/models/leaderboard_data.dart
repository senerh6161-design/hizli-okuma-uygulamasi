import 'dart:math';
import '../services/auth_service.dart';
import '../services/leaderboard_service.dart';
import 'progress_manager.dart';

class LeaderboardEntry {
  final String name;
  final String avatar;
  final int count;
  final bool isYou;

  const LeaderboardEntry({
    required this.name,
    required this.avatar,
    required this.count,
    this.isYou = false,
  });
}

/// [LeaderboardData.todayRanking] sonucunu, gerçek Firestore verisi mi
/// yoksa yerel örnek (demo) veri mi olduğu bilgisiyle birlikte taşır —
/// arayüz bu bilgiye göre farklı bir uyarı/boş durum gösterebilir.
class LeaderboardResult {
  final List<LeaderboardEntry> entries;
  final bool isDemo;

  const LeaderboardResult({required this.entries, required this.isDemo});
}

class LeaderboardData {
  static const List<Map<String, String>> _bots = [
    {'name': 'Elif', 'avatar': '🦊'},
    {'name': 'Kerem', 'avatar': '🐼'},
    {'name': 'Zeynep', 'avatar': '🐰'},
    {'name': 'Ege', 'avatar': '🐯'},
    {'name': 'Defne', 'avatar': '🐨'},
  ];

  static const List<String> _avatarPool = [
    '🦊', '🐼', '🐰', '🐯', '🐨', '🦁', '🐸', '🐧', '🦄', '🐢',
  ];

  static String _avatarFor(String seed) {
    final sum = seed.codeUnits.fold<int>(0, (a, b) => a + b);
    return _avatarPool[sum % _avatarPool.length];
  }

  static int _dayOfYear(DateTime date) {
    final start = DateTime(date.year, 1, 1);
    return date.difference(start).inDays + 1;
  }

  /// Girişi olan kullanıcılar için Firestore'dan bugünün GERÇEK sırasını
  /// çeker (diğer gerçek kullanıcılarla birlikte). Giriş yapılmamışsa ya
  /// da bir ağ/izin hatası olursa, yerel örnek profillerle bir gösterim
  /// (demo) sıralamasına düşer — bu durumda [LeaderboardResult.isDemo]
  /// true olur ve arayüz bunu kullanıcıya açıkça belirtmeli.
  static Future<LeaderboardResult> todayRanking() async {
    if (AuthService.isLoggedIn) {
      try {
        final remote = await LeaderboardService.todayTop();
        final entries = remote
            .map((e) => LeaderboardEntry(
                  name: e.isYou ? '${e.name} (Sen)' : e.name,
                  avatar: e.isYou ? '⭐' : _avatarFor(e.uid),
                  count: e.count,
                  isYou: e.isYou,
                ))
            .toList();
        return LeaderboardResult(entries: entries, isDemo: false);
      } catch (_) {
        // İnternet yok, izin hatası vb. — yerel örneğe düş.
        return LeaderboardResult(entries: _localDemoRanking(), isDemo: true);
      }
    }
    return LeaderboardResult(entries: _localDemoRanking(), isDemo: true);
  }

  static List<LeaderboardEntry> _localDemoRanking() {
    final now = DateTime.now();
    final seed = now.year * 1000 + _dayOfYear(now);
    final random = Random(seed);

    final entries = _bots.map((bot) {
      final count = 3 + random.nextInt(14);
      return LeaderboardEntry(name: bot['name']!, avatar: bot['avatar']!, count: count);
    }).toList();

    entries.add(
      LeaderboardEntry(
        name: 'Sen',
        avatar: '⭐',
        count: ProgressManager.todayCompletedCount,
        isYou: true,
      ),
    );

    entries.sort((a, b) => b.count.compareTo(a.count));
    return entries;
  }
}

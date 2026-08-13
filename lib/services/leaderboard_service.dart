import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class LeaderboardEntryRemote {
  final String uid;
  final String name;
  final int count;
  final bool isYou;

  const LeaderboardEntryRemote({
    required this.uid,
    required this.name,
    required this.count,
    this.isYou = false,
  });
}

/// Firestore üzerinde GERÇEK, cihazlar arası bir "bugün en çok kim okudu"
/// tablosu tutar.
///
/// Veri modeli: leaderboard_daily/{yyyy-MM-dd}/entries/{uid}
/// Her kullanıcı SADECE kendi belgesini yazabilir (bkz. Firestore Security
/// Rules), ama herkes hepsini okuyabilir — liderlik tablosunun çalışması
/// için bu gerekli. Böylece her gün için ayrı, küçük bir koleksiyon oluşur
/// ve sıralamayı hesaplamak için TÜM kullanıcı geçmişini taramaya gerek
/// kalmaz.
class LeaderboardService {
  static String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static CollectionReference<Map<String, dynamic>> _todayCollection() {
    final todayKey = _dateKey(DateTime.now());
    return FirebaseFirestore.instance
        .collection('leaderboard_daily')
        .doc(todayKey)
        .collection('entries');
  }

  /// Kullanıcı bir egzersiz tamamladığında çağrılır — bugünkü toplam
  /// sayacını Firestore'a yazar. Kaynak zaten ProgressManager olduğu için
  /// burada "artırma" değil, doğrudan güncel değeri yazma yapılır.
  /// Giriş yapılmamışsa hiçbir şey yapmaz (yerel/misafir modda kalınır).
  static Future<void> updateTodayCount(int count) async {
    final user = AuthService.currentUser;
    if (user == null) return;

    final name = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : 'Kullanıcı';

    await _todayCollection().doc(user.uid).set({
      'name': name,
      'count': count,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Bugünün ilk [limit] sırasını büyükten küçüğe döner.
  static Future<List<LeaderboardEntryRemote>> todayTop({int limit = 20}) async {
    final myUid = AuthService.currentUser?.uid;
    final snapshot = await _todayCollection()
        .orderBy('count', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return LeaderboardEntryRemote(
        uid: doc.id,
        name: (data['name'] as String?) ?? 'Kullanıcı',
        count: (data['count'] as num?)?.toInt() ?? 0,
        isYou: doc.id == myUid,
      );
    }).toList();
  }
}

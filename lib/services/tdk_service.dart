import 'dart:convert';
import 'package:http/http.dart' as http;

/// TDK (Türk Dil Kurumu) Güncel Türkçe Sözlük servisinden GERÇEK,
/// resmî kelime tanımlarını çeker. https://sozluk.gov.tr üzerinden herkese
/// açık, kimlik doğrulama gerektirmeyen bir uç nokta kullanılır.
class TdkService {
  static Future<List<String>?> lookup(String word) async {
    final cleaned = word.trim();
    if (cleaned.isEmpty) return null;

    try {
      final uri = Uri.https('sozluk.gov.tr', '/gts', {'ara': cleaned});
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      // Kelime bulunamazsa TDK {"error": "Sonuç bulunamadı"} döner.
      if (decoded is! List || decoded.isEmpty) return null;

      final entry = decoded.first as Map<String, dynamic>;
      final anlamlar = entry['anlamlarListe'] as List<dynamic>?;
      if (anlamlar == null || anlamlar.isEmpty) return null;

      return anlamlar
          .map((a) => (a as Map<String, dynamic>)['anlam'] as String?)
          .whereType<String>()
          .where((a) => a.trim().isNotEmpty)
          .toList();
    } catch (_) {
      // İnternet yok ya da TDK servisi geçici olarak yanıt vermiyor —
      // çağıran taraf bunu null olarak alıp yerel sözlüğe düşer.
      return null;
    }
  }
}

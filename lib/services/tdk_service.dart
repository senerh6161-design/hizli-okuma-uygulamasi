import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/turkish_stemmer.dart';

/// TDK (Türk Dil Kurumu) Güncel Türkçe Sözlük servisinden GERÇEK,
/// resmî kelime tanımlarını çeker. https://sozluk.gov.tr üzerinden herkese
/// açık, kimlik doğrulama gerektirmeyen bir uç nokta kullanılır.
class TdkService {
  static Future<List<String>?> lookup(String word) async {
    final cleaned = word.trim();
    if (cleaned.isEmpty) return null;

    // Metindeki kelimelerin çoğu ek alıyor (ör. "ülkelerin", "keşfetmeyi")
    // ve TDK sözlüğü ekli hâlleri değil kök/mastar hâlleri barındırıyor.
    // Önce kelimenin kendisi, olmazsa gittikçe daha fazla ek çıkarılmış
    // aday kökleri sırayla denenir.
    for (final candidate in turkishStemCandidates(cleaned)) {
      final result = await _lookupExact(candidate);
      if (result != null && result.isNotEmpty) return result;
    }
    return null;
  }

  // sozluk.gov.tr, Dart'ın varsayılan User-Agent'ıyla (ör. "Dart/3.x
  // (dart:io)") gelen isteklerde bağlantıyı yanıt tamamlanmadan kapatıyor —
  // tarayıcı benzeri bir User-Agent gönderilince sorun ortadan kalkıyor.
  static const Map<String, String> _requestHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36',
  };

  static Future<List<String>?> _lookupExact(String word) async {
    try {
      final uri = Uri.https('sozluk.gov.tr', '/gts', {'ara': word});
      final response = await http.get(uri, headers: _requestHeaders).timeout(const Duration(seconds: 8));
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

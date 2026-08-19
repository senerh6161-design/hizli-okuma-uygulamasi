/// Anlama Testi metinlerinde geçen kelimeler için çocuk dostu, kısa
/// tanımlar sağlar. Tamamen cihaz üzerinde (offline) çalışır — internet
/// bağlantısı ya da dış sözlük servisi GEREKTİRMEZ.
///
/// Kullanım: Anlama Testi'nde okuma ekranında bir kelimeye dokunulduğunda
/// [WordDictionary.define] çağrılır. Kelime doğrudan sözlükte yoksa, basit
/// bir Türkçe ek ayıklama denemesi yapılır (ör. "kapasitesini" ->
/// "kapasite"); o da bulamazsa arkadaşça bir "bulunamadı" mesajı gösterilir.
library;

import '../utils/turkish_stemmer.dart';

class WordDictionary {
  static const Map<String, String> _definitions = {
    // p1 - Hızlı Okuma ve Beyin Kasları
    'kapasite': 'Bir şeyin yapabileceği en yüksek miktar ya da güç.',
    'süreç': 'Bir işin başlangıcından bitimine kadar geçen aşamalar zinciri.',
    'odaklanmak': 'Dikkatini tamamen tek bir noktaya vermek.',
    'sıçrama': 'Bir yerden diğerine hızlı ve ani geçiş, atlama hareketi.',
    'duraklama': 'Kısa bir süreliğine durma, ara verme.',
    'egzersiz': 'Bir beceriyi geliştirmek için düzenli yapılan alıştırma.',
    'algılamak': 'Bir şeyi duyu organlarıyla fark etmek, kavramak.',

    // p2 - Yapay Zekânın Geleceği
    'analiz': 'Bir şeyi parçalarına ayırıp inceleme, çözümleme.',
    'kalıp': 'Tekrar eden, belli bir düzeni olan biçim.',
    'mühendislik': 'Bilim ve matematiği kullanarak yararlı şeyler tasarlama sanatı.',
    'doğruluk': 'Bir bilginin gerçeğe uygun olması.',
    'kalite': 'Bir şeyin iyilik ya da yeterlilik derecesi.',

    // p3 - Arıların Doğa İçindeki Önemi
    'ekosistem': 'Canlıların ve çevrelerinin birlikte oluşturduğu doğal denge.',
    'sürdürülebilirlik': 'Bir şeyin uzun süre bozulmadan devam edebilmesi.',
    'tozlaşma': 'Bitkilerin üreyebilmesi için polenin taşınması.',
    'polen': 'Çiçeklerin ürettiği, tozlaşmayı sağlayan ince toz.',
    'nüfus': 'Bir yerde yaşayan canlıların sayısı.',
    'tehdit': 'Bir şeye zarar verebilecek tehlike.',

    // p4 - Güneş Sistemimizin Gizemleri
    'gezegen': 'Bir yıldızın çevresinde dönen, kendi ışığı olmayan gök cismi.',
    'mesafe': 'İki nokta arasındaki uzaklık.',
    'teleskop': 'Uzaktaki gök cisimlerini yakından görmeyi sağlayan alet.',
    'fırtına': 'Çok güçlü rüzgar ve kötü hava koşulları.',
    'keşfetmek': 'Daha önce bilinmeyen bir şeyi bulmak, ortaya çıkarmak.',

    // p5 - Takım Ruhu ve Başarı
    'dayanışma': 'Birbirine destek olma, yardımlaşma.',
    'savunma': 'Bir takımın rakibin sayı yapmasını engellemeye çalışması.',
    'iletişim': 'Düşünce ve duyguları başkalarına aktarma.',
    'güvenmek': 'Birine inanmak, ona dayanabileceğini hissetmek.',

    // p6 - Resmin Büyülü Dünyası
    'tuval': 'Ressamların resim yaptığı, gerilmiş kumaş yüzey.',
    'coşku': 'Çok güçlü, taşkın bir sevinç duygusu.',
    'huzur': 'Rahatlık ve iç sükunet hâli.',
    'akım': 'Sanatta ya da düşüncede ortaya çıkan ortak bir yönelim.',
    'ipucu': 'Bir şeyi anlamaya yardımcı olan küçük bilgi.',

    // p7 - Yunusların Şaşırtıcı Zekâsı
    'sosyal': 'Başkalarıyla birlikte yaşamayı ve iletişim kurmayı seven.',
    'sürü': 'Aynı türden hayvanların bir arada oluşturduğu topluluk.',
    'zekâ': 'Öğrenme, anlama ve problem çözme yeteneği.',
    'imza': 'Bir kişiye ya da varlığa özgü, onu tanımlayan işaret.',

    // p8 - Yağmur Ormanlarının Sırrı
    'oksijen': 'Canlıların nefes almak için ihtiyaç duyduğu gaz.',
    'inşaat': 'Bina, yol gibi yapıların yapılması işi.',
    'değerli': 'Kıymetli, önemi büyük olan.',

    // p9 - Robotlar Hayatımızda
    'cerrahi': 'Ameliyatla ilgili, ameliyat yoluyla yapılan.',
    'hassas': 'Çok dikkatli ve titiz olmayı gerektiren.',
    'keşif': 'Bilinmeyen bir yeri ya da şeyi araştırıp bulma.',
    'avantaj': 'Bir şeyin sağladığı üstünlük ya da kolaylık.',

    // Genel / sık kullanılan destek kelimeler
    'yetenek': 'Bir işi iyi yapabilme becerisi.',
    'başarı': 'İstenen sonuca ulaşma.',
    'gelecek': 'Henüz yaşanmamış, ileride olacak zaman.',
    'kritik': 'Çok önemli, sonucu etkileyen.',
    'faaliyet': 'Yapılan iş ya da etkinlik.',
  };

  // Uzunluğa göre büyükten küçüğe sıralı basit Türkçe ekler. Kelimenin
  // sonunda bu eklerden biri varsa çıkarılır ve kalan kök sözlükte
  // aranır. Yanlış eşleşmeyi önlemek için kök en az 3 harf olmalı VE
  // sözlükte doğrudan bulunmalı — yani "tahmin" ile eşleşme yapılmaz,
  // sadece gerçek kökler bulunur. Ek listesi turkish_stemmer.dart'ta,
  // TDK araması ile aynı yerde tutuluyor.

  static String _normalize(String raw) {
    var w = raw.trim();
    w = w.replaceAll(RegExp(r'''[.,;:!?"'“”‘’()\[\]…]'''), '');
    // Türkçe'ye uygun büyük/küçük harf dönüşümü (İ->i, I->ı).
    w = w.replaceAll('İ', 'i').replaceAll('I', 'ı');
    return w.toLowerCase();
  }

  /// Verilen kelime (veya cümle içindeki noktalamalı hâli) için kısa bir
  /// tanım döner. Bulunamazsa null döner — arayüz bu durumda arkadaşça
  /// bir mesaj gösterebilir.
  static String? define(String rawWord) {
    final key = _normalize(rawWord);
    if (key.isEmpty) return null;

    for (final candidate in turkishStemCandidates(key)) {
      if (_definitions.containsKey(candidate)) return _definitions[candidate];
    }

    return null;
  }

  /// Sadece noktalamadan arındırılmış temiz kelimeyi döner (gösterim için).
  static String cleanWord(String rawWord) => _normalize(rawWord);
}

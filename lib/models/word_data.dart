import 'dart:math';

class WordData {
  static final Random _random = Random();

  // Zengin Tekil Kelime Havuzu
  static const List<String> singleWords = [
    'çınar', 'ıspanak', 'karanfil', 'kestane', 'akasya', 'palamut', 'çekirdek',
    'çimen', 'sarmaşık', 'nilüfer', 'nergis', 'yasemin', 'menekşe', 'sarımsak',
    'domates', 'patlıcan', 'şeftali', 'portakal', 'kiraz', 'kayısı', 'mantar',
    'gökkuşağı', 'pırasa', 'akarsu', 'gökyüzü', 'anahtar', 'güneş', 'bardak',
    'bilgisayar', 'kamera', 'şemsiye', 'tencere', 'koltuk', 'kavanoz', 'mutluluk',
    'heyecan', 'sağlık', 'hediye', 'oyuncak', 'kelebek', 'güvercin', 'papağan',
    'kaplumbağa', 'mühendis', 'öğretmen', 'gazeteci', 'hikâye', 'piyano', 'basketbol',
    'uçurtma', 'bisiklet', 'dondurma', 'eczaneler', 'çikolata', 'asansör', 'alkış',
    'zaman', 'gece', 'yıldız', 'bulut', 'fırtına', 'şelale', 'oksijen', 'gezegen',
    'teleskop', 'mikroskop', 'pusula', 'harita', 'kütüphane', 'müze', 'tiyatro',
    'senfoni', 'heykeltıraş', 'ressam', 'mimar', 'astronot', 'biyoloji', 'felsefe',
    'matematik', 'algoritma', 'yazılım', 'donanım', 'teknoloji', 'inovasyon',
    'sardunya', 'papatya', 'manolya', 'zambak', 'biberiye', 'fesleğen', 'mandalina'
  ];

  // Zengin İkili Öbek Havuzu
  static const List<String> pairs = [
    'halı kilim', 'orman gülü', 'yakacak kömür', 'sevgi yolu', 'bundan böyle',
    'bayram geldi', 'bilge insan', 'çalışkan insan', 'yaramaz çocuk', 'uzun köprü',
    'komşu ülke', 'canlı balık', 'yeşil orman', 'yol yapımı', 'kitap kurdu',
    'inci mercan', 'taze simit', 'bahar geldi', 'gece gündüz', 'karlı dağlar',
    'bilgi gücü', 'kum saati', 'güzel ülke', 'beyaz dişler', 'pazar yeri',
    'diş hekimi', 'bozuk para', 'siyah gömlek', 'kırmızı kalem', 'yeni araba',
    'büyük otobüs', 'yüksek apartman', 'ucuz ekmek', 'ekşi limon', 'sarı patates',
    'yeşil domates', 'beyaz telefon', 'ince ip', 'eski günler', 'mavi kazak',
    'güzel kitap', 'derin deniz', 'sıcak çay', 'soğuk su', 'açık pencere',
    'parlak güneş', 'hızlı tren', 'sessiz kütüphane', 'renkli resim', 'uzak diyar'
  ];

  /// İstenilen adette rastgele BENZERSİZ tekil kelime getirir
  static List<String> getRandomSingleWords(int count) {
    List<String> shuffled = List.from(singleWords)..shuffle(_random);
    return shuffled.take(count).toList();
  }

  /// İstenilen adette rastgele BENZERSİZ ikili kelime getirir
  static List<String> getRandomPairs(int count) {
    List<String> shuffled = List.from(pairs)..shuffle(_random);
    return shuffled.take(count).toList();
  }
}
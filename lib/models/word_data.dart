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
    'sardunya', 'papatya', 'manolya', 'zambak', 'biberiye', 'fesleğen', 'mandalina',
    // Hocanın "hızlı kelimeler" sunumundan eklenen kelimeler
    'babaanne', 'ağabey', 'abla', 'rüzgarlı', 'battaniye', 'buzdolabı', 'fotoğraf', 'şampuan', 'süpürge',
    'anlaşmak', 'alkışlamak', 'biriktirmek', 'başarmak', 'çarpışmak', 'büyümek', 'değiştirmek',
    'düzenlemek', 'cevaplamak', 'ilgilenmek', 'iyileşmek', 'güvenmek', 'gülümsemek', 'kararlaştırmak',
    'kahvaltı', 'karıştırmak', 'kilitlemek', 'savaşmak', 'toplamak', 'uzaklaşmak', 'uyandırmak',
    'vazgeçmek', 'yenilmek', 'yükselmek', 'padişah', 'tekerlek', 'yaprak', 'arkadaş', 'hareket',
    'bereket', 'gözyaşı', 'konuşma', 'kaynak', 'mektup', 'yarışmak', 'misafir', 'mevsim', 'mahalle',
    'elektrik', 'yiyecek', 'yolculuk', 'dikkat', 'pantolon', 'ayakkabı', 'eldiven', 'karınca',
    'örümcek', 'zürafa', 'itfaiyeci', 'postacı', 'hemşire', 'saklambaç', 'salıncak', 'otobüs',
    'helikopter', 'başparmak', 'eczane',
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
    'parlak güneş', 'hızlı tren', 'sessiz kütüphane', 'renkli resim', 'uzak diyar',
    // Hocanın "hızlı kelimeler" sunumundan eklenen ikili öbekler
    'kabak çekirdeği', 'diş fırçası', 'çamaşır makinesi', 'fotoğraf makinesi', 'çöp kovası',
    'çalar saat', 'oturma odası', 'davet etmek', 'acele etmek', 'fark etmek', 'fotoğraf çekmek',
    'dikkat etmek', 'izin vermek', 'hareket etmek', 'takip etmek', 'tamir etmek', 'yardım etmek',
    'doğum günü', 'öğle yemeği', 'çizgi film', 'hayvanat bahçesi',
    'açık kapalı', 'acı tatlı', 'aşağı yukarı', 'büyük küçük', 'yaşlı genç', 'dağınık düzenli',
    'güzel çirkin', 'içeri dışarı', 'hızlı yavaş', 'sıcak soğuk', 'önce sonra', 'taze bayat',
    'yumuşak sert', 'yanlış doğru', 'film senaryosu', 'matematik geometri', 'psikoloji sosyoloji',
    'astronomi biyoloji', 'futbol basketbol', 'masa tenisi', 'roman hikaye', 'gölge oyunu',
    'kızartma köfte', 'yanak yüz', 'simit şeker', 'kol kulak', 'çember daire', 'kitap defter',
    'pilot polis',
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
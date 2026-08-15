class ReadingTopic {
  final String id;
  final String title;
  final String emoji;

  const ReadingTopic({
    required this.id,
    required this.title,
    required this.emoji,
  });
}

class ReadingPassage {
  final String id;
  final String title;
  final String topic; // ReadingTopic.id ile eşleşir
  final String content;
  final List<Map<String, dynamic>> questions;

  const ReadingPassage({
    required this.id,
    required this.title,
    required this.topic,
    required this.content,
    required this.questions,
  });
}

class ComprehensionData {
  // Çocuğun ilgisine göre seçebileceği konu havuzu. Sırayla Egzersiz >
  // Anlama Testi akışında gösterilir.
  static const List<ReadingTopic> topics = [
    ReadingTopic(id: 'bilim', title: 'Bilim', emoji: '🔬'),
    ReadingTopic(id: 'teknoloji', title: 'Teknoloji', emoji: '🤖'),
    ReadingTopic(id: 'doga', title: 'Doğa', emoji: '🌿'),
    ReadingTopic(id: 'uzay', title: 'Uzay', emoji: '🚀'),
    ReadingTopic(id: 'spor', title: 'Spor', emoji: '⚽'),
    ReadingTopic(id: 'sanat', title: 'Sanat', emoji: '🎨'),
    ReadingTopic(id: 'hayvanlar', title: 'Hayvanlar', emoji: '🐬'),
  ];

  static ReadingTopic? topicById(String? id) {
    if (id == null) return null;
    for (final topic in topics) {
      if (topic.id == id) return topic;
    }
    return null;
  }

  static const List<ReadingPassage> passages = [
    ReadingPassage(
      id: 'p1',
      title: 'Hızlı Okuma ve Beyin Kasları',
      topic: 'bilim',
      content:
          'Hızlı okuma, yalnızca gözlerin metin üzerinde hızla kayması değil, beynin görsel verileri işleme kapasitesini artırma sürecidir. İnsan gözü bir kelimeye odaklandığında sıçrama ve duraklama hareketleri yapar. Doğru egzersizlerle bu duraklama süreleri azaltılabilir ve gözün tek bir bakışta algıladığı kelime sayısı artırılabilir.',
      questions: [
        {
          'question': 'Hızlı okuma, beynin görsel verileri işleme kapasitesini artırma sürecidir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'İnsan gözü okurken sadece dairesel hareketler yapar.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Doğru egzersizlerle gözün tek bir bakışta algıladığı kelime sayısı artırılabilir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
      ],
    ),
    ReadingPassage(
      id: 'p2',
      title: 'Yapay Zekânın Geleceği',
      topic: 'teknoloji',
      content:
          'Yapay zekâ teknolojileri, günümüzde veri analizi ve kalıp tanıma yetenekleriyle insan hayatını kolaylaştırmaktadır. Özellikle mühendislik ve tıp alanında karmaşık problemleri saniyeler içinde çözebilmektedir. Ancak yapay zekânın başarısı, eğitildiği verilerin kalitesine ve doğruluğuna doğrudan bağlıdır.',
      questions: [
        {
          'question': 'Yapay zekânın başarısı, eğitildiği verilerin kalitesine bağlıdır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Yapay zekâ sadece moda ve mimari alanlarında kullanılır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Yapay zekâ, veri analizi ve kalıp tanıma yetenekleriyle öne çıkar.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
      ],
    ),
    ReadingPassage(
      id: 'p3',
      title: 'Arıların Doğa İçindeki Önemi',
      topic: 'doga',
      content:
          'Arılar, ekosistemin sürdürülebilirliği için kritik bir role sahiptir. Çiçekler arasında polen taşıyarak bitkilerin tozlaşmasını sağlarlar. Dünya üzerindeki tarımsal ürünlerin büyük bir kısmı arıların bu polenleme faaliyetine bağımlıdır. Arı nüfusunun azalması, küresel gıda güvenliği için ciddi bir tehdittir.',
      questions: [
        {
          'question': 'Arılar, çiçekler arasında polen taşıyarak tozlaşmayı sağlar.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Arı nüfusunun azalmasının küresel gıda güvenliğiyle hiçbir ilgisi yoktur.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Tarımsal ürünlerin büyük bir kısmı arıların polenleme faaliyetine bağımlıdır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
      ],
    ),
    ReadingPassage(
      id: 'p4',
      title: 'Güneş Sistemimizin Gizemleri',
      topic: 'uzay',
      content:
          'Güneş Sistemi, merkezinde Güneş olan ve onun çevresinde dönen sekiz gezegenden oluşur. Dünya, Güneş\'e olan mesafesi sayesinde yaşama uygun sıcaklığa sahiptir. Jüpiter, sistemin en büyük gezegeni olup güçlü fırtınalarıyla bilinir. Bilim insanları, uzay teleskopları sayesinde Güneş Sistemi dışındaki gezegenleri de keşfetmeye devam ediyor.',
      questions: [
        {
          'question': 'Güneş Sistemi sekiz gezegenden oluşur.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Sistemin en büyük gezegeni Mars\'tır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Dünya, Güneş\'e olan mesafesi sayesinde yaşama uygun sıcaklığa sahiptir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
      ],
    ),
    ReadingPassage(
      id: 'p5',
      title: 'Takım Ruhu ve Başarı',
      topic: 'spor',
      content:
          'Spor yalnızca fiziksel güç kazandırmaz, aynı zamanda paylaşmayı ve dayanışmayı da öğretir. Bir basketbol takımında her oyuncu farklı bir görev üstlenir; kimi pas verir, kimi savunma yapar, kimi de sayı atar. Takım arkadaşlarına güvenmeyi öğrenen bir sporcu, sahada olduğu kadar günlük hayatta da başarılı iletişim kurar.',
      questions: [
        {
          'question': 'Spor, paylaşmayı ve dayanışmayı da öğretir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Basketbol takımında bütün oyuncular aynı görevi üstlenir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Takım arkadaşına güvenmeyi öğrenen sporcu, günlük hayatta da başarılı iletişim kurar.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
      ],
    ),
    ReadingPassage(
      id: 'p6',
      title: 'Resmin Büyülü Dünyası',
      topic: 'sanat',
      content:
          'Resim yapmak, düşüncelerimizi kelimeler olmadan anlatmanın en özgür yollarından biridir. Bir ressam, fırçasıyla hem gördüklerini hem de hayal ettiklerini tuvale aktarabilir. Renkler bize duygular hakkında ipucu verir: sıcak tonlar coşkuyu, soğuk tonlar ise huzuru çağrıştırabilir. Sanat tarihinde her dönem, kendi zamanının izlerini taşıyan yeni akımlar doğurmuştur.',
      questions: [
        {
          'question': 'Resim yapmak, düşünceleri kelimeler olmadan anlatmanın en özgür yollarından biridir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Sıcak renk tonları huzuru çağrıştırır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Sanat tarihinde her dönem, kendi zamanının izlerini taşıyan akımlar doğurmuştur.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
      ],
    ),
    ReadingPassage(
      id: 'p7',
      title: 'Yunusların Şaşırtıcı Zekâsı',
      topic: 'hayvanlar',
      content:
          'Yunuslar, denizlerin en zeki canlılarından sayılır. Birbirleriyle özel ıslık sesleriyle iletişim kurar, hatta her yunusun kendine özgü bir "imza ıslığı" olduğu bilinir. Sürü hâlinde avlanırken birbirlerine yardım ederler ve yaralı bir yunusu yüzeye çıkarıp nefes almasına yardımcı olabilirler. Bu davranışlar, yunusların güçlü bir sosyal zekâya sahip olduğunu gösterir.',
      questions: [
        {
          'question': 'Yunuslar birbirleriyle özel ıslık sesleriyle iletişim kurar.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Her yunusun "imza ıslığı" birbirinin aynısıdır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Yaralı bir yunusu sürüsü yüzeye çıkarıp nefes almasına yardım eder.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
      ],
    ),
    ReadingPassage(
      id: 'p8',
      title: 'Yağmur Ormanlarının Sırrı',
      topic: 'doga',
      content:
          'Yağmur ormanları, Dünya\'daki bitki ve hayvan türlerinin yarısından fazlasına ev sahipliği yapar. Bu ormanlar aynı zamanda "Dünya\'nın akciğerleri" olarak da anılır, çünkü ürettikleri oksijen tüm gezegene yayılır. Ne yazık ki tarım ve inşaat için yapılan ağaç kesimleri, bu değerli ekosistemleri her geçen yıl küçültüyor. Ormanları korumak, geleceğimizi korumak anlamına gelir.',
      questions: [
        {
          'question': 'Yağmur ormanları "Dünya\'nın akciğerleri" olarak anılır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Yağmur ormanları hiçbir tehditle karşı karşıya değildir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Yağmur ormanları, Dünya\'daki bitki ve hayvan türlerinin yarısından fazlasına ev sahipliği yapar.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
      ],
    ),
    ReadingPassage(
      id: 'p9',
      title: 'Robotlar Hayatımızda',
      topic: 'teknoloji',
      content:
          'Robotlar artık yalnızca fabrikalarda değil, evlerimizde, hastanelerde ve hatta uzayda da görev yapıyor. Temizlik robotları evi süpürürken, cerrahi robotlar doktorlara hassas ameliyatlarda yardımcı oluyor. Mars\'ta gezen keşif robotları ise insan ayak basmadan önce gezegen hakkında bilgi topluyor. Robotların en büyük avantajı, tehlikeli ya da tekrar eden işleri yorulmadan yapabilmeleridir.',
      questions: [
        {
          'question': 'Cerrahi robotlar doktorlara hassas ameliyatlarda yardımcı olur.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Robotlar sadece fabrikalarda kullanılır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Mars\'taki keşif robotları gezegen hakkında bilgi toplar.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
      ],
    ),
  ];

  /// Verilen konu id'sine ait metinleri döner. Konu null ise ya da o
  /// konuda hiç metin yoksa TÜM havuzu döner (rastgele karışık deneyim).
  static List<ReadingPassage> passagesForTopic(String? topicId) {
    if (topicId == null || topicId.isEmpty) return passages;
    final filtered = passages.where((p) => p.topic == topicId).toList();
    return filtered.isEmpty ? passages : filtered;
  }
}

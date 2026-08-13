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
          'question': 'Metne göre hızlı okuma sürecinde asıl amaç nedir?',
          'answers': [
            'Gözleri yormak',
            'Beynin verileri işleme kapasitesini artırmak',
            'Kelime atlayarak okumak',
            'Sadece sayfa sayısını bitirmek'
          ],
          'correct': 1,
        },
        {
          'question': 'İnsan gözü okuma sırasında hangi hareketleri yapar?',
          'answers': [
            'Sıçrama ve duraklama',
            'Dairesel dönme',
            'Geriye doğru tarama',
            'Sabit kalma'
          ],
          'correct': 0,
        },
        {
          'question': 'Doğru egzersizlerle aşağıdakilerden hangisi sağlanır?',
          'answers': [
            'Duraklama süresi uzar',
            'Göz sağlığı bozulur',
            'Tek bakışta algılanan kelime sayısı artar',
            'Okuma isteği azalır'
          ],
          'correct': 2,
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
          'question': 'Yapay zekânın başarısı neye bağlıdır?',
          'answers': [
            'İnternet hızına',
            'Eğitildiği verilerin kalitesine',
            'Bilgisayarın rengine',
            'Kullanılan dilin zorluğuna'
          ],
          'correct': 1,
        },
        {
          'question': 'Metne göre yapay zekâ hangi alanlarda karmaşık problemleri çözer?',
          'answers': [
            'Mühendislik ve tıp',
            'Spor ve edebiyat',
            'Aşçılık ve müzik',
            'Moda ve mimari'
          ],
          'correct': 0,
        },
        {
          'question': 'Yapay zekâ temel olarak hangi yetenekleriyle öne çıkar?',
          'answers': [
            'Duygusal tepki verme',
            'Veri analizi ve kalıp tanıma',
            'Hayal kurma',
            'Fiziksel hareket etme'
          ],
          'correct': 1,
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
          'question': 'Arıların bitkilere en büyük katkısı nedir?',
          'answers': [
            'Yaprakları temizlemek',
            'Polen taşıyarak tozlaşmayı sağlamak',
            'Toprağı havalandırmak',
            'Zararlı böcekleri yemek'
          ],
          'correct': 1,
        },
        {
          'question': 'Arı nüfusunun azalması neyi tehdit eder?',
          'answers': [
            'Deniz seviyelerini',
            'Rüzgâr hızını',
            'Küresel gıda güvenliğini',
            'Hava kalitesini'
          ],
          'correct': 2,
        },
        {
          'question': 'Metnin ana fikri aşağıdakilerden hangisidir?',
          'answers': [
            'Arı balının faydaları',
            'Arıların doğa ve gıda üretimi için hayati önemi',
            'Çiçek türlerinin çeşitliliği',
            'Tarım araçlarının kullanımı'
          ],
          'correct': 1,
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
          'question': 'Güneş Sistemi kaç gezegenden oluşur?',
          'answers': ['Beş', 'Yedi', 'Sekiz', 'On'],
          'correct': 2,
        },
        {
          'question': 'Dünya neden yaşama uygundur?',
          'answers': [
            'Çok büyük olduğu için',
            'Güneş\'e olan mesafesi sayesinde',
            'En hızlı döndüğü için',
            'Rengi mavi olduğu için'
          ],
          'correct': 1,
        },
        {
          'question': 'Sistemin en büyük gezegeni hangisidir?',
          'answers': ['Mars', 'Jüpiter', 'Venüs', 'Merkür'],
          'correct': 1,
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
          'question': 'Metne göre spor çocuklara ne kazandırır?',
          'answers': [
            'Sadece kas gücü',
            'Paylaşma ve dayanışma',
            'Yalnız kalma isteği',
            'Hız kaybı'
          ],
          'correct': 1,
        },
        {
          'question': 'Basketbol takımında oyuncular nasıl çalışır?',
          'answers': [
            'Hepsi aynı görevi yapar',
            'Farklı görevler üstlenirler',
            'Sırayla oyunu izler',
            'Tek başına oynarlar'
          ],
          'correct': 1,
        },
        {
          'question': 'Takım arkadaşına güvenmeyi öğrenen sporcu neyi başarır?',
          'answers': [
            'Sahada yalnız kalmayı',
            'Günlük hayatta iyi iletişim kurmayı',
            'Antrenmanlardan kaçmayı',
            'Rakibini hafife almayı'
          ],
          'correct': 1,
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
          'question': 'Metne göre resim yapmanın en özgür yönü nedir?',
          'answers': [
            'Sadece gerçekleri çizmek',
            'Düşünceleri kelimesiz anlatmak',
            'Renkleri karıştırmamak',
            'Hızlı çizim yapmak'
          ],
          'correct': 1,
        },
        {
          'question': 'Sıcak renk tonları hangi duyguyu çağrıştırır?',
          'answers': ['Huzuru', 'Üzüntüyü', 'Coşkuyu', 'Korkuyu'],
          'correct': 2,
        },
        {
          'question': 'Sanat tarihindeki akımlar neyi yansıtır?',
          'answers': [
            'Ressamın boyunu',
            'Kendi döneminin izlerini',
            'Tuvalin büyüklüğünü',
            'Fırça sayısını'
          ],
          'correct': 1,
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
          'question': 'Yunuslar birbirleriyle nasıl iletişim kurar?',
          'answers': [
            'Renk değiştirerek',
            'Özel ıslık sesleriyle',
            'Yüzgeçlerini sallayarak',
            'Su püskürterek'
          ],
          'correct': 1,
        },
        {
          'question': 'Her yunusun kendine özgü olan şey nedir?',
          'answers': ['Rengi', 'İmza ıslığı', 'Boyu', 'Yüzme hızı'],
          'correct': 1,
        },
        {
          'question': 'Yaralı bir yunusa sürüsü nasıl yardım eder?',
          'answers': [
            'Onu yalnız bırakır',
            'Yüzeye çıkarıp nefes almasına yardım eder',
            'Ona balık getirir',
            'Onu sudan çıkarır'
          ],
          'correct': 1,
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
          'question': 'Yağmur ormanları neden "Dünya\'nın akciğerleri" olarak anılır?',
          'answers': [
            'Çok büyük oldukları için',
            'Ürettikleri oksijen gezegene yayıldığı için',
            'Yağmur yağdırdıkları için',
            'Renkleri yeşil olduğu için'
          ],
          'correct': 1,
        },
        {
          'question': 'Yağmur ormanlarını küçülten en büyük tehdit nedir?',
          'answers': ['Kuraklık', 'Ağaç kesimleri', 'Soğuk hava', 'Deniz seviyesinin artması'],
          'correct': 1,
        },
        {
          'question': 'Metne göre ormanları korumak ne anlama gelir?',
          'answers': [
            'Sadece hayvanları korumak',
            'Geleceğimizi korumak',
            'Turizmi artırmak',
            'Odun üretimini artırmak'
          ],
          'correct': 1,
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
          'question': 'Cerrahi robotlar doktorlara nasıl yardımcı olur?',
          'answers': [
            'Ameliyat sonrası temizlik yaparak',
            'Hassas ameliyatlarda yardımcı olarak',
            'Hastaneyi süpürerek',
            'Randevu alarak'
          ],
          'correct': 1,
        },
        {
          'question': 'Mars\'taki keşif robotları ne yapar?',
          'answers': [
            'Gezegen hakkında bilgi toplar',
            'Mars\'ta ev inşa eder',
            'Diğer gezegenlere gider',
            'Sadece fotoğraf çeker'
          ],
          'correct': 0,
        },
        {
          'question': 'Metne göre robotların en büyük avantajı nedir?',
          'answers': [
            'Çok pahalı olmaları',
            'Tehlikeli işleri yorulmadan yapabilmeleri',
            'Renkli olmaları',
            'Sadece gece çalışmaları'
          ],
          'correct': 1,
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

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
    ReadingTopic(id: 'kodlama', title: 'Kodlama', emoji: '💻'),
    ReadingTopic(id: 'yemek', title: 'Yemek', emoji: '🍽️'),
    ReadingTopic(id: 'kitaplar', title: 'Kitaplar', emoji: '📚'),
    ReadingTopic(id: 'ulkeler', title: 'Ülkeler', emoji: '🌍'),
    ReadingTopic(id: 'biyografi', title: 'Biyografi', emoji: '📜'),
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
        {
          'question': 'Hızlı okuma tekniklerinin beyinle hiçbir ilgisi yoktur.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
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
        {
          'question': 'Yapay zekânın başarısı kullanılan verilerden bağımsızdır.',
          'answers': ['Doğru', 'Yanlış'],
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
        {
          'question': 'Arılar tozlaşmada hiçbir rol oynamaz.',
          'answers': ['Doğru', 'Yanlış'],
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
        {
          'question': 'Güneş Sistemi\'nin merkezinde Dünya bulunur.',
          'answers': ['Doğru', 'Yanlış'],
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
        {
          'question': 'Sporcular takım arkadaşlarına güvenmeyi hiç öğrenmez.',
          'answers': ['Doğru', 'Yanlış'],
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
        {
          'question': 'Renklerin duygularla hiçbir ilişkisi yoktur.',
          'answers': ['Doğru', 'Yanlış'],
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
        {
          'question': 'Yunuslar birbirleriyle hiçbir şekilde iletişim kurmaz.',
          'answers': ['Doğru', 'Yanlış'],
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
        {
          'question': 'Yağmur ormanları oksijen üretmez.',
          'answers': ['Doğru', 'Yanlış'],
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
        {
          'question': 'Robotlar sadece uzayda kullanılır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p10',
      title: 'Kodlama Nedir?',
      topic: 'kodlama',
      content:
          'Kodlama, bilgisayara ne yapması gerektiğini adım adım anlatmaktır. Programcılar, "kod" adı verilen özel bir dille bilgisayara talimatlar yazar. Bir oyunun nasıl çalışacağını, bir uygulamanın nasıl görüneceğini bile kodlama sayesinde tasarlarız. En küçük bir hata bile, tıpkı bir tarifte yanlış malzeme kullanmak gibi, programın çalışmamasına neden olabilir. Bu yüzden kodlama hem yaratıcılık hem de sabır gerektirir.',
      questions: [
        {
          'question': 'Kodlama, bilgisayara adım adım ne yapması gerektiğini anlatmaktır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Kodlamada küçük bir hata programın çalışmasını asla etkilemez.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Kodlama hem yaratıcılık hem sabır gerektirir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Kodlama hiçbir dikkat ya da özen gerektirmez.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p11',
      title: 'Sağlıklı Beslenmenin Sırrı',
      topic: 'yemek',
      content:
          'Sağlıklı beslenmek, vücudumuzun ihtiyaç duyduğu farklı besinleri dengeli bir şekilde almaktır. Meyveler ve sebzeler vitamin deposu iken, tahıllar bize enerji verir. Fazla şekerli ve yağlı yiyecekler ise sadece ara sıra, ölçülü tüketilmelidir. Bol su içmek de sindirim sistemimizin düzgün çalışması için çok önemlidir.',
      questions: [
        {
          'question': 'Meyveler ve sebzeler vitamin deposudur.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Şekerli ve yağlı yiyecekler her öğünde bol miktarda tüketilmelidir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Bol su içmek sindirim sistemi için önemlidir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Tahıllar vücuda hiç enerji vermez.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p12',
      title: 'Kitapların Büyülü Dünyası',
      topic: 'kitaplar',
      content:
          'Bir kitap açtığımızda, aslında başka bir dünyaya kapı aralarız. Roman okurken hayal gücümüz canlanır, karakterlerin yaşadıklarını sanki kendimiz yaşıyormuş gibi hissederiz. Düzenli kitap okumak sadece hayal gücümüzü değil, kelime dağarcığımızı ve empati kurma becerimizi de geliştirir. Her kitap, okuyana farklı bir bakış açısı kazandırır.',
      questions: [
        {
          'question': 'Düzenli kitap okumak kelime dağarcığını geliştirir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Kitap okumak hayal gücümüzü hiçbir şekilde etkilemez.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Her kitap okuyana farklı bir bakış açısı kazandırır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Kitap okumak empati kurma becerisini hiç geliştirmez.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p13',
      title: 'Dünyanın Dört Bir Yanından',
      topic: 'ulkeler',
      content:
          'Dünya üzerinde yaklaşık 195 farklı ülke bulunur ve her birinin kendine özgü bir bayrağı, dili ve kültürü vardır. Bazı ülkeler çok büyük topraklara sahipken, bazıları küçücük adalardan oluşur. Ülkeler arasındaki bu çeşitlilik, dünyayı keşfetmeyi ve farklı gelenekleri tanımayı heyecanlı bir maceraya dönüştürür. Her ülkenin başkenti, o ülkenin yönetim merkezi olarak kabul edilir.',
      questions: [
        {
          'question': 'Dünya üzerinde yaklaşık 195 farklı ülke bulunur.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Bütün ülkeler aynı bayrağı, dili ve kültürü paylaşır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Bir ülkenin başkenti, o ülkenin yönetim merkezi olarak kabul edilir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Dünya üzerinde sadece 10 ülke bulunur.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p14',
      title: 'İbni Sina: Tıbbın Öncüsü',
      topic: 'biyografi',
      content:
          'İbni Sina, 980 yılında bugünkü Özbekistan sınırları içinde doğmuş ünlü bir bilgin ve hekimdir. Küçük yaşta tıp, felsefe ve matematik alanlarında kendini yetiştirmiş, on sekiz yaşına geldiğinde döneminin önde gelen hekimlerinden biri olmuştur. En bilinen eseri El-Kânun fi\'t-Tıbb (Tıbbın Kanunu), yüzyıllarca hem İslam dünyasında hem de Avrupa üniversitelerinde tıp eğitiminin temel kaynağı olarak okutulmuştur. İbni Sina\'nın çalışmaları, modern tıbbın gelişimine de önemli katkılar sağlamıştır.',
      questions: [
        {
          'question': 'İbni Sina\'nın en bilinen eseri El-Kânun fi\'t-Tıbb\'dır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'İbni Sina\'nın eserleri sadece İslam dünyasında okutulmuş, Avrupa\'da hiç kullanılmamıştır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'İbni Sina, küçük yaşta tıp, felsefe ve matematik alanlarında kendini yetiştirmiştir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'İbni Sina hiçbir zaman hekim olmamıştır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p15',
      title: 'Ali Kuşçu: Yıldızların Bilgini',
      topic: 'biyografi',
      content:
          'Ali Kuşçu, 15. yüzyılda yaşamış önemli bir Türk astronomu ve matematikçisidir. Semerkant\'ta Uluğ Bey Rasathanesi\'nde çalışarak gök cisimleri üzerine değerli gözlemler yapmıştır. Fatih Sultan Mehmed\'in daveti üzerine İstanbul\'a gelmiş, burada matematik ve astronomi alanında dersler vermiştir. Ali Kuşçu\'nun bilime katkılarını anmak için Ay üzerindeki bir krater onun adıyla anılmaktadır.',
      questions: [
        {
          'question': 'Ali Kuşçu, Uluğ Bey Rasathanesi\'nde çalışmıştır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Ali Kuşçu, Fatih Sultan Mehmed\'in davetini reddederek İstanbul\'a hiç gitmemiştir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Ay üzerinde Ali Kuşçu\'nun adını taşıyan bir krater vardır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Ali Kuşçu hiçbir gök cismi gözlemi yapmamıştır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p16',
      title: 'Bîrûnî: Çok Yönlü Bilgin',
      topic: 'biyografi',
      content:
          'Bîrûnî, 973 yılında Harezm\'de doğmuş; matematik, astronomi, coğrafya ve tarih gibi pek çok alanda eser vermiş çok yönlü bir bilgindir. Dünya\'nın yarıçapını, o dönem için şaşırtıcı derecede doğru bir yöntemle hesaplamıştır. Hindistan\'a yaptığı geziler sonucunda kaleme aldığı Kitâbü\'l-Hind adlı eseriyle Hint kültürünü ve bilimini tanıtmıştır. Bîrûnî\'nin çalışmaları, onun tarihin ilk gerçek bilim insanlarından biri olarak anılmasını sağlamıştır.',
      questions: [
        {
          'question': 'Bîrûnî, Dünya\'nın yarıçapını hesaplamıştır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Bîrûnî yalnızca astronomiyle ilgilenmiş, başka hiçbir alanda çalışma yapmamıştır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Kitâbü\'l-Hind, Bîrûnî\'nin Hindistan gezileri sonucunda yazdığı bir eserdir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Bîrûnî sadece Avrupa\'yı ziyaret etmiştir, Hindistan\'a hiç gitmemiştir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p17',
      title: 'Mikroplar Dünyası',
      topic: 'bilim',
      content:
          'Mikroplar, çıplak gözle görülemeyecek kadar küçük canlılardır; bakteri, virüs ve mantarları kapsar. Bazı mikroplar hastalıklara neden olurken, bazıları sindirim sistemimizde besinleri parçalamamıza yardımcı olan faydalı canlılardır. Bilim insanları mikroskop sayesinde bu küçük dünyayı keşfedip incelemeyi başarmıştır. Ellerimizi düzenli yıkamak, zararlı mikropların vücudumuza girmesini önlemenin en etkili yollarından biridir.',
      questions: [
        {'question': 'Mikroplar çıplak gözle görülemeyecek kadar küçüktür.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Bütün mikroplar vücudumuza zarar verir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Elleri düzenli yıkamak zararlı mikroplardan korunmanın etkili bir yoludur.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Mikroplar mikroskopla bile görülemez.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
      ],
    ),
    ReadingPassage(
      id: 'p18',
      title: 'Enerjinin Halleri',
      topic: 'bilim',
      content:
          'Enerji, bir işin yapılabilmesini sağlayan güçtür ve farklı biçimlerde bulunabilir: ışık enerjisi, ısı enerjisi, hareket enerjisi ve elektrik enerjisi gibi. Güneş, dünyadaki en büyük enerji kaynağıdır ve bitkiler fotosentez yoluyla bu enerjiyi kullanır. Enerji yoktan var edilemez ya da yok edilemez, sadece bir biçimden diğerine dönüşür. Rüzgar türbinleri, rüzgarın hareket enerjisini elektrik enerjisine çevirerek evlerimizi aydınlatmamıza yardımcı olur.',
      questions: [
        {'question': 'Güneş, dünyadaki en büyük enerji kaynağıdır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Enerji yoktan var edilip yok edilebilir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Rüzgar türbinleri rüzgarın hareket enerjisini elektrik enerjisine çevirir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Bitkiler güneş enerjisini hiçbir şekilde kullanmaz.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
      ],
    ),
    ReadingPassage(
      id: 'p19',
      title: 'Deney Yapmanın Önemi',
      topic: 'bilim',
      content:
          'Bilim insanları, bir fikrin doğru olup olmadığını anlamak için deneyler yapar. Bir deney yaparken önce bir soru sorulur, sonra bu soruya cevap bulmak için dikkatli bir plan hazırlanır. Aynı deneyin birkaç kez tekrarlanması, sonuçların güvenilir olup olmadığını anlamamızı sağlar. Deneyler sırasında elde edilen veriler dikkatle kaydedilir ve sonunda bir sonuca varılır.',
      questions: [
        {'question': 'Deneyler bir fikrin doğru olup olmadığını anlamak için yapılır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Bir deneyi sadece bir kez yapmak sonuçların güvenilirliği için yeterlidir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Deneyler sırasında elde edilen veriler kaydedilmez.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Bir deney yapmadan önce dikkatli bir plan hazırlanır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
      ],
    ),
    ReadingPassage(
      id: 'p20',
      title: 'Karıncaların Gizli Dünyası',
      topic: 'hayvanlar',
      content:
          'Karıncalar, küçük görünse de son derece düzenli bir toplum içinde yaşayan böceklerdir. Her karınca kolonisinde işçi karıncalar, asker karıncalar ve bir kraliçe karınca farklı görevler üstlenir. Karıncalar, kendi ağırlıklarının kat kat fazlasını taşıyabilecek kadar güçlüdür. Birbirleriyle özel kokular (feromonlar) bırakarak iletişim kurar ve yiyecek kaynaklarına giden yolu arkadaşlarına gösterirler.',
      questions: [
        {'question': 'Karınca kolonisinde farklı görevler üstlenen karıncalar vardır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Karıncalar kendi ağırlıklarını bile taşıyamayacak kadar güçsüzdür.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Karıncalar birbirleriyle özel kokular bırakarak iletişim kurar.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Karıncalar birbirleriyle hiçbir şekilde iletişim kurmaz.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
      ],
    ),
    ReadingPassage(
      id: 'p21',
      title: 'Kutup Ayısının Yaşamı',
      topic: 'hayvanlar',
      content:
          'Kutup ayıları, Kuzey Kutbu\'nun buzlu sularında ve karlarla kaplı topraklarında yaşayan büyük memelilerdir. Kalın kürkleri ve altındaki yağ tabakası, onları dondurucu soğuktan korur. Mükemmel yüzücülerdir ve saatlerce kesintisiz yüzebilirler. Beslenmeleri büyük ölçüde foklara dayanır, bu yüzden buzların erimesi onların hayatta kalması için ciddi bir tehdit oluşturur.',
      questions: [
        {'question': 'Kutup ayılarının kalın kürkü ve yağ tabakası onları soğuktan korur.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Kutup ayıları yüzmeyi hiç beceremez.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Buzların erimesi kutup ayıları için bir tehdit oluşturur.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Kutup ayılarının beslenmesi foklarla hiç ilgili değildir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
      ],
    ),
    ReadingPassage(
      id: 'p22',
      title: 'Kelebeğin Değişimi',
      topic: 'hayvanlar',
      content:
          'Bir kelebeğin hayatı, minik bir yumurtadan başlar ve tırtıl haline gelmesiyle devam eder. Tırtıl, yeterince büyüdüğünde kendini bir kozanın içine sarar ve burada büyük bir dönüşüm geçirir. Bu sürece başkalaşım (metamorfoz) denir. Kozadan çıkan canlı, artık renkli kanatlara sahip bir kelebektir ve çiçeklerden nektar toplayarak beslenir.',
      questions: [
        {'question': 'Kelebeğin hayatı bir yumurtayla başlar.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Tırtıl, kozaya girmeden doğrudan kelebeğe dönüşür.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Bu dönüşüm sürecine başkalaşım (metamorfoz) denir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Kelebekler nektarla değil etle beslenir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
      ],
    ),
    ReadingPassage(
      id: 'p23',
      title: 'Kütüphanelerin Tarihi',
      topic: 'kitaplar',
      content:
          'Kütüphaneler, binlerce yıldır bilginin saklandığı özel yerlerdir. Tarihteki en ünlü kütüphanelerden biri, Mısır\'daki İskenderiye Kütüphanesi\'ydi ve dönemin en büyük bilgi hazinesini barındırıyordu. Eskiden kitaplar el yazmasıyla yazıldığı için çok değerliydi ve üretilmesi uzun zaman alıyordu. Günümüzde kütüphaneler hem basılı kitapları hem de dijital kaynakları bir arada sunmaktadır.',
      questions: [
        {'question': 'İskenderiye Kütüphanesi Mısır\'daydı.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Eskiden kitaplar matbaa makineleriyle saniyeler içinde basılırdı.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Günümüz kütüphaneleri sadece basılı kitap sunar, dijital kaynak sunmaz.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Eskiden kitaplar el yazmasıyla yazılırdı.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
      ],
    ),
    ReadingPassage(
      id: 'p24',
      title: 'Bir Kitap Nasıl Yazılır',
      topic: 'kitaplar',
      content:
          'Bir kitap yazmak, önce bir fikir bulmakla başlar. Yazar, hikayesinin karakterlerini, olay örgüsünü ve mekanını dikkatlice planlar. İlk taslak tamamlandıktan sonra, yazar metni tekrar tekrar gözden geçirir ve düzeltmeler yapar. Bu düzenleme sürecine "editleme" denir ve bir kitabın okuyucuya ulaşmadan önce geçirdiği en önemli aşamalardan biridir.',
      questions: [
        {'question': 'Bir kitap yazmak bir fikir bulmakla başlar.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Yazarlar ilk taslağı yazdıktan sonra hiç değişiklik yapmadan kitabı yayınlar.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Metni gözden geçirip düzeltme sürecine editleme denir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Yazar, hikayesinin karakterlerini ve olay örgüsünü hiç planlamaz.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
      ],
    ),
    ReadingPassage(
      id: 'p25',
      title: 'E-Kitap mı Kağıt Kitap mı',
      topic: 'kitaplar',
      content:
          'Günümüzde kitaplar hem kağıt hem de elektronik (e-kitap) biçiminde okunabiliyor. E-kitaplar, bir tablet ya da telefonla yüzlerce kitabı yanınızda taşımanıza olanak tanır. Kağıt kitaplar ise sayfaları çevirme hissini ve göz yorgunluğunun daha az olmasını sağlar. Her iki biçimin de kendine göre avantajları vardır ve tercih genellikle okuyucunun alışkanlıklarına bağlıdır.',
      questions: [
        {'question': 'E-kitaplar bir cihazla yüzlerce kitabı taşımaya olanak tanır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Kağıt kitapların hiçbir avantajı yoktur.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Kitap biçimi tercihi genellikle okuyucunun alışkanlıklarına bağlıdır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Kağıt kitaplar göz yorgunluğunu artırır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
      ],
    ),
    ReadingPassage(
      id: 'p26',
      title: 'Algoritma Nedir',
      topic: 'kodlama',
      content:
          'Algoritma, bir problemi çözmek için izlenen adım adım talimatlar dizisidir. Günlük hayatta bile farkında olmadan algoritmalar kullanırız; örneğin bir sandviç yapmanın adımları da bir algoritmadır. Bilgisayar programcıları, bir algoritmayı kodlama diline çevirerek bilgisayarın belirli bir görevi yerine getirmesini sağlar. İyi bir algoritma, hem doğru sonucu verir hem de mümkün olduğunca hızlı çalışır.',
      questions: [
        {'question': 'Algoritma, bir problemi çözmek için izlenen adım adım talimatlardır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Algoritmalar sadece bilgisayarlarda kullanılır, günlük hayatta kullanılmaz.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'İyi bir algoritma doğru sonucu vermeli ve hızlı çalışmalıdır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Algoritmalar günlük hayatta hiç kullanılmaz.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
      ],
    ),
    ReadingPassage(
      id: 'p27',
      title: 'Robotlar ve Kodlama',
      topic: 'kodlama',
      content:
          'Bir robotun hareket edebilmesi, aslında arkasındaki koda bağlıdır. Programcılar, robota ne zaman döneceğini, ne zaman duracağını ve engellerden nasıl kaçınacağını kod satırlarıyla öğretir. Sensörler sayesinde robot çevresini algılar ve bu bilgiyi kodun belirlediği kurallara göre işler. Kodlama sayesinde bir robot, fabrikalarda parça taşımaktan evde toz almaya kadar birçok işi yapabilir.',
      questions: [
        {'question': 'Bir robotun hareketleri arkasındaki koda bağlıdır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Robotlar çevrelerini hiçbir sensör kullanmadan algılar.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Kodlama sayesinde robotlar farklı birçok işi yapabilir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Programcılar robota nasıl duracağını hiç öğretmez.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
      ],
    ),
    ReadingPassage(
      id: 'p28',
      title: 'Oyun Programlama',
      topic: 'kodlama',
      content:
          'Video oyunları, arkasında yüzlerce satır kodla çalışan karmaşık programlardır. Bir oyun programcısı, karakterlerin nasıl hareket edeceğini, puanların nasıl hesaplanacağını ve oyunun kurallarını kodla belirler. Grafik tasarımcılar görsel dünyayı oluştururken, programcılar bu dünyayı hayata geçiren "motoru" yazar. Basit bir oyun bile, saatlerce planlama ve kodlama gerektirir.',
      questions: [
        {'question': 'Video oyunları yüzlerce satır kodla çalışan programlardır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Bir oyunu kodlamak hiç zaman almaz, anında tamamlanır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Programcılar oyunun kurallarını ve karakter hareketlerini kodla belirler.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Grafik tasarımcılar oyunun kod motorunu yazar.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
      ],
    ),
    ReadingPassage(
      id: 'p29',
      title: 'Heykel Sanatı',
      topic: 'sanat',
      content:
          'Heykel, taş, tunç, ahşap ya da kil gibi malzemelerden üç boyutlu eserler yaratma sanatıdır. Heykeltıraşlar, düz bir resimden farklı olarak eserlerini her açıdan izlenebilecek şekilde şekillendirir. Tarihteki en ünlü heykellerden biri, Michelangelo\'nun yaptığı Davut Heykeli\'dir. Heykel yapmak, hem sabır hem de malzemenin doğasını iyi anlamayı gerektiren zorlu bir zanaattir.',
      questions: [
        {'question': 'Heykel üç boyutlu eserler yaratma sanatıdır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Heykeller sadece tek bir açıdan izlenebilir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Davut Heykeli Michelangelo tarafından yapılmıştır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Heykel yapmak hiçbir sabır gerektirmez.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
      ],
    ),
    ReadingPassage(
      id: 'p30',
      title: 'Müziğin Gücü',
      topic: 'sanat',
      content:
          'Müzik, sesleri belirli bir düzen içinde bir araya getirerek duygu ve düşünceleri anlatan evrensel bir sanattır. Farklı kültürlerin kendine özgü müzik aletleri ve tarzları vardır, ama müziğin duyguları harekete geçirme gücü her yerde aynıdır. Bilim insanları, müzik dinlemenin stresi azaltabileceğini ve odaklanmayı artırabileceğini keşfetmiştir. Bir beste yazmak, notaları doğru sırayla bir araya getirmekten çok daha fazlasını, yani duygu aktarmayı gerektirir.',
      questions: [
        {'question': 'Müzik, sesleri belirli bir düzen içinde bir araya getiren bir sanattır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Müziğin duyguları harekete geçirme gücü sadece bazı kültürlerde geçerlidir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Müzik dinlemenin stresi azaltabileceği keşfedilmiştir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Bir beste yazmak sadece notaları sıraya koymaktır, duygu gerekmez.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
      ],
    ),
    ReadingPassage(
      id: 'p31',
      title: 'Tiyatronun Doğuşu',
      topic: 'sanat',
      content:
          'Tiyatro, insanların bir hikayeyi canlı olarak sahnede canlandırdığı en eski sanat türlerinden biridir. Antik Yunan\'da tiyatro, hem eğlence hem de toplumsal konuları tartışma amacı taşıyordu. Oyuncular, maskeler takarak farklı karakterleri ve duyguları seyirciye aktarırdı. Günümüzde tiyatro, sinema ve dizilerin yanında hâlâ canlı performansın eşsiz heyecanını sunmaya devam ediyor.',
      questions: [
        {'question': 'Tiyatro insanların bir hikayeyi canlı olarak sahnede canlandırmasıdır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Antik Yunan\'da tiyatronun toplumsal konularla hiçbir ilgisi yoktu.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Antik Yunan\'da oyuncular maskeler takarak karakterleri canlandırırdı.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Tiyatro yirminci yüzyılda ortaya çıkmış yeni bir sanattır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
      ],
    ),
    ReadingPassage(
      id: 'p32',
      title: 'Olimpiyat Oyunlarının Tarihi',
      topic: 'spor',
      content:
          'Olimpiyat Oyunları, ilk olarak Antik Yunanistan\'da, Olympia şehrinde binlerce yıl önce düzenlenmeye başlamıştır. O dönemde oyunlar sırasında şehirler arasındaki savaşlar bile geçici olarak durdurulurdu. Modern Olimpiyatlar ise 1896 yılında Atina\'da yeniden başlatılmıştır. Bugün dünyanın dört bir yanından binlerce sporcu, dört yılda bir bu büyük yarışmada bir araya gelmektedir.',
      questions: [
        {'question': 'Olimpiyat Oyunları ilk olarak Antik Yunanistan\'da başlamıştır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Modern Olimpiyatlar ilk kez Paris\'te düzenlenmiştir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Olimpiyat Oyunları her yıl düzenlenir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Dört yılda bir dünyanın dört bir yanından sporcular bir araya gelir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
      ],
    ),
    ReadingPassage(
      id: 'p33',
      title: 'Yüzmenin Faydaları',
      topic: 'spor',
      content:
          'Yüzme, vücuttaki hemen hemen tüm kasları aynı anda çalıştıran ender sporlardan biridir. Su içinde hareket etmek, eklemlere kara sporlarına göre çok daha az yük bindirir. Düzenli yüzmek, kalp ve akciğer sağlığını güçlendirir ve dayanıklılığı artırır. Ayrıca suyun serinletici etkisi, yüzmeyi hem eğlenceli hem de rahatlatıcı bir aktivite haline getirir.',
      questions: [
        {'question': 'Yüzme vücuttaki hemen hemen tüm kasları çalıştırır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Su içinde hareket etmek eklemlere kara sporlarından daha fazla yük bindirir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Düzenli yüzmek kalp ve akciğer sağlığını güçlendirir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Yüzme kalp ve akciğer sağlığına hiçbir katkı sağlamaz.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
      ],
    ),
    ReadingPassage(
      id: 'p34',
      title: 'Satranç Bir Spor mu',
      topic: 'spor',
      content:
          'Satranç, fiziksel güç gerektirmese de büyük bir zihinsel yoğunluk ve strateji becerisi ister. Uluslararası Olimpiyat Komitesi, satrancı "zihin sporu" olarak tanımaktadır. Profesyonel satranç oyuncuları, uzun bir maç sırasında yüzlerce kalori harcayabilir çünkü yoğun konsantrasyon beyni oldukça yorar. Satranç, sabırlı planlama ve rakibin hamlelerini önceden tahmin etme becerisini geliştirir.',
      questions: [
        {'question': 'Satranç Uluslararası Olimpiyat Komitesi tarafından "zihin sporu" olarak tanınır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Satranç oynamak beyni hiç yormaz.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Satranç, rakibin hamlelerini önceden tahmin etme becerisini geliştirir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Profesyonel satranç oyuncuları maç sırasında hiç kalori harcamaz.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
      ],
    ),
    ReadingPassage(
      id: 'p35',
      title: 'Japonya\'nın Gelenekleri',
      topic: 'ulkeler',
      content:
          'Japonya, modern teknolojisiyle tanınsa da köklü geleneklerini de büyük bir özenle korumaktadır. Çay seremonisi, sadece çay içmekten öte, sakinlik ve saygıyı simgeleyen özel bir törendir. Kiraz çiçeklerinin (sakura) açtığı bahar mevsiminde, aileler parklarda "hanami" adı verilen çiçek izleme etkinlikleri düzenler. Japon kültüründe nezaket ve düzen, günlük yaşamın her alanında önemli bir yer tutar.',
      questions: [
        {'question': 'Japonya\'da çay seremonisi sakinlik ve saygıyı simgeler.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Japonya geleneklerini tamamen terk etmiş, sadece teknolojiye odaklanmıştır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Hanami, kiraz çiçeklerini izleme etkinliğidir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Hanami, kış mevsiminde yapılan bir kar festivalidir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
      ],
    ),
    ReadingPassage(
      id: 'p36',
      title: 'Mısır Piramitleri',
      topic: 'ulkeler',
      content:
          'Mısır piramitleri, binlerce yıl önce firavunlar için mezar olarak inşa edilmiş devasa yapılardır. En büyük ve en ünlü piramit, Giza\'daki Büyük Piramit\'tir ve yüzyıllarca dünyanın en yüksek yapısı olma özelliğini korumuştur. Piramitlerin nasıl inşa edildiği hâlâ bilim insanlarını şaşırtan bir konudur, çünkü o dönemde modern makineler yoktu. Bu yapılar, Antik Mısır uygarlığının mühendislik becerisinin canlı bir kanıtıdır.',
      questions: [
        {'question': 'Mısır piramitleri firavunlar için mezar olarak inşa edilmiştir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Giza\'daki Büyük Piramit dünyanın en küçük yapısıdır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Piramitler modern makineler kullanılarak inşa edilmiştir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Piramitlerin nasıl inşa edildiği hâlâ bilim insanlarını şaşırtmaktadır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
      ],
    ),
    ReadingPassage(
      id: 'p37',
      title: 'Antarktika Kıtası',
      topic: 'ulkeler',
      content:
          'Antarktika, Dünya\'nın en güneyinde yer alan ve neredeyse tamamı kalın buzla kaplı bir kıtadır. Burada herhangi bir ülkenin daimi vatandaşı yaşamaz, sadece bilim insanları araştırma istasyonlarında geçici olarak kalır. Kıtadaki sıcaklıklar bazen eksi 80 dereceye kadar düşebilir, bu da onu Dünya\'nın en soğuk yeri yapar. Antarktika\'daki buzullar, Dünya\'nın tatlı su rezervlerinin büyük bir kısmını barındırır.',
      questions: [
        {'question': 'Antarktika\'nın neredeyse tamamı kalın buzla kaplıdır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Antarktika\'da milyonlarca daimi vatandaş yaşar.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Antarktika, Dünya\'nın en soğuk yerlerinden biridir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Antarktika Dünya\'nın en sıcak yeridir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
      ],
    ),
    ReadingPassage(
      id: 'p38',
      title: 'Ay\'a Yolculuk',
      topic: 'uzay',
      content:
          'İnsanoğlu ilk kez 1969 yılında Ay\'a ayak basmıştır; bu tarihi adımı atan kişi astronot Neil Armstrong\'dur. Ay\'a gitmek için özel olarak tasarlanmış roketler, dünyanın yerçekiminden kurtulacak kadar güçlü olmalıdır. Ay\'da atmosfer olmadığı için gökyüzü her zaman siyah görünür ve sessizlik tamdır. Bilim insanları, Ay\'dan getirilen kayaları inceleyerek Güneş Sistemi\'nin oluşumu hakkında önemli bilgiler edinmiştir.',
      questions: [
        {'question': 'İnsanoğlu ilk kez 1969 yılında Ay\'a ayak basmıştır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Ay\'da yoğun bir atmosfer bulunur.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Ay\'dan getirilen kayalar Güneş Sistemi hakkında bilgi vermiştir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Ay\'a ilk ayak basan kişi bir Rus kozmonottur.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
      ],
    ),
    ReadingPassage(
      id: 'p39',
      title: 'Yıldızlar Nasıl Doğar',
      topic: 'uzay',
      content:
          'Yıldızlar, uzaydaki dev gaz ve toz bulutlarının kendi yerçekimiyle çökmesi sonucu oluşur. Bu bulutun merkezi giderek ısınır ve sonunda nükleer füzyon adı verilen bir süreç başlar, bu da yıldızın parlamasını sağlar. Güneşimiz de yaklaşık 4.6 milyar yıl önce böyle bir bulutun içinden doğmuştur. Bir yıldızın ömrü, boyutuna bağlı olarak milyonlarca ya da milyarlarca yıl sürebilir.',
      questions: [
        {'question': 'Yıldızlar dev gaz ve toz bulutlarının çökmesiyle oluşur.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Güneşimiz hiçbir bulut olmadan aniden ortaya çıkmıştır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Bir yıldızın ömrü boyutuna bağlı olarak değişebilir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Bütün yıldızların ömrü birbirinin tamamen aynısıdır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
      ],
    ),
    ReadingPassage(
      id: 'p40',
      title: 'Uzay İstasyonunda Yaşam',
      topic: 'uzay',
      content:
          'Uluslararası Uzay İstasyonu, Dünya\'nın yörüngesinde dönen ve içinde astronotların aylarca yaşayıp çalışabildiği devasa bir yapıdır. Yerçekimi neredeyse hiç olmadığı için astronotlar istasyon içinde havada süzülerek hareket eder. Yemek yemek bile burada farklıdır; sıvılar damlalar halinde havada uçuşabileceği için özel kaplarda saklanır. Astronotlar, kaslarının erimemesi için istasyonda her gün özel egzersizler yapmak zorundadır.',
      questions: [
        {'question': 'Uluslararası Uzay İstasyonu\'nda astronotlar havada süzülerek hareket eder.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Uzay istasyonunda yerçekimi Dünya\'dakiyle tamamen aynıdır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Astronotlar kaslarının erimemesi için her gün egzersiz yapar.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Uzay istasyonunda yemekler tabaklarda normal şekilde servis edilir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
      ],
    ),
    ReadingPassage(
      id: 'p41',
      title: 'Ekmeğin Tarihi',
      topic: 'yemek',
      content:
          'Ekmek, insanlık tarihinin en eski ve en temel besinlerinden biridir; binlerce yıl önce eski Mısırlılar tarafından mayalanarak yapılmaya başlanmıştır. Un, su ve mayanın bir araya gelmesiyle oluşan hamur, fırınlanarak bugün bildiğimiz ekmeğe dönüşür. Dünyanın farklı bölgelerinde farklı ekmek çeşitleri gelişmiştir; örneğin Fransa\'da baget, Hindistan\'da naan öne çıkar. Ekmek, günümüzde de dünyanın hemen her sofrasında yer alan vazgeçilmez bir besindir.',
      questions: [
        {'question': 'Ekmek eski Mısırlılar tarafından mayalanarak yapılmaya başlanmıştır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Dünyanın her yerinde sadece tek bir çeşit ekmek yapılır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Baget, Fransa\'da öne çıkan bir ekmek çeşididir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Ekmek hamuru fırınlanmadan doğrudan yenir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
      ],
    ),
    ReadingPassage(
      id: 'p42',
      title: 'Dünya Mutfaklarından Lezzetler',
      topic: 'yemek',
      content:
          'Her ülkenin mutfağı, o toplumun kültürünü, iklimini ve tarihini yansıtır. İtalya\'da makarna ve pizza öne çıkarken, Japonya\'da suşi ve ramen çok sevilen yemeklerdendir. Baharatlar, yemeklere hem lezzet hem de renk katar; örneğin Hindistan mutfağında köri baharatı sıkça kullanılır. Farklı mutfakları tatmak, bir ülkeyi ziyaret etmeden de o kültürü tanımanın keyifli bir yoludur.',
      questions: [
        {'question': 'Her ülkenin mutfağı o toplumun kültürünü yansıtır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Suşi, İtalyan mutfağının bir parçasıdır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Baharatlar yemeklere lezzet ve renk katar.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Köri baharatı Japon mutfağında sıkça kullanılır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
      ],
    ),
    ReadingPassage(
      id: 'p43',
      title: 'Meyvelerin Faydaları',
      topic: 'yemek',
      content:
          'Meyveler, vücudumuzun ihtiyaç duyduğu vitamin ve lifleri doğal yoldan almamızı sağlayan besinlerdir. Portakal ve çilek gibi meyveler C vitamini bakımından zengindir ve bağışıklık sistemimizi güçlendirir. Meyvelerdeki lifler, sindirim sistemimizin düzenli çalışmasına yardımcı olur. Günde birkaç porsiyon meyve tüketmek, sağlıklı bir yaşamın basit ama etkili yollarından biridir.',
      questions: [
        {'question': 'Portakal ve çilek C vitamini bakımından zengindir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Meyvelerdeki lifler sindirim sistemine hiçbir katkı sağlamaz.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Günde birkaç porsiyon meyve tüketmek sağlıklı bir alışkanlıktır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Meyveler vücudumuza hiçbir vitamin sağlamaz.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
      ],
    ),
    ReadingPassage(
      id: 'p44',
      title: 'Mevsimlerin Değişimi',
      topic: 'doga',
      content:
          'Dünya\'nın kendi ekseni etrafında eğik durması, mevsimlerin oluşmasının temel nedenidir. Bu eğiklik sayesinde, Dünya Güneş çevresinde dönerken farklı bölgeler farklı zamanlarda daha fazla ya da daha az güneş ışığı alır. İlkbaharda doğa canlanır, yazın sıcaklıklar artar, sonbaharda yapraklar dökülür ve kışın hava soğur. Mevsimler, birçok hayvanın göç etme ya da kış uykusuna yatma zamanını da belirler.',
      questions: [
        {'question': 'Mevsimlerin oluşmasının temel nedeni Dünya\'nın ekseninin eğik olmasıdır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Bütün bölgeler Güneş\'ten her zaman aynı miktarda ışık alır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Mevsimler bazı hayvanların göç etme zamanını belirler.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Mevsimler hayvanların davranışlarını hiç etkilemez.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
      ],
    ),
    ReadingPassage(
      id: 'p45',
      title: 'Su Döngüsü',
      topic: 'doga',
      content:
          'Su döngüsü, suyun Dünya üzerinde sürekli olarak buharlaşıp yağış hâlinde geri dönmesini sağlayan doğal bir sistemdir. Güneşin ısısıyla denizlerdeki ve göllerdeki su buharlaşarak gökyüzüne yükselir ve bulutları oluşturur. Bulutlar soğuduğunda, içindeki su damlacıkları yağmur ya da kar olarak yeryüzüne düşer. Bu döngü sayesinde Dünya\'daki su miktarı hiç azalmadan sürekli yeniden kullanılır.',
      questions: [
        {'question': 'Su döngüsünde su buharlaşıp yağış hâlinde geri döner.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Bulutlar suyun hiçbir aşamasında rol oynamaz.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Su döngüsü sayesinde Dünya\'daki su sürekli yeniden kullanılır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Su döngüsünde Dünya\'daki su miktarı giderek azalır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
      ],
    ),
    ReadingPassage(
      id: 'p46',
      title: 'İnternetin Doğuşu',
      topic: 'teknoloji',
      content:
          'İnternet, başlangıçta 1960\'larda bilgisayarların birbirleriyle bilgi paylaşabilmesi için askeri ve akademik amaçlarla geliştirilmiştir. Zamanla bu ağ genişleyerek dünyanın dört bir yanındaki milyonlarca bilgisayarı birbirine bağlayan devasa bir sisteme dönüşmüştür. World Wide Web\'in 1990\'larda icat edilmesiyle internet, sıradan insanların da kolayca kullanabileceği bir araç haline geldi. Bugün internet, bilgiye ulaşmaktan iletişim kurmaya kadar hayatımızın her alanında yer almaktadır.',
      questions: [
        {'question': 'İnternet başlangıçta askeri ve akademik amaçlarla geliştirilmiştir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'World Wide Web 1800\'lerde icat edilmiştir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'İnternet günümüzde hayatımızın her alanında yer almaktadır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'İnternet en başından beri herkesin kolayca kullanabileceği bir araç olmuştur.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
      ],
    ),
    ReadingPassage(
      id: 'p47',
      title: 'Akıllı Telefonların Gelişimi',
      topic: 'teknoloji',
      content:
          'İlk cep telefonları sadece arama yapmak için kullanılırken, günümüzün akıllı telefonları birer mini bilgisayar haline gelmiştir. Kamera, internet tarayıcısı, harita ve binlerce uygulama artık cebimizdeki bu tek cihazda toplanmış durumda. Dokunmatik ekran teknolojisi, telefonların kullanımını çok daha kolay ve sezgisel hale getirmiştir. Akıllı telefonlar sayesinde insanlar artık dünyanın her yerinden anında bilgiye ulaşabilmektedir.',
      questions: [
        {'question': 'İlk cep telefonları sadece arama yapmak için kullanılırdı.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Akıllı telefonlarda dokunmatik ekran teknolojisi kullanılmaz.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Akıllı telefonlar sayesinde insanlar anında bilgiye ulaşabilir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'İlk cep telefonları kamera ve internet tarayıcısıyla gelirdi.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
      ],
    ),
    ReadingPassage(
      id: 'p48',
      title: 'Mimar Sinan: Ustaların Ustası',
      topic: 'biyografi',
      content:
          'Mimar Sinan, 16. yüzyılda yaşamış, Osmanlı Devleti\'nin en usta mimarlarından biridir. Süleymaniye Camii ve Selimiye Camii gibi birçok görkemli yapıyı tasarlayarak mimarlık tarihine adını altın harflerle yazdırmıştır. Sinan, yapılarında hem estetiği hem de depreme dayanıklılığı bir araya getirmeyi başarmış, bu yüzden eserlerinin çoğu günümüze kadar sapasağlam ulaşmıştır. Kendisi "ustalık eserim" olarak nitelendirdiği Selimiye Camii\'ni Edirne\'de inşa etmiştir.',
      questions: [
        {'question': 'Mimar Sinan, Süleymaniye Camii\'ni tasarlamıştır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Mimar Sinan\'ın eserlerinin hiçbiri günümüze ulaşmamıştır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
        {'question': 'Sinan, Selimiye Camii\'ni kendi "ustalık eserim" olarak nitelendirmiştir.', 'answers': ['Doğru', 'Yanlış'], 'correct': 0},
        {'question': 'Mimar Sinan hiçbir camiyi tasarlamamıştır.', 'answers': ['Doğru', 'Yanlış'], 'correct': 1},
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

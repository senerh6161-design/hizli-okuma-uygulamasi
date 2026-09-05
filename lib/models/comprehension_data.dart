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
  final String?
  level; // ReadingLevel.id ile eşleşir — null: seviyeye özel değil
  final bool isFinalTest; // true: Son Metin'in seviye havuzuna ait

  const ReadingPassage({
    required this.id,
    required this.title,
    required this.topic,
    required this.content,
    required this.questions,
    this.level,
    this.isFinalTest = false,
  });
}

// Seviyeye göre okuma metni seçimi için — konu seçiminden ayrı, ayrı bir
// giriş noktası. Şimdilik sadece "Kitaba Hürmet" metninin üç seviye
// uyarlaması var.
class ReadingLevel {
  final String id;
  final String title;
  final String emoji;

  const ReadingLevel({
    required this.id,
    required this.title,
    required this.emoji,
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

  static const List<ReadingLevel> levels = [
    ReadingLevel(id: 'ilkokul', title: 'İlkokul', emoji: '🎒'),
    ReadingLevel(id: 'ortaokul', title: 'Ortaokul', emoji: '📘'),
    ReadingLevel(id: 'lise', title: 'Lise', emoji: '🎓'),
  ];

  static ReadingPassage? passageForLevel(
    String levelId, {
    bool isFinalTest = false,
  }) {
    for (final p in passages) {
      if (p.level == levelId && p.isFinalTest == isFinalTest) return p;
    }
    return null;
  }

  static const List<ReadingPassage> passages = [
    ReadingPassage(
      id: 'p1',
      title: 'Hızlı Okuma ve Beyin Kasları',
      topic: 'bilim',
      content:
          'Hızlı okuma, yalnızca gözlerin metin üzerinde hızla kayması değil, beynin görsel verileri işleme kapasitesini artırma sürecidir. İnsan gözü bir kelimeye odaklandığında sıçrama ve duraklama hareketleri yapar. Doğru egzersizlerle bu duraklama süreleri azaltılabilir ve gözün tek bir bakışta algıladığı kelime sayısı artırılabilir.\n\n'
          'Birçok insan okurken kelimeleri zihninde sessizce seslendirir; buna iç seslendirme denir. İç seslendirmeyi azaltmak, okuma hızını artırmanın en etkili yollarından biridir çünkü göz, sesin çıkma hızından çok daha hızlı bilgi işleyebilir. Gözün yan görüş alanını genişletmeyi öğrenen bir okuyucu, bir bakışta tek kelime yerine birkaç kelimeyi birden algılayabilir.\n\n'
          'Hızlı okuma, tıpkı bir kas gibi düzenli çalışmayla gelişir. İlk başta yavaş ve zor gelen egzersizler, haftalar içinde doğal bir alışkanlığa dönüşür. Önemli olan sabırlı olmak ve pes etmeden pratik yapmaya devam etmektir. Bu sayede hem daha kısa sürede daha çok bilgiye ulaşılır hem de anlama becerisi zamanla güçlenir.',
      questions: [
        {
          'question':
              'Hızlı okuma, beynin görsel verileri işleme kapasitesini artırma sürecidir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'İnsan gözü okurken sadece dairesel hareketler yapar.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'Doğru egzersizlerle gözün tek bir bakışta algıladığı kelime sayısı artırılabilir.',
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
          'Yapay zekâ teknolojileri, günümüzde veri analizi ve kalıp tanıma yetenekleriyle insan hayatını kolaylaştırmaktadır. Özellikle mühendislik ve tıp alanında karmaşık problemleri saniyeler içinde çözebilmektedir. Ancak yapay zekânın başarısı, eğitildiği verilerin kalitesine ve doğruluğuna doğrudan bağlıdır.\n\n'
          'Yapay zekâ sistemleri, insanlar gibi doğrudan öğretilmez; bunun yerine binlerce, hatta milyonlarca örnek üzerinden kendi kalıplarını bulmayı öğrenir. Buna "makine öğrenmesi" denir. Bir yapay zekâ, çok sayıda kedi fotoğrafını inceleyerek bir kediyi tanımayı öğrenebilir, tıpkı bir çocuğun tekrar tekrar gördüğü bir hayvanı tanımayı öğrenmesi gibi.\n\n'
          'Günlük hayatta yapay zekâyı fark etmeden sık sık kullanırız: telefonumuzun sesli asistanı, film önerileri sunan uygulamalar ya da bir dili başka bir dile çeviren programlar hep bu teknolojiye dayanır. Yine de yapay zekâ, insan gibi vicdan ya da sağduyuya sahip değildir; bu yüzden önemli kararlarda mutlaka bir insanın kontrolünde çalışması gerekir.',
      questions: [
        {
          'question':
              'Yapay zekânın başarısı, eğitildiği verilerin kalitesine bağlıdır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Yapay zekâ sadece moda ve mimari alanlarında kullanılır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'Yapay zekâ, veri analizi ve kalıp tanıma yetenekleriyle öne çıkar.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Yapay zekânın başarısı kullanılan verilerden bağımsızdır.',
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
          'Arılar, ekosistemin sürdürülebilirliği için kritik bir role sahiptir. Çiçekler arasında polen taşıyarak bitkilerin tozlaşmasını sağlarlar. Dünya üzerindeki tarımsal ürünlerin büyük bir kısmı arıların bu polenleme faaliyetine bağımlıdır. Arı nüfusunun azalması, küresel gıda güvenliği için ciddi bir tehdittir.\n\n'
          'Bir arı kovanı, mükemmel bir düzen içinde çalışan küçük bir toplumdur. Kovanın merkezinde yumurtlamakla görevli bir kraliçe arı bulunur, işçi arılar ise hem yavruların bakımını üstlenir hem de dışarı çıkıp yiyecek toplar. İşçi arılar, bulduğu çiçek tarlasının yönünü arkadaşlarına özel bir dansla, "sallantı dansı" ile anlatır.\n\n'
          'Arılar aynı zamanda bal üretir; topladıkları çiçek özsuyunu (nektarı) kovanda işleyerek kışın besin olarak saklarlar. Ne yazık ki tarımda kullanılan bazı zararlı ilaçlar ve iklim değişikliği arı nüfusunu tehdit etmektedir. Bahçelere çiçekli bitkiler dikmek ve arılara zarar veren kimyasallardan kaçınmak, bu küçük ama vazgeçilmez canlıları korumaya yardımcı olabilir.',
      questions: [
        {
          'question':
              'Arılar, çiçekler arasında polen taşıyarak tozlaşmayı sağlar.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Arı nüfusunun azalmasının küresel gıda güvenliğiyle hiçbir ilgisi yoktur.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'Tarımsal ürünlerin büyük bir kısmı arıların polenleme faaliyetine bağımlıdır.',
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
          'Güneş Sistemi, merkezinde Güneş olan ve onun çevresinde dönen sekiz gezegenden oluşur. Dünya, Güneş\'e olan mesafesi sayesinde yaşama uygun sıcaklığa sahiptir. Jüpiter, sistemin en büyük gezegeni olup güçlü fırtınalarıyla bilinir. Bilim insanları, uzay teleskopları sayesinde Güneş Sistemi dışındaki gezegenleri de keşfetmeye devam ediyor.\n\n'
          'Güneş\'e yakın dört gezegen (Merkür, Venüs, Dünya ve Mars) sert kayalık yüzeylere sahiptir; bunlara "kayaç gezegenler" denir. Daha uzaktaki Jüpiter, Satürn, Uranüs ve Neptün ise büyük ölçüde gazdan oluşan devasa gezegenlerdir. Mars ile Jüpiter arasında, milyonlarca küçük kaya parçasından oluşan asteroit kuşağı yer alır.\n\n'
          'Bir zamanlar dokuzuncu gezegen sayılan Plüton, 2006 yılında bilim insanları tarafından "cüce gezegen" olarak yeniden sınıflandırılmıştır. Güneş Sistemi\'ndeki birçok gezegenin kendi ayları vardır; örneğin Satürn\'ün çevresinde yüzden fazla ay dönmektedir. Uzay araçları sayesinde bu gezegenlerin yakın fotoğrafları çekilmiş ve Güneş Sistemi hakkındaki bilgimiz her geçen yıl artmaktadır.',
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
          'question':
              'Dünya, Güneş\'e olan mesafesi sayesinde yaşama uygun sıcaklığa sahiptir.',
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
          'Spor yalnızca fiziksel güç kazandırmaz, aynı zamanda paylaşmayı ve dayanışmayı da öğretir. Bir basketbol takımında her oyuncu farklı bir görev üstlenir; kimi pas verir, kimi savunma yapar, kimi de sayı atar. Takım arkadaşlarına güvenmeyi öğrenen bir sporcu, sahada olduğu kadar günlük hayatta da başarılı iletişim kurar.\n\n'
          'Futboldan voleybola, hentboldan su topuna kadar birçok takım sporunda başarı, bireysel yeteneklerden çok oyuncuların birbiriyle uyum içinde çalışmasına bağlıdır. İyi bir takım oyuncusu, hata yapan arkadaşını suçlamak yerine ona destek olur ve birlikte çözüm arar. Kaptanlar ise takımı motive ederek zor anlarda moral kaynağı olur.\n\n'
          'Her takım zaman zaman kaybeder; önemli olan yenilgiyi olgunlukla karşılayıp ondan ders çıkarmaktır. Düzenli antrenman, disiplin ve sabır, hem bireysel gelişimin hem de takım başarısının temel taşlarıdır. Sahada öğrenilen bu değerler, okulda grup çalışmalarında ya da arkadaşlıklarda da işe yarar.',
      questions: [
        {
          'question': 'Spor, paylaşmayı ve dayanışmayı da öğretir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Basketbol takımında bütün oyuncular aynı görevi üstlenir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'Takım arkadaşına güvenmeyi öğrenen sporcu, günlük hayatta da başarılı iletişim kurar.',
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
          'Resim yapmak, düşüncelerimizi kelimeler olmadan anlatmanın en özgür yollarından biridir. Bir ressam, fırçasıyla hem gördüklerini hem de hayal ettiklerini tuvale aktarabilir. Renkler bize duygular hakkında ipucu verir: sıcak tonlar coşkuyu, soğuk tonlar ise huzuru çağrıştırabilir. Sanat tarihinde her dönem, kendi zamanının izlerini taşıyan yeni akımlar doğurmuştur.\n\n'
          'Ressamlar farklı teknikler ve malzemeler kullanır: suluboya hafif ve şeffaf bir görünüm verirken, yağlıboya daha yoğun ve kalıcı renkler sunar. On dokuzuncu yüzyılda ortaya çıkan izlenimcilik (empresyonizm) akımı, ışığın anlık etkisini yakalamayı amaçlayarak sanat dünyasında büyük bir değişim yaratmıştır.\n\n'
          'Resim yapmak, tıpkı bir müzik aleti çalmak gibi pratikle gelişen bir beceridir; ilk çizilen basit şekiller zamanla ustalaşarak karmaşık eserlere dönüşebilir. Bir resme bakan iki farklı kişi ondan tamamen farklı duygular hissedebilir, bu da sanatı gerçekten evrensel ve kişisel bir deneyim haline getirir.',
      questions: [
        {
          'question':
              'Resim yapmak, düşünceleri kelimeler olmadan anlatmanın en özgür yollarından biridir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Sıcak renk tonları huzuru çağrıştırır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'Sanat tarihinde her dönem, kendi zamanının izlerini taşıyan akımlar doğurmuştur.',
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
          'Yunuslar, denizlerin en zeki canlılarından sayılır. Birbirleriyle özel ıslık sesleriyle iletişim kurar, hatta her yunusun kendine özgü bir "imza ıslığı" olduğu bilinir. Sürü hâlinde avlanırken birbirlerine yardım ederler ve yaralı bir yunusu yüzeye çıkarıp nefes almasına yardımcı olabilirler. Bu davranışlar, yunusların güçlü bir sosyal zekâya sahip olduğunu gösterir.\n\n'
          'Yunuslar, karanlık ya da bulanık sularda yön bulmak için "ekolokasyon" adı verilen özel bir yöntem kullanır: çıkardıkları sesler nesnelere çarpıp yankı olarak geri döner ve bu sayede önlerindeki cismin şeklini, büyüklüğünü ve uzaklığını "görmeden" anlayabilirler. Bilim insanları, yunusların aynadaki yansımalarını tanıyabildiğini de keşfetmiştir; bu, sınırlı sayıda hayvanda görülen ileri bir öz farkındalık belirtisidir.\n\n'
          'Yunuslar oyun oynamayı da çok sever; dalgaların üzerinde sörf yapar, birbirleriyle yüzme yarışları düzenler. Ne yazık ki denizlerdeki plastik kirliliği ve ağlara takılma tehlikesi yunusların hayatını zorlaştırmaktadır. Denizleri temiz tutmak, bu zeki canlıların güvenle yaşamasına destek olur.',
      questions: [
        {
          'question':
              'Yunuslar birbirleriyle özel ıslık sesleriyle iletişim kurar.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Her yunusun "imza ıslığı" birbirinin aynısıdır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'Yaralı bir yunusu sürüsü yüzeye çıkarıp nefes almasına yardım eder.',
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
          'Yağmur ormanları, Dünya\'daki bitki ve hayvan türlerinin yarısından fazlasına ev sahipliği yapar. Bu ormanlar aynı zamanda "Dünya\'nın akciğerleri" olarak da anılır, çünkü ürettikleri oksijen tüm gezegene yayılır. Ne yazık ki tarım ve inşaat için yapılan ağaç kesimleri, bu değerli ekosistemleri her geçen yıl küçültüyor. Ormanları korumak, geleceğimizi korumak anlamına gelir.\n\n'
          'En büyük yağmur ormanı olan Amazon Ormanları, Güney Amerika\'da dokuz ülkeye yayılır ve içinde henüz keşfedilmemiş binlerce canlı türü barındırdığı düşünülmektedir. Bu ormanlar birkaç kata ayrılır: en üstteki "tepe katmanı" güneş ışığını ilk alan bölgedir, altındaki daha karanlık katmanlarda ise farklı bitki ve hayvanlar yaşar.\n\n'
          'Birçok modern ilaç, yağmur ormanlarındaki bitkilerden elde edilen maddelerden geliştirilmiştir; bu yüzden ormanların yok olması bilim için de büyük bir kayıptır. Günümüzde birçok ülke ve kuruluş, ağaçlandırma çalışmaları ve koruma alanları oluşturarak bu değerli ekosistemleri gelecek nesillere aktarmaya çalışmaktadır.',
      questions: [
        {
          'question':
              'Yağmur ormanları "Dünya\'nın akciğerleri" olarak anılır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Yağmur ormanları hiçbir tehditle karşı karşıya değildir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'Yağmur ormanları, Dünya\'daki bitki ve hayvan türlerinin yarısından fazlasına ev sahipliği yapar.',
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
          'Robotlar artık yalnızca fabrikalarda değil, evlerimizde, hastanelerde ve hatta uzayda da görev yapıyor. Temizlik robotları evi süpürürken, cerrahi robotlar doktorlara hassas ameliyatlarda yardımcı oluyor. Mars\'ta gezen keşif robotları ise insan ayak basmadan önce gezegen hakkında bilgi topluyor. Robotların en büyük avantajı, tehlikeli ya da tekrar eden işleri yorulmadan yapabilmeleridir.\n\n'
          'Bir robotun çevresini "algılayabilmesi" için üzerinde kameralar, ışık sensörleri ya da dokunma sensörleri bulunur; topladığı bu bilgiler, önceden yazılmış kodlara göre işlenir ve robot buna uygun hareket eder. Deprem sonrası enkaz altında arama yapan ya da yanardağların içine inen özel robotlar, insanların gidemeyeceği tehlikeli yerlerde hayat kurtarabilir.\n\n'
          'Robotlar birçok işi kolaylaştırsa da, yaratıcılık, empati ve karar verme gerektiren birçok görev hâlâ insanlara ihtiyaç duyar. Bir öğretmenin, bir doktorun ya da bir sanatçının işini bütünüyle bir robotun yapması beklenmez; teknoloji ile insan becerisi genellikle birlikte, birbirini tamamlayarak çalışır.',
      questions: [
        {
          'question':
              'Cerrahi robotlar doktorlara hassas ameliyatlarda yardımcı olur.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Robotlar sadece fabrikalarda kullanılır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'Mars\'taki keşif robotları gezegen hakkında bilgi toplar.',
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
          'Kodlama, bilgisayara ne yapması gerektiğini adım adım anlatmaktır. Programcılar, "kod" adı verilen özel bir dille bilgisayara talimatlar yazar. Bir oyunun nasıl çalışacağını, bir uygulamanın nasıl görüneceğini bile kodlama sayesinde tasarlarız. En küçük bir hata bile, tıpkı bir tarifte yanlış malzeme kullanmak gibi, programın çalışmamasına neden olabilir. Bu yüzden kodlama hem yaratıcılık hem de sabır gerektirir.\n\n'
          'Dünyada yüzlerce farklı kodlama dili vardır; her biri farklı işler için daha uygun olabilir. Bir programı yazdıktan sonra, içindeki hataları bulup düzeltme sürecine "hata ayıklama" (debugging) denir ve tecrübeli programcılar bile sık sık bu süreçten geçer. Hata bulmak, aslında bir bulmacayı çözmek gibi eğlenceli bir uğraş olabilir.\n\n'
          'Çocuklar için geliştirilen Scratch gibi programlar, gerçek kod yazmadan önce renkli bloklarla sürükle-bırak yöntemiyle basit oyunlar ve hikayeler oluşturmayı öğretir. Küçük yaşta kodlamayla tanışmak, problem çözme becerisini ve mantıksal düşünmeyi geliştirir; bu beceriler sadece bilgisayarla değil, günlük hayattaki birçok durumla da işe yarar.',
      questions: [
        {
          'question':
              'Kodlama, bilgisayara adım adım ne yapması gerektiğini anlatmaktır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Kodlamada küçük bir hata programın çalışmasını asla etkilemez.',
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
          'Sağlıklı beslenmek, vücudumuzun ihtiyaç duyduğu farklı besinleri dengeli bir şekilde almaktır. Meyveler ve sebzeler vitamin deposu iken, tahıllar bize enerji verir. Fazla şekerli ve yağlı yiyecekler ise sadece ara sıra, ölçülü tüketilmelidir. Bol su içmek de sindirim sistemimizin düzgün çalışması için çok önemlidir.\n\n'
          'Et, yumurta, süt ürünleri ve baklagiller gibi besinlerde bulunan protein, kaslarımızın ve hücrelerimizin onarılıp güçlenmesi için gereklidir. Beslenme uzmanları, bir tabağın yarısının sebzelerden, kalan kısmının ise tahıl ve proteinden oluşmasını önerir; bu dengeye bazen "sağlıklı tabak" modeli denir.\n\n'
          'Düzenli saatlerde ve öğün atlamadan beslenmek, vücudun enerjisini gün boyunca dengeli tutar. Özellikle kahvaltı yapmak, sabah derslerinde dikkati ve konsantrasyonu artırdığı için okula giden çocuklar için oldukça önemlidir. Sağlıklı alışkanlıklar küçük yaşta kazanıldığında, bir ömür boyu sürebilir.',
      questions: [
        {
          'question': 'Meyveler ve sebzeler vitamin deposudur.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Şekerli ve yağlı yiyecekler her öğünde bol miktarda tüketilmelidir.',
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
          'Bir kitap açtığımızda, aslında başka bir dünyaya kapı aralarız. Roman okurken hayal gücümüz canlanır, karakterlerin yaşadıklarını sanki kendimiz yaşıyormuş gibi hissederiz. Düzenli kitap okumak sadece hayal gücümüzü değil, kelime dağarcığımızı ve empati kurma becerimizi de geliştirir. Her kitap, okuyana farklı bir bakış açısı kazandırır.\n\n'
          'Kitaplar öyle çeşitlidir ki herkes kendine uygun bir tür bulabilir: macera severler fantastik romanlara, meraklılar bilim kurguya, gerçek olayları merak edenler ise biyografilere yönelebilir. Her yeni kitap türü denemek, okuma zevkimizi genişletir ve daha önce hiç ilgilenmediğimiz konularla tanışmamızı sağlar.\n\n'
          'Düzenli okuma alışkanlığı kazanmak için her gün küçük bir süre ayırmak yeterlidir; önemli olan miktar değil sürekliliktir. Kütüphaneler, herkesin ücretsiz olarak binlerce kitaba ulaşabileceği değerli mekanlardır. Çok okuyan kişiler genellikle daha akıcı ve düzgün yazar, çünkü okudukları güzel cümleler zamanla kendi yazılarına da yansır.',
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
          'Dünya üzerinde yaklaşık 195 farklı ülke bulunur ve her birinin kendine özgü bir bayrağı, dili ve kültürü vardır. Bazı ülkeler çok büyük topraklara sahipken, bazıları küçücük adalardan oluşur. Ülkeler arasındaki bu çeşitlilik, dünyayı keşfetmeyi ve farklı gelenekleri tanımayı heyecanlı bir maceraya dönüştürür. Her ülkenin başkenti, o ülkenin yönetim merkezi olarak kabul edilir.\n\n'
          'Rusya, yüz ölçümü bakımından dünyanın en büyük ülkesiyken, Vatikan sadece birkaç yüz metrekarelik alanıyla en küçük ülke olarak bilinir. Bazı ülkeler tek bir dil konuşurken bazılarında onlarca farklı dil bir arada yaşar. Ülkeler, ortak konularda iş birliği yapmak için Birleşmiş Milletler gibi uluslararası kuruluşlarda bir araya gelir.\n\n'
          'Bir ülkeyi tanımanın yolu sadece oraya gitmekten geçmez; haritalar incelemek, o ülkenin yemeklerini tatmak ya da kitaplar okumak da dünyayı keşfetmenin keyifli yollarıdır. Farklı kültürleri tanımak, insanların birbirine olan saygısını ve hoşgörüsünü artırır.',
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
          'question':
              'Bir ülkenin başkenti, o ülkenin yönetim merkezi olarak kabul edilir.',
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
          'İbni Sina, 980 yılında bugünkü Özbekistan sınırları içinde doğmuş ünlü bir bilgin ve hekimdir. Küçük yaşta tıp, felsefe ve matematik alanlarında kendini yetiştirmiş, on sekiz yaşına geldiğinde döneminin önde gelen hekimlerinden biri olmuştur. En bilinen eseri El-Kânun fi\'t-Tıbb (Tıbbın Kanunu), yüzyıllarca hem İslam dünyasında hem de Avrupa üniversitelerinde tıp eğitiminin temel kaynağı olarak okutulmuştur. İbni Sina\'nın çalışmaları, modern tıbbın gelişimine de önemli katkılar sağlamıştır.\n\n'
          'El-Kânun fi\'t-Tıbb adlı eserinde İbni Sina, bazı hastalıkların havadaki ya da sudaki görünmez etkenlerle bir kişiden diğerine geçebileceğini yazmıştır; bu fikir, yüzyıllar sonra keşfedilecek olan mikroplar bilgisine ışık tutan öncü bir gözlemdir. Ayrıca ameliyat sırasında acıyı azaltmak için bazı bitkisel karışımlar kullanmış, hastaların rahat tedavi görmesine önem vermiştir.\n\n'
          'İbni Sina yalnızca tıpla ilgilenmemiş, felsefe üzerine de önemli eserler yazmış çok yönlü bir düşünürdür. Yaşamı boyunca yazdığı yüzlerce eser, dünyanın birçok diline çevrilmiştir. Bugün hâlâ birçok üniversite ve hastane, onun bilime olan katkılarını anmak için adını taşımaktadır.',
      questions: [
        {
          'question':
              'İbni Sina\'nın en bilinen eseri El-Kânun fi\'t-Tıbb\'dır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'İbni Sina\'nın eserleri sadece İslam dünyasında okutulmuş, Avrupa\'da hiç kullanılmamıştır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'İbni Sina, küçük yaşta tıp, felsefe ve matematik alanlarında kendini yetiştirmiştir.',
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
          'Ali Kuşçu, 15. yüzyılda yaşamış önemli bir Türk astronomu ve matematikçisidir. Semerkant\'ta Uluğ Bey Rasathanesi\'nde çalışarak gök cisimleri üzerine değerli gözlemler yapmıştır. Fatih Sultan Mehmed\'in daveti üzerine İstanbul\'a gelmiş, burada matematik ve astronomi alanında dersler vermiştir. Ali Kuşçu\'nun bilime katkılarını anmak için Ay üzerindeki bir krater onun adıyla anılmaktadır.\n\n'
          'Ali Kuşçu\'nun yazdığı "Risale-i Fethiye" adlı eser, dönemin en gelişmiş astronomi bilgilerini bir araya getirmiş ve uzun yıllar boyunca ders kitabı olarak kullanılmıştır. İstanbul\'a geldiğinde Ayasofya medresesinde matematik dersleri vermiş, birçok öğrenciyi yetiştirerek bilginin genç nesillere aktarılmasına öncülük etmiştir.\n\n'
          'Onun titiz gözlem yöntemleri, kendisinden sonra gelen astronomlara da yol gösterici olmuştur. Ali Kuşçu\'nun bilime olan bu değerli katkıları, yüzyıllar sonra bile hatırlanmakta ve gökbilim tarihinde önemli bir yere sahip olmaya devam etmektedir.',
      questions: [
        {
          'question': 'Ali Kuşçu, Uluğ Bey Rasathanesi\'nde çalışmıştır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Ali Kuşçu, Fatih Sultan Mehmed\'in davetini reddederek İstanbul\'a hiç gitmemiştir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'Ay üzerinde Ali Kuşçu\'nun adını taşıyan bir krater vardır.',
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
          'Bîrûnî, 973 yılında Harezm\'de doğmuş; matematik, astronomi, coğrafya ve tarih gibi pek çok alanda eser vermiş çok yönlü bir bilgindir. Dünya\'nın yarıçapını, o dönem için şaşırtıcı derecede doğru bir yöntemle hesaplamıştır. Hindistan\'a yaptığı geziler sonucunda kaleme aldığı Kitâbü\'l-Hind adlı eseriyle Hint kültürünü ve bilimini tanıtmıştır. Bîrûnî\'nin çalışmaları, onun tarihin ilk gerçek bilim insanlarından biri olarak anılmasını sağlamıştır.\n\n'
          'Dünya\'nın yarıçapını hesaplarken bir dağın tepesinden ufka bakış açısını ölçmüş ve basit geometri kurallarını kullanarak sonuca ulaşmıştır; bu yöntem, dönemine göre son derece yaratıcı bir çözümdü. Bîrûnî ayrıca birçok dili akıcı biçimde konuşabiliyordu; bu sayede farklı kültürlerdeki bilgi kaynaklarını doğrudan okuyup karşılaştırabiliyordu.\n\n'
          'Taşlar ve madenler üzerine yaptığı çalışmalarla mineraloji bilimine de katkı sağlamıştır. Bîrûnî\'nin gözleme dayalı, önyargısız araştırma anlayışı, günümüz bilimsel yönteminin temel ilkeleriyle büyük benzerlik taşır ve bu yüzden modern bilim tarihinde saygıyla anılır.',
      questions: [
        {
          'question': 'Bîrûnî, Dünya\'nın yarıçapını hesaplamıştır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Bîrûnî yalnızca astronomiyle ilgilenmiş, başka hiçbir alanda çalışma yapmamıştır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'Kitâbü\'l-Hind, Bîrûnî\'nin Hindistan gezileri sonucunda yazdığı bir eserdir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Bîrûnî sadece Avrupa\'yı ziyaret etmiştir, Hindistan\'a hiç gitmemiştir.',
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
          'Mikroplar, çıplak gözle görülemeyecek kadar küçük canlılardır; bakteri, virüs ve mantarları kapsar. Bazı mikroplar hastalıklara neden olurken, bazıları sindirim sistemimizde besinleri parçalamamıza yardımcı olan faydalı canlılardır. Bilim insanları mikroskop sayesinde bu küçük dünyayı keşfedip incelemeyi başarmıştır. Ellerimizi düzenli yıkamak, zararlı mikropların vücudumuza girmesini önlemenin en etkili yollarından biridir.\n\n'
          'Mikroskop icat edilmeden önce insanlar bu küçük canlıların varlığından habersizdi. On yedinci yüzyılda geliştirilen ilk mikroskoplarla bilim insanları, bir su damlasının içinde bile binlerce mikroorganizma olduğunu görünce büyük bir şaşkınlık yaşamıştır. Bu keşif, hastalıkların nasıl yayıldığını anlamamızda dönüm noktası olmuştur.\n\n'
          'Yoğurt ve ekmek gibi birçok besin, faydalı mikropların yardımıyla üretilir; mayalanma denen bu süreç sayesinde hamur kabarır, süt yoğurda dönüşür. Aşılar ve antibiyotikler de mikroplarla mücadele etmek için geliştirilmiş önemli buluşlardır. Ellerimizi sabunla en az yirmi saniye yıkamak, hastalık yapan mikropların yayılmasını büyük ölçüde azaltır.',
      questions: [
        {
          'question': 'Mikroplar çıplak gözle görülemeyecek kadar küçüktür.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Bütün mikroplar vücudumuza zarar verir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'Elleri düzenli yıkamak zararlı mikroplardan korunmanın etkili bir yoludur.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Mikroplar mikroskopla bile görülemez.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p18',
      title: 'Enerjinin Halleri',
      topic: 'bilim',
      content:
          'Enerji, bir işin yapılabilmesini sağlayan güçtür ve farklı biçimlerde bulunabilir: ışık enerjisi, ısı enerjisi, hareket enerjisi ve elektrik enerjisi gibi. Güneş, dünyadaki en büyük enerji kaynağıdır ve bitkiler fotosentez yoluyla bu enerjiyi kullanır. Enerji yoktan var edilemez ya da yok edilemez, sadece bir biçimden diğerine dönüşür. Rüzgar türbinleri, rüzgarın hareket enerjisini elektrik enerjisine çevirerek evlerimizi aydınlatmamıza yardımcı olur.\n\n'
          'Enerji kaynakları ikiye ayrılır: kömür ve petrol gibi tükenebilir kaynaklar, güneş ve rüzgar gibi ise sürekli yenilenen kaynaklardır. Güneş panelleri, güneş ışığını doğrudan elektriğe çevirerek evlere ve hatta uydulara enerji sağlayabilir. Yenilenebilir enerji kaynaklarının kullanımı arttıkça çevreye verilen zarar da azalmaktadır.\n\n'
          'Enerji tasarrufu yapmak için kullanılmayan odalarda ışıkları kapatmak, cihazları fişten çekmek ve gün ışığından olabildiğince faydalanmak gibi basit alışkanlıklar edinebiliriz. Küçük görünen bu davranışlar, birçok insan tarafından uygulandığında büyük bir enerji tasarrufuna dönüşür.',
      questions: [
        {
          'question': 'Güneş, dünyadaki en büyük enerji kaynağıdır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Enerji yoktan var edilip yok edilebilir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'Rüzgar türbinleri rüzgarın hareket enerjisini elektrik enerjisine çevirir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Bitkiler güneş enerjisini hiçbir şekilde kullanmaz.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p19',
      title: 'Deney Yapmanın Önemi',
      topic: 'bilim',
      content:
          'Bilim insanları, bir fikrin doğru olup olmadığını anlamak için deneyler yapar. Bir deney yaparken önce bir soru sorulur, sonra bu soruya cevap bulmak için dikkatli bir plan hazırlanır. Aynı deneyin birkaç kez tekrarlanması, sonuçların güvenilir olup olmadığını anlamamızı sağlar. Deneyler sırasında elde edilen veriler dikkatle kaydedilir ve sonunda bir sonuca varılır.\n\n'
          'İyi bir deneyde genellikle iki grup karşılaştırılır: değişikliğin uygulandığı grup ve hiçbir değişiklik yapılmadan bırakılan "kontrol grubu". Bu karşılaştırma, gözlenen farkın gerçekten yapılan değişiklikten mi yoksa tesadüften mi kaynaklandığını anlamamıza yardımcı olur.\n\n'
          'Okullarda düzenlenen bilim şenlikleri, öğrencilerin kendi sorularını sorup küçük deneylerle cevap aramasına fırsat tanır. Bir bitkinin farklı miktarda suyla nasıl büyüdüğünü gözlemlemek gibi basit bir deney bile, bilimsel düşünme becerisini geliştirmek için harika bir başlangıçtır. Deney yaparken güvenlik kurallarına uymak da her zaman en önemli adımdır.',
      questions: [
        {
          'question':
              'Deneyler bir fikrin doğru olup olmadığını anlamak için yapılır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Bir deneyi sadece bir kez yapmak sonuçların güvenilirliği için yeterlidir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Deneyler sırasında elde edilen veriler kaydedilmez.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Bir deney yapmadan önce dikkatli bir plan hazırlanır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
      ],
    ),
    ReadingPassage(
      id: 'p20',
      title: 'Karıncaların Gizli Dünyası',
      topic: 'hayvanlar',
      content:
          'Karıncalar, küçük görünse de son derece düzenli bir toplum içinde yaşayan böceklerdir. Her karınca kolonisinde işçi karıncalar, asker karıncalar ve bir kraliçe karınca farklı görevler üstlenir. Karıncalar, kendi ağırlıklarının kat kat fazlasını taşıyabilecek kadar güçlüdür. Birbirleriyle özel kokular (feromonlar) bırakarak iletişim kurar ve yiyecek kaynaklarına giden yolu arkadaşlarına gösterirler.\n\n'
          'Bir karınca kolonisi, bazen milyonlarca bireyden oluşabilir ve toprağın altında birbirine bağlı karmaşık tünellerden oluşan devasa bir yuva inşa edebilir. İlginç bir şekilde bazı karınca türleri, tıpkı çiftçilerin ineklerden süt sağması gibi, yaprak bitlerinden tatlı bir sıvı elde ederek onları "sağar" ve karşılığında koruyup bakar.\n\n'
          'Karıncaların hiçbir merkezi yönetici olmadan bu kadar düzenli çalışabilmesi, bilim insanlarını uzun süre hayrete düşürmüştür; her karınca sadece yakınındaki birkaç ipucuna göre hareket eder, ama sonuçta koloninin tamamı uyum içinde çalışır. Bu, birlikte çalışmanın küçük çabalarla bile büyük işler başarabileceğinin güzel bir örneğidir.',
      questions: [
        {
          'question':
              'Karınca kolonisinde farklı görevler üstlenen karıncalar vardır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Karıncalar kendi ağırlıklarını bile taşıyamayacak kadar güçsüzdür.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'Karıncalar birbirleriyle özel kokular bırakarak iletişim kurar.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Karıncalar birbirleriyle hiçbir şekilde iletişim kurmaz.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p21',
      title: 'Kutup Ayısının Yaşamı',
      topic: 'hayvanlar',
      content:
          'Kutup ayıları, Kuzey Kutbu\'nun buzlu sularında ve karlarla kaplı topraklarında yaşayan büyük memelilerdir. Kalın kürkleri ve altındaki yağ tabakası, onları dondurucu soğuktan korur. Mükemmel yüzücülerdir ve saatlerce kesintisiz yüzebilirler. Beslenmeleri büyük ölçüde foklara dayanır, bu yüzden buzların erimesi onların hayatta kalması için ciddi bir tehdit oluşturur.\n\n'
          'İlginç bir şekilde kutup ayılarının kürkü beyaz görünse de, derilerinin altı aslında siyahtır; bu koyu renk, güneş ışığının ısısını daha iyi emerek onları sıcak tutmaya yardımcı olur. Avlanırken genellikle foklerin nefes almak için buzda açtığı deliklerin başında sabırla bekler ve fok yüzeye çıktığı anda hızla yakalar.\n\n'
          'Yavru kutup ayıları, doğduktan sonra ilk aylarını anneleriyle birlikte kar mağarasında geçirir ve avlanmayı, yüzmeyi anneden izleyerek öğrenir. Küresel ısınma nedeniyle deniz buzlarının erken erimesi, kutup ayılarının avlanma süresini kısaltmakta ve bu değerli türün geleceğini tehdit etmektedir.',
      questions: [
        {
          'question':
              'Kutup ayılarının kalın kürkü ve yağ tabakası onları soğuktan korur.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Kutup ayıları yüzmeyi hiç beceremez.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'Buzların erimesi kutup ayıları için bir tehdit oluşturur.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Kutup ayılarının beslenmesi foklarla hiç ilgili değildir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p22',
      title: 'Kelebeğin Değişimi',
      topic: 'hayvanlar',
      content:
          'Bir kelebeğin hayatı, minik bir yumurtadan başlar ve tırtıl haline gelmesiyle devam eder. Tırtıl, yeterince büyüdüğünde kendini bir kozanın içine sarar ve burada büyük bir dönüşüm geçirir. Bu sürece başkalaşım (metamorfoz) denir. Kozadan çıkan canlı, artık renkli kanatlara sahip bir kelebektir ve çiçeklerden nektar toplayarak beslenir.\n\n'
          'Tırtıl evresinde kelebek, hızla büyüyebilmek için gün boyunca durmadan yaprak yiyerek kendi ağırlığının kat kat fazlası kadar besin tüketir. Bazı kelebek türleri, örneğin Monark kelebekleri, kışı geçirmek için binlerce kilometre uçarak göç eder; bu küçük canlıların bu kadar uzun bir yolculuğu nasıl başardığı hâlâ araştırılan bir konudur.\n\n'
          'Kelebekler çiçekten çiçeğe uçarken üzerlerine bulaşan poleni taşıyarak, tıpkı arılar gibi bitkilerin tozlaşmasına yardımcı olur. Bir kelebeğin yetişkin hâldeki ömrü genellikle sadece birkaç hafta sürer, ama bu kısa sürede doğaya sağladığı katkı oldukça büyüktür.',
      questions: [
        {
          'question': 'Kelebeğin hayatı bir yumurtayla başlar.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Tırtıl, kozaya girmeden doğrudan kelebeğe dönüşür.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Bu dönüşüm sürecine başkalaşım (metamorfoz) denir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Kelebekler nektarla değil etle beslenir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p23',
      title: 'Kütüphanelerin Tarihi',
      topic: 'kitaplar',
      content:
          'Kütüphaneler, binlerce yıldır bilginin saklandığı özel yerlerdir. Tarihteki en ünlü kütüphanelerden biri, Mısır\'daki İskenderiye Kütüphanesi\'ydi ve dönemin en büyük bilgi hazinesini barındırıyordu. Eskiden kitaplar el yazmasıyla yazıldığı için çok değerliydi ve üretilmesi uzun zaman alıyordu. Günümüzde kütüphaneler hem basılı kitapları hem de dijital kaynakları bir arada sunmaktadır.\n\n'
          'On beşinci yüzyılda matbaanın icadıyla kitaplar artık elle değil makineyle basılmaya başlandı; bu da kitapların çok daha hızlı üretilip daha fazla insana ulaşmasını sağladı. Bu buluş, bilginin yayılma hızını inanılmaz derecede artırmış ve okuma yazma bilen insan sayısının artmasına katkı sağlamıştır.\n\n'
          'Günümüz kütüphaneleri sadece kitap ödünç vermekle kalmaz; bilgisayar kullanımı, film gösterimleri ve çocuklar için hikaye saatleri gibi birçok etkinlik de düzenler. Bazı şehirlerde, kitaplara kolay ulaşamayan mahallelere kitap götüren "gezici kütüphaneler" bile bulunur. Herkesin ücretsiz olarak bilgiye ulaşabilmesi, kütüphanelerin en değerli özelliğidir.',
      questions: [
        {
          'question': 'İskenderiye Kütüphanesi Mısır\'daydı.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Eskiden kitaplar matbaa makineleriyle saniyeler içinde basılırdı.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'Günümüz kütüphaneleri sadece basılı kitap sunar, dijital kaynak sunmaz.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Eskiden kitaplar el yazmasıyla yazılırdı.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
      ],
    ),
    ReadingPassage(
      id: 'p24',
      title: 'Bir Kitap Nasıl Yazılır',
      topic: 'kitaplar',
      content:
          'Bir kitap yazmak, önce bir fikir bulmakla başlar. Yazar, hikayesinin karakterlerini, olay örgüsünü ve mekanını dikkatlice planlar. İlk taslak tamamlandıktan sonra, yazar metni tekrar tekrar gözden geçirir ve düzeltmeler yapar. Bu düzenleme sürecine "editleme" denir ve bir kitabın okuyucuya ulaşmadan önce geçirdiği en önemli aşamalardan biridir.\n\n'
          'Bazı yazarlar, hikayelerini gerçekçi kılmak için önceden araştırma yapar; tarihi bir roman yazan bir yazar, o döneme ait giysileri, konuşma biçimlerini ve olayları dikkatle inceleyebilir. Taslak tamamlandığında, yayınevindeki editörler yazarla birlikte çalışarak metni daha akıcı ve anlaşılır hale getirir.\n\n'
          'Çocuk kitaplarında genellikle resimleyiciler de görev alır; onların çizdiği renkli resimler, hikayeyi görsel olarak zenginleştirir. Bir kitabın fikir aşamasından raflara ulaşmasına kadar geçen süre, bazen aylar bazen de yıllar alabilir; bu yüzden her kitabın arkasında sabırlı ve emek dolu uzun bir çalışma vardır.',
      questions: [
        {
          'question': 'Bir kitap yazmak bir fikir bulmakla başlar.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Yazarlar ilk taslağı yazdıktan sonra hiç değişiklik yapmadan kitabı yayınlar.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Metni gözden geçirip düzeltme sürecine editleme denir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Yazar, hikayesinin karakterlerini ve olay örgüsünü hiç planlamaz.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p25',
      title: 'E-Kitap mı Kağıt Kitap mı',
      topic: 'kitaplar',
      content:
          'Günümüzde kitaplar hem kağıt hem de elektronik (e-kitap) biçiminde okunabiliyor. E-kitaplar, bir tablet ya da telefonla yüzlerce kitabı yanınızda taşımanıza olanak tanır. Kağıt kitaplar ise sayfaları çevirme hissini ve göz yorgunluğunun daha az olmasını sağlar. Her iki biçimin de kendine göre avantajları vardır ve tercih genellikle okuyucunun alışkanlıklarına bağlıdır.\n\n'
          'Son yıllarda sesli kitaplar da üçüncü bir seçenek olarak popülerlik kazanmıştır; bir hikayeyi dinleyerek "okumak", yolda ya da ev işleri yaparken bile mümkün olur. E-kitap okuyucularda yazı boyutunu istediğimiz gibi büyütüp küçültebilmemiz, göz sağlığı için özellikle faydalı bir özelliktir.\n\n'
          'Bazı kitapseverler ise kağıt kitapları biriktirmeyi bir hobi haline getirir; raflarında özenle sakladıkları kitaplar onlar için özel bir değer taşır. Hangi biçim tercih edilirse edilsin, önemli olan okuma alışkanlığını sürdürmek ve kitaplarla vakit geçirmekten keyif almaktır.',
      questions: [
        {
          'question':
              'E-kitaplar bir cihazla yüzlerce kitabı taşımaya olanak tanır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Kağıt kitapların hiçbir avantajı yoktur.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'Kitap biçimi tercihi genellikle okuyucunun alışkanlıklarına bağlıdır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Kağıt kitaplar göz yorgunluğunu artırır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p26',
      title: 'Algoritma Nedir',
      topic: 'kodlama',
      content:
          'Algoritma, bir problemi çözmek için izlenen adım adım talimatlar dizisidir. Günlük hayatta bile farkında olmadan algoritmalar kullanırız; örneğin bir sandviç yapmanın adımları da bir algoritmadır. Bilgisayar programcıları, bir algoritmayı kodlama diline çevirerek bilgisayarın belirli bir görevi yerine getirmesini sağlar. İyi bir algoritma, hem doğru sonucu verir hem de mümkün olduğunca hızlı çalışır.\n\n'
          'Programcılar, bir algoritmayı kod yazmadan önce genellikle "akış şeması" adı verilen oklu bir çizimle görselleştirir; bu da adımların doğru sırayla planlanmasına yardımcı olur. Kitapları alfabetik sıraya dizmek ya da bir yarışta sporcuları puanına göre sıralamak da birer algoritma örneğidir.\n\n'
          'Kullandığımız arama motorları, milyonlarca sayfa arasından en uygun sonucu bulmak için karmaşık algoritmalar kullanır; harita uygulamaları ise en kısa yolu hesaplamak için benzer bir mantıkla çalışır. Günlük görevlerimizi adım adım planlamayı öğrenmek, aslında algoritmik düşünmeyi pratik yapmanın eğlenceli bir yoludur.',
      questions: [
        {
          'question':
              'Algoritma, bir problemi çözmek için izlenen adım adım talimatlardır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Algoritmalar sadece bilgisayarlarda kullanılır, günlük hayatta kullanılmaz.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'İyi bir algoritma doğru sonucu vermeli ve hızlı çalışmalıdır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Algoritmalar günlük hayatta hiç kullanılmaz.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p27',
      title: 'Robotlar ve Kodlama',
      topic: 'kodlama',
      content:
          'Bir robotun hareket edebilmesi, aslında arkasındaki koda bağlıdır. Programcılar, robota ne zaman döneceğini, ne zaman duracağını ve engellerden nasıl kaçınacağını kod satırlarıyla öğretir. Sensörler sayesinde robot çevresini algılar ve bu bilgiyi kodun belirlediği kurallara göre işler. Kodlama sayesinde bir robot, fabrikalarda parça taşımaktan evde toz almaya kadar birçok işi yapabilir.\n\n'
          'Fabrikalarda kullanılan robot kollar, aynı hareketi binlerce kez tekrar ederek arabalara parça takabilir ya da ürünleri paketleyebilir; bu da üretimi hem hızlandırır hem de daha güvenli hale getirir. Işık sensörleri, mesafe sensörleri ve dokunma sensörleri, robotların farklı görevleri yerine getirmesine yardımcı olan yaygın örneklerdir.\n\n'
          'Birçok okulda düzenlenen robotik yarışmaları, öğrencilerin takım hâlinde çalışarak kendi robotlarını tasarlayıp kodlamasına olanak tanır. Bu tür etkinlikler, hem kodlama becerisini geliştirir hem de takım çalışmasının ve sabırlı denemelerin önemini öğretir.',
      questions: [
        {
          'question': 'Bir robotun hareketleri arkasındaki koda bağlıdır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Robotlar çevrelerini hiçbir sensör kullanmadan algılar.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Kodlama sayesinde robotlar farklı birçok işi yapabilir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Programcılar robota nasıl duracağını hiç öğretmez.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p28',
      title: 'Oyun Programlama',
      topic: 'kodlama',
      content:
          'Video oyunları, arkasında yüzlerce satır kodla çalışan karmaşık programlardır. Bir oyun programcısı, karakterlerin nasıl hareket edeceğini, puanların nasıl hesaplanacağını ve oyunun kurallarını kodla belirler. Grafik tasarımcılar görsel dünyayı oluştururken, programcılar bu dünyayı hayata geçiren "motoru" yazar. Basit bir oyun bile, saatlerce planlama ve kodlama gerektirir.\n\n'
          'Bir oyun tamamlanmadan önce mutlaka test edilir; test uzmanları oyunu defalarca oynayarak hataları bulmaya çalışır, çünkü küçük bir kod hatası oyunun donmasına ya da beklenmedik şekilde çalışmasına neden olabilir. Ses tasarımcıları ise karakterlerin adımlarından müzik parçalarına kadar oyundaki tüm sesleri hazırlar.\n\n'
          'Büyük oyunlar genellikle onlarca kişinin bir arada çalıştığı takımlar tarafından yapılır; programcı, tasarımcı ve ses uzmanı birlikte uyum içinde çalışmalıdır. Yeni başlayanlar için geliştirilen basit oyun tasarım araçları sayesinde, çocuklar bile küçük yaşta kendi oyunlarını tasarlamayı deneyebilir.',
      questions: [
        {
          'question':
              'Video oyunları yüzlerce satır kodla çalışan programlardır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Bir oyunu kodlamak hiç zaman almaz, anında tamamlanır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'Programcılar oyunun kurallarını ve karakter hareketlerini kodla belirler.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Grafik tasarımcılar oyunun kod motorunu yazar.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p29',
      title: 'Heykel Sanatı',
      topic: 'sanat',
      content:
          'Heykel, taş, tunç, ahşap ya da kil gibi malzemelerden üç boyutlu eserler yaratma sanatıdır. Heykeltıraşlar, düz bir resimden farklı olarak eserlerini her açıdan izlenebilecek şekilde şekillendirir. Tarihteki en ünlü heykellerden biri, Michelangelo\'nun yaptığı Davut Heykeli\'dir. Heykel yapmak, hem sabır hem de malzemenin doğasını iyi anlamayı gerektiren zorlu bir zanaattir.\n\n'
          'Heykel yapmanın birçok yöntemi vardır: bazı sanatçılar bir taş bloğunu yontarak fazlalıkları kazır, bazıları ise erimiş metali bir kalıba dökerek şekil verir. Kil gibi yumuşak malzemelerle çalışan heykeltıraşlar ise eseri elleriyle şekillendirip sonra fırınlayarak sertleştirir. Antik Mısır ve Antik Yunan uygarlıkları, günümüze kadar ulaşan pek çok etkileyici heykel bırakmıştır.\n\n'
          'Günümüzde heykeltıraşlar metal, cam ve hatta geri dönüştürülmüş malzemelerle de eserler üretmektedir. Şehir meydanlarında ve parklarda gördüğümüz heykeller, hem şehre estetik bir güzellik katar hem de genellikle önemli bir kişiyi ya da olayı hatırlatmak amacıyla dikilir.',
      questions: [
        {
          'question': 'Heykel üç boyutlu eserler yaratma sanatıdır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Heykeller sadece tek bir açıdan izlenebilir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Davut Heykeli Michelangelo tarafından yapılmıştır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Heykel yapmak hiçbir sabır gerektirmez.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p30',
      title: 'Müziğin Gücü',
      topic: 'sanat',
      content:
          'Müzik, sesleri belirli bir düzen içinde bir araya getirerek duygu ve düşünceleri anlatan evrensel bir sanattır. Farklı kültürlerin kendine özgü müzik aletleri ve tarzları vardır, ama müziğin duyguları harekete geçirme gücü her yerde aynıdır. Bilim insanları, müzik dinlemenin stresi azaltabileceğini ve odaklanmayı artırabileceğini keşfetmiştir. Bir beste yazmak, notaları doğru sırayla bir araya getirmekten çok daha fazlasını, yani duygu aktarmayı gerektirir.\n\n'
          'Müzik aletleri genellikle üç ana gruba ayrılır: telli çalgılar (gitar, keman), üflemeli çalgılar (flüt, trompet) ve vurmalı çalgılar (davul, ksilofon). Bir orkestrada onlarca farklı çalgı, bir şef yönetiminde uyum içinde çalarak tek bir eseri hayata geçirir; bu da müziğin aynı zamanda büyük bir takım çalışması olduğunu gösterir.\n\n'
          'Küçük yaşta bir müzik aleti çalmayı öğrenmek, hem el becerisini hem de matematiksel düşünmeyi geliştirdiği için bilim insanları tarafından önerilir. Dünyanın her köşesinde farklı müzik türleri gelişmiştir; bu çeşitlilik, müziği kültürler arasında en güçlü ortak dillerden biri haline getirir.',
      questions: [
        {
          'question':
              'Müzik, sesleri belirli bir düzen içinde bir araya getiren bir sanattır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Müziğin duyguları harekete geçirme gücü sadece bazı kültürlerde geçerlidir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Müzik dinlemenin stresi azaltabileceği keşfedilmiştir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Bir beste yazmak sadece notaları sıraya koymaktır, duygu gerekmez.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p31',
      title: 'Tiyatronun Doğuşu',
      topic: 'sanat',
      content:
          'Tiyatro, insanların bir hikayeyi canlı olarak sahnede canlandırdığı en eski sanat türlerinden biridir. Antik Yunan\'da tiyatro, hem eğlence hem de toplumsal konuları tartışma amacı taşıyordu. Oyuncular, maskeler takarak farklı karakterleri ve duyguları seyirciye aktarırdı. Günümüzde tiyatro, sinema ve dizilerin yanında hâlâ canlı performansın eşsiz heyecanını sunmaya devam ediyor.\n\n'
          'Antik Yunan\'da kullanılan maskelerin gülen yüzü komediyi, üzgün yüzü ise trajediyi (dramatik oyunları) temsil ederdi; bu maskeler bugün bile tiyatronun simgesi olarak bilinir. Oyunlar, sesin en arka sıraya kadar net duyulmasını sağlayan özel taş amfitiyatrolarda sahnelenirdi.\n\n'
          'Sinema ve dizilerden farklı olarak tiyatroda oyuncular seyirciyle aynı anda, aynı mekânda bulunur ve her gösterim birbirinden biraz farklı olabilir; bu da tiyatroya tekrarlanamaz bir heyecan katar. Okullarda düzenlenen tiyatro oyunları, öğrencilerin özgüvenini, sesini doğru kullanmasını ve ekip çalışmasını geliştiren değerli bir deneyim sunar.',
      questions: [
        {
          'question':
              'Tiyatro insanların bir hikayeyi canlı olarak sahnede canlandırmasıdır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Antik Yunan\'da tiyatronun toplumsal konularla hiçbir ilgisi yoktu.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'Antik Yunan\'da oyuncular maskeler takarak karakterleri canlandırırdı.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Tiyatro yirminci yüzyılda ortaya çıkmış yeni bir sanattır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p32',
      title: 'Olimpiyat Oyunlarının Tarihi',
      topic: 'spor',
      content:
          'Olimpiyat Oyunları, ilk olarak Antik Yunanistan\'da, Olympia şehrinde binlerce yıl önce düzenlenmeye başlamıştır. O dönemde oyunlar sırasında şehirler arasındaki savaşlar bile geçici olarak durdurulurdu. Modern Olimpiyatlar ise 1896 yılında Atina\'da yeniden başlatılmıştır. Bugün dünyanın dört bir yanından binlerce sporcu, dört yılda bir bu büyük yarışmada bir araya gelmektedir.\n\n'
          'Olimpiyat bayrağındaki beş iç içe geçmiş halka, dünyanın beş kıtasını ve sporun birleştirici gücünü simgeler. Yaz Olimpiyatlarında yüzme ve atletizm gibi dallar yer alırken, kış aylarında düzenlenen Kış Olimpiyatları\'nda kayak ve buz pateni gibi kar ve buz sporları öne çıkar.\n\n'
          'Oyunlar başlamadan önce Olympia\'da yakılan olimpiyat ateşi, koşucular tarafından ülkeden ülkeye taşınarak yarışmaların yapılacağı şehre ulaştırılır. Olimpiyatların temelinde yatan en önemli değer, kazanmaktan çok dürüst ve saygılı bir şekilde yarışmaktır; buna "fair play" (adil oyun) denir.',
      questions: [
        {
          'question':
              'Olimpiyat Oyunları ilk olarak Antik Yunanistan\'da başlamıştır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Modern Olimpiyatlar ilk kez Paris\'te düzenlenmiştir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Olimpiyat Oyunları her yıl düzenlenir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'Dört yılda bir dünyanın dört bir yanından sporcular bir araya gelir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
      ],
    ),
    ReadingPassage(
      id: 'p33',
      title: 'Yüzmenin Faydaları',
      topic: 'spor',
      content:
          'Yüzme, vücuttaki hemen hemen tüm kasları aynı anda çalıştıran ender sporlardan biridir. Su içinde hareket etmek, eklemlere kara sporlarına göre çok daha az yük bindirir. Düzenli yüzmek, kalp ve akciğer sağlığını güçlendirir ve dayanıklılığı artırır. Ayrıca suyun serinletici etkisi, yüzmeyi hem eğlenceli hem de rahatlatıcı bir aktivite haline getirir.\n\n'
          'Yarışmalarda kullanılan başlıca yüzme stilleri serbest stil, sırtüstü, kurbağalama ve kelebektir; her biri farklı kas gruplarını çalıştırır ve farklı teknik beceriler gerektirir. Küçük yaşta doğru teknikle yüzmeyi öğrenmek, hem güvenlik açısından önemlidir hem de ileride bu sporu severek sürdürmeyi kolaylaştırır.\n\n'
          'Havuzda ya da denizde yüzerken bir yetişkinin gözetiminde olmak ve derin sulara tek başına girmemek, su güvenliğinin en temel kurallarındandır. Dünya çapındaki yüzme yarışmalarında sporcular, yıllarca süren disiplinli antrenmanlar sonunda saniyelerle ölçülen farklarla dereceye girer.',
      questions: [
        {
          'question': 'Yüzme vücuttaki hemen hemen tüm kasları çalıştırır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Su içinde hareket etmek eklemlere kara sporlarından daha fazla yük bindirir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Düzenli yüzmek kalp ve akciğer sağlığını güçlendirir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Yüzme kalp ve akciğer sağlığına hiçbir katkı sağlamaz.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p34',
      title: 'Satranç Bir Spor mu',
      topic: 'spor',
      content:
          'Satranç, fiziksel güç gerektirmese de büyük bir zihinsel yoğunluk ve strateji becerisi ister. Uluslararası Olimpiyat Komitesi, satrancı "zihin sporu" olarak tanımaktadır. Profesyonel satranç oyuncuları, uzun bir maç sırasında yüzlerce kalori harcayabilir çünkü yoğun konsantrasyon beyni oldukça yorar. Satranç, sabırlı planlama ve rakibin hamlelerini önceden tahmin etme becerisini geliştirir.\n\n'
          'Satranç tahtası 64 kareden oluşur ve her oyuncunun on altı taşı vardır; her taş türü farklı bir şekilde hareket eder, bu da oyunu her seferinde farklı bir bulmacaya dönüştürür. Bir satranç oyuncusunun ulaşabileceği en yüksek unvan "büyükusta"dır ve bu unvana ulaşmak yıllarca süren çalışma gerektirir.\n\n'
          'Küçük yaşta satranç oynamayı öğrenen çocuklarda hafıza, sabır ve problem çözme becerilerinin geliştiği gözlemlenmiştir. Günümüzde bilgisayar programları, en güçlü insan oyuncuları bile yenebilecek kadar gelişmiştir; yine de satranç, insanlar arasında hâlâ en sevilen zihinsel yarışmalardan biri olmaya devam etmektedir.',
      questions: [
        {
          'question':
              'Satranç Uluslararası Olimpiyat Komitesi tarafından "zihin sporu" olarak tanınır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Satranç oynamak beyni hiç yormaz.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'Satranç, rakibin hamlelerini önceden tahmin etme becerisini geliştirir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Profesyonel satranç oyuncuları maç sırasında hiç kalori harcamaz.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p35',
      title: 'Japonya\'nın Gelenekleri',
      topic: 'ulkeler',
      content:
          'Japonya, modern teknolojisiyle tanınsa da köklü geleneklerini de büyük bir özenle korumaktadır. Çay seremonisi, sadece çay içmekten öte, sakinlik ve saygıyı simgeleyen özel bir törendir. Kiraz çiçeklerinin (sakura) açtığı bahar mevsiminde, aileler parklarda "hanami" adı verilen çiçek izleme etkinlikleri düzenler. Japon kültüründe nezaket ve düzen, günlük yaşamın her alanında önemli bir yer tutar.\n\n'
          'Origami, tek bir kağıt parçasını kesmeden katlayarak kuş, çiçek ya da hayvan şekilleri oluşturma sanatıdır ve sabır ile dikkat gerektirir. Geleneksel kıyafet olan kimono, özel gün ve törenlerde hâlâ gururla giyilir; her deseni ve rengi farklı bir anlam taşıyabilir.\n\n'
          'Japonya\'da insanlar birbirini selamlarken genellikle eğilerek saygı gösterir; eğilmenin derecesi bile karşıdaki kişiye duyulan saygının miktarını belirtebilir. Zamana ve temizliğe verilen önem de Japon kültüründe öne çıkan değerlerdendir; örneğin okul öğrencileri sınıflarını kendileri temizler.',
      questions: [
        {
          'question':
              'Japonya\'da çay seremonisi sakinlik ve saygıyı simgeler.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Japonya geleneklerini tamamen terk etmiş, sadece teknolojiye odaklanmıştır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Hanami, kiraz çiçeklerini izleme etkinliğidir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Hanami, kış mevsiminde yapılan bir kar festivalidir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p36',
      title: 'Mısır Piramitleri',
      topic: 'ulkeler',
      content:
          'Mısır piramitleri, binlerce yıl önce firavunlar için mezar olarak inşa edilmiş devasa yapılardır. En büyük ve en ünlü piramit, Giza\'daki Büyük Piramit\'tir ve yüzyıllarca dünyanın en yüksek yapısı olma özelliğini korumuştur. Piramitlerin nasıl inşa edildiği hâlâ bilim insanlarını şaşırtan bir konudur, çünkü o dönemde modern makineler yoktu. Bu yapılar, Antik Mısır uygarlığının mühendislik becerisinin canlı bir kanıtıdır.\n\n'
          'Giza\'daki Büyük Piramit\'in inşasında on binlerce işçinin, ağır taş blokları kızaklar ve rampalar yardımıyla taşıyarak çalıştığı düşünülmektedir. Piramitlerin hemen yanında yer alan ve aslan gövdeli, insan başlı dev heykel Sfenks de Antik Mısır\'ın en tanınan simgelerinden biridir.\n\n'
          'Antik Mısırlılar, hiyeroglif adı verilen resim yazısıyla duvarlara ve tapınaklara önemli olayları kaydetmiştir. Bilim insanları bu yazıları çözerek Antik Mısır hakkında pek çok bilgiye ulaşmış, piramitlerin ve o döneme ait yaşamın sırlarını gün geçtikçe daha iyi anlamaya başlamıştır.',
      questions: [
        {
          'question':
              'Mısır piramitleri firavunlar için mezar olarak inşa edilmiştir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Giza\'daki Büyük Piramit dünyanın en küçük yapısıdır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'Piramitler modern makineler kullanılarak inşa edilmiştir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'Piramitlerin nasıl inşa edildiği hâlâ bilim insanlarını şaşırtmaktadır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
      ],
    ),
    ReadingPassage(
      id: 'p37',
      title: 'Antarktika Kıtası',
      topic: 'ulkeler',
      content:
          'Antarktika, Dünya\'nın en güneyinde yer alan ve neredeyse tamamı kalın buzla kaplı bir kıtadır. Burada herhangi bir ülkenin daimi vatandaşı yaşamaz, sadece bilim insanları araştırma istasyonlarında geçici olarak kalır. Kıtadaki sıcaklıklar bazen eksi 80 dereceye kadar düşebilir, bu da onu Dünya\'nın en soğuk yeri yapar. Antarktika\'daki buzullar, Dünya\'nın tatlı su rezervlerinin büyük bir kısmını barındırır.\n\n'
          'Bu dondurucu soğuğa rağmen Antarktika\'da penguenler, foklar ve çeşitli deniz kuşları yaşar; penguenler kalın yağ tabakaları ve sıkı tüyleri sayesinde bu zorlu iklime uyum sağlamıştır. Kıtanın bazı bölgelerinde yılın belirli aylarında güneş hiç batmazken, diğer aylarda uzun süre hiç doğmaz.\n\n'
          'Antarktika, hiçbir ülkeye ait değildir; birçok ülke burada yalnızca bilimsel araştırma yapmak amacıyla anlaşarak ortak çalışmalar yürütür. Bu iş birliği sayesinde Antarktika, Dünya\'nın iklim geçmişini ve buzulların erimesini incelemek için eşsiz bir doğal laboratuvar olarak korunmaktadır.',
      questions: [
        {
          'question': 'Antarktika\'nın neredeyse tamamı kalın buzla kaplıdır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Antarktika\'da milyonlarca daimi vatandaş yaşar.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Antarktika, Dünya\'nın en soğuk yerlerinden biridir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Antarktika Dünya\'nın en sıcak yeridir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p38',
      title: 'Ay\'a Yolculuk',
      topic: 'uzay',
      content:
          'İnsanoğlu ilk kez 1969 yılında Ay\'a ayak basmıştır; bu tarihi adımı atan kişi astronot Neil Armstrong\'dur. Ay\'a gitmek için özel olarak tasarlanmış roketler, dünyanın yerçekiminden kurtulacak kadar güçlü olmalıdır. Ay\'da atmosfer olmadığı için gökyüzü her zaman siyah görünür ve sessizlik tamdır. Bilim insanları, Ay\'dan getirilen kayaları inceleyerek Güneş Sistemi\'nin oluşumu hakkında önemli bilgiler edinmiştir.\n\n'
          'Bu tarihi yolculuğa Apollo 11 görevi adı verilmiştir. Ay\'da rüzgar ve hava olmadığı için astronotların bıraktığı ayak izleri, tıpkı ilk bırakıldığı gün gibi hâlâ yerinde durmaktadır. Ay\'ın Dünya çevresindeki dönüşü sırasında güneş ışığını farklı açılardan alması, gökyüzünde gördüğümüz hilal, dolunay gibi farklı Ay evrelerini oluşturur.\n\n'
          'Ay\'a ilk gidişin üzerinden yıllar geçmiş olsa da bilim insanları, gelecekte Ay\'da uzun süreli bir üs kurmayı ve oradan Mars gibi daha uzak gezegenlere yolculuklar yapmayı planlamaktadır. Ay, hâlâ uzay araştırmalarının en önemli hedeflerinden biri olmaya devam etmektedir.',
      questions: [
        {
          'question': 'İnsanoğlu ilk kez 1969 yılında Ay\'a ayak basmıştır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Ay\'da yoğun bir atmosfer bulunur.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'Ay\'dan getirilen kayalar Güneş Sistemi hakkında bilgi vermiştir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Ay\'a ilk ayak basan kişi bir Rus kozmonottur.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p39',
      title: 'Yıldızlar Nasıl Doğar',
      topic: 'uzay',
      content:
          'Yıldızlar, uzaydaki dev gaz ve toz bulutlarının kendi yerçekimiyle çökmesi sonucu oluşur. Bu bulutun merkezi giderek ısınır ve sonunda nükleer füzyon adı verilen bir süreç başlar, bu da yıldızın parlamasını sağlar. Güneşimiz de yaklaşık 4.6 milyar yıl önce böyle bir bulutun içinden doğmuştur. Bir yıldızın ömrü, boyutuna bağlı olarak milyonlarca ya da milyarlarca yıl sürebilir.\n\n'
          'Yıldızların rengi aslında sıcaklıkları hakkında ipucu verir: mavimsi yıldızlar en sıcak, kırmızımsı yıldızlar ise nispeten daha soğuk yıldızlardır. Büyük bir yıldız ömrünün sonuna geldiğinde muazzam bir patlamayla parçalanabilir; bu olaya süpernova denir ve geride bazen çok yoğun küçük bir çekirdek bırakır.\n\n'
          'Eski denizciler ve kervan yolcuları, yıldızların oluşturduğu takımyıldızlarına bakarak yönlerini bulurdu; bu yüzden yıldızlar tarih boyunca hem bilim hem de yolculuk için yol gösterici olmuştur. Gökyüzünde yıldızların titreşerek parlıyormuş gibi görünmesinin nedeni, ışığın Dünya\'nın hareketli atmosferinden geçerken kırılmasıdır.',
      questions: [
        {
          'question':
              'Yıldızlar dev gaz ve toz bulutlarının çökmesiyle oluşur.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Güneşimiz hiçbir bulut olmadan aniden ortaya çıkmıştır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Bir yıldızın ömrü boyutuna bağlı olarak değişebilir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Bütün yıldızların ömrü birbirinin tamamen aynısıdır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p40',
      title: 'Uzay İstasyonunda Yaşam',
      topic: 'uzay',
      content:
          'Uluslararası Uzay İstasyonu, Dünya\'nın yörüngesinde dönen ve içinde astronotların aylarca yaşayıp çalışabildiği devasa bir yapıdır. Yerçekimi neredeyse hiç olmadığı için astronotlar istasyon içinde havada süzülerek hareket eder. Yemek yemek bile burada farklıdır; sıvılar damlalar halinde havada uçuşabileceği için özel kaplarda saklanır. Astronotlar, kaslarının erimemesi için istasyonda her gün özel egzersizler yapmak zorundadır.\n\n'
          'Bu istasyon, birçok ülkenin uzay ajansının ortaklaşa yürüttüğü uluslararası bir bilim projesidir; farklı ülkelerden astronotlar burada birlikte çalışır. İstasyon Dünya\'nın çevresinde çok hızlı döndüğü için astronotlar günde on altı kez gün doğumu ve gün batımı görebilir.\n\n'
          'Yerçekimi olmadığından astronotlar uyurken havada süzülmemek için duvara bağlı özel uyku tulumlarında uyurlar. İstasyonda bitkilerin uzayda nasıl büyüdüğünden insan vücudunun uzun süreli uzay yolculuğuna nasıl tepki verdiğine kadar birçok bilimsel deney yapılır; bu deneyler gelecekteki uzay yolculukları için değerli bilgiler sağlar.',
      questions: [
        {
          'question':
              'Uluslararası Uzay İstasyonu\'nda astronotlar havada süzülerek hareket eder.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Uzay istasyonunda yerçekimi Dünya\'dakiyle tamamen aynıdır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'Astronotlar kaslarının erimemesi için her gün egzersiz yapar.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Uzay istasyonunda yemekler tabaklarda normal şekilde servis edilir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p41',
      title: 'Ekmeğin Tarihi',
      topic: 'yemek',
      content:
          'Ekmek, insanlık tarihinin en eski ve en temel besinlerinden biridir; binlerce yıl önce eski Mısırlılar tarafından mayalanarak yapılmaya başlanmıştır. Un, su ve mayanın bir araya gelmesiyle oluşan hamur, fırınlanarak bugün bildiğimiz ekmeğe dönüşür. Dünyanın farklı bölgelerinde farklı ekmek çeşitleri gelişmiştir; örneğin Fransa\'da baget, Hindistan\'da naan öne çıkar. Ekmek, günümüzde de dünyanın hemen her sofrasında yer alan vazgeçilmez bir besindir.\n\n'
          'Mayanın hamuru kabartması, aslında canlı mikroskobik mantarların hamurdaki şekeri sindirmesi ve bu sırada gaz üretmesiyle gerçekleşir; bu gaz hamurun içinde küçük kabarcıklar oluşturarak ekmeği yumuşacık yapar. Mayanın keşfedilmesinden önce insanlar, kabarmayan daha düz ve sert ekmekler yapıyordu; bu ekmekler bugün bile bazı kültürlerde tercih edilmektedir.\n\n'
          'Türkiye\'de de yöreden yöreye değişen birçok ekmek çeşidi bulunur; bazı bölgelerde ince ve yuvarlak, bazı bölgelerde ise kalın ve kabarık ekmekler pişirilir. Birçok kültürde ekmek paylaşmak, misafirperverliğin ve dostluğun bir simgesi olarak kabul edilir.',
      questions: [
        {
          'question':
              'Ekmek eski Mısırlılar tarafından mayalanarak yapılmaya başlanmıştır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Dünyanın her yerinde sadece tek bir çeşit ekmek yapılır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Baget, Fransa\'da öne çıkan bir ekmek çeşididir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Ekmek hamuru fırınlanmadan doğrudan yenir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p42',
      title: 'Dünya Mutfaklarından Lezzetler',
      topic: 'yemek',
      content:
          'Her ülkenin mutfağı, o toplumun kültürünü, iklimini ve tarihini yansıtır. İtalya\'da makarna ve pizza öne çıkarken, Japonya\'da suşi ve ramen çok sevilen yemeklerdendir. Baharatlar, yemeklere hem lezzet hem de renk katar; örneğin Hindistan mutfağında köri baharatı sıkça kullanılır. Farklı mutfakları tatmak, bir ülkeyi ziyaret etmeden de o kültürü tanımanın keyifli bir yoludur.\n\n'
          'Türk mutfağı da dünyaca tanınan zengin bir mutfaktır; kebaplar, mantı ve baklava gibi lezzetler birçok ülkede sevilerek tüketilir. Bir bölgenin mutfağı genellikle o bölgede yetişen ürünlere göre şekillenir; örneğin sahil kesimlerinde balık, tarım arazilerinde ise tahıl ve sebze ağırlıklı yemekler öne çıkar.\n\n'
          'Sokak lezzetleri de bir kültürü tanımanın keyifli bir yoludur; Meksika\'da taco, Tayland\'da pad thai gibi yemekler o ülkenin sokaklarında kolayca bulunabilir. Yemek tarifleri, göç eden insanlar ve ticaret yoluyla ülkeler arasında yayılarak zamanla birbirini etkilemiş ve zenginleştirmiştir.',
      questions: [
        {
          'question': 'Her ülkenin mutfağı o toplumun kültürünü yansıtır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Suşi, İtalyan mutfağının bir parçasıdır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Baharatlar yemeklere lezzet ve renk katar.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Köri baharatı Japon mutfağında sıkça kullanılır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p43',
      title: 'Meyvelerin Faydaları',
      topic: 'yemek',
      content:
          'Meyveler, vücudumuzun ihtiyaç duyduğu vitamin ve lifleri doğal yoldan almamızı sağlayan besinlerdir. Portakal ve çilek gibi meyveler C vitamini bakımından zengindir ve bağışıklık sistemimizi güçlendirir. Meyvelerdeki lifler, sindirim sistemimizin düzenli çalışmasına yardımcı olur. Günde birkaç porsiyon meyve tüketmek, sağlıklı bir yaşamın basit ama etkili yollarından biridir.\n\n'
          'Her mevsimin kendine has meyveleri vardır; yazın karpuz ve kayısı, kışın ise mandalina ve nar sofralarımızı süsler. Mevsiminde yetişen meyveleri tercih etmek, hem daha lezzetli hem de genellikle daha uygun fiyatlı olur. Meyvelerdeki şeker doğal olduğu için işlenmiş şekerli atıştırmalıklara göre vücudumuz tarafından daha dengeli bir şekilde kullanılır.\n\n'
          'Bir meyveyi suyunu sıkarak içmek yerine bütün olarak yemek, içindeki değerli lifleri de almamızı sağlar. Acıktığımızda cips ya da şekerleme yerine bir meyve tercih etmek, hem açlığımızı giderir hem de vücudumuza daha fazla fayda sağlar.',
      questions: [
        {
          'question': 'Portakal ve çilek C vitamini bakımından zengindir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Meyvelerdeki lifler sindirim sistemine hiçbir katkı sağlamaz.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'Günde birkaç porsiyon meyve tüketmek sağlıklı bir alışkanlıktır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Meyveler vücudumuza hiçbir vitamin sağlamaz.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p44',
      title: 'Mevsimlerin Değişimi',
      topic: 'doga',
      content:
          'Dünya\'nın kendi ekseni etrafında eğik durması, mevsimlerin oluşmasının temel nedenidir. Bu eğiklik sayesinde, Dünya Güneş çevresinde dönerken farklı bölgeler farklı zamanlarda daha fazla ya da daha az güneş ışığı alır. İlkbaharda doğa canlanır, yazın sıcaklıklar artar, sonbaharda yapraklar dökülür ve kışın hava soğur. Mevsimler, birçok hayvanın göç etme ya da kış uykusuna yatma zamanını da belirler.\n\n'
          'İlginç bir şekilde, Dünya\'nın kuzey ve güney yarım küreleri aynı anda farklı mevsimler yaşar; biz yazı yaşarken güney yarım kürede kış hüküm sürer. Sonbaharda yaprakların renk değiştirmesinin nedeni, yapraklardaki yeşil renk veren klorofil maddesinin azalması ve altında gizli olan sarı, turuncu tonların ortaya çıkmasıdır.\n\n'
          'Ayılar ve kirpiler gibi bazı hayvanlar, besin bulmanın zorlaştığı kış aylarında enerji harcamamak için kış uykusuna yatar. Ekvatora yakın bölgelerde ise güneş ışığı yıl boyunca daha eşit dağıldığından mevsimler arasındaki fark çok daha az hissedilir.',
      questions: [
        {
          'question':
              'Mevsimlerin oluşmasının temel nedeni Dünya\'nın ekseninin eğik olmasıdır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Bütün bölgeler Güneş\'ten her zaman aynı miktarda ışık alır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Mevsimler bazı hayvanların göç etme zamanını belirler.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Mevsimler hayvanların davranışlarını hiç etkilemez.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p45',
      title: 'Su Döngüsü',
      topic: 'doga',
      content:
          'Su döngüsü, suyun Dünya üzerinde sürekli olarak buharlaşıp yağış hâlinde geri dönmesini sağlayan doğal bir sistemdir. Güneşin ısısıyla denizlerdeki ve göllerdeki su buharlaşarak gökyüzüne yükselir ve bulutları oluşturur. Bulutlar soğuduğunda, içindeki su damlacıkları yağmur ya da kar olarak yeryüzüne düşer. Bu döngü sayesinde Dünya\'daki su miktarı hiç azalmadan sürekli yeniden kullanılır.\n\n'
          'Bitkiler de bu döngüye katkıda bulunur; kökleriyle topraktan aldıkları suyu yapraklarından buhar hâlinde havaya bırakır, bu sürece terleme (transpirasyon) denir. Yağan yağmur suyunun bir kısmı toprağa sızarak yer altı sularını beslerken, bir kısmı da dereler ve nehirler aracılığıyla tekrar denizlere ulaşır.\n\n'
          'İçtiğimiz su, aslında milyonlarca yıldır bu döngü içinde defalarca dönüşüp durmuş aynı sudur. Suyu israf etmemek, örneğin diş fırçalarken musluğu kapalı tutmak, bu değerli ve sınırlı kaynağın herkes için yeterli kalmasına küçük ama önemli bir katkı sağlar.',
      questions: [
        {
          'question': 'Su döngüsünde su buharlaşıp yağış hâlinde geri döner.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Bulutlar suyun hiçbir aşamasında rol oynamaz.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'Su döngüsü sayesinde Dünya\'daki su sürekli yeniden kullanılır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Su döngüsünde Dünya\'daki su miktarı giderek azalır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p46',
      title: 'İnternetin Doğuşu',
      topic: 'teknoloji',
      content:
          'İnternet, başlangıçta 1960\'larda bilgisayarların birbirleriyle bilgi paylaşabilmesi için askeri ve akademik amaçlarla geliştirilmiştir. Zamanla bu ağ genişleyerek dünyanın dört bir yanındaki milyonlarca bilgisayarı birbirine bağlayan devasa bir sisteme dönüşmüştür. World Wide Web\'in 1990\'larda icat edilmesiyle internet, sıradan insanların da kolayca kullanabileceği bir araç haline geldi. Bugün internet, bilgiye ulaşmaktan iletişim kurmaya kadar hayatımızın her alanında yer almaktadır.\n\n'
          'Bir mesaj gönderdiğimizde ya da bir web sitesi açtığımızda, bilgi aslında küçük parçalara (veri paketlerine) bölünerek kablolar, fiber hatlar ve hatta uydular aracılığıyla saniyeler içinde dünyanın öbür ucuna ulaşabilir. Bu sayede binlerce kilometre uzaktaki biriyle anında haberleşebiliriz.\n\n'
          'İnternet sayesinde bilgiye ulaşmak çok kolaylaşsa da, karşılaştığımız her bilginin doğru olduğunu varsaymamak önemlidir; güvenilir kaynakları tanımayı öğrenmek, internetin en değerli kullanım becerilerinden biridir. İnterneti güvenli ve bilinçli kullanmak, hem kişisel bilgilerimizi korumamıza hem de zamanımızı verimli değerlendirmemize yardımcı olur.',
      questions: [
        {
          'question':
              'İnternet başlangıçta askeri ve akademik amaçlarla geliştirilmiştir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'World Wide Web 1800\'lerde icat edilmiştir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'İnternet günümüzde hayatımızın her alanında yer almaktadır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'İnternet en başından beri herkesin kolayca kullanabileceği bir araç olmuştur.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p47',
      title: 'Akıllı Telefonların Gelişimi',
      topic: 'teknoloji',
      content:
          'İlk cep telefonları sadece arama yapmak için kullanılırken, günümüzün akıllı telefonları birer mini bilgisayar haline gelmiştir. Kamera, internet tarayıcısı, harita ve binlerce uygulama artık cebimizdeki bu tek cihazda toplanmış durumda. Dokunmatik ekran teknolojisi, telefonların kullanımını çok daha kolay ve sezgisel hale getirmiştir. Akıllı telefonlar sayesinde insanlar artık dünyanın her yerinden anında bilgiye ulaşabilmektedir.\n\n'
          'İlk cep telefonları bugünkülerden çok daha büyük ve ağırdı; bazıları neredeyse bir tuğla kadar yer kaplıyordu ve sadece birkaç saat konuşma imkânı sunuyordu. Modern akıllı telefonların içinde, telefonun hareketini algılayan sensörler ve konumunu bulan uydu alıcıları gibi birçok gizli teknoloji bulunur.\n\n'
          'Telefon kameraları öylesine gelişmiştir ki artık herkes profesyonel ekipmana ihtiyaç duymadan kaliteli fotoğraflar çekebilir. Bu kadar çok işe yaraması, akıllı telefonları hayatımızın vazgeçilmez bir parçası yapsa da, ekran karşısında geçirilen zamanı dengelemek ve göz sağlığına dikkat etmek de bir o kadar önemlidir.',
      questions: [
        {
          'question':
              'İlk cep telefonları sadece arama yapmak için kullanılırdı.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Akıllı telefonlarda dokunmatik ekran teknolojisi kullanılmaz.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'Akıllı telefonlar sayesinde insanlar anında bilgiye ulaşabilir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'İlk cep telefonları kamera ve internet tarayıcısıyla gelirdi.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'p48',
      title: 'Mimar Sinan: Ustaların Ustası',
      topic: 'biyografi',
      content:
          'Mimar Sinan, 16. yüzyılda yaşamış, Osmanlı Devleti\'nin en usta mimarlarından biridir. Süleymaniye Camii ve Selimiye Camii gibi birçok görkemli yapıyı tasarlayarak mimarlık tarihine adını altın harflerle yazdırmıştır. Sinan, yapılarında hem estetiği hem de depreme dayanıklılığı bir araya getirmeyi başarmış, bu yüzden eserlerinin çoğu günümüze kadar sapasağlam ulaşmıştır. Kendisi "ustalık eserim" olarak nitelendirdiği Selimiye Camii\'ni Edirne\'de inşa etmiştir.\n\n'
          'Sinan, mimarlığa başlamadan önce orduda inşaat ve mühendislik işleriyle uğraşmış, köprüler ve yollar yaparak büyük bir tecrübe kazanmıştır. Bu mühendislik bilgisi, sonradan tasarladığı büyük kubbeli yapıların sağlam ve dengeli durmasında ona büyük avantaj sağlamıştır.\n\n'
          'Uzun ve verimli mesleki hayatı boyunca cami, köprü, çeşme ve saray gibi üç yüzden fazla yapıya imza attığı bilinmektedir. Sinan\'ın geliştirdiği kubbe destekleme yöntemleri, kendisinden sonra gelen mimarlara da ilham kaynağı olmuş ve dünya mimarlık tarihinde önemli bir yer edinmesini sağlamıştır.',
      questions: [
        {
          'question': 'Mimar Sinan, Süleymaniye Camii\'ni tasarlamıştır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Mimar Sinan\'ın eserlerinin hiçbiri günümüze ulaşmamıştır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'Sinan, Selimiye Camii\'ni kendi "ustalık eserim" olarak nitelendirmiştir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Mimar Sinan hiçbir camiyi tasarlamamıştır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),

    // Seviyeye göre hız ölçme metni: Nurullah Ataç'ın "Kitaba Hürmet"
    // denemesinin ilkokul/ortaokul/lise seviyelerine göre uyarlanmış üç
    // hali. Normal konu havuzunun dışında tutuluyor (topic: 'kitaba-hurmet'
    // ComprehensionData.topics içinde yok) — sadece seviye seçiciyle
    // erişiliyor.
    ReadingPassage(
      id: 'kh-ilkokul',
      title: 'Kitaba Hürmet',
      topic: 'kitaba-hurmet',
      level: 'ilkokul',
      content:
          'Okumayı sever misiniz? Böyle bir soru olur mu hiç? Elbette '
          'seversiniz. Sevmeseydiniz bu yazıyı okuyor olmazdınız. Bir '
          'yazarın seslendiği kişiler, kesinlikle okumayı seven '
          'insanlardır. Ama kimisi az okur, kimisi çok. Benim asıl merak '
          'ettiğim şu: Siz az okuyanlardan mısınız, yoksa çok '
          'okuyanlardan mı? Eğer az okuyorsanız, kendinize haksızlık '
          'ediyorsunuz demektir. Çünkü az okumak, neredeyse hiç '
          'okumamak gibidir. Sizi harika bir kitap dostu olmaya '
          'çağırıyorum. Dünyada kitaptan daha güzel ne olabilir ki? '
          'İşte önünüzde iki yüz, üç yüz sayfalık bir kitap duruyor. Ne '
          'anlattığını henüz bilmiyorsunuz. Yalnızca adını ve yazarını '
          'görüyorsunuz. Hemen kapağını açın! Belki de içinde '
          'sevinçleri, üzüntüleri ve meraklarıyla sizi kendine çekecek '
          'insanlarla tanışacaksınız. Onlarla saatlerce, belki '
          'günlerce birlikte yaşayacaksınız. Onların sırlarını '
          'öğrenecek, üzüntülerine üzülüp sevinçleriyle mutlu '
          'olacaksınız. Hatta en zor günlerinizden birinde, bir roman '
          'kahramanının yanınıza gelip size destek olduğunu bile '
          'hissedebilirsiniz. Çok okuyan, kitaplarla vakit geçiren bir '
          'insan hayatı boyunca asla yalnız kalmaz. Okuyun! Ne '
          'bulursanız okuyun. En azından bir kere açıp bakın. '
          'Beğenmediniz mi? Bırakmak çok kolay! Ama diyeceksiniz ki: '
          '"Kitaplara para veriyoruz, aldanmak istemeyiz. Alacağımız '
          'kitaplar kaliteli olmalı." Gel gelelim şu para meselesine... '
          'Bir kitaba ya da dergiye verdiğiniz para ile ondan aldığınız '
          'mutluluğu kıyaslayabilir misiniz? Beğendiğiniz bir kitabın '
          'kahramanlarıyla tanışmanın değerini parayla ölçebilir '
          'misiniz? Bir dergi alırsınız; resimlerine bakar, yazılarını '
          'okur ve yeni şeyler öğrenirsiniz. Bütün bu kazandıklarınız '
          'ile ödediğiniz küçük bir miktar para arasında hiçbir ilişki '
          'yoktur. Zaten hiçbir kitabın veya yazının gerçek değeri '
          'parayla ölçülemez. Verdiğiniz para, sadece o kitabın '
          'basılmasına katkı sağlamaktır. Güzel kitapların '
          'yazılabilmesi için her türlü kitabın basılması gerekir. '
          'Hayatım boyunca kaç kitap okudum bilmiyorum. Ama '
          'içlerinden elli, belki de yüz tanesi zihnimde ve kalbimde '
          'yaşamaya devam ediyor. Diğerlerini okuduğum için de hiç '
          'pişman değilim. Hatta kötü olduğunu anlayıp yarıda '
          'bıraktığım kitaplar için bile üzülmüyorum. Aldığı on '
          'kitaptan biri bile çok iyi çıkan insan şanslı sayılır. Kitap '
          'alın ve okuyun! Şunu da bilin ki, hiçbir yazar sizi '
          'kandırmak için yazmaz. Kötü yazan bir yazar bile eserinin '
          'çok iyi olduğuna inanır. Siz birkaç liranızı verirsiniz, o '
          'ise yıllarını ve emeğini verir. Ben bu kısa yazıyı yazmak '
          'için saatlerimi veriyorum. Siz belki beş dakikada okuyup '
          'bitireceksiniz. Bir roman yazarı ise aylarını bu işe '
          'ayırıyor. Sırf vakit geçirmek için bir kitaba şöyle bir göz '
          'atıp geçmek doğru olur mu? Yazıyı beğenmek zorunda '
          'değilsiniz ama dikkatle okumalısınız. Çünkü yazar, sizi '
          'güldürmek isterken bile size faydalı olmaya çalışır. Eğer '
          'bir yazarı ve kitabını ciddiye almazsanız, kitap da size '
          'küser ve içindeki güzellikleri sizinle paylaşmaz. O zaman '
          'kitap okumuş olmazsınız; sadece yazılı kâğıtlara bakıp '
          'gözlerinizi yormuş olursunuz. Kitap okurken beğendiğiniz '
          'cümleleri yazmak isterseniz not da alabilirsiniz. Ama hiç '
          'acele etmeyin; çünkü yeni dostunuz olan kitap her zaman '
          'yanınızda duruyor ve hiçbir yere kaçmıyor.\n\n— Nurullah '
          'Ataç',
      questions: [
        {
          'question': 'Yazar, insanları kitap okumaya davet etmektedir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Yazara göre, bir kitabın değeri sadece ödenen parayla ölçülür.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Yazara göre az okumak, neredeyse hiç okumamak gibidir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Yazı, kitap okumanın zararlı olduğunu anlatmaktadır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'kh-ortaokul',
      title: 'Kitaba Hürmet',
      topic: 'kitaba-hurmet',
      level: 'ortaokul',
      content:
          'Okumayı sever misiniz? Böyle bir soru olur mu hiç? Elbette '
          'seversiniz. Sevmeseydiniz bu yazıyı elinize almaz, bu '
          'satırları okumazdınız. Bir yazarın seslendiği kitle, '
          'kesinlikle okumayı seven insanlardan oluşur. Ancak kimimiz '
          'çok okuruz, kimimiz az. Benim asıl merak ettiğim soru şu: '
          'Siz az okuyanlardan mısınız, yoksa çok okuyanlardan mı? '
          'Eğer az okuyan taraftaysanız kendinize haksızlık '
          'ediyorsunuz demektir. Çünkü az okumak, neredeyse hiç '
          'okumamakla eş değerdir. Sizi gerçek bir kitap dostu olmaya '
          'davet ediyorum. Şu dünyada kitaptan daha güzel ne '
          'olabilir? Önünüzde iki yüz, üç yüz sayfalık bir kitap '
          'duruyor diyelim... Ne anlattığını henüz bilmiyorsunuz, '
          'sadece adını ve yazarını görüyorsunuz. Hiç durmayın, açın '
          'kapağını! Belki de içinde sevinçleri, üzüntüleri, sevgileri '
          'ya da nefretleriyle sizi kendine çekecek karakterlerle '
          'tanışacaksınız. Onlarla günlerce birlikte yaşayacak, '
          'sırlarına ortak olacaksınız. Üzüntülerine üzülüp '
          'başarılarıyla sevineceksiniz. Hatta en zor gününüzde bir '
          'roman kahramanının zihninizde belirip size, "Yalnız '
          'değilsin, ben de benzer şeyler yaşadım!" dediğini '
          'duyabilirsiniz. Çok okuyan ve kitapların sunduğu dünyalara '
          'inanan bir insan, hayatı boyunca asla yalnızlık çekmez. '
          'Okuyun; ne bulursanız okuyun. En azından bir şans verip '
          'kapağını açın. Beğenmediniz mi? Bırakmak zor değil ya! Ama '
          'diyeceksiniz ki: "Parayla alıyoruz, aldanmak istemeyiz; '
          'aldığımız kitaplar kaliteli olmalı." Gelin şu para ve '
          'aldanma konusunu biraz konuşalım. Bir kitaba veya dergiye '
          'ödediğiniz miktar ile ondan aldığınız zevk ve bilgi '
          'arasında bir oran kurabilir misiniz? Beğendiğiniz bir '
          'romanın dünyasına girmek parayla ölçülebilir mi? Bir '
          'dergi alırsınız; resimlerine bakar, yazılarını okur, belki '
          'yeni bir şey öğrenir ya da düşüncelerinizi sorgularsınız. '
          'Bütün bu zihinsel kazanımlar ile ödediğiniz küçük miktar '
          'arasında bir ilişki kurmak imkânsızdır. Hiçbir kitabın '
          'veya yazının gerçek değeri parayla ölçülemez. Verdiğiniz '
          'ücret, yalnızca o eserin basılmasına ve edebiyat '
          'dünyasının yaşamasına sağladığınız bir katkıdır. İyi '
          'kitapların yazılabilmesi için zayıf örneklerin de var '
          'olması gerekir. Hayatım boyunca kaç kitap okuduğumu '
          'hatırlamıyorum. Fakat bunların içinden belki elli, belki '
          'yüz tanesi zihnimde ve ruhumda yaşamaya devam ediyor. '
          'Diğerlerinin de mutlaka faydası oldu, üzerimde iz '
          'bıraktılar. Hiçbirini okuduğuma pişman değilim; hatta ilk '
          'sayfasında kötü olduğunu anlayıp kenara koyduğum kitaplar '
          'için bile üzülmüyorum. Aldığı on kitaptan biri bile harika '
          'çıkan insan şanslı sayılır. Şunu da unutmayın: Hiçbir '
          'yazar okurunu kandırmak için kaleme sarılmaz. En zayıf '
          'yazan bile eserinin nitelikli olduğuna inanır. Siz en '
          'fazla küçük bir miktar paranızı riske atarsınız, yazar ise '
          'aylarını, hatta yıllarını verir. Ben bu kısa yazıyı '
          'hazırlamak için saatlerimi harcıyorum; siz ise belki '
          'beş-on dakikada okuyup bitireceksiniz. Bir roman yazarı '
          'ise aylarını o yapıta adıyor. Dolayısıyla bir yazara veya '
          'romana sırf vakit geçirme aracı gözüyle bakmak doğru bir '
          'yaklaşım değildir. Yazarı beğenmek zorunda değilsiniz '
          'elbette; ancak ona ve emeğine saygı duyarak, ciddiyetle '
          'okumalısınız. Yazar sizi güldürmeyi amaçladığında bile '
          'aslında zihninize ve ruhunuza hizmet ediyordur. Eğer bir '
          'yazarı ve eserini ciddiye almazsanız, kitap da size küser '
          've derinindeki sırları sizinle paylaşmaz. O zaman okumuş '
          'olmazsınız; yalnızca yazılı kâğıtlar üzerinde gözlerinizi '
          'yormuş olursunuz. Okurken beğendiğiniz cümlelerin altını '
          'çizebilir veya not alabilirsiniz. Ancak acele etmeyin; '
          'dostunuz olan kitap başucunuzda duruyor ve hiçbir yere '
          'kaçmıyor.\n\n— Nurullah Ataç',
      questions: [
        {
          'question': 'Yazar, insanları kitap okumaya davet etmektedir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Yazara göre, bir kitabın değeri sadece ödenen parayla ölçülür.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Yazara göre az okumak, neredeyse hiç okumamak gibidir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Yazı, kitap okumanın zararlı olduğunu anlatmaktadır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'kh-lise',
      title: 'Kitaba Hürmet',
      topic: 'kitaba-hurmet',
      level: 'lise',
      content:
          '— Okumayı sever misiniz? Böyle soru olur mu? Elbette '
          'seversiniz; eğer sevmeseydiniz bu gazeteyi almaz, bu '
          'satırları okumazdınız. Her kim olursa olsun bir yazarın '
          'hitap ettiği kimseler muhakkak okumayı seven kimselerdir. '
          'Ama kimisi çok kimisi az okur. Ben de sorumu sorarken '
          'bilhassa bunu öğrenmek istiyordum: Az okuyanlardan '
          'mısınız, çok okuyanlardan mı? Birinci sınıftansanız '
          'haksızsınız; çünkü az okumak, hemen hemen hiç '
          'okumamakla birdir. Sizi bir kitap dostu olmaya davet '
          'ediyorum. Dünyada kitaptan güzel ne vardır ki? İşte '
          'önünüzde iki yüz, üç yüz sayfalık bir kitap... Ne '
          'olduğunu, neden bahsettiğini bilmiyorsunuz. Yalnız ismini '
          'görüyorsunuz. Yazarını da tanımıyorsunuz. Sadece '
          'biliyorsunuz ki bir romandır. Hiç durmadan açın, belki '
          'içinde elemleri, sevinçleri, muhabbetleri veya nefretleri '
          'sizi alakadar edecek bir veya birkaç insanla '
          'tanışacaksınız. Onlarla birkaç saat veya birkaç gün '
          'beraber yaşayacak, onların sırlarını -belki '
          'kendinizkinden de daha iyi- öğreneceksiniz. Onların belki '
          'de dostu olacaksınız, onların kederlerine ağlayacak, '
          'saadetleri ile sevineceksiniz. Onlar da sizin dostunuz '
          'olacak, en ıstıraplı günlerinizden birinde bir roman '
          'kahramanlarının size geldiğini görebilir, "Bilmez misin? '
          'Ben de senin gibi idim!" dediğini duyabilirsiniz. Çok '
          'okuyan, hikâye ve romanlarla geçen saatlerin '
          'kaybolmadığına inanan adam ömründe asla yalnız kalmaz. '
          'Okuyun, ne bulursanız okuyun; hiç olmazsa bir kere açın. '
          'Çok mu fena buldunuz? Bırakması zor değil ya!... Ama '
          'diyeceksiniz ki, para veriyorsunuz, aldanmak '
          'istemezsiniz, alacağınız kitaplar değerli olmalı... Şu '
          'para ve aldanmak meselesinden bahsedelim. Aldığınız '
          'kitaba nihayet on, on beş; dergiye de beş yahut en fazla '
          'yedi lira vermiyor musunuz? Bunu da yerine sarf etmek '
          'iddiasındasınız. Okuduğunuz kitap, dergi iyi ise ondan '
          'aldığınız zevk ile verdiğiniz para arasında bir '
          'münasebet var mıdır? Beğendiğiniz bir romanın şahısları '
          'ile tanışmak yüz elli kuruş mu eder? On kuruş verip bu '
          'mecmuayı aldınız. Birtakım resimler gördünüz, yazılar '
          'okudunuz, belki bir şey öğrendiniz, belki düşüncelerinize '
          'uymayan sözlerle karşılaşıp sinirlendiniz ve bu suretle '
          'belki kanaatleriniz biraz sarsıldı veya kuvvet buldu. '
          'Bütün bunlarla o beş-on lira arasında, sorarım size, bir '
          'nispet kurmak imkânı var mı? Hayır, siz on lira ile bir '
          'kitabın, beş lira ile bir derginin hakiki değerini vermiş '
          'olmuyorsunuz. Zaten hiçbir kitabın, yazının para ile '
          'ölçülecek bir değeri yoktur. Verdiğiniz para bir iştirak '
          'bedelidir. Kitabın yazılmasını, derginin çıkmasını mümkün '
          'kılmak isteyenlerin arasına karışıyorsunuz. İyi kitap '
          'yazılması için, iyi dergi çıkması için fenalarının da '
          'bulunması lazımdır. Bilin ki, güzel yazı adeta bir '
          'mucizedir; fakat bu mucizeyi etrafı hazırlar. Ömrümde kaç '
          'kitap okudum bilmiyorum; fakat bütün bunlardan belki '
          'kırk, elli nihayet yüz tanesi içimde yaşar. Öbürleri... '
          'Elbette onların da faydası oldu, onlar da izini bıraktı. '
          'Hiçbirini okuduğuma pişman değilim; hatta fena olduğu '
          'daha ilk sahifede anlaşıldığı için attığım kitapları '
          'aldığıma da pişman değilim. Aldığı on kitaptan yalnız bir '
          'tanesi iyi olan adam bahtiyar sayılır. Kitap alın, okuyun, '
          'beğenirseniz devam edersiniz; fakat bilin ki iyiler '
          'fenaların, fenalar iyilerin sayesinde yazılıp neşredilir. '
          'Aldanmak... Tersini bile bile aldatan yazar yok gibidir. '
          'En fena yazan bile eserinin iyi olduğuna emindir ve sizi '
          'aldatmak istemez. Zavallı, kendisi aldanıyordur. Siz '
          'aldanıp beş-on lira veriyorsunuz; o aldanıp ömrünü '
          'veriyor. Kim daha ziyanda? Ben, derginizde nihayet bir '
          'sayfa tutacak bu satırları ne kadar zamanda yazıyorum? '
          'Hiç olmazsa bir saatim gidiyor. Siz belki on dakikada, '
          'hatta beş dakikada okuyuvereceksiniz. Yalnız bir saatim '
          'mi? Hayır, elbette her satırda bütün ömrümün, bütün '
          'okuduklarımın bir hissesi var. Roman yazan bir saatte de '
          'bitirmiyor, haftalarını, aylarını o işe bağlıyor ve '
          'kendisi kadar size, kendisinden ziyade size hizmet '
          'ediyor. Benim yazıma veya onun romanına yalnız vakit '
          'geçirmek maksadıyla bir göz atmak hakkınız mıdır? '
          'Beğenmeye mecbursunuz demiyoruz; fakat dikkatlice '
          'okumaya başlayın, bizi okurken ciddi bir iş gördüğünüzü '
          'bilin. Bizim hakkımızda vereceğiniz hüküm ağır olabilir. '
          '"Bir para etmez" diye elinizden atabilirsiniz; fakat '
          'eğlenmek için okumayın, çünkü ben de o da sizinle '
          'eğlenmek için yazmıyoruz. Söylediklerimizi, '
          'yazdıklarımızı beğenirseniz dikkatle okuyun ki '
          'unutmayasınız. Size not alın, kitapların altını çizin '
          'demiyorum; onu ben de sevmem. Dikkatle, ciddiyetle '
          'okumanız kâfidir, yani kitap veya mecmua okuduğunuz '
          'zaman elinizdeki yazı tuhaf varlık vakalar bile '
          'anlatıyorsa, ciddi bir iş gördüğünüze inanın. Çünkü yazar '
          'sizi güldürmek istediği zaman bile, size hizmet etmek '
          'ister. Ama bu hizmet eşit adamlar arasındaki hizmettir; '
          'siz yazarı kendinizden küçük görür, onu ciddiye almaz ve '
          'eserlerini ancak vakit geçirmek için bir vasıta '
          'sayarsanız, o da size küser ve yazısı, size sırlarını '
          'vermez. O zaman kitap okumuş olmazsınız; bütün yaptığınız '
          'birtakım karalamış kâğıtlarla göz yormaktan ibaret kalır. '
          'Not almak da olur; fakat beğendiğiniz cümle sizi bizzat '
          'buna mecbur etmeli. O zaman kalkar, kâğıt kalem arar, '
          'yazarsınız. Ama acele etmeyin, kitap, dergi yani '
          'dostunuz yanınızda, kaçmıyor, kaçmayacak...\n\n— '
          'Nurullah Ataç',
      questions: [
        {
          'question': 'Yazar, insanları kitap okumaya davet etmektedir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Yazara göre, bir kitabın değeri sadece ödenen parayla ölçülür.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Yazara göre az okumak, neredeyse hiç okumamak gibidir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question': 'Yazı, kitap okumanın zararlı olduğunu anlatmaktadır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),

    // Seviyeye göre Son Metin (son test) havuzu — "Hayatına Kitap Okuyarak
    // Hareket Kat!" metninin ilkokul ve ortaokul/lise seviyelerine göre
    // uyarlanmış halleri. Ortaokul ve lise için hoca AYNI metni verdi.
    ReadingPassage(
      id: 'st-ilkokul',
      title: 'Hayatına Kitap Okuyarak Hareket Kat!',
      topic: 'son-test',
      level: 'ilkokul',
      isFinalTest: true,
      content:
          'Evrende her şey hareket eder. Yıldızlar, gezegenler, ağaçlar ve '
          'canlı-cansız bütün varlıklar... Hareketsiz duran hiçbir şey '
          'yoktur. Nerede bir hareket varsa, orada hayat vardır. Cansız '
          'gördüğümüz taş ve demir bile kendi içinde sistemli bir '
          'harekete sahiptir. Bir atasözümüz şöyle der: "Nerede hareket, '
          'orada bereket." Bu söz hayatın her alanında geçerlidir. '
          'Durarak ve sadece bekleyerek kim hedefine ulaşabilir ki? '
          'Dünyamız, denizlerimiz ve nehirlerimiz sürekli hareket eder. '
          'Zaman bile bir an olsun durmaz. Peki, biz insanlar nasıl '
          'hareketsiz kalabiliriz? Karlı toprağı delip çıkan kardelen '
          'çiçeklerini düşünün... Onlar da hareket hâlindedir. Çünkü '
          'hareket varsa hayat vardır. Durgun kalmak ise gerilemek '
          'demektir. Toprağa can veren sudur. Su olmazsa toprak kurur. '
          'Su geldiğinde ise her yer yeşillenir ve şenlenir. İnsan '
          'bedeni de böyledir. Uzun süre hareketsiz kalırsak '
          'hantallaşırız, çabuk yoruluruz. Spor yapan bir insan canlı '
          've sağlıklıyken, yapmayan insan sürekli yorgun hisseder. '
          'Ancak buradaki tek konu bedenimizin hareketi değil. Asıl '
          'önemli olan zihnimizin ve ruhumuzun hareketidir. İnsan '
          'sadece bedenden ibaret değildir; ruhumuz ve beynimiz de '
          'vardır. Beynimiz hareketsiz kalırsa tıpkı kurak bir toprak '
          'gibi verimsizleşir. Peki, beynimizin pas tutmasını nasıl '
          'önleriz? Tabii ki yeni şeyler öğrenerek! Su toprağa nasıl '
          'can veriyorsa, kitaplar da beynimize öyle can verir. '
          'Faydalı bir kitap okuduğumuzda, bilgilerin ışığı beynimizi '
          'aydınlatır. Bunun yolu da her gün düzenli ve planlı '
          'okumaktan geçer. Bir çiftçinin "Ben tarlamı geçen yıl '
          'suladım, artık sulamama gerek yok" demesi ne kadar '
          'yanlışsa, "Bugün okudum, yarın okumama gerek yok" demek de '
          'o kadar yanlıştır. Başarılı olmak istiyorsak okuma '
          'alışkanlığımızı her gün sürdürmeliyiz. Bir söz vardır: '
          '"Düşüncelerine dikkat et, davranışın olur. Davranışlarına '
          'dikkat et, alışkanlığın olur. Alışkanlıklarına dikkat et, '
          'karakterin olur. Karakterine dikkat et, kaderin olur." İşte '
          'kitaplar, bizim en büyük düşünce kaynağımızdır. Bazen bir '
          'kitap, hatta tek bir cümle bile hayatımızı değiştirebilir. '
          'Zamanını iyi planlayan, okuyan ve çalışan insanlar hayatı '
          'dolu dolu yaşarlar. Gerçekten iz bırakan insanların hayata '
          'attıkları bir imza vardır. Kimi buluşlarıyla, kimi güzel '
          'düşünceleriyle, kimi de dürüstlüğü ve yardımseverliğiyle '
          'unutulmaz olur. Şimdi harekete geçme zamanı! Akan su '
          'tazeliğini korur, akmayan su ise zamanla bozulur. Siz de '
          'hayatınıza kitap okuyarak hareket katın!',
      questions: [
        {
          'question': 'Yazıya göre, hareket olan yerde hayat vardır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Yazıya göre, kitap okumanın beynimize hiçbir faydası yoktur.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question': 'Yazıya göre, okuma alışkanlığı her gün sürdürülmelidir.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Yazıya göre, bir kez okuyup bırakmak yeterlidir, tekrar '
              'okumaya gerek yoktur.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'st-ortaokul',
      title: 'Hayatına Kitap Okuyarak Hareket Kat!',
      topic: 'son-test',
      level: 'ortaokul',
      isFinalTest: true,
      content: _sonTestOrtaokulLiseContent,
      questions: _sonTestOrtaokulLiseQuestions,
    ),
    ReadingPassage(
      id: 'st-lise',
      title: 'Hayatına Kitap Okuyarak Hareket Kat!',
      topic: 'son-test',
      level: 'lise',
      isFinalTest: true,
      content: _sonTestOrtaokulLiseContent,
      questions: _sonTestOrtaokulLiseQuestions,
    ),
  ];

  // Ortaokul ve lise için hoca AYNI son test metnini verdi — tek bir yerde
  // tanımlayıp iki ReadingPassage'da da kullanıyoruz.
  static const String _sonTestOrtaokulLiseContent =
      'Kâinatta her şey hareket halinde… Yıldızlar, gezegenler, ağaçlar, '
      'canlı ve cansız tüm varlıklar. Boş duran hareketsiz duran hiçbir '
      'şey yok. Nerde hareket varsa orda hayat var. Cansız dediğimiz taş '
      've demir gibi cisimlerde bile hareket söz konusu. Bu tür cisimler '
      'atomdan yaratıldığı için onlarda da elektron hareketi vardır. '
      'Cansız varlıklar da, yani hareketsiz dursa da içten içe hareket '
      'halinde. Peki, canlıların en şereflisi, en mükemmeli biz insanlar '
      'ne kadar hareketliyiz? Canlı olduğumuz halde ne kadar canlıyız? '
      'Her günümüz aynı mı geçiyor? Yoksa capcanlı, hareketli günler mi '
      'yaşıyoruz? "Nerde hareket, orda bereket." demiş atalarımız. Bu '
      'söz, ticaret alanında, sosyal alanda, bireysel hayatta, her yerde '
      'geçerlidir bence. Hareketin olmadığı yer; durgunluğun, '
      'beklemenin olduğu yerdir. Durarak, bekleyerek kim hedefine '
      'ulaşmış söyler misiniz? Dünyamız, her an hareket halinde değil '
      'mi? Denizler, nehirler her zaman hareket halinde değil mi? '
      'Güneşimiz ve tüm yıldızlar hareket halinde değil mi? Ya zaman! '
      'Zaman, durmadan hareket halinde değil mi? Öyle iken biz, nasıl '
      'hareketsiz kalabiliriz? Karları delen kardelenler, toprağı yaran '
      'tohumlar hep hareket halinde. Çünkü hareket varsa bereket var; '
      'hareket varsa hayat var. Durgunluğun, gerilemekten hatta '
      'ölmekten farkı yoktur. Bakın, toprağı hareketlendiren, '
      'canlandıran sudur. Allah su vermezse toprak; çorak ve kurak '
      'olarak kalır. Suyla ilkbahar gelir, her yer şenlenir, yeşillenir '
      've canlanır. Yani, su hayattır toprak için. Şimdi de insan '
      'hayatına bakalım. Bedenimiz, uzun süre hareketsiz kalsa '
      'hantallaşır, yağlanır ve ağırlaşır. Böylece hareket hızımız '
      'yavaşlar. Hareket derken sadece sporu kast etmiyorum tabii ki. '
      'Spor bile söz konusu olsa spor yapan ile yapmayan kişiler '
      'arasında bile ne kadar fark olduğunu biliyoruz. Biri hareketli, '
      'canlı, sağlıklı iken; diğeri ise monoton, her zaman yorgun ve '
      'hastalıklı… Doktorların neden her zaman spor yapın, dediğini '
      'şimdi daha iyi anlıyorum. Aslında spordan bahsetmiyorum. '
      'Konumuz "Hayatta hareketlilik." Yani hiçbir iş yapmadan boş '
      'oturmanın ne kadar tehlikeli olduğunu anlatmaya çalışıyorum. '
      'Yalnız, fiziksel hareketsizlik tehlikeli olduğu gibi, ruhsal, '
      'düşünsel hareketsizlik daha tehlikelidir; çünkü insan sadece '
      'fiziksel yapıdan ibaret değildir. Bizim ruhumuz, beynimiz de '
      'var. Oradaki durgunluk, başıboşluk, hedefsizlik fiziksel '
      'hayatımızı doğrudan etkileyeceği gibi, gelecek hayatımızı da '
      'büsbütün etkiler. Beynimiz hareketsiz kalsa, çevikliğini ve '
      'dinamikliğini kaybeder. Kurak bir toprak gibi verimsizleşir. '
      'Peki, "Beynimizin pas tutmasını nasıl önleriz?" derseniz, tabii '
      'ki de her zaman öğrendiğimiz ve öğreneceğimiz bilgilerle... '
      'Bilgi de beynimizin hayat kaynağıdır. Su toprağa nasıl hayat '
      'veriyorsa, ışık yandığında karanlık nasıl kaçıyorsa; bizler de '
      'faydalı bir kitap okuduğumuzda, bilgilerin ışığıyla beynimiz, '
      'canlanır ve aydınlanır. Yani beynimizin de bilgi hareketliliğine '
      'ihtiyacı var. Bunun yolu da sürekli ve planlı olarak okumaktır. '
      'Neden sürekli ve planlı diyorum? Çünkü başarmak için, ilerlemek '
      'için, yükselmek için, bilgi hareketliliğinin sürekli olması '
      'gerekir. "Bugün okudum, yarın okumaya gerek yok." ya da "Okul '
      'bitti, artık kitaplar da bitti." demek çok yanlıştır. Bu durum '
      'şuna benzer: Bir çiftçinin, "Ben tarlamı geçen sene suladım, '
      'artık bundan sonra sulamaya gerek yok." demesine benzer ki, bu '
      'da hayati bir yanlıştır. O çiftçi istediği kadar eksin, ne '
      'yazık ki, ektiğini biçemeyecektir. Okumak da öyledir. Her gün '
      'olmalıdır, her yıl olmalıdır, sürekli olmalıdır. Aksi takdirde '
      'başarılı ve kazançlı bir hayatı zor buluruz. Kısacası, '
      'beynimizin, hayatımızın verimliliği, başarısı, ilacı; bilgi '
      'hareketliliğiyle, yani kitap okumakla sağlanır. Hani "Her şey '
      'düşüncede başlar." diye bir söz var. Gerçekten de çok doğru. '
      'Hatta bir atasözü var, konuyla tamamen örtüşüyor: '
      '"Düşüncelerine dikkat et, davranışın haline gelir; '
      'davranışlarına dikkat et; alışkanlığın haline gelir; '
      'alışkanlığına dikkat et, karakterin olur; karakterine dikkat '
      'et, kaderin olur." Kitaplar en büyük düşünce kaynağıdır. Bir '
      'kitap, hatta bir kitaptan bir söz, bir örnek hayatını '
      'değiştirebilir. Belli bir işi, bir ödevi olan biri için zamanın '
      'çok büyük önemi vardır. Bu tür insanlar başarı odaklı, azimli, '
      'prensipli insanlardır. Dakikaların hatta saniyelerin bile '
      'hesabını yaparlar. Nerde, ne zaman, ne iş yapacakları bellidir. '
      'Monoton bir hayattan uzaktırlar. İşte bu tür insanlar hayatı '
      'yaşarlar. Çünkü hayatı, yaşlanarak yaşayamazsın; hayatı '
      'yaşayarak, çalışarak ve başarılı olarak yaşayabilirsin. '
      'Gerçekten yaşayanların ise, hayata attıkları bir imza vardır. O '
      'imza yıllar geçse de unutulmaz. Kimisi buluşlarıyla hayata '
      'imza atar, kimisi düşünceleriyle, kimisi eserleriyle imza atar, '
      'kimisi başarılarıyla, kimisi dürüstlüğüyle, kimisi '
      'yardımseverliğiyle, kimisi çalışkanlığıyla, kimisi hizmetiyle… '
      'Önemli olan bundan yüz yıl sonra sen olmasan da hayata, '
      'ülkene attığın iyi bir imzanın olmasıdır. Şimdi harekete geçme '
      'zamanı, hareketsizlik ölüm demektir. Akan su değil, akmayan su '
      'kokar. Hayata akan yol alır; akmayan buhar olur, tıpkı akmayan '
      'su gibi yok olur. Hayatına kitap okuyarak ve okuduklarını '
      'uygulayarak hareket kat!';

  static const List<Map<String, dynamic>> _sonTestOrtaokulLiseQuestions = [
    {
      'question': 'Yazıya göre, hareket olan yerde hayat vardır.',
      'answers': ['Doğru', 'Yanlış'],
      'correct': 0,
    },
    {
      'question':
          'Yazıya göre, kitap okumanın beynimize hiçbir faydası yoktur.',
      'answers': ['Doğru', 'Yanlış'],
      'correct': 1,
    },
    {
      'question': 'Yazıya göre, okuma alışkanlığı her gün sürdürülmelidir.',
      'answers': ['Doğru', 'Yanlış'],
      'correct': 0,
    },
    {
      'question':
          'Yazıya göre, bir kez okuyup bırakmak yeterlidir, tekrar okumaya '
          'gerek yoktur.',
      'answers': ['Doğru', 'Yanlış'],
      'correct': 1,
    },
  ];

  /// Verilen konu id'sine ait metinleri döner. Konu null ise ya da o
  /// konuda hiç metin yoksa TÜM havuzu döner (rastgele karışık deneyim).
  static List<ReadingPassage> passagesForTopic(String? topicId) {
    if (topicId == null || topicId.isEmpty) return passages;
    final filtered = passages.where((p) => p.topic == topicId).toList();
    return filtered.isEmpty ? passages : filtered;
  }
}

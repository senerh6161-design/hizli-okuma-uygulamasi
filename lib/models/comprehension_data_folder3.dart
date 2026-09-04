import 'comprehension_data.dart';

/// Klasör 3 oturumuna girince gösterilen ön metin adımında seviyeye göre
/// okunan gerçek antreman metinleri — hocanın verdiği "İlk ve Son Antreman
/// Metni" belgelerinin ilkokul ve ortaokul-lise uyarlamaları. Klasör 1'deki
/// Kitaba Hürmet ve Klasör 2'deki [Folder2ReadingData] ile aynı desen:
/// ayrı bir seviye havuzu, sadece seviye seçiciyle erişiliyor. Ortaokul ve
/// Lise metni aynı olsa da (hoca tek bir "ortaokul-lise" uyarlaması
/// verdi), Klasör 1'deki gibi ayrı iki kart olarak gösteriliyor.
class Folder3ReadingData {
  static const List<ReadingLevel> levels = [
    ReadingLevel(id: 'ilkokul', title: 'İlkokul', emoji: '🎒'),
    ReadingLevel(id: 'ortaokul', title: 'Ortaokul', emoji: '📘'),
    ReadingLevel(id: 'lise', title: 'Lise', emoji: '🎓'),
  ];

  static ReadingPassage? passageForLevel(String levelId) {
    for (final p in levelPassages) {
      if (p.level == levelId) return p;
    }
    return null;
  }

  static const List<ReadingPassage> levelPassages = [
    ReadingPassage(
      id: 'f3-ilkokul',
      title: 'Başarılı İnsanların 5 Harika Özelliği',
      topic: 'egitim',
      level: 'ilkokul',
      content:
          'Hiç düşündünüz mü; çevrenizde veya dünyada harika işler başaran '
          'insanlar bu noktaya nasıl geliyor? Şanslı doğdukları için mi, '
          'yoksa bilmediğimiz gizli bir güçleri olduğu için mi? Cevap çok '
          'basit: Onlar sadece bazı güzel alışkanlıkları hayatlarının bir '
          'parçası haline getiriyorlar.\n\n'
          'Gelin, başarıya ulaşmış insanların 5 ortak özelliğine yakından '
          'bakalım ve bu yolculuğu birlikte keşfedelim!\n\n'
          '1. Öğrenmekten Asla Vazgeçmezler\n'
          'Dünyadaki hiçbir usta, işini bilerek doğmaz. Başarılı insanlar '
          'da en başta birer "çırak" gibi davranır. Yıllarca işin '
          'inceliklerini öğrenir, kendilerini geliştirmek için sorular '
          'sorar ve sürekli çalışırlar. Şunu unutmamalıyız: Öğrenmeyi '
          'bıraktığımız an, geride kalmaya başlarız. Başarıya giden ilk '
          'adım, her zaman öğrenmeye meraklı birer çırak olabilmektir.\n\n'
          'Peki, sadece öğrenmek yeterli midir? Elbette hayır! Doğru '
          'zamanı yakalamak da bir o kadar önemlidir.\n\n'
          '2. Fırsatları Heyecanla Beklerler\n'
          'Başarılı insanlar "Günün birinde şans yüzüme gülerse yaparım" '
          'deyip yan gelip yatmazlar. Onlar zifiri karanlıkta bile '
          'güneşin doğacağını bilir ve o an geldiğinde hazır olmak için '
          'sürekli çalışırlar. Fırsat kapıyı çaldığında onu sıcacık '
          'yataklarında uyuyarak değil, ayakta ve heyecanla karşılarlar. '
          'Yan gelip yatanlar ise fırsatları ancak rüyalarında görür ve '
          'sadece rüyalarıyla avunurlar.\n\n'
          'Fırsatları yakalayıp zirveye ulaşmak harikadır. Fakat asıl '
          'macera şimdi başlıyor!\n\n'
          '3. Zirvede Kalmak İçin Çabalamaya Devam Ederler\n'
          'Onlar için başarı bir varış noktası değil, hiç bitmeyen '
          'keyifli bir yolculuktur. Zirveye çıkmak zordur ama orada '
          'kalmak çok daha zordur. Bunun bilincinde oldukları için '
          'kendilerini sürekli yenilerler. "Ben artık başardım" deyip '
          'durmazlar, işlerini daha iyi nasıl yapacaklarını '
          'araştırırlar. Çünkü bilirler ki; başarı elde edilebilir ama '
          'onu korumak sürekli ilgi ve emek ister.\n\n'
          'Peki, bu uzun yolculukta hiç mi ayakları takılmaz? Elbette '
          'takılır!\n\n'
          '4. Düşünce Fişek Gibi Ayağa Kalkarlar\n'
          'İşte onların en çarpıcı özelliği! Bazen işler yolunda '
          'gitmeyebilir, ayakları tökezleyip düşebilirler. Ama onlar '
          'yere düştüklerinde karanlığa gömülüp ağlamazlar; gökyüzündeki '
          'ışıl ışıl yıldızlara bakıp umutlanırlar. Yaşadıkları hatadan '
          'bir ders çıkarır ve fişek gibi yeniden ayağa kalkarlar. Onlar '
          'için başarısızlık, zafere giden yoldaki birer merdiven '
          'basamağıdır. O basamaklara basmadan zirveye çıkılamaz!\n\n'
          'Hiçbir engelde pes etmeyen bu insanlar, en zor anlarda bile '
          'bir yol bulurlar.\n\n'
          '5. Bahanelerin Arkasına Sığınmazlar\n'
          'Ben buna "Koca Seyit Kuralı" diyorum. Çanakkale Savaşı’nda '
          'Koca Seyit Dedemiz, 215 kiloluk dev mermiyi kaldırırken "Ben '
          'yapamam, gücüm yetmez" diye bahaneler üretmedi. "Yardım '
          'Sen\'dendir Allah\'ım!" diyerek o mermiyi sırtladı ve '
          'imkânsız görüneni başardı.\n\n'
          'Başarılı insanlar "Benim kafam basmıyor, bu iş benden geçti" '
          'demezler. "Sığınma bahanelere, geleceğin olsun şahane!" '
          'kuralıyla hareket ederler. Bilirler ki karamsarlık bir '
          'bataklıktır, ümitsizlik ise kendi hayallerini baltalamaktır. '
          'Nefes aldığımız ve güneş doğduğu sürece her zaman bir çare '
          'vardır.\n\n'
          'Unutmayın sevgili arkadaşlar;\n'
          'Başarı bir tesadüf değildir. İnanarak yola çıkan, bahanelere '
          'sığınmayan ve her gün yeni bir şey öğrenen herkes kendi '
          'hikâyesinin kahramanı olabilir!\n\n'
          '(Cumali Sever)',
      questions: [
        {
          'question':
              'Yazıya göre başarılı insanlar öğrenmekten asla vazgeçmez.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Koca Seyit, ağır mermiyi kaldırırken bahane üretmeden '
              'görevini yapmıştır.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 0,
        },
        {
          'question':
              'Yazıya göre başarılı insanlar fırsat geldiğinde onu '
              'uyuyarak karşılar.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
        {
          'question':
              'Yazıya göre başarısızlığa uğrayan biri asla yeniden ayağa '
              'kalkamaz.',
          'answers': ['Doğru', 'Yanlış'],
          'correct': 1,
        },
      ],
    ),
    ReadingPassage(
      id: 'f3-ortaokul',
      title: 'Başarının Şifreleri: Zirveye Uzanan 5 Adım',
      topic: 'egitim',
      level: 'ortaokul',
      content: _ortaokulLiseContent,
      questions: _ortaokulLiseQuestions,
    ),
    ReadingPassage(
      id: 'f3-lise',
      title: 'Başarının Şifreleri: Zirveye Uzanan 5 Adım',
      topic: 'egitim',
      level: 'lise',
      content: _ortaokulLiseContent,
      questions: _ortaokulLiseQuestions,
    ),
  ];

  // Ortaokul ve Lise için hoca aynı metni verdi — hoca ileride ayrı bir
  // Lise uyarlaması paylaşırsa yalnızca bu değişkeni ayırmak yeterli.
  static const String _ortaokulLiseContent =
      'Çevrenize şöyle bir bakın; tarihe adını yazdırmış şahsiyetler, '
      'çağ açıp kapatan dâhiler ya da hayallerinin peşinden koşan '
      'bilim insanları... Bu insanları “başarılı” kılan şey doğuştan '
      'gelen gizemli bir yetenek mi, yoksa tesadüfler mi? Aslında '
      'cevap sandığımızdan çok daha açık: Başarı, tesadüflerin '
      'değil; doğru alışkanlıkların ve sarsılmaz bir iradenin '
      'eseridir.\n\n'
      'Gelin, insanlığın seyrini değiştiren isimlerin izinden '
      'giderek başarılı insanların 5 temel özelliğini ve bu '
      'özelliklerin aralarındaki güçlü bağı birlikte keşfedelim.\n\n'
      '1. İşin Çilesini Çeker, Çıraklığını Yapmadıkları İşin Ustası '
      'Olamazlar\n'
      'Hiç kimse bu dünyaya zirvede başlamaz. Başarılı insanlar '
      'hayata her zaman bir "çırak" alçakgönüllülüğüyle bakar. '
      'Yıllarca işin çilesini çeker, inceliklerini öğrenir ve '
      'kendilerini kesintisiz bir öğrenme sürecine adarlar. Şunu '
      'unutmamak gerekir ki; öğrenmeyi bıraktığımız an, gelişimi de '
      'durdurmuş oluruz.\n\n'
      'Sibernetiğin kurucusu büyük Müslüman bilim insanı El-Cezeri, '
      'otomatik makineler ve robotlar tasarlamadan önce yıllarca '
      'mekaniğin, dişlilerin ve suyun akış prensiplerinin çıraklığını '
      'yapmıştır. Sıfırdan başlayıp sabırla işin mutfağında yetiştiği '
      'için bugün mühendislik tarihinin öncülerinden biri olarak '
      'anılmaktadır.\n\n'
      'Peki, çile çekip işin inceliklerini öğrenmek tek başına '
      'yeterli midir? Öğrenilen bu birikimin zafere dönüşmesi için '
      'doğru anı kollamak gerekir.\n\n'
      '2. Fırsatlara Karşı Daima "Tetikte" Beklerler\n'
      'Başarılı insanlar "Bir gün şans yüzüme gülerse yaparım" '
      'kolaycılığına kaçmazlar. Onlar zifiri karanlıkta bile güneşin '
      'doğacağını bilir ve o an geldiğinde hazır olmak için gece '
      'gündüz çalışırlar. Fırsat kapıyı çaldığında onu sıcacık '
      'yataklarında uyuyarak değil; ayakta, heyecanla ve büyük bir '
      'donanımla karşılarlar. Yan gelip yatanlar ise fırsatları '
      'ancak rüyalarında görür ve hayal kırıklıklarıyla '
      'avunurlar.\n\n'
      'İstanbul’u fethederken henüz 21 yaşında olan Fatih Sultan '
      'Mehmet, surları yıkacak olan devasa "Şahi" toplarının '
      'planlarını kendi eliyle çizerken ve donanmayı karadan '
      'yürütme fikrini olgunlaştırırken yıllarca o doğru anı '
      'beklemişti. Fatih, tarih sahnesindeki o büyük fırsatı '
      'uyuyarak değil; gecesini gündüzüne katarak, strateji '
      'üreterek ve tetikte bekleyerek yakaladı.\n\n'
      'Fırsatı yakalayıp zirveye ulaşmak muazzam bir duygudur. Ancak '
      'asıl zorlu mücadele zirveye ulaştıktan sonra başlar.\n\n'
      '3. Başarıyı Bir Sonuç Değil, Sürekli Bir Yolculuk Olarak '
      'Görürler\n'
      'Onlar için zirveye çıkmak bitiş çizgisi değildir. Zirveye '
      'çıkmak zordur ancak orada kalabilmek çok daha büyük bir emek '
      'gerektirir. Başarıyı korumanın yolunun sürekli değişimden, '
      'yenilenmekten ve öz eleştiriden geçtiğini çok iyi bilirler. '
      '"Ben artık oldum" dedikleri an düşüşün başlayacağını '
      'bildiklerinden, gelişimi hayat boyu süren bir prensip haline '
      'getirirler.\n\n'
      'Tıbbın Kanunu kitabıyla yüzyıllar boyunca Doğu ve Batı '
      'dünyasını aydınlatan İbn-i Sînâ, onlarca tıp eserine ve '
      'felsefi keşfe imza atmasına rağmen ömrünün sonuna kadar '
      'araştırmayı kesmemiştir. "Dünyada tıp hususunda bilmediğim '
      'hiçbir şey yoktur derdim; meğer hiçbir şey bilmiyormuşum" '
      'diyerek bilginin ve başarının sonu olmayan bir süreç '
      'olduğunu vurgulamıştır.\n\n'
      'Ancak bu uzun ve meşakkatli yolculukta her zaman işler '
      'yolunda gitmeyebilir. İnsan bazen tökezler ve yere düşer.\n\n'
      '4. Düşmeyi Kayıp Değil, Zafere Giden Yolda Bir Ders Olarak '
      'Görürler\n'
      'İşte başarılı insanları sıradan olanlardan ayıran en çarpıcı '
      'nokta! Onların da ayakları takılır, onlar da başarısızlıklar '
      'yaşarlar. Ancak yere düştüklerinde derin karanlığa bürünüp '
      'pes etmezler; başlarını kaldırıp gökyüzündeki yıldızların '
      'parlaklığına odaklanırlar. Onlar için başarısızlık, zafere '
      'giden yoldaki tecrübe basamaklarıdır.\n\n'
      'Kütle çekimini ve evrenin sırlarını çözen Albert Einstein, '
      'gençlik yıllarında okullardan kabul görmemiş ve teorileri '
      'defalarca eleştirilmiştir. Fakat o, her hatayı gerçeğe biraz '
      'daha yaklaşma fırsatı olarak görmüştür. Einstein’ın şu sözü '
      'bu duruşu harika özetler: "Hiç hata yapmamış bir insan, yeni '
      'bir şey denememiş demektir." Yere her düştüklerinde bir ders '
      'çıkarıp fişek gibi ayağa kalkanlar, yarınları inşa '
      'edenlerdir.\n\n'
      'Bütün bu engelleri aşmanın ve en zor anlarda bile yola devam '
      'edebilmenin sırrı ise ruhumuzda taşıdığımız inançta '
      'gizlidir.\n\n'
      '5. Hiçbir Bahanenin Arkasına Sığınmaz, Ümitle Yola Devam '
      'Ederler\n'
      'Ben bu özelliğe "Koca Seyit Kuralı" diyorum. Çanakkale '
      'Savaşı’nın kaderini değiştiren Koca Seyit Dedemiz, 215 '
      'kiloluk mermiyi sırtlamadan önce "Bu mermi çok ağır, '
      'imkânlarım yetersiz, benim gücüm bunu kaldırmaya yetmez" '
      'diye bahaneler üretmedi. "Yardım Sen\'dendir Allah\'ım!" '
      'diyerek imkânsız görüneni başardı ve vatanın kaderini '
      'değiştirdi.\n\n'
      'Başarılı insanlar "Benim kafam basmıyor, benden geçti" '
      'demezler. Şartlar ne olursa olsun mazeretlere sığınmazlar. '
      'Bilirler ki karamsarlık bir bataklıktır, ümitsizlik ise '
      'insanın kendi hayallerini baltalamasıdır. Gökbilimci Birûnî, '
      'ölüm döşeğindeyken bile ziyarete gelen dostuna bilmediği bir '
      'matematik problemini sormuş; dostunun "Bu haldeyken mi?" '
      'şaşkınlığına, "O meseleyi öğrenip ölmem, onu bilmeden '
      'ölmemden daha iyi değil midir?" yanıtını vermiştir.\n\n'
      'Sevgili Gençler;\n'
      'Güneş doğduğu ve nefes aldığımız sürece her zaman bir ümit, '
      'her zaman bir çare vardır. Bahanelerin arkasına sığınmayan, '
      'çile çekmekten korkmayan, düştüğünde yeniden ayağa kalkan ve '
      'ümidini kaybetmeyen herkes kendi hikâyesinin kahramanı olmaya '
      'adaydır.\n\n'
      'Şimdi kendinize sorun: Kendi zirvenize doğru ilk adımı ne '
      'zaman atacaksınız?\n\n'
      '(Cumali Sever)';

  static const List<Map<String, dynamic>> _ortaokulLiseQuestions = [
    {
      'question':
          'Yazıya göre başarı, tesadüflerin değil doğru '
          'alışkanlıkların ve iradenin eseridir.',
      'answers': ['Doğru', 'Yanlış'],
      'correct': 0,
    },
    {
      'question':
          'El-Cezeri, otomatik makineler tasarlamadan önce yıllarca '
          'çıraklık yapmıştır.',
      'answers': ['Doğru', 'Yanlış'],
      'correct': 0,
    },
    {
      'question':
          'Yazıya göre Einstein\'ın teorileri gençlik yıllarında '
          'herkes tarafından hemen kabul görmüştür.',
      'answers': ['Doğru', 'Yanlış'],
      'correct': 1,
    },
    {
      'question':
          'Yazıya göre başarılı insanlar zirveye ulaştıktan sonra '
          'artık hiçbir çaba göstermez.',
      'answers': ['Doğru', 'Yanlış'],
      'correct': 1,
    },
  ];
}

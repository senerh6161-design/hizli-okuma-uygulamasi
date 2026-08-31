import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/comprehension_data.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../models/settings_manager.dart';
import '../../models/audio_manager.dart';
import '../../models/school_level.dart';
import '../../widgets/reading_theme_picker.dart';
import '../../widgets/word_definition_sheet.dart';
import '../../widgets/confetti_overlay.dart';
import '../../widgets/background_music_picker.dart';
import '../levels/level_page.dart';
import 'eye_coordination_page.dart';
import 'circular_sequence_page.dart';
import 'arrow_word_cycle_page.dart';
import 'growing_words_page.dart';
import 'attention_questions_page.dart';
import 'word_hide_seek_page.dart';
import 'object_flow_counting_page.dart';
import 'word_flow_counting_page.dart';
import 'exercise_menu_page.dart';

enum _Phase {
  intro,
  warmupIntro,
  warmup,
  preTopic,
  preText,
  preQuiz,
  activities,
  postTopic,
  postText,
  postQuiz,
  results,
}

class _ActivityRef {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget Function() build;
  const _ActivityRef(
    this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.build,
  );
}

/// Öğretmen dokümanındaki tam akış: önce kısa bir metinle okuma hızı
/// ölçülür, ardından Klasör 1'deki 10 etkinlik tamamlanır, sonra FARKLI bir
/// metinle tekrar hız ölçülür, her iki metinden sonra da D/Y sorularıyla
/// anlama kontrol edilir. Sonunda okuma hızı ve dikkat puanı AYRI AYRI
/// gösterilir.
class Folder1SessionPage extends StatefulWidget {
  const Folder1SessionPage({super.key});

  @override
  State<Folder1SessionPage> createState() => _Folder1SessionPageState();
}

class _Folder1SessionPageState extends State<Folder1SessionPage> {
  final Random _random = Random();
  _Phase _phase = _Phase.intro;
  // Konu seçme ekranında "Seviyene Göre Oku" seçilirse konu ızgarası yerine
  // seviye ızgarası (İlkokul/Ortaokul/Lise) gösteriliyor.
  bool _showLevelPicker = false;

  // Son Metin'den ÖNCE gösterilen, puansız antreman metni — hocanın
  // "Hızlı Okumanın Alışkanlık Haline Gelmesi İçin Önemli On Madde"
  // metninin TAMAMI (kitap s. 53-57). Kelimeler sayfanın üstünden soldan
  // sağa doğru tek tek gelir; kutu dolunca yeni bir sayfa açılır, öğrenci
  // metnin tamamını sayfa sayfa okur. Hız ÖLÇÜLMEZ, sadece ısınma
  // amaçlıdır.
  static const String _warmupText =
      'HIZLI OKUMANIN ALIŞKANLIK HALİNE GELMESİ İÇİN ÖNEMLİ ON MADDE:\n\n'
      '1. İlk zamanlar sadece göz hızını artırınız.\n'
      'İlk zamanlar anlamaya odaklanmayınız. Yoksa hızınız istenilen '
      'düzeye çıkmayabilir. Eski alışkanlıkları yıkmak tabii ki çok zor. '
      'Dolayısıyla asla önyargılı olmayınız. Bir de başaracağınıza olan '
      'inanç çok yüksek olsun. Şunu da unutmayınız ki: "Ben '
      'başaramayacağım galiba." diye işe başlayanla "Ben bu işi '
      'başaracağım." diye başlayanın elde edecekleri sonuç asla aynı '
      'olmayacaktır. Zihnimizde şöyle bir düşünce baloncuğu '
      'oluşturalım: "Her şeye rağmen çalışacağım. Başarana kadar '
      'vazgeçmeyeceğim!" Emin olun ki insanların çoğu, kaybettikleri '
      'için başarısız olmazlar. İnsanların çoğunun başarısız olmasının '
      'nedeni, yaptıkları işi yarıda bırakıp pes etmeleri, o işi '
      'neticelendirmemeleridir. Bir işi yarıda bırakmak, onu hiç '
      'yapmamakla eş değer olduğu gibi insan için zaman, enerji ve '
      'özgüven kaybına da sebep olur.\n\n'
      '2. Egzersizleri her gün uygulayınız.\n'
      'Gözlerimiz ve beynimiz, hızlı görmeye ve odaklanmaya alışıncaya '
      'kadar, göz-beyin arasındaki uyum hızını en az iki katına '
      'çıkarana kadar, egzersizleri her gün, en az 3-4 hafta boyunca '
      'aralıksız yapmalı.\n\n'
      '3. Sözcükleri içten ve dıştan seslendirmeyiniz!\n'
      'İçten okumanın ya da dudakla okumanın sesli okumadan pek de '
      'farkı yoktur. İç sesi tamamen yok edemeyiz belki; ama en aza '
      'indirmemiz gerekir. Bu kazanım da, kitaptaki etkinlikleri '
      'verilen sayıda ve sürelerde yapmaya bağlı olarak zamanla '
      'oluşacaktır. Seslendirerek 1 dakikada okuyacağımız kelime '
      'sayısı sınırlıdır. Sesli olarak anlaşılabilir bir şekilde '
      'okuyacağımız sözcük sayısı 250-300 kelime arasındadır. Daha '
      'fazlası okunsa da anlaşılmaz; ama sessiz okumanın sınırı '
      'kişiden kişiye değişir. Örneğin hızlı okuma tekniğini öğrenmiş '
      'bir öğrenci dakikada 400-800 kelime okuyabilir.\n\n'
      '4. Sözcük hazinenizi her gün bir kelime de olsa geliştiriniz.\n'
      'Eğer bir öğrenci bir kitap kurduysa ve sözcük hazinesi çok '
      'zenginse bu okuma oranı gitgide artacaktır. Yeteneğine, almış '
      'olduğu eğitime, kitap okuma alışkanlığına ve kendini sürekli '
      'geliştirmesine bağlı olarak bu 1 dakikada okunan kelime sayısı, '
      'daha da yükselecektir. Yani sözcükleri içten seslendirme '
      'oranımızı ne kadar azaltırsak o kadar hızlı okumaya başlarız. '
      'Ne kadar çok sözcük bilirsek o kadar az seslendirme yaparız. '
      'Çünkü genelde seslendirdiğimiz kelimeler, ilk kez '
      'karşılaştığımız kelimelerdir. Şu bir gerçek ki beynimiz, bir '
      'salisede bilindik bir kelimeyi algılayabilmektedir. O zaman '
      'yapacağımız önemli işlerden biri de bilindik kelime sayısını '
      'artırmak olmalıdır. Bu muhteşem potansiyeli kullanabilmek, '
      'gözümüzün bu muhteşem hızından faydalanabilmek için sık sık '
      'kitap okumalı, ara ara sözlük taraması yaparak sözcük '
      'bilgimizi geliştirmeliyiz. Aslında hızlı okuma sürecinde '
      'günlük 20 kelimenin anlamını öğrensek bir ayda 600 kelime '
      'yapar ki, bu da müthiş bir sonuçtur.\n\n'
      '5. Sözcükleri gruplandırarak okuyunuz.\n'
      'Tek tek sözcüklere değil, sözcük gruplarına odaklanarak '
      'okumalı. Bunun alışkanlık haline gelmesi için egzersizleri '
      'yaparken ilk zamanlar anlama odaklanmamalı. Israrla '
      'egzersizleri yapmaya devam etmeli. Kelimeleri bir nesne, '
      'paragrafları da bir hediye kutusu varsayarsak şöyle bir örnek '
      'verebiliriz: Kutunun içindeki hediyeyi bir bütün olarak '
      'görürüz. Parçalara pek de takılmayız. O hediyeyi anlamlı kılan '
      'da zaten o bütünlüktür. Kelimeler de bir cümlenin, paragrafın '
      'hatta bir yazının anlamlı parçalarıdır. Bir kelimenin cümle '
      'içinde anlamı değişebilir. Dolayısıyla cümle içindeki bulunan '
      'kelimeleri ne kadar hızlı okursak anlam hediyesine o kadar '
      'çabuk ulaşırız. Bu konuyla ilgili örnekleri ve açıklamaları '
      'etkinlikler bölümünde bulabilirsiniz.\n\n'
      '6. Geriye dönük değil, ileriye dönük okuyunuz.\n'
      'Geriye dönüşleri azaltmalı ve sıfıra indirmeli. Bir kelimeyi, '
      'cümleyi sık sık geriye dönerek tekrar okumak, özgüven '
      'eksikliğini doğurur. Bunu aşmanın yolu, tüm dikkatimizi '
      'okuduğumuz yazıya vermektir. Okuduğumuz parçayla adeta '
      'iletişime geçmeli, bize ne anlatmaya çalıştığını kavramaya '
      'çalışmalıyız. Dikkatimizi parçada yoğunlaştırmak için yazıyı '
      'okumadan önce kendimize sorular sorarak dikkatimizi '
      'canlandırabiliriz. "Yazar bana ne anlatmaya çalışıyor?" "Bu '
      'metinden ne sonuç çıkarabilirim?" Hatta okuduğumuz paragraf '
      'sorularını sıkıcılıktan kurtarmak için paragrafa başlamadan '
      'önce "Hey dostum, senin derdin ne?" diyerek işi biraz da '
      'espriye vurarak dikkatimize uyandırabiliriz. Bu tip sorularla '
      'okumaya başladığımızda dikkatimiz, daha canlı olacak ve bir '
      'cümleyi, bir metni tekrar tekrar okumuş olmaktan ve zaman '
      'kaybından kurtulmuş olacağız. Şu bir gerçek ki, hedefine '
      'varmış, başarıya ulaşmış tüm insanların hayatlarını '
      'gözlemlediğimizde "Her ne iş yapıyorsan o işi, hayatın o işe '
      'bağlıymışçasına yap." ilkesini tüm çalışmalarında '
      'kullandıklarını görüyoruz.\n\n'
      '7. İlk zamanlar her satırı en fazla üç veya dört duruşta '
      'okuyunuz.\n'
      'Egzersizleri sabırla uygulayarak odaklanma hızımızı artırmalı '
      've bir satırdaki duruş sayımızı düşürmek için gayret etmeliyiz. '
      'Unutmayalım ki, her gün yapılan bir davranış daha kolay ve '
      'daha hızlı yapılarak alışkanlık haline gelir. Ve şunu da '
      'unutmayalım ki, biz koşmayı öğrenmeden önce yürümeyi öğrendik. '
      'Yıllarca tek tek kelimelerle okumaya alışmış olan gözümüzün bu '
      'alışkanlığını yıkmak, zaman alabilir. Biraz zamana, biraz '
      'sabırla çalışmaya ve daha çok kendimize inanmaya ihtiyacımız '
      'olacaktır.\n\n'
      '8. Dikkatinizi sadece ve sadece okuduğunuz parçaya odaklayınız.\n'
      'Dağınık dikkat, yapılan işte görünmesine rağmen zihnin '
      'yapılandan uzaklaşarak daldan dala konması, konudan konuya '
      'atlamasıdır. Eğer bu okunan bir kitap ise gözler ile '
      'düşüncenin aynı doğrultuda olmaması demektir. Bunun önüne '
      'geçmek için okurken belirli aralıklarla kendimize soru '
      'yöneltebiliriz. "Düşüncem ile okuduklarım aynı doğrultuda mı?" '
      'Cevabınız evet ise hızınızı hiç düşürmeden cümlenin, '
      'paragrafın ve metnin ana düşüncesine odaklanarak okumanızı '
      'sürdürün. Sözcüklere değil, anlama ve düşünceye yoğunlaşın.\n\n'
      '9. Kararlı ve istikrarlı çalışınız.\n'
      'Kayayı delen damlacıkların kuvveti değil sürekliliğidir. İlk '
      'zamanlar anlama oranı düşse de, kararlılıkla okumaya devam '
      'ederseniz okuma hızınız en az iki katına çıkacaktır. Kültür '
      'birikimi ve kitap okuma alışkanlığınıza göre de hızınız ve '
      'anlama oranınızın giderek arttığını gördükçe kendiniz bile '
      'ulaştığınız seviyeye şaşıracaksınız. İşte başarının altın '
      'kuralı: Tüm dikkatini, yaptığın işte topla. Okuyorsan sadece '
      've sadece okuduğunu düşünmelisin ve tüm dikkatini okuduğun '
      'yazıya vermelisin. Anlam hazinelerinin anahtarı budur.\n\n'
      '10. Yani hızlı okumak için kısaca üç şey gerekli:\n'
      '1. İnanarak ISRARLA çalışmak\n'
      '2. İnanarak ISRARLA çalışmak\n'
      '3. İnanarak ISRARLA çalışmak\n'
      'Hızlı okumak için olmazsa olmaz iki madde:\n'
      '1. Kendine inanmak ve güvenmek\n'
      '2. Daha iyisini yapabileceğini düşünmek ve çalışmak\n'
      'Daha iyisi için gayret ediniz ve daha iyisini gerçekleştirene '
      'kadar vazgeçmeyiniz, pes etmeyiniz, yılmayınız ve lütfen bir '
      'daha deneyiniz!';
  // Kimine yavaş, kimine hızlı gelebilir diye öğrenci kendi hızını seçiyor.
  static const List<String> _warmupSpeedLabels = ['Yavaş', 'Orta', 'Hızlı'];
  static const List<int> _warmupWordMsBySpeed = [550, 350, 200];
  int _warmupSpeedLevel = 1;
  static const int _warmupWordsPerPage = 55;
  late final List<String> _warmupWords = _warmupText
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  late final List<List<String>> _warmupPages = [
    for (int i = 0; i < _warmupWords.length; i += _warmupWordsPerPage)
      _warmupWords.sublist(
        i,
        i + _warmupWordsPerPage > _warmupWords.length
            ? _warmupWords.length
            : i + _warmupWordsPerPage,
      ),
  ];
  int _warmupPageIndex = 0;
  int _warmupWordIndex = 0;
  bool _warmupDone = false;
  Timer? _warmupTimer;

  ReadingPassage? _preText;
  ReadingPassage? _postText;

  DateTime? _readStart;
  Timer? _tickTimer;
  int _elapsedSeconds = 0;

  int _preWpm = 0;
  int _postWpm = 0;
  int _preComprehensionPercent = 0;
  int _postComprehensionPercent = 0;

  int _quizIndex = 0;
  int _quizCorrect = 0;
  // Sorular veride hep aynı sırada (çoğunlukla Doğru-Yanlış-Doğru) —
  // çocuk bu kalıbı fark edip okumadan cevaplayabiliyordu. Her metin
  // başladığında sorular KARIŞTIRILMIŞ bir kopyaya alınır ki sıra her
  // seferinde gerçekten rastgele olsun.
  List<Map<String, dynamic>> _preQuizQuestions = [];
  List<Map<String, dynamic>> _postQuizQuestions = [];

  // Sırayı karıştırmak yetmiyordu: her metnin havuzunda hep 2 Doğru + 1
  // Yanlış cümle vardı, bu yüzden çocuk sırayla "Doğru" deyip her seferinde
  // garanti 2/3 alabiliyordu. Bunu kırmak için her metnin 4 aday sorusu
  // (2 Doğru + 2 Yanlış) var; her denemede rastgele ya 2D+1Y ya da 1D+2Y
  // seçilir — hangi oranın çıkacağı da önceden tahmin edilemez.
  List<Map<String, dynamic>> _pickQuizQuestions(
    List<Map<String, dynamic>> pool,
  ) {
    final trueOnes = pool.where((q) => q['correct'] == 0).toList()
      ..shuffle(_random);
    final falseOnes = pool.where((q) => q['correct'] == 1).toList()
      ..shuffle(_random);
    final wantTwoTrue = _random.nextBool();
    final picked = wantTwoTrue
        ? [...trueOnes.take(2), ...falseOnes.take(1)]
        : [...trueOnes.take(1), ...falseOnes.take(2)];
    return picked..shuffle(_random);
  }

  late final List<_ActivityRef> _activities;
  final Set<int> _activityDone = {};

  @override
  void initState() {
    super.initState();

    _activities = [
      _ActivityRef(
        'Göz Koordinasyonu',
        'Gözlerini rotayı takip ettir',
        Icons.visibility_outlined,
        const Color(0xFF2563EB),
        () => const EyeCoordinationPage(),
      ),
      _ActivityRef(
        'Hızlı Okuma',
        'Metni oku, hızını ölç',
        Icons.speed,
        const Color(0xFF0D9488),
        () => LevelPage(
          schoolLevel: SchoolLevelConfig.levels[1],
          showSchoolLevelInTitle: false,
        ),
      ),
      _ActivityRef(
        'Dairesel Sıralama',
        'Sayıları sırayla dokun',
        Icons.donut_large,
        const Color(0xFFE11D48),
        () => const CircularSequencePage(
          availableModes: [CircularMode.numbers12, CircularMode.numbers20],
          appBarTitle: '🔄 Dairesel Sıralama (Sayılar)',
        ),
      ),
      _ActivityRef(
        'Dairesel Gün/Ay',
        'Gün ve ayları sırala',
        Icons.calendar_month,
        const Color(0xFFD97706),
        () => const CircularSequencePage(
          availableModes: [CircularMode.days, CircularMode.months],
          appBarTitle: '🔄 Dairesel Gün/Ay Sıralama',
        ),
      ),
      _ActivityRef(
        'Kelime Döngüsü',
        'Oku, yönünü takip et',
        Icons.sync,
        const Color(0xFF0891B2),
        () => const ArrowWordCyclePage(),
      ),
      _ActivityRef(
        'Uzayan Kelimeler',
        'Kelime ailesini hatırla',
        Icons.expand,
        const Color(0xFF16A34A),
        () => const GrowingWordsPage(),
      ),
      _ActivityRef(
        'Dikkat Soruları',
        'Hızlı ve dikkatli cevapla',
        Icons.help_center,
        const Color(0xFF65A30D),
        () => const AttentionQuestionsPage(),
      ),
      _ActivityRef(
        'Nesne Akışı',
        'Nesneleri say, unutma',
        Icons.category,
        const Color(0xFF0284C7),
        () => const ObjectFlowCountingPage(),
      ),
      _ActivityRef(
        'Kelime Akışı',
        'Kelimeleri say, unutma',
        Icons.waves,
        const Color(0xFF475569),
        () => const WordFlowCountingPage(),
      ),
      _ActivityRef(
        'Kelimelerle Saklambaç',
        'Harflerden yeni kelime bul',
        Icons.extension,
        const Color(0xFFDC2626),
        () => const WordHideSeekPage(),
      ),
    ];
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _warmupTimer?.cancel();
    AudioManager.stopAmbient();
    super.dispose();
  }

  // ---------------- ANTREMAN METNİ (puansız, süre ölçülmez) ----------------

  void _goToWarmupIntro() {
    setState(() => _phase = _Phase.warmupIntro);
  }

  void _startWarmup() {
    _warmupTimer?.cancel();
    setState(() {
      _phase = _Phase.warmup;
      _warmupPageIndex = 0;
      _warmupWordIndex = 1; // ilk kelime hemen görünsün
      _warmupDone = false;
    });
    _scheduleWarmupWord();
  }

  // Sayfa dolunca (kelimeler bitince) kısa bir bekleme sonrası yeni bir
  // sayfa açılıp kaldığı yerden devam ediyor — son sayfa bitince metnin
  // tamamı okunmuş oluyor.
  void _scheduleWarmupWord() {
    final currentPage = _warmupPages[_warmupPageIndex];
    if (_warmupWordIndex >= currentPage.length) {
      if (_warmupPageIndex >= _warmupPages.length - 1) {
        setState(() => _warmupDone = true);
        return;
      }
      _warmupTimer = Timer(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() {
          _warmupPageIndex++;
          _warmupWordIndex = 1;
        });
        _scheduleWarmupWord();
      });
      return;
    }
    _warmupTimer = Timer(
      Duration(milliseconds: _warmupWordMsBySpeed[_warmupSpeedLevel]),
      () {
        if (!mounted) return;
        setState(() => _warmupWordIndex++);
        _scheduleWarmupWord();
      },
    );
  }

  int _computeWpm(ReadingPassage passage) {
    final start = _readStart;
    final elapsed = start == null
        ? _elapsedSeconds.toDouble()
        : DateTime.now().difference(start).inMilliseconds / 1000.0;
    final wordCount = passage.content
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    final minutes = max(elapsed / 60.0, 0.05);
    return (wordCount / minutes).round().clamp(40, 1200).toInt();
  }

  void _startTimer() {
    _tickTimer?.cancel();
    _elapsedSeconds = 0;
    _readStart = DateTime.now();
    _pausedAt = null;
    AudioManager.startAmbient();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
    });
  }

  // Renk seçici gibi metin okumayı gerçekten durduran bir panel açıldığında
  // çağrılır — süre orada geçen zamanı SAYMASIN diye sayaç durdurulur ve
  // panel kapanınca _readStart o kadar ileri kaydırılarak WPM hesabından
  // düşürülür.
  DateTime? _pausedAt;

  void _pauseTimer() {
    _tickTimer?.cancel();
    _pausedAt = DateTime.now();
  }

  void _resumeTimer() {
    final pausedAt = _pausedAt;
    final start = _readStart;
    if (pausedAt != null && start != null) {
      _readStart = start.add(DateTime.now().difference(pausedAt));
    }
    _pausedAt = null;
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
    });
  }

  void _goToPreTopic() {
    setState(() {
      _phase = _Phase.preTopic;
      _showLevelPicker = false;
    });
  }

  void _choosePreLevel(String levelId) {
    setState(() {
      _preText = ComprehensionData.passageForLevel(levelId)!;
      _phase = _Phase.preText;
    });
    _startTimer();
  }

  ReadingPassage _pickPassage(String? topicId, {ReadingPassage? avoid}) {
    final pool = ComprehensionData.passagesForTopic(topicId);
    final shuffled = List<ReadingPassage>.from(pool)..shuffle(_random);
    if (avoid != null && shuffled.length > 1) {
      return shuffled.firstWhere(
        (p) => p.id != avoid.id,
        orElse: () => shuffled.first,
      );
    }
    return shuffled.first;
  }

  void _choosePreTopic(String? topicId) {
    setState(() {
      _preText = _pickPassage(topicId);
      _phase = _Phase.preText;
    });
    _startTimer();
  }

  void _finishPreText() {
    _tickTimer?.cancel();
    AudioManager.stopAmbient();
    _preWpm = _computeWpm(_preText!);
    setState(() {
      _phase = _Phase.preQuiz;
      _quizIndex = 0;
      _quizCorrect = 0;
      _preQuizQuestions = _pickQuizQuestions(_preText!.questions);
    });
  }

  void _answerQuiz(
    List<Map<String, dynamic>> questions,
    int index,
    VoidCallback onDone,
  ) {
    final q = questions[_quizIndex];
    if (index == q['correct']) {
      _quizCorrect++;
      SoundManager.playCorrect();
    } else {
      SoundManager.playGentleTap();
    }
    if (_quizIndex < questions.length - 1) {
      setState(() => _quizIndex++);
    } else {
      onDone();
    }
  }

  void _finishPreQuiz() {
    _preComprehensionPercent = ((_quizCorrect / _preQuizQuestions.length) * 100)
        .round();
    ProgressManager.recordComprehensionResult(
      correct: _quizCorrect,
      total: _preQuizQuestions.length,
      title: 'Klasör 1 · Ön Metin',
    );
    _showPreTextReport();
  }

  // Etkinliklere geçmeden önce, ön metinde ne kadar sürede kaç kelime
  // okunduğunu ve ne kadarının anlaşıldığını gösteren küçük bir "karne".
  void _showPreTextReport() {
    final wordCount = _preText!.content
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('📊 Ön Metin Karnen'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _reportRow('⏱️ Süre', '$_elapsedSeconds saniye'),
              _reportRow('📖 Okunan', '$wordCount kelime'),
              const SizedBox(height: 14),
              _metricBar(
                label: '⚡ Hız',
                value: _preWpm,
                maxValue: 300,
                color: const Color(0xFF2563EB),
                suffix: ' WPM',
              ),
              const SizedBox(height: 10),
              _metricBar(
                label: '🎯 Anlama',
                value: _preComprehensionPercent,
                maxValue: 100,
                color: const Color(0xFF16A34A),
                suffix: '%',
              ),
              const SizedBox(height: 12),
              Text(
                'Şimdi 10 etkinliğe geçiyoruz, sonunda tekrar ölçeceğiz!',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _phase = _Phase.activities);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Etkinliklere Geç'),
          ),
        ],
      ),
    );
  }

  Widget _reportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }

  // Tek bir değeri (WPM ya da %) yatay bar olarak gösterir — Ön Metin
  // karnesinde henüz karşılaştırma yok, tek ölçüm var.
  Widget _metricBar({
    required String label,
    required int value,
    required int maxValue,
    required Color color,
    String suffix = '',
  }) {
    final fraction = maxValue <= 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              '$value$suffix',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 10,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Future<void> _openActivity(int index) async {
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _activities[index].build()),
    );
    if (!mounted) return;
    if (completed == true) {
      // "Bitir" (ya da normal tamamlama) sadece işaretleyip egzersiz
      // listesine döner — başka bir etkinliğe otomatik geçmez, öğrenci
      // sıradakini kendi seçer.
      setState(() => _activityDone.add(index));
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Etkinliği tamamlamadan çıktın, bu yüzden tik atılmadı.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _goToPostTopic() {
    setState(() {
      _phase = _Phase.postTopic;
      _showLevelPicker = false;
    });
  }

  void _choosePostLevel(String levelId) {
    setState(() {
      _postText = ComprehensionData.passageForLevel(
        levelId,
        isFinalTest: true,
      )!;
      _phase = _Phase.postText;
    });
    _startTimer();
  }

  void _choosePostTopic(String? topicId) {
    setState(() {
      _postText = _pickPassage(topicId, avoid: _preText);
      _phase = _Phase.postText;
    });
    _startTimer();
  }

  void _finishPostText() {
    _tickTimer?.cancel();
    AudioManager.stopAmbient();
    _postWpm = _computeWpm(_postText!);
    setState(() {
      _phase = _Phase.postQuiz;
      _quizIndex = 0;
      _quizCorrect = 0;
      _postQuizQuestions = _pickQuizQuestions(_postText!.questions);
    });
  }

  void _finishPostQuiz() {
    _postComprehensionPercent =
        ((_quizCorrect / _postQuizQuestions.length) * 100).round();
    ProgressManager.recordComprehensionResult(
      correct: _quizCorrect,
      total: _postQuizQuestions.length,
      title: 'Klasör 1 · Son Metin',
    );
    _finishSession();
  }

  void _finishSession() {
    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Klasör 1 Oturumu',
      result:
          'Hız $_preWpm→$_postWpm WPM · Dikkat %${ProgressManager.attentionSuccess}',
    );
    if (unlocked.isNotEmpty) SoundManager.playAchievement();
    setState(() => _phase = _Phase.results);
    showConfetti(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🎬 Klasör 1 Oturumu')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: switch (_phase) {
            _Phase.intro => _buildIntro(),
            _Phase.warmupIntro => _buildWarmupIntro(),
            _Phase.warmup => _buildWarmupFlow(),
            _Phase.preTopic => _buildTopicPicker(isPost: false),
            _Phase.preText => _buildReadingView(
              _preText!,
              'ÖN METİN',
              _finishPreText,
            ),
            _Phase.preQuiz => _quizBody(_preText!, isPost: false),
            _Phase.activities => _buildActivitiesView(),
            _Phase.postTopic => _buildTopicPicker(isPost: true),
            _Phase.postText => _buildReadingView(
              _postText!,
              'SON METİN',
              _finishPostText,
            ),
            _Phase.postQuiz => _quizBody(_postText!, isPost: true),
            _Phase.results => _buildResultsView(),
          },
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0369A1), Color(0xFF0D9488)],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0369A1).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Klasör 1 Oturumu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Baştan sona rehberli bir okuma antrenmanı',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _stepRow(
            icon: Icons.menu_book_rounded,
            color: const Color(0xFF2563EB),
            title: 'Ön Metin',
            subtitle: 'Konu seç, oku, hızını ölçelim',
            isFirst: true,
          ),
          _stepRow(
            icon: Icons.psychology_rounded,
            color: const Color(0xFF0D9488),
            title: '${_activities.length} Etkinlik',
            subtitle: 'Göz koordinasyonundan kelime oyunlarına',
          ),
          _stepRow(
            icon: Icons.local_fire_department_rounded,
            color: const Color(0xFFEA580C),
            title: 'Antreman Metni',
            subtitle: 'Puansız ısınma — hız ölçülmez',
          ),
          _stepRow(
            icon: Icons.auto_stories_rounded,
            color: const Color(0xFF059669),
            title: 'Son Metin',
            subtitle: 'FARKLI bir metinle tekrar ölçüm + D/Y sorular',
          ),
          _stepRow(
            icon: Icons.emoji_events_rounded,
            color: const Color(0xFFE11D48),
            title: 'Sonuç',
            subtitle: 'Okuma hızın ve dikkat puanın grafikle',
            isLast: true,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _goToPreTopic,
              icon: const Icon(Icons.play_arrow),
              label: const Text(
                'OTURUMU BAŞLAT',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExerciseMenuPage()),
              );
            },
            child: Text(
              'Sadece tek tek pratik yapmak istiyorum',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 2,
                height: 10,
                color: isFirst ? Colors.transparent : Colors.grey.shade300,
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast ? Colors.transparent : Colors.grey.shade300,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarmupIntro() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Antreman Metni',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEA580C),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    const Center(
                      child: Text('🔥', style: TextStyle(fontSize: 64)),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFFEA580C),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Kelimeleri sayfanın en üstünden, soldan sağa '
                              'doğru birlikte takip edeceğiz. Sayfa dolunca '
                              'yeni bir sayfa açılacak — metnin tamamını '
                              'birlikte okuyacağız. Bu bölümde hızımızı '
                              'ÖLÇMEYECEĞİZ — sadece gözlerimizi '
                              'ısındıracağız!',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9A3412),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _warmupSpeedChipRow(),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _startWarmup,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text(
                        'BAŞLA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEA580C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _warmupSpeedChipRow() {
    return Row(
      children: [
        Text(
          'Hız: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 6),
        for (int i = 0; i < _warmupSpeedLabels.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          ChoiceChip(
            label: Text(_warmupSpeedLabels[i]),
            selected: _warmupSpeedLevel == i,
            onSelected: (_) => setState(() => _warmupSpeedLevel = i),
            selectedColor: const Color(0xFFEA580C),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _warmupSpeedLevel == i
                  ? Colors.white
                  : const Color(0xFFEA580C),
            ),
            backgroundColor: const Color(0xFFEA580C).withValues(alpha: 0.08),
            side: BorderSide(
              color: const Color(
                0xFFEA580C,
              ).withValues(alpha: _warmupSpeedLevel == i ? 1 : 0.3),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ],
    );
  }

  Widget _buildWarmupFlow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEA580C).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Antreman Metni · Sayfa ${_warmupPageIndex + 1}/'
            '${_warmupPages.length} · süre ölçülmüyor',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFEA580C),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _warmupSpeedChipRow(),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            // Kelimeler sayfanın en üstünden, soldan sağa doğru tek tek
            // birikiyor — normal bir metin gibi doğal olarak alt satıra
            // geçiyor, bilerek Center DEĞİL topLeft.
            child: Align(
              alignment: Alignment.topLeft,
              child: SingleChildScrollView(
                child: Wrap(
                  alignment: WrapAlignment.start,
                  spacing: 8,
                  runSpacing: 12,
                  children: [
                    for (
                      int i = 0;
                      i < _warmupWordIndex &&
                          i < _warmupPages[_warmupPageIndex].length;
                      i++
                    )
                      TweenAnimationBuilder<double>(
                        key: ValueKey('warmup-$_warmupPageIndex-$i'),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 220),
                        builder: (context, value, child) => Opacity(
                          opacity: value,
                          child: Transform.scale(
                            scale: 0.8 + 0.2 * value,
                            child: child,
                          ),
                        ),
                        child: Text(
                          _warmupPages[_warmupPageIndex][i],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: _warmupDone
              ? ElevatedButton.icon(
                  onPressed: _goToPostTopic,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text(
                    'DEVAM ET',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildTopicPicker({required bool isPost}) {
    if (_showLevelPicker) {
      return _buildLevelPicker(isPost: isPost);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isPost ? 'Son metin için bir konu seç' : 'Ön metin için bir konu seç',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Ne okumak istersin? İlgini çeken bir konu seç.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: 16),
        const BackgroundMusicPicker(),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
            children: [
              _topicCard(
                emoji: '📖',
                title: 'Seviyene Göre Oku',
                onTap: () => setState(() => _showLevelPicker = true),
              ),
              for (final topic in ComprehensionData.topics)
                _topicCard(
                  emoji: topic.emoji,
                  title: topic.title,
                  onTap: () => isPost
                      ? _choosePostTopic(topic.id)
                      : _choosePreTopic(topic.id),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLevelPicker({required bool isPost}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _showLevelPicker = false),
              icon: const Icon(Icons.arrow_back_rounded),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            const Expanded(
              child: Text(
                'Seviyeni seç',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '"Kitaba Hürmet" metnini seviyene uygun bir uyarlamayla okuyacaksın.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: 16),
        const BackgroundMusicPicker(),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
            children: [
              for (final level in ComprehensionData.levels)
                _topicCard(
                  emoji: level.emoji,
                  title: level.title,
                  onTap: () => isPost
                      ? _choosePostLevel(level.id)
                      : _choosePreLevel(level.id),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _topicCard({
    required String emoji,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadingView(
    ReadingPassage passage,
    String label,
    VoidCallback onFinish,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () async {
                    _pauseTimer();
                    await showReadingThemePicker(
                      context,
                      () => setState(() {}),
                    );
                    if (mounted) _resumeTimer();
                  },
                  icon: const Icon(Icons.palette_outlined),
                  tooltip: 'Metin rengini değiştir',
                  visualDensity: VisualDensity.compact,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$_elapsedSeconds sn',
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          passage.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.touch_app_rounded,
              size: 14,
              color: Colors.grey.shade500,
            ),
            const SizedBox(width: 4),
            Text(
              'Anlamını bilmediğin bir kelimeye dokun!',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: SettingsManager.readingBackgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SettingsManager.readingBorderColor),
              ),
              child: buildInteractiveText(
                context,
                passage.content,
                accentColor: SettingsManager.readingAccentColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: onFinish,
            icon: const Icon(Icons.check),
            label: const Text(
              'OKUDUM, BİTTİM',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: SettingsManager.readingAccentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _quizBody(ReadingPassage passage, {required bool isPost}) {
    final questions = isPost ? _postQuizQuestions : _preQuizQuestions;
    final q = questions[_quizIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${isPost ? "SON" : "ÖN"} METİN · D/Y ${_quizIndex + 1}/${questions.length}',
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          q['question'],
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: _dyButton(
                'D) Doğru',
                Colors.green,
                () => _handleQuizAnswer(questions, 0, isPost),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _dyButton(
                'Y) Yanlış',
                Colors.red,
                () => _handleQuizAnswer(questions, 1, isPost),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dyButton(String label, Color color, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 22),
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: color,
        ),
      ),
    );
  }

  void _handleQuizAnswer(
    List<Map<String, dynamic>> questions,
    int index,
    bool isPost,
  ) {
    _answerQuiz(questions, index, isPost ? _finishPostQuiz : _finishPreQuiz);
  }

  void _confirmSkipToPostText() {
    final remaining = _activities.length - _activityDone.length;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('⚠️ Etkinlikler Bitmedi'),
        content: Text(
          'Henüz $remaining etkinliği tamamlamadın. Yine de son metne geçmek istiyor musun?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _goToWarmupIntro();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Yine de Geç'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesView() {
    final allDone = _activityDone.length == _activities.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_activities.length} Etkinlik',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_activityDone.length}/${_activities.length} tamamlandı',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: _activities.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final activity = _activities[index];
              final done = _activityDone.contains(index);
              final color = done ? const Color(0xFF16A34A) : activity.color;
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _openActivity(index),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: color.withValues(alpha: 0.12),
                          child: Icon(
                            done ? Icons.check_circle : activity.icon,
                            color: color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      activity.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Etkinlik ${index + 1}',
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                activity.subtitle,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              done ? 'Tamamlandı' : 'Aç',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (!done) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: color,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: allDone ? _goToWarmupIntro : _confirmSkipToPostText,
            icon: Icon(
              allDone ? Icons.arrow_forward : Icons.warning_amber_rounded,
            ),
            label: Text(
              allDone ? 'SON METNE GEÇ' : 'Etkinlikler Bitmedi, Yine de Geç',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: allDone
                  ? const Color(0xFF2563EB)
                  : Colors.grey.shade500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsView() {
    final attentionScore = ProgressManager.attentionSuccess;

    return Column(
      children: [
        const Icon(Icons.emoji_events, size: 60, color: Colors.amber),
        const SizedBox(height: 12),
        const Text(
          'Oturum Tamamlandı! 🎉',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            children: [
              _comparisonCard(
                icon: Icons.speed,
                color: const Color(0xFF2563EB),
                title: 'Okuma Hızı',
                before: _preWpm,
                after: _postWpm,
                suffix: ' WPM',
              ),
              const SizedBox(height: 12),
              _resultCard(
                icon: Icons.psychology,
                color: Colors.orange,
                title: 'Dikkat Puanı',
                mainValue: '%$attentionScore',
                subValue: '${_activities.length} etkinlikteki performansın',
                subColor: Colors.grey,
              ),
              const SizedBox(height: 12),
              _comparisonCard(
                icon: Icons.menu_book,
                color: Colors.green,
                title: 'Anlama (D/Y)',
                before: _preComprehensionPercent,
                after: _postComprehensionPercent,
                suffix: '%',
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Bitir',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _resultCard({
    required IconData icon,
    required Color color,
    required String title,
    required String mainValue,
    required String subValue,
    required Color subColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mainValue,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  subValue,
                  style: TextStyle(
                    color: subColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Sonuç ekranında Ön Metin → Son Metin karşılaştırmasını iki yatay bar
  // olarak (Önce/Sonra) gösterir — artma/azalma tek bakışta görülür.
  Widget _comparisonCard({
    required IconData icon,
    required Color color,
    required String title,
    required int before,
    required int after,
    String suffix = '',
  }) {
    final delta = after - before;
    final maxValue = [before, after, 1].reduce((a, b) => a > b ? a : b);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                delta >= 0 ? '+$delta$suffix arttı' : '$delta$suffix azaldı',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: delta >= 0 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _comparisonBarRow(
            'Önce',
            before,
            maxValue,
            color.withValues(alpha: 0.35),
            suffix,
          ),
          const SizedBox(height: 8),
          _comparisonBarRow('Sonra', after, maxValue, color, suffix),
        ],
      ),
    );
  }

  Widget _comparisonBarRow(
    String label,
    int value,
    int maxValue,
    Color color,
    String suffix,
  ) {
    final fraction = (value / maxValue).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 16,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 54,
          child: Text(
            '$value$suffix',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

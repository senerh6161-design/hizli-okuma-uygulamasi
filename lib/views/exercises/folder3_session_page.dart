import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/comprehension_data.dart';
import '../../models/comprehension_data_folder3.dart';
import '../../models/progress_manager.dart';
import '../../models/settings_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/confetti_overlay.dart';
import '../../widgets/reading_theme_picker.dart';
import '../../widgets/word_definition_sheet.dart';
import 'color_word_match_page.dart';
import 'column_reading_page.dart';
import 'focus_box_page.dart';
import 'four_direction_scan_page.dart';
import 'number_hunt_page.dart';
import 'proverb_matching_page.dart';
import 'scrambled_letters_page.dart';
import 'synonym_antonym_page.dart';
import 'topic_selection_page.dart';
import 'word_pair_scan_page.dart';

enum _Phase {
  intro,
  preLevel,
  preText,
  preQuiz,
  activities,
  warmupIntro,
  warmup,
  postText,
  postQuiz,
  results,
}

class _Folder3Activity {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color color;
  final Widget Function() build;
  const _Folder3Activity({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.color,
    required this.build,
  });
}

/// Klasör 1/2'deki gibi tam bir oturum: önce seviyeye göre Ön Metin
/// okunup hız ölçülür ([Folder3ReadingData]), ardından 10 etkinlik
/// tamamlanır, sonra puansız bir Antreman Metni ile ısınılır, ardından
/// Klasör 1'in konu havuzundan FARKLI bir metinle (Son Metin) tekrar hız
/// + D/Y anlama ölçülür, en sonunda Sonuç ekranında önce/sonra
/// karşılaştırması gösterilir.
class Folder3SessionPage extends StatefulWidget {
  const Folder3SessionPage({super.key});

  @override
  State<Folder3SessionPage> createState() => _Folder3SessionPageState();
}

class _Folder3SessionPageState extends State<Folder3SessionPage> {
  final Random _random = Random();

  static final List<_Folder3Activity> _activities = [
    _Folder3Activity(
      title: 'Eş ve Zıt Anlamlı Kelimeler',
      subtitle: 'Kelime kutucuklarını hızlı tara',
      badge: 'Etkinlik 1',
      icon: Icons.compare_arrows_rounded,
      color: const Color(0xFF15803D),
      build: () => const SynonymAntonymPage(),
    ),
    _Folder3Activity(
      title: 'Sayı Avı',
      subtitle: '1\'den 30\'a kadar sayıları bul',
      badge: 'Etkinlik 2',
      icon: Icons.pin_rounded,
      color: const Color(0xFF1D4ED8),
      build: () => const NumberHuntPage(),
    ),
    _Folder3Activity(
      title: 'Dört Yönlü Kelime Taraması',
      subtitle: 'Soldan sağa, sağdan sola, aşağı, yukarı tara',
      badge: 'Etkinlik 3',
      icon: Icons.explore_rounded,
      color: const Color(0xFF7C3AED),
      build: () => const FourDirectionScanPage(),
    ),
    _Folder3Activity(
      title: 'Karışık Harfler',
      subtitle: '9 harfi birleştir, kelimeyi bul',
      badge: 'Etkinlik 4',
      icon: Icons.spellcheck_rounded,
      color: const Color(0xFF0D9488),
      build: () => const ScrambledLettersPage(),
    ),
    _Folder3Activity(
      title: 'Atasözü Eşleştirme',
      subtitle: 'Atasözünün doğru yarısını bul',
      badge: 'Etkinlik 5',
      icon: Icons.menu_book_rounded,
      color: const Color(0xFFDB2777),
      build: () => const ProverbMatchingPage(),
    ),
    _Folder3Activity(
      title: 'Renk Uyumu',
      subtitle: 'Rengiyle uyuşmayan kelimeyi hızlıca bul',
      badge: 'Etkinlik 6',
      icon: Icons.palette_rounded,
      color: const Color(0xFFEA580C),
      build: () => const ColorWordMatchPage(),
    ),
    _Folder3Activity(
      title: 'Kelime Takibi',
      subtitle: 'Sırası gelen kelimeyi büyüyünce takip et',
      badge: 'Etkinlik 7',
      icon: Icons.text_fields_rounded,
      color: const Color(0xFF4338CA),
      build: () => const ColumnReadingPage(),
    ),
    _Folder3Activity(
      title: 'Odaklanma Kutucukları',
      subtitle: 'Yanıp sönen kutucuğu soldan sağa takip et',
      badge: 'Etkinlik 8',
      icon: Icons.center_focus_strong_rounded,
      color: const Color(0xFFB91C1C),
      build: () => const FocusBoxPage(),
    ),
    _Folder3Activity(
      title: 'Kelime Çiftleri Tarama',
      subtitle: '3 sayfa, 4 yönde kelime çifti tara',
      badge: 'Etkinlik 9',
      icon: Icons.grid_view_rounded,
      color: const Color(0xFF65A30D),
      build: () => const WordPairScanPage(),
    ),
    _Folder3Activity(
      title: 'Konulu Antreman Metinleri',
      subtitle: 'Konu seç, ilgini çeken metni oku',
      badge: 'Etkinlik 10',
      icon: Icons.auto_stories_rounded,
      color: const Color(0xFF0369A1),
      build: () => const TopicSelectionPage(),
    ),
  ];

  // Etkinliklerden sonra gösterilen, puansız antreman metni — hocanın
  // verdiği "İlk Test ve Antreman Metni" belgesinin ortaokul-lise
  // uyarlaması ("Dünyayı Değiştiren Asıl Güç", Klasör 2'nin Ön Metin'iyle
  // aynı içerik). Kelimeler sayfanın üstünden soldan sağa doğru tek tek
  // gelir; kutu dolunca yeni bir sayfa açılır. Hız ÖLÇÜLMEZ, sadece
  // ısınma amaçlıdır.
  static const String _warmupText =
      'Dünyayı zenginlikleriyle göz kamaştıran ve teknolojisiyle öne '
      'çıkan ülkelerin yönettiğini düşünebiliriz. Dışarıdan '
      'bakıldığında tablo böyle görünse de meselenin özüne '
      'indiğimizde dünyayı biçimlendiren asıl gücün kalem ve kitap '
      'olduğunu çok iyi biliriz. Bir ülkeyi ayakta tutan, onu '
      'geleceğe güvenle taşıyan ve gerçek gücün kaynağını özetleyen '
      'tarihi bir hikâye anlatılır:\n\n'
      'Eski zamanlarda güçlü bir ordu, zengin yer altı kaynaklarına '
      'sahip küçük bir ülkeye saldırmak üzere yola çıkmış. Halk '
      'büyük bir endişe ve paniğe kapılmış. Kimi ülkeyi terk etmek '
      'isterken kimi de "Düşman yakında burayı yerle bir edecek, '
      'buna nasıl engel olacağız?" kaygısıyla çaresizce beklemiş. '
      'Tam o sırada toplumun saygı duyduğu bilge biri ortaya çıkmış '
      've gür bir sesle:\n'
      '— "Okul yapın! Hiç durmayın, hemen okul yapın!" demiş.\n'
      'Halk şaşkınlıkla itiraz etmiş:\n'
      '— "Zaman mı var? Düşman kapımıza dayandı, okul yapmanın '
      'sırası mı?"\n'
      'Bilge adam acı bir tebessümle cevap vermiş:\n'
      '— "İşte başımıza gelen bu felaket, okuyanlarımızın azlığından '
      'kaynaklanıyor ya! Belki bu gelişlerinde düşmana engel '
      'olamayız, fakat okullarımızda gençlerimizi yetiştirirsek bir '
      'sonraki sefer için hazırlıklı ve güçlü oluruz."\n\n'
      'Günümüzde gelişmiş okullarımız ve bu kurumlara anlam katan '
      'değerli öğretmenlerimiz var. Öğretmenlerimiz, büyük bir '
      'gayret ve heyecanla bizleri yarınlara hazırlıyor. Biz '
      'eğitimcilerin en temel görevi, gençlerimizin geleceğine '
      'değer katmaktır. Sizlerin de aynı azimle derslerinize '
      'odaklandığınızı bilmek, bizim için en büyük motivasyon '
      'kaynağıdır. Şunu unutmamalıyız ki; bir ülkenin geleceği, '
      'gençliğin zihinsel ve ruhsal gelişimi kadar aydınlık '
      'olabilir.\n\n'
      'İç Dünyanın Derinliği\n\n'
      'Bugün teknolojik imkânlarımız, konforlu evlerimiz ve şık '
      'giysilerimiz olabilir. Ancak ihmal etmememiz gereken bir '
      'diğer unsur da iç dünyamızdır.\n\n'
      'Zamanında bir bilge, son derece şık giyinmiş bir gençle '
      'karşılaşır. Ona tarih ve dünya kültürleri hakkında sorular '
      'sorar; fakat gencin bu konularda hiçbir fikri yoktur. Bilge '
      'adam, gencin zihinsel birikimini ölçmek adına herkesçe '
      'bilinen klasik kitapları okuyup okumadığını sorar. Gencin '
      'kitaplardan da habersiz olduğunu görünce şu tarihi tespiti '
      'yapar:\n'
      '— "Muhteşem bir saray! Fakat ne yazık ki içinde bilgiye dair '
      'hiçbir şey yok, bomboş..."\n\n'
      'Geleceğimiz ve umudumuz; bu toprakların kültürüyle beslenip '
      'büyüyen gençliktir. Gençlerin donanımlı olması, bilimin ve '
      'nitelikli kitapların rehberliğinde yetişmesi hem kendi '
      'yaşamları hem de ülkemizin geleceği açısından çok '
      'önemlidir.\n\n'
      'Okuma eylemi sadece okul duvarları arasına sıkıştırılamaz; '
      'yaşam boyu süren nitelikli bir alışkanlıktır. Okuma '
      'alışkanlığı kazanmak için gösterilen her çaba, gelecekte inşa '
      'edeceğiniz başarı sarayına konulmuş sağlam bir tuğladır.\n\n'
      'Gerçek kitap dostları için okumak; nefes kadar hayati, su '
      'kadar bereketli ve ekmek kadar kutsaldır. Edebiyat '
      'dünyamızda iz bırakmış bir yazarımızın şu sözü, kitap '
      'sevgisinin ulaştığı noktayı açıkça gösterir:\n'
      '"Bana işkence etmek isteyenler, bulunduğum odadaki kitapları '
      've kalemleri yok etsinler; bu kadarı yeterlidir."\n\n'
      'Kendi ayakları üzerinde duran, adalet ve hoşgörü anlayışıyla '
      'etrafını aydınlatan güçlü bir gelecek hayal ediyorsak; '
      'kitaba, okumaya ve öğrenmeye gereken zamanı ayırmak '
      'zorundayız. Geleceğin öncü şahsiyetleri ve liderleri, hiç '
      'şüphesiz bugün okuyanların arasından çıkacaktır.\n\n'
      '(Cumali Sever)';
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

  _Phase _phase = _Phase.intro;
  final Set<int> _activityDone = {};

  ReadingPassage? _preText;
  ReadingPassage? _postText;

  Timer? _tickTimer;
  int _elapsedSeconds = 0;

  int _preWpm = 0;
  int _postWpm = 0;
  int _preComprehensionPercent = 0;
  int _postComprehensionPercent = 0;

  int _quizIndex = 0;
  int _quizCorrect = 0;
  List<Map<String, dynamic>> _preQuizQuestions = [];
  List<Map<String, dynamic>> _postQuizQuestions = [];

  @override
  void dispose() {
    _tickTimer?.cancel();
    _warmupTimer?.cancel();
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

  // Sırayı karıştırmak yetmiyordu: her metnin havuzunda hep 2 Doğru + 2
  // Yanlış aday soru var; hangisinin 2D+1Y ya da 1D+2Y şeklinde çıkacağı
  // her denemede rastgele seçilir.
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

  int _computeWpm(ReadingPassage passage) {
    final elapsed = _elapsedSeconds.toDouble();
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
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
    });
  }

  void _goToPreLevel() {
    setState(() => _phase = _Phase.preLevel);
  }

  void _choosePreLevel(String levelId) {
    setState(() {
      _preText = Folder3ReadingData.passageForLevel(levelId)!;
      _phase = _Phase.preText;
    });
    _startTimer();
  }

  void _finishPreText() {
    _tickTimer?.cancel();
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

  void _handleQuizAnswer(
    List<Map<String, dynamic>> questions,
    int index,
    bool isPost,
  ) {
    _answerQuiz(questions, index, isPost ? _finishPostQuiz : _finishPreQuiz);
  }

  void _finishPreQuiz() {
    _preComprehensionPercent = ((_quizCorrect / _preQuizQuestions.length) * 100)
        .round();
    ProgressManager.recordComprehensionResult(
      correct: _quizCorrect,
      total: _preQuizQuestions.length,
      title: 'Klasör 3 · Ön Metin',
    );
    _showPreTextReport();
  }

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
                color: const Color(0xFF0369A1),
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
                'Şimdi ${_activities.length} etkinliğe geçiyoruz, sonunda tekrar ölçeceğiz!',
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
              backgroundColor: const Color(0xFF0369A1),
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
              color: Color(0xFF0369A1),
            ),
          ),
        ],
      ),
    );
  }

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
              backgroundColor: const Color(0xFF0369A1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Yine de Geç'),
          ),
        ],
      ),
    );
  }

  // Son Metin, Klasör 1'in gerçek konu havuzundan (seviyeye özel Kitaba
  // Hürmet metinleri HARİÇ) rastgele seçiliyor — Ön Metin'den mutlaka
  // farklı bir metin olacak şekilde.
  ReadingPassage _pickPostPassage() {
    final pool = ComprehensionData.passages
        .where((p) => p.level == null)
        .toList();
    final shuffled = List<ReadingPassage>.from(pool)..shuffle(_random);
    if (_preText != null && shuffled.length > 1) {
      return shuffled.firstWhere(
        (p) => p.id != _preText!.id,
        orElse: () => shuffled.first,
      );
    }
    return shuffled.first;
  }

  void _goToPostText() {
    setState(() {
      _postText = _pickPostPassage();
      _phase = _Phase.postText;
    });
    _startTimer();
  }

  void _finishPostText() {
    _tickTimer?.cancel();
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
      title: 'Klasör 3 · Son Metin',
    );
    _finishSession();
  }

  void _finishSession() {
    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Klasör 3 Oturumu',
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
      appBar: AppBar(
        title: const Text(
          'Klasör 3',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: switch (_phase) {
            _Phase.intro => _buildIntro(),
            _Phase.preLevel => _buildPreLevelPicker(),
            _Phase.preText => _buildReadingView(
              _preText!,
              'ÖN METİN',
              _finishPreText,
            ),
            _Phase.preQuiz => _quizBody(isPost: false),
            _Phase.activities => _buildActivitiesView(),
            _Phase.warmupIntro => _buildWarmupIntro(),
            _Phase.warmup => _buildWarmupFlow(),
            _Phase.postText => _buildReadingView(
              _postText!,
              'SON METİN',
              _finishPostText,
            ),
            _Phase.postQuiz => _quizBody(isPost: true),
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
                colors: [Color(0xFF0369A1), Color(0xFF15803D)],
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
                    Icons.folder_open,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Klasör 3 Oturumu',
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
            color: const Color(0xFF0369A1),
            title: 'Ön Metin',
            subtitle: 'Seviyeni seç, oku, hızını ölçelim',
            isFirst: true,
          ),
          _stepRow(
            icon: Icons.psychology_rounded,
            color: const Color(0xFF15803D),
            title: '${_activities.length} Etkinlik',
            subtitle: 'Kelime taramadan dikkat oyunlarına',
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _goToPreLevel,
              icon: const Icon(Icons.play_arrow),
              label: const Text(
                'OTURUMU BAŞLAT',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0369A1),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFF0369A1).withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
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

  Widget _buildPreLevelPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seviyeni seç',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Ön metni seviyene uygun bir uyarlamayla okuyacaksın.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
            children: [
              for (final level in Folder3ReadingData.levels)
                Card(
                  elevation: 1,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _choosePreLevel(level.id),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            level.emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            level.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
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
                color: const Color(0xFF0369A1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0369A1),
                ),
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () =>
                      showReadingThemePicker(context, () => setState(() {})),
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

  Widget _quizBody({required bool isPost}) {
    final questions = isPost ? _postQuizQuestions : _preQuizQuestions;
    final q = questions[_quizIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${isPost ? "SON" : "ÖN"} METİN · D/Y ${_quizIndex + 1}/${questions.length}',
            style: const TextStyle(
              color: Color(0xFF0369A1),
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
            itemBuilder: (context, index) => _activityCard(index),
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
                  ? const Color(0xFF0369A1)
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

  Widget _activityCard(int index) {
    final activity = _activities[index];
    final done = _activityDone.contains(index);
    final color = done ? const Color(0xFF16A34A) : activity.color;
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                            activity.badge,
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
                    Icon(Icons.arrow_forward_rounded, size: 14, color: color),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
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
                  onPressed: _goToPostText,
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
                color: const Color(0xFF0369A1),
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
              backgroundColor: const Color(0xFF0369A1),
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
                const SizedBox(height: 2),
                Text(subValue, style: TextStyle(color: subColor, fontSize: 12)),
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';

enum _Phase { intro, bolum2Intro, announcing, showing, answering }

class _Round {
  final List<String> grid;
  final String target;
  final int correctCount;
  const _Round(this.grid, this.target, this.correctCount);
}

/// Klasör 2'nin beşinci etkinliği: "İkili Kelime Grubu Say". Öğretmen
/// dokümanındaki tablo formatının uyarlaması: sayfada bir sürü ikili
/// kelime grubu (ör. "elma-armut") var, hedef gösterilen bir grup sayfada
/// kaç kere geçiyor — öğrenci hızlıca tarayıp sayıyor, süre dolunca (ya da
/// "CEVAPLA" ile erken) kaç kere gördüğünü seçiyor. Her turdan önce hangi
/// grubu arayacağı duyurulur, sonra kutucuklar soldan sağa, satır satır
/// ritimli bir şekilde beliriyor.
class WordPairCountPage extends StatefulWidget {
  const WordPairCountPage({super.key});

  @override
  State<WordPairCountPage> createState() => _WordPairCountPageState();
}

class _WordPairCountPageState extends State<WordPairCountPage> {
  static const Color _color = Color(0xFF0891B2);
  static const List<String> _speedLabels = ['Yavaş', 'Orta', 'Hızlı'];
  static const List<int> _roundTimeMsBySpeed = [15000, 10000, 6000];
  // Hızlı ayar daha zor olduğu için doğru cevap daha çok puan kazandırıyor.
  static const List<int> _pointsBySpeed = [50, 75, 100];
  // Eskiden 30 hücre + 5 tur vardı; 30 hücre ekrana sığmayıp kaydırma
  // gerektiriyordu. İkiye bölündü: 15 hücre (kaydırmadan sığıyor), tur
  // sayısı 10'a çıkarıldı — öğrenci toplamda daha fazla soru görüyor.
  static const int _roundCount = 10;
  static const int _totalRoundCount = _roundCount * 2;
  static const int _gridCellCount = 15;

  // Tur başlamadan önce hangi grubu arayacağı 1.4 sn boyunca duyurulur.
  static const int _announceMs = 1400;
  // Kutucuklar hep birden değil, soldan sağa satır satır ritimli beliriyor.
  static const int _revealStepMs = 60;

  // Doğru cevapta hep aynı yazı çıkmasın diye rastgele seçilen kutlama
  // mesajları.
  static const List<String> _celebrationMessages = [
    '🎉 Harikasın!',
    '✅ Süpersin!',
    '👏 Aferin sana!',
    '🌟 Mükemmel!',
    '💪 Başardın!',
    '🔥 Tam isabet!',
  ];

  // Not: "domates-domates" ve "fasulye-bezelye" gibi çok uzun çiftler
  // havuzdan bilerek çıkarıldı — grid hücresinde alt satıra kayıp çirkin
  // görünüyorlardı; kalanların hepsi tek satıra sığıyor.
  static const List<String> _pairPool = [
    'elma-armut',
    'kiraz-çilek',
    'patates-soğan',
    'karpuz-kavun',
    'havuç-turp',
    'muz-ananas',
    'nar-ayva',
    'üzüm-erik',
    'incir-dut',
    'marul-lahana',
  ];

  final Random _random = Random();
  _Phase _phase = _Phase.intro;
  bool _hasCompletedOnce = false;
  bool _isPaused = false;
  int _speedLevel = 1;

  // 0 = 1. Bölüm (yatay, "elma-armut"), 1 = 2. Bölüm (dikey, kelimeler
  // alt alta). Puan/doğru sayısı iki bölüm boyunca birikir, tek sonuç
  // ekranında gösterilir.
  int _bolumIndex = 0;
  int _roundIndex = 0;
  int _totalScore = 0;
  int _correctRoundCount = 0;
  late _Round _round;
  int _elapsedMs = 0;
  int _revealedCount = 0;
  Timer? _roundTimer;
  Timer? _tickTimer;
  Timer? _revealTimer;
  List<int> _answerOptions = const [];
  int? _selectedAnswer;
  bool _answered = false;
  String _lastCelebration = _celebrationMessages.first;
  // Aynı oturumda hedef kelime grubu tekrar etmesin diye (ör. üst üste
  // "domates-domates" çıkmasın) her tur farklı bir hedef seçiliyor.
  final Set<String> _usedTargets = {};

  @override
  void dispose() {
    _roundTimer?.cancel();
    _tickTimer?.cancel();
    _revealTimer?.cancel();
    super.dispose();
  }

  _Round _generateRound() {
    final available = _pairPool
        .where((p) => !_usedTargets.contains(p))
        .toList();
    final pool = available.isNotEmpty ? available : _pairPool;
    final target = pool[_random.nextInt(pool.length)];
    _usedTargets.add(target);
    final targetCount = 2 + _random.nextInt(5); // 2..6
    final grid = <String>[];
    for (int i = 0; i < targetCount; i++) {
      grid.add(target);
    }
    // Kelimeler aynı ama sırası ters olan bir çeldirici ekleniyor (ör.
    // hedef "kiraz-çilek" ise "çilek-kiraz" da tuzak olarak geçebilir) —
    // öğrenci sadece kelimelere değil, sırasına da dikkat etmeli.
    final parts = target.split('-');
    if (parts.length == 2 && parts[0] != parts[1]) {
      final reversed = '${parts[1]}-${parts[0]}';
      final reversedCount = 1 + _random.nextInt(2); // 1-2 kere
      for (int i = 0; i < reversedCount; i++) {
        grid.add(reversed);
      }
    }
    final decoys = _pairPool.where((p) => p != target).toList();
    while (grid.length < _gridCellCount) {
      grid.add(decoys[_random.nextInt(decoys.length)]);
    }
    grid.shuffle(_random);
    return _Round(grid, target, targetCount);
  }

  void _startGame() {
    _usedTargets.clear();
    setState(() {
      _bolumIndex = 0;
      _roundIndex = 0;
      _totalScore = 0;
      _correctRoundCount = 0;
    });
    _startRound();
  }

  // 1. Bölümün 10 turu bitince çağrılır: aynı mekanik, ama kelime grupları
  // artık alt alta yazılı olacak.
  void _startBolum2() {
    _usedTargets.clear();
    setState(() {
      _bolumIndex = 1;
      _roundIndex = 0;
    });
    _startRound();
  }

  // Kelime çiftini bölüme göre yatay ("elma-armut") ya da dikey (alt alta
  // "elma" / "armut") gösterir.
  Widget _pairDisplay(
    String pair, {
    required TextStyle style,
    TextAlign textAlign = TextAlign.center,
  }) {
    if (_bolumIndex == 0) {
      return Text(
        pair,
        textAlign: textAlign,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final part in pair.split('-'))
          Text(
            part,
            textAlign: textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
      ],
    );
  }

  // Önce hangi grubu arayacağı duyurulur (_Phase.announcing), sonra
  // kutucuklar ritimli belirmeye başlar (_beginShowing).
  void _startRound() {
    _roundTimer?.cancel();
    _tickTimer?.cancel();
    _revealTimer?.cancel();
    final round = _generateRound();
    setState(() {
      _phase = _Phase.announcing;
      _round = round;
      _elapsedMs = 0;
      _revealedCount = 0;
      _selectedAnswer = null;
      _answered = false;
    });
    _roundTimer = Timer(const Duration(milliseconds: _announceMs), () {
      if (!mounted) return;
      _beginShowing();
    });
  }

  void _beginShowing() {
    setState(() {
      _phase = _Phase.showing;
      _revealedCount = 0;
    });
    _scheduleReveal();
    final totalMs = _roundTimeMsBySpeed[_speedLevel];
    _tickTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) return;
      setState(() => _elapsedMs = (_elapsedMs + 80).clamp(0, totalMs));
    });
    _roundTimer = Timer(Duration(milliseconds: totalMs), () {
      if (!mounted) return;
      _goToAnswerStep();
    });
  }

  // Kutucuklar hepsi birden değil, soldan sağa satır satır (grid sırasına
  // göre) tek tek beliriyor — okuma ritmini taklit ediyor.
  void _scheduleReveal() {
    _revealTimer = Timer(const Duration(milliseconds: _revealStepMs), () {
      if (!mounted || _phase != _Phase.showing) return;
      if (_revealedCount >= _round.grid.length) return;
      setState(() => _revealedCount++);
      _scheduleReveal();
    });
  }

  void _pauseGame() {
    _roundTimer?.cancel();
    _tickTimer?.cancel();
    _revealTimer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resumeGame() {
    setState(() => _isPaused = false);
    if (_phase == _Phase.announcing) {
      _roundTimer = Timer(const Duration(milliseconds: _announceMs), () {
        if (!mounted) return;
        _beginShowing();
      });
    } else if (_phase == _Phase.showing) {
      final totalMs = _roundTimeMsBySpeed[_speedLevel];
      final remainingMs = (totalMs - _elapsedMs).clamp(0, totalMs);
      _tickTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
        if (!mounted) return;
        setState(() => _elapsedMs = (_elapsedMs + 80).clamp(0, totalMs));
      });
      _roundTimer = Timer(Duration(milliseconds: remainingMs), () {
        if (!mounted) return;
        _goToAnswerStep();
      });
      if (_revealedCount < _round.grid.length) _scheduleReveal();
    }
  }

  void _goToAnswerStep() {
    _roundTimer?.cancel();
    _tickTimer?.cancel();
    _revealTimer?.cancel();
    final correctCount = _round.correctCount;
    // Rastgele deneme yerine olası tüm değerlerden karışık örnekleme —
    // doğru sayı sınıra yakınken sonsuz döngüye girme riski olmasın.
    const maxOption = 8;
    final otherValues = [
      for (int i = 0; i <= maxOption; i++)
        if (i != correctCount) i,
    ]..shuffle(_random);
    setState(() {
      _phase = _Phase.answering;
      _answerOptions = [correctCount, ...otherValues.take(3)]..shuffle(_random);
    });
  }

  void _answer(int selected) {
    if (_answered) return;
    final isCorrect = selected == _round.correctCount;
    setState(() => _selectedAnswer = selected);
    if (isCorrect) {
      SoundManager.playCorrect();
      _totalScore += _pointsBySpeed[_speedLevel];
      _correctRoundCount++;
      _lastCelebration =
          _celebrationMessages[_random.nextInt(_celebrationMessages.length)];
    } else {
      SoundManager.playGentleTap();
    }
    setState(() => _answered = true);
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      if (_roundIndex < _roundCount - 1) {
        setState(() => _roundIndex++);
        _startRound();
      } else if (_bolumIndex == 0) {
        setState(() => _phase = _Phase.bolum2Intro);
      } else {
        _finishAll();
      }
    });
  }

  void _finishAll() {
    _roundTimer?.cancel();
    _tickTimer?.cancel();
    _revealTimer?.cancel();
    _hasCompletedOnce = true;

    final percent = ((_correctRoundCount / _totalRoundCount) * 100).round();
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'İkili Kelime Grubu Say',
      result: '$_correctRoundCount/$_totalRoundCount doğru (%$percent)',
    );
    if (unlocked.isNotEmpty) SoundManager.playAchievement();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🎉 Etkinlik Tamamlandı!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Doğru: $_correctRoundCount / $_totalRoundCount (%$percent)'),
            if (unlocked.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                '🎉 Yeni Başarım Kazandın!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: unlocked.map((a) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(a.icon, size: 14, color: Colors.amber.shade800),
                        const SizedBox(width: 4),
                        Text(
                          a.title,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('Bitir'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _phase = _Phase.intro);
            },
            child: const Text('Yeniden Başlat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompletionPopScope(
      isCompleted: () => _hasCompletedOnce,
      child: Scaffold(
        appBar: AppBar(title: const Text('🔎 İkili Kelime Grubu Say')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _phase == _Phase.intro
                    ? _buildIntro()
                    : _phase == _Phase.bolum2Intro
                    ? _buildBolum2Intro()
                    : _buildRound(
                        key: ValueKey(
                          'round-$_bolumIndex-$_roundIndex-$_phase',
                        ),
                      ),
              ),
              if (_isPaused)
                buildPauseOverlay(color: _color, onResume: _resumeGame),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntro() {
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
                    color: _color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Etkinlik 5 · 1. Bölüm · İkili Kelime Grubu Say',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _color,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAmacYontemBox(),
                    const SizedBox(height: 12),
                    _buildExampleBox(),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text('🔎', style: TextStyle(fontSize: 64)),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: _color,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Önce hangi grubu arayacağın söylenecek, sonra '
                              'kutucuklar soldan sağa belirecek — süre dolmadan '
                              'sayfada kaç kere geçtiğini say, sonra doğru '
                              'sayıyı seç!',
                              style: TextStyle(
                                fontSize: 13,
                                color: _color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _speedChipRow(),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _startGame,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text(
                        'BAŞLA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _color,
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

  // Kitaptaki sayfanın başındaki "Amaç / Yöntem" kutusu.
  Widget _buildAmacYontemBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFCFFAFE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _color, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text.rich(
            textAlign: TextAlign.center,
            TextSpan(
              style: const TextStyle(fontSize: 13, color: Color(0xFF164E63)),
              children: [
                const TextSpan(
                  text: 'Amaç: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(
                  text:
                      'Gözlerimizin odaklanma hızını artırmak, ikili kelime '
                      'gruplarını görebilmek.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text.rich(
            textAlign: TextAlign.center,
            TextSpan(
              style: const TextStyle(fontSize: 13, color: Color(0xFF164E63)),
              children: [
                const TextSpan(
                  text: 'Yöntem: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(
                  text:
                      'İkili kelime grubunu seçerek 10 saniye içinde sayfada '
                      'kaç kere kullanıldığını bulunuz.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Oyuna geçmeden önce nasıl sayılacağını gösteren küçük, sabit bir
  // örnek — kitaptaki "ÖRNEK" kutularının aynısı.
  Widget _buildExampleBox() {
    const exampleTarget = 'elma-armut';
    const exampleGrid = [
      'elma-armut',
      'kiraz-çilek',
      'elma-armut',
      'patates-soğan',
      'elma-armut',
      'karpuz-kavun',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'ÖRNEK',
              style: TextStyle(
                color: Colors.amber.shade900,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 1.6,
            children: [
              for (final pair in exampleGrid)
                Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: pair == exampleTarget
                        ? const Color(0xFF16A34A).withValues(alpha: 0.14)
                        : Colors.grey.shade100,
                    border: Border.all(
                      color: pair == exampleTarget
                          ? const Color(0xFF16A34A)
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    pair,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: pair == exampleTarget
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF334155),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              children: const [
                TextSpan(text: '"elma-armut" burada '),
                TextSpan(
                  text: '3 kere',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16A34A),
                  ),
                ),
                TextSpan(text: ' geçiyor — cevap 3 olurdu!'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. Bölüm bitince arada gösterilen geçiş ekranı: aynı oyun, ama bu
  // sefer kelime grupları kutucuklarda alt alta yazılı olacak.
  Widget _buildBolum2Intro() {
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
                    color: _color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Etkinlik 5 · 2. Bölüm · Dikey Kelime Grupları',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _color,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCFFAFE),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _color, width: 1.5),
                      ),
                      child: const Text(
                        '1. Bölümü tamamladık! Şimdi aynı oyunu oynayacağız '
                        'ama kelime grupları bu sefer yan yana değil, alt '
                        'alta yazılı olacak.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF164E63),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBolum2ExampleBox(),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text('🔎', style: TextStyle(fontSize: 64)),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: _color,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Yine önce hangi grubu arayacağın söylenecek, '
                              'sonra kutucuklar belirecek — bu sefer '
                              'kelimeler alt alta yazılı olacak, yine 10 tur '
                              'oynayacağız!',
                              style: TextStyle(
                                fontSize: 13,
                                color: _color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _speedChipRow(),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _startBolum2,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text(
                        'BAŞLA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _color,
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

  // 2. Bölümün "ÖRNEK" kutusu — aynı örnek çift ama alt alta yazılı.
  Widget _buildBolum2ExampleBox() {
    const exampleTarget = 'elma-armut';
    const exampleGrid = [
      'elma-armut',
      'kiraz-çilek',
      'elma-armut',
      'patates-soğan',
      'elma-armut',
      'karpuz-kavun',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'ÖRNEK',
              style: TextStyle(
                color: Colors.amber.shade900,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 1.3,
            children: [
              for (final pair in exampleGrid)
                Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: pair == exampleTarget
                        ? const Color(0xFF16A34A).withValues(alpha: 0.14)
                        : Colors.grey.shade100,
                    border: Border.all(
                      color: pair == exampleTarget
                          ? const Color(0xFF16A34A)
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final part in pair.split('-'))
                          Text(
                            part,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: pair == exampleTarget
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF334155),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              children: const [
                TextSpan(text: '"elma" ve "armut" alt alta yazılı görürsen '),
                TextSpan(
                  text: '3 kere',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16A34A),
                  ),
                ),
                TextSpan(text: ' geçiyor demektir!'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _speedChipRow() {
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
        for (int i = 0; i < _speedLabels.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          ChoiceChip(
            label: Text(_speedLabels[i]),
            selected: _speedLevel == i,
            onSelected: (_) => setState(() => _speedLevel = i),
            selectedColor: _color,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _speedLevel == i ? Colors.white : _color,
            ),
            backgroundColor: _color.withValues(alpha: 0.08),
            side: BorderSide(
              color: _color.withValues(alpha: _speedLevel == i ? 1 : 0.3),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ],
    );
  }

  Widget _buildRound({required Key key}) {
    final totalMs = _roundTimeMsBySpeed[_speedLevel];
    final remainingFraction = (1 - (_elapsedMs / totalMs)).clamp(0.0, 1.0);
    return KeyedSubtree(
      key: key,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_bolumIndex + 1}. Bölüm · Tur ${_roundIndex + 1}/$_roundCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _color,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Puan: $_totalScore',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _color,
                    ),
                  ),
                  if (_phase == _Phase.showing) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '⏱ ${(remainingFraction * totalMs / 1000).ceil()} sn',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  if (_phase == _Phase.showing)
                    buildPauseButton(color: _color, onPressed: _pauseGame),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_phase != _Phase.announcing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text(
                    'Ara: ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    _round.target,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _color,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          if (_phase == _Phase.showing)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: remainingFraction,
                minHeight: 8,
                backgroundColor: _color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(
                  remainingFraction <= 0.25 ? Colors.red : _color,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: switch (_phase) {
              _Phase.announcing => _buildAnnounce(),
              _Phase.showing => _buildGrid(),
              _ => _buildAnswerStep(),
            },
          ),
          if (_phase == _Phase.showing) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _goToAnswerStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'CEVAPLA',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnnounce() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Şimdi bunu arayacaksın:',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          _bolumIndex == 0
              ? Text(
                  '"${_round.target}"',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _color,
                  ),
                )
              : _pairDisplay(
                  _round.target,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _color,
                  ),
                ),
        ],
      ),
    );
  }

  // Kelime grubu sayısı ekrana sığmayabilir — bu yüzden kart her zaman
  // kaydırılabilir, hiçbir zaman taşmaz. Kutucuklar hepsi birden değil,
  // soldan sağa satır satır (grid sırasına göre) ritimli beliriyor.
  Widget _buildGrid() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SingleChildScrollView(
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.15,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: _round.grid.length,
          itemBuilder: (context, index) {
            final revealed = index < _revealedCount;
            return AnimatedOpacity(
              opacity: revealed ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: revealed
                    ? Padding(
                        padding: const EdgeInsets.all(2),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _pairDisplay(
                            _round.grid[index],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnswerStep() {
    final isCorrect = _selectedAnswer == _round.correctCount;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _bolumIndex == 0
                ? Text(
                    '"${_round.target}"',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _color,
                    ),
                  )
                : _pairDisplay(
                    _round.target,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _color,
                    ),
                  ),
            const SizedBox(height: 8),
            const Text(
              'sayfada kaç kere geçti?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (_answered) ...[
              const SizedBox(height: 12),
              Text(
                isCorrect
                    ? _lastCelebration
                    : '📖 Doğrusu: ${_round.correctCount}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isCorrect
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFE11D48),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                for (final option in _answerOptions) _answerButton(option),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _answerButton(int option) {
    final answered = _answered;
    final isSelected = _selectedAnswer == option;
    final isCorrectOption = option == _round.correctCount;
    Color bg = _color.withValues(alpha: 0.08);
    Color border = _color.withValues(alpha: 0.3);
    Color fg = _color;
    if (answered && isCorrectOption) {
      bg = const Color(0xFF16A34A).withValues(alpha: 0.12);
      border = const Color(0xFF16A34A);
      fg = const Color(0xFF16A34A);
    } else if (answered && isSelected && !isCorrectOption) {
      bg = const Color(0xFFE11D48).withValues(alpha: 0.12);
      border = const Color(0xFFE11D48);
      fg = const Color(0xFFE11D48);
    }
    return SizedBox(
      width: 64,
      height: 64,
      child: OutlinedButton(
        onPressed: answered ? null : () => _answer(option),
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          side: BorderSide(color: border, width: 2),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          '$option',
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: fg,
          ),
        ),
      ),
    );
  }
}

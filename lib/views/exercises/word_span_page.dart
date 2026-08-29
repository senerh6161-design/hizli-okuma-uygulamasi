import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';

enum _Phase { streamIntro, stream, scatterIntro, scatter, quizIntro, quiz }

class _SpanWord {
  final int id;
  final String word;
  final double x;
  final double y;
  const _SpanWord(this.id, this.word, this.x, this.y);
}

/// Klasör 2'nin üçüncü etkinliği: "Görsel Genişlik"in (Etkinlik 2) KELİME
/// versiyonu. Aynı üç bölüm, sadece nesne emojileri yerine kelimeler var:
/// 1) Satır üzerinde akan kelimeler (daha hızlı, daha uzun süreli),
/// 2) Ekranın her yerine dağılmış kelimeler, öğrenci merkez noktaya
/// bakarak onları algılamaya çalışır — her gösterimde yerleri değişir,
/// 3) Kısa bir gösterimden sonra "'X' kelimesini kaç kere gördün?" diye
/// sorulur, doğru cevap puan kazandırır.
class WordSpanPage extends StatefulWidget {
  const WordSpanPage({super.key});

  @override
  State<WordSpanPage> createState() => _WordSpanPageState();
}

class _WordSpanPageState extends State<WordSpanPage> {
  static const int _stageDurationSec = 60;
  static const Color _color = Color(0xFFE11D48);
  static const List<String> _speedLabels = ['Yavaş', 'Orta', 'Hızlı'];

  // 2. etkinlikteki gibi "satırda beliren kelime" akışı — burada 1
  // saniyede yaklaşık 6-7 kelime belirsin diye Orta seviye ~150 ms.
  static const List<int> _streamSpawnMsBySpeed = [320, 220, 150];
  static const List<int> _flashMsBySpeed = [1500, 1000, 650];

  static const int _spanWordCount = 6;
  static const List<String> _words = [
    'kitap',
    'kalem',
    'deniz',
    'yıldız',
    'çiçek',
    'bulut',
  ];
  static const int _quizRoundCount = 5;

  final Random _random = Random();
  _Phase _phase = _Phase.streamIntro;
  bool _hasCompletedOnce = false;
  bool _isPaused = false;
  int _speedLevel = 1;

  int _elapsedSec = 0;
  Timer? _countdownTimer;

  // 1. Bölüm: Satır Akışı — Klasör 1'deki "Nesne Akışı" ile aynı mantık:
  // kelimeler soldan sağa TEK TEK belirip sabit bir satırda yan yana durur
  // (uçuşup kaymaz), satır dolunca hepsi birden kaybolup yeniden başlar.
  static const int _itemsPerLine = 5;
  static const int _rowPauseMs = 700;
  List<String> _currentLine = const [];
  int _lineItemIndex = 0;
  final List<String> _streamBag = [];
  String? _lastStreamWord;
  Timer? _streamSpawnTimer;

  // 2. Bölüm: Kelime Alanı (puansız, dağınık gösterim).
  int _nextWordId = 0;
  List<_SpanWord> _scatterWords = [];
  Timer? _scatterTimer;

  // 3. Bölüm: Quiz — aynı dağınık gösterim + "kaç kere gördün?" sorusu.
  int _quizRoundIndex = 0;
  int _quizScore = 0;
  List<_SpanWord> _quizWords = [];
  Map<String, int> _quizCounts = {};
  String _quizAskedWord = _words.first;
  List<int> _quizOptions = const [];
  int? _quizSelected;
  bool _quizAnnouncing = true;
  bool _quizShowingWords = true;
  Timer? _quizFlashTimer;
  static const int _quizAnnounceMs = 1400;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _streamSpawnTimer?.cancel();
    _scatterTimer?.cancel();
    _quizFlashTimer?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  // ---------------- 1. BÖLÜM: Satır Akışı ----------------

  void _startStream() {
    _countdownTimer?.cancel();
    _streamSpawnTimer?.cancel();
    _streamBag.clear();
    _lastStreamWord = null;
    setState(() {
      _phase = _Phase.stream;
      _elapsedSec = 0;
      _currentLine = _generateLine();
      _lineItemIndex = 1; // ilk kelime hemen belirsin
    });
    _startCountdownTimer(_finishStream);
    _scheduleStreamReveal();
  }

  void _startCountdownTimer(VoidCallback onExpire) {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSec++);
      if (_elapsedSec >= _stageDurationSec) onExpire();
    });
  }

  // Aynı satırda aynı kelimenin iki kez görünmesini istemiyoruz.
  List<String> _generateLine() {
    final line = <String>[];
    while (line.length < _itemsPerLine) {
      final candidate = _nextStreamWord();
      if (!line.contains(candidate)) line.add(candidate);
    }
    return line;
  }

  // Aktif satırdaki kelimeler TEK TEK belirir; satır tamamen dolunca kısa
  // bir süre öylece durup öğrenciye bakma fırsatı verir, sonra hepsi
  // birden kaybolup yeni satır aynı şekilde tek tek belirmeye başlar.
  void _scheduleStreamReveal() {
    if (!mounted || _phase != _Phase.stream) return;
    final rowComplete = _lineItemIndex >= _currentLine.length;
    final delay = rowComplete
        ? _rowPauseMs
        : _streamSpawnMsBySpeed[_speedLevel];
    _streamSpawnTimer = Timer(Duration(milliseconds: delay), () {
      if (!mounted || _phase != _Phase.stream) return;
      if (rowComplete) {
        setState(() {
          _currentLine = _generateLine();
          _lineItemIndex = 1;
        });
      } else {
        setState(() => _lineItemIndex++);
      }
      _scheduleStreamReveal();
    });
  }

  // "Shuffle bag": havuzun karışık bir kopyasını tüketip bitince yeniden
  // dolduruyor — saf rastgelelik gibi bir kelimenin çok fazla tekrar
  // etmesine izin vermiyor, her tur her kelime tam bir kez çıkıyor. Yeni
  // turun ilk elemanı bir öncekiyle aynıysa yer değiştiriliyor ki aynı
  // kelime art arda (yan yana) gelmesin.
  String _nextStreamWord() {
    if (_streamBag.isEmpty) {
      _streamBag.addAll(_words);
      _streamBag.shuffle(_random);
      if (_streamBag.length > 1 && _streamBag.last == _lastStreamWord) {
        final tmp = _streamBag.last;
        _streamBag[_streamBag.length - 1] = _streamBag[0];
        _streamBag[0] = tmp;
      }
    }
    final next = _streamBag.removeLast();
    _lastStreamWord = next;
    return next;
  }

  void _finishStream() {
    _countdownTimer?.cancel();
    _streamSpawnTimer?.cancel();
    setState(() {
      _phase = _Phase.scatterIntro;
    });
  }

  // ---------------- 2. BÖLÜM: Kelime Alanı (puansız) ----------------

  void _startScatter() {
    _countdownTimer?.cancel();
    _scatterTimer?.cancel();
    setState(() {
      _phase = _Phase.scatter;
      _elapsedSec = 0;
      _scatterWords = [];
    });
    _startCountdownTimer(_finishScatter);
    _scheduleScatterFlash();
  }

  void _scheduleScatterFlash() {
    // Bölüm değişince zincirin her adımı kontrol edilmezse, geçiş
    // sırasında gereksiz bir setState daha tetiklenip sonraki bölümün
    // BAŞLA'sına dokunmayı bazen kaçırtabiliyordu.
    if (!mounted || _phase != _Phase.scatter) return;
    setState(() => _scatterWords = _generateSpanWords());
    _scatterTimer = Timer(
      Duration(milliseconds: _flashMsBySpeed[_speedLevel]),
      () {
        if (!mounted || _phase != _Phase.scatter) return;
        setState(() => _scatterWords = []);
        _scatterTimer = Timer(const Duration(milliseconds: 350), () {
          if (!mounted || _phase != _Phase.scatter) return;
          _scheduleScatterFlash();
        });
      },
    );
  }

  // Kelimeler ekranın her yerine dağılıyor ama merkez odak noktasının
  // üstüne binmiyor, birbirlerine de çok yakın düşmüyor (kelime kutuları
  // emojiden daha geniş olduğu için minimum mesafe biraz daha büyük). Çok
  // zor olmasın diye kelimeler odak noktasından FAZLA uzağa gitmiyor.
  List<_SpanWord> _generateSpanWords() {
    final list = <_SpanWord>[];
    for (int i = 0; i < _spanWordCount; i++) {
      double x = 0.5, y = 0.5;
      for (int attempt = 0; attempt < 30; attempt++) {
        x = 0.22 + _random.nextDouble() * 0.56;
        y = 0.24 + _random.nextDouble() * 0.52;
        final dxCenter = x - 0.5;
        final dyCenter = y - 0.5;
        final tooCloseToCenter =
            dxCenter * dxCenter + dyCenter * dyCenter < 0.14 * 0.14;
        final tooCloseToOther = list.any((o) {
          final dx = o.x - x;
          final dy = o.y - y;
          return dx * dx + dy * dy < 0.18 * 0.18;
        });
        if (!tooCloseToCenter && !tooCloseToOther) break;
      }
      final word = _words[_random.nextInt(_words.length)];
      list.add(_SpanWord(_nextWordId++, word, x, y));
    }
    return list;
  }

  void _finishScatter() {
    _countdownTimer?.cancel();
    _scatterTimer?.cancel();
    setState(() {
      _scatterWords = [];
      _phase = _Phase.quizIntro;
    });
  }

  // ---------------- 3. BÖLÜM: Quiz ----------------

  void _startQuiz() {
    setState(() {
      _phase = _Phase.quiz;
      _quizRoundIndex = 0;
      _quizScore = 0;
    });
    _startQuizRound();
  }

  void _startQuizRound() {
    _quizFlashTimer?.cancel();
    final words = _generateSpanWords();
    final counts = <String, int>{};
    for (final w in words) {
      counts[w.word] = (counts[w.word] ?? 0) + 1;
    }
    final asked = _words[_random.nextInt(_words.length)];
    final correctCount = counts[asked] ?? 0;
    // Doğru sayı 0'a veya _spanWordCount'a çok yakınsa rastgele deneme
    // sonsuz döngüye girebiliyordu (4 farklı sayı asla bulunamıyordu) —
    // bu yüzden olası tüm değerlerden karışık örnekleme yapılıyor.
    final otherValues = [
      for (int i = 0; i <= _spanWordCount; i++)
        if (i != correctCount) i,
    ]..shuffle(_random);
    final options = [correctCount, ...otherValues.take(3)]..shuffle(_random);

    setState(() {
      _quizWords = words;
      _quizCounts = counts;
      _quizAskedWord = asked;
      _quizOptions = options;
      _quizSelected = null;
      _quizAnnouncing = true;
      _quizShowingWords = false;
    });

    _quizFlashTimer = Timer(const Duration(milliseconds: _quizAnnounceMs), () {
      if (!mounted) return;
      setState(() {
        _quizAnnouncing = false;
        _quizShowingWords = true;
      });
      _quizFlashTimer = Timer(
        Duration(milliseconds: _flashMsBySpeed[_speedLevel]),
        () {
          if (!mounted) return;
          setState(() => _quizShowingWords = false);
        },
      );
    });
  }

  void _answerQuiz(int selected) {
    if (_quizSelected != null) return;
    final correctCount = _quizCounts[_quizAskedWord] ?? 0;
    final isCorrect = selected == correctCount;
    setState(() => _quizSelected = selected);
    if (isCorrect) {
      SoundManager.playCorrect();
      _quizScore++;
    } else {
      SoundManager.playGentleTap();
    }
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_quizRoundIndex < _quizRoundCount - 1) {
        setState(() => _quizRoundIndex++);
        _startQuizRound();
      } else {
        _finishAll();
      }
    });
  }

  void _finishAll() {
    _countdownTimer?.cancel();
    _streamSpawnTimer?.cancel();
    _scatterTimer?.cancel();
    _quizFlashTimer?.cancel();
    _hasCompletedOnce = true;

    final percent = ((_quizScore / _quizRoundCount) * 100).round();
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Görsel Genişlik (Kelime)',
      result: 'Quiz: $_quizScore/$_quizRoundCount doğru (%$percent)',
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
            Text('Quiz sonucu: $_quizScore / $_quizRoundCount (%$percent)'),
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
              setState(() {
                _phase = _Phase.streamIntro;
                _elapsedSec = 0;
                _quizScore = 0;
                _quizRoundIndex = 0;
              });
            },
            child: const Text('Yeniden Başlat'),
          ),
        ],
      ),
    );
  }

  void _pauseGame() {
    _countdownTimer?.cancel();
    _streamSpawnTimer?.cancel();
    _scatterTimer?.cancel();
    _quizFlashTimer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resumeGame() {
    setState(() => _isPaused = false);
    switch (_phase) {
      case _Phase.stream:
        _startCountdownTimer(_finishStream);
        _scheduleStreamReveal();
      case _Phase.scatter:
        _startCountdownTimer(_finishScatter);
        _scheduleScatterFlash();
      case _Phase.quiz:
        if (_quizAnnouncing) {
          _quizFlashTimer = Timer(
            const Duration(milliseconds: _quizAnnounceMs),
            () {
              if (!mounted) return;
              setState(() {
                _quizAnnouncing = false;
                _quizShowingWords = true;
              });
              _quizFlashTimer = Timer(
                Duration(milliseconds: _flashMsBySpeed[_speedLevel]),
                () {
                  if (!mounted) return;
                  setState(() => _quizShowingWords = false);
                },
              );
            },
          );
        } else if (_quizShowingWords) {
          _quizFlashTimer = Timer(
            Duration(milliseconds: _flashMsBySpeed[_speedLevel]),
            () {
              if (!mounted) return;
              setState(() => _quizShowingWords = false);
            },
          );
        }
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompletionPopScope(
      isCompleted: () => _hasCompletedOnce,
      child: Scaffold(
        appBar: AppBar(title: const Text('📝 Görsel Genişlik · Kelime')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildBody(),
              ),
              if (_isPaused)
                buildPauseOverlay(color: _color, onResume: _resumeGame),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _Phase.streamIntro:
        return KeyedSubtree(
          key: const ValueKey('stream-intro'),
          child: _buildStreamIntro(),
        );
      case _Phase.stream:
        return KeyedSubtree(
          key: const ValueKey('stream-flow'),
          child: _buildStreamFlow(),
        );
      case _Phase.scatterIntro:
        return KeyedSubtree(
          key: const ValueKey('scatter-intro'),
          child: _buildScatterIntro(),
        );
      case _Phase.scatter:
        return KeyedSubtree(
          key: const ValueKey('scatter-flow'),
          child: _buildScatterFlow(),
        );
      case _Phase.quizIntro:
        return KeyedSubtree(
          key: const ValueKey('quiz-intro'),
          child: _buildQuizIntro(),
        );
      case _Phase.quiz:
        return KeyedSubtree(
          key: ValueKey('quiz-flow-$_quizRoundIndex'),
          child: _buildQuizFlow(),
        );
    }
  }

  Widget _buildIntro({
    required String badge,
    required String emoji,
    required String instruction,
    required VoidCallback onStart,
  }) {
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
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _color,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 64)),
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
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: _color,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              instruction,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: onStart,
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

  Widget _buildStreamIntro() {
    return _buildIntro(
      badge: '1. Bölüm · Satır Akışı',
      emoji: '➡️',
      instruction:
          'Kelimeler satır üzerinde hızlıca akıp geçecek. Başını oynatmadan, '
          'sadece gözlerinle takip et — hız arttıkça daha da hızlanacak!',
      onStart: _startStream,
    );
  }

  Widget _buildScatterIntro() {
    return _buildIntro(
      badge: '2. Bölüm · Kelime Alanı',
      emoji: '🎯',
      instruction:
          'Ortadaki noktaya sabit bak, gözlerini oynatma. Kelimeler ekranın her '
          'yerinde kısaca belirip kaybolacak — onları çevresel görüşünle '
          'fark etmeye çalış!',
      onStart: _startScatter,
    );
  }

  Widget _buildQuizIntro() {
    return _buildIntro(
      badge: '3. Bölüm · Ne Kadar Gördün?',
      emoji: '❓',
      instruction:
          'Aynı şekilde ortadaki noktaya bak. Kelimeler kısaca görünecek, sonra '
          'kaybolup sana bir kelimeyi kaç kere gördüğünü soracağız — doğru '
          'cevap puan kazandırır!',
      onStart: _startQuiz,
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

  Widget _skipButton(VoidCallback onSkip) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onSkip,
        icon: const Icon(Icons.skip_next_rounded),
        label: const Text(
          'SONRAKİ BÖLÜM',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _color,
          side: const BorderSide(color: _color),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _stageHeader(
    String badge, {
    bool showTimer = true,
    bool showPause = true,
  }) {
    final remaining = _stageDurationSec - _elapsedSec;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            badge,
            style: const TextStyle(fontWeight: FontWeight.bold, color: _color),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showTimer)
              Text(
                'Süre: $remaining sn',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: remaining <= 10 ? Colors.red : Colors.orange,
                ),
              ),
            if (showPause)
              buildPauseButton(color: _color, onPressed: _pauseGame),
          ],
        ),
      ],
    );
  }

  Widget _buildStreamFlow() {
    return Column(
      children: [
        _stageHeader('1. Bölüm · Satır Akışı'),
        const SizedBox(height: 10),
        _speedChipRow(),
        const SizedBox(height: 12),
        Expanded(
          child: Center(
            // Tabletlerde bu alan çok uzayabiliyor — üst sınır koyup
            // ortalayarak kutunun ekrana orantısız yayılmasını önlüyoruz.
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 460),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                    ),
                  ],
                ),
                // Klasör 1'deki Nesne Akışı gibi: kelimeler soldan sağa TEK
                // TEK belirip sabit bir satırda yan yana durur, uçuşmaz.
                // Bilerek Center DEĞİL, sola yaslı: ortalanmış olsaydı her
                // yeni kelime eklendiğinde satırın tamamı yeniden ortalanıp
                // kelimeler "ortadan çıkıyormuş" gibi kayardı. Wrap DEĞİL,
                // yatay kaydırılabilir Row: dar (dikey) ekranlarda 5 kelime
                // sığmayınca alt satıra kaymasın, bunun yerine kaydırılsın.
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (int i = 0; i < _lineItemIndex; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: TweenAnimationBuilder<double>(
                              key: ValueKey('stream-$i-${_currentLine[i]}'),
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
                                _currentLine[i],
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: _color,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _skipButton(_finishStream),
      ],
    );
  }

  // Merkez odak noktası — 2. ve 3. Bölüm'de öğrencinin gözünü sabit
  // tutması gereken yer.
  Widget _centerFocusDot() {
    return Center(
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _color,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(color: _color.withValues(alpha: 0.5), blurRadius: 8),
          ],
        ),
      ),
    );
  }

  Widget _spanWordsLayer(List<_SpanWord> words) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            for (final w in words)
              Positioned(
                key: ValueKey(w.id),
                left: w.x * constraints.maxWidth - 45,
                top: w.y * constraints.maxHeight - 16,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  builder: (context, t, child) =>
                      Opacity(opacity: t, child: child),
                  child: SizedBox(
                    width: 90,
                    child: Text(
                      w.word,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _color,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildScatterFlow() {
    return Column(
      children: [
        _stageHeader('2. Bölüm · Kelime Alanı'),
        const SizedBox(height: 10),
        _speedChipRow(),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Stack(
              children: [_centerFocusDot(), _spanWordsLayer(_scatterWords)],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _skipButton(_finishScatter),
      ],
    );
  }

  Widget _buildQuizFlow() {
    return Column(
      children: [
        _stageHeader(
          '3. Bölüm · Soru ${_quizRoundIndex + 1}/$_quizRoundCount',
          showTimer: false,
          showPause:
              !_quizAnnouncing && _quizShowingWords && _quizSelected == null,
        ),
        const SizedBox(height: 10),
        _speedChipRow(),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _quizAnnouncing
                ? _buildQuizAnnounce()
                : (_quizShowingWords
                      ? Stack(
                          children: [
                            _centerFocusDot(),
                            _spanWordsLayer(_quizWords),
                          ],
                        )
                      : _buildQuizQuestion()),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizAnnounce() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Şimdi bunu sayacaksın:',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '"$_quizAskedWord"',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizQuestion() {
    final correctCount = _quizCounts[_quizAskedWord] ?? 0;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '"$_quizAskedWord"',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _color,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'kelimesini kaç kere gördün?',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              for (final option in _quizOptions)
                _quizOptionButton(option, correctCount),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quizOptionButton(int option, int correctCount) {
    final answered = _quizSelected != null;
    final isSelected = _quizSelected == option;
    final isCorrectOption = option == correctCount;
    Color bg = _color.withValues(alpha: 0.08);
    Color border = _color.withValues(alpha: 0.3);
    Color fg = _color;
    if (answered && isCorrectOption) {
      bg = const Color(0xFF16A34A).withValues(alpha: 0.12);
      border = const Color(0xFF16A34A);
      fg = const Color(0xFF16A34A);
    } else if (answered && isSelected && !isCorrectOption) {
      bg = const Color(0xFF64748B).withValues(alpha: 0.12);
      border = const Color(0xFF64748B);
      fg = const Color(0xFF64748B);
    }
    return SizedBox(
      width: 64,
      height: 64,
      child: OutlinedButton(
        onPressed: answered ? null : () => _answerQuiz(option),
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

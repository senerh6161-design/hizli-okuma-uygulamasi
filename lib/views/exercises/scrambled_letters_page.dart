import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/exercise_settings_sheet.dart';

class _Puzzle {
  final List<String> letters; // 3x3 karışık harfler
  final String answer;
  // 2. ipucunda gösterilen, kelimenin ne olduğunu anlatan tanım — harf
  // vermez, sadece anlam ipucu verir.
  final String clue;
  const _Puzzle(this.letters, this.answer, this.clue);
}

// Öğrenci yazdığı cevabı büyük/küçük harf ve Türkçe İ/I farkına takılmadan
// karşılaştırabilsin diye önce Türkçe'ye özgü harfler normalize ediliyor,
// sonra küçük harfe çevriliyor.
String _normalize(String s) {
  var t = s.trim().replaceAll('İ', 'i').replaceAll('I', 'ı');
  return t.toLowerCase();
}

enum _Phase { intro, question, bolum2Intro }

// Harf kutucuğu belirirken kısa bir süre "yanarak" (parlayıp sönerek)
// geliyor — sırayla, kutudan kutuya gecikmeli tetiklenir.
class _GlowLetter extends StatefulWidget {
  final String letter;
  final double cellSize;
  final double fontSize;
  final Color color;
  final Duration delay;
  const _GlowLetter({
    super.key,
    required this.letter,
    required this.cellSize,
    required this.fontSize,
    required this.color,
    required this.delay,
  });

  @override
  State<_GlowLetter> createState() => _GlowLetterState();
}

class _GlowLetterState extends State<_GlowLetter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    // Harf sadece bir kere, sırayla gecikmeli olarak yıldız gibi parlayıp
    // geliyor — tekrar yanıp sönme yok.
    _delayTimer = Timer(widget.delay, () {
      if (!mounted) return;
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final v = _controller.value;
        final fade = (v / 0.2).clamp(0.0, 1.0);
        // Yıldız gibi ANİ parlayıp hızla sönsün diye eğri; 0'da tepe
        // (en parlak), sonra hızla düşüyor — düz doğrusal solma değil.
        final glow = (1 - v) * (1 - v);
        final scale = 1.0 + 0.12 * glow;
        return Opacity(
          opacity: fade,
          child: Transform.scale(
            scale: scale,
            child: SizedBox(
              width: widget.cellSize,
              height: widget.cellSize,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        widget.color.withValues(alpha: 0.1),
                        const Color(0xFFFFF7CC),
                        glow,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Color.lerp(
                          widget.color.withValues(alpha: 0.4),
                          const Color(0xFFFFC633),
                          glow,
                        )!,
                        width: 1 + glow,
                      ),
                      boxShadow: glow > 0.05
                          ? [
                              BoxShadow(
                                color: const Color(
                                  0xFFFFC633,
                                ).withValues(alpha: 0.7 * glow),
                                blurRadius: 18 * glow,
                                spreadRadius: 3 * glow,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      widget.letter,
                      style: TextStyle(
                        fontSize: widget.fontSize,
                        fontWeight: FontWeight.bold,
                        color: widget.color,
                      ),
                    ),
                  ),
                  if (glow > 0.15) ...[
                    Positioned(
                      top: -widget.cellSize * 0.14,
                      right: -widget.cellSize * 0.14,
                      child: Opacity(
                        opacity: glow,
                        child: Icon(
                          Icons.star_rounded,
                          size: widget.cellSize * 0.32 * glow + 4,
                          color: const Color(0xFFFFC633),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -widget.cellSize * 0.1,
                      left: -widget.cellSize * 0.1,
                      child: Opacity(
                        opacity: glow,
                        child: Icon(
                          Icons.star_rounded,
                          size: widget.cellSize * 0.2 * glow + 3,
                          color: const Color(0xFFFFC633),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// 2. Bölüm'de öğrencinin parmağıyla çizdiği yolu (ziyaret edilen kutucuklar
// arasındaki çizgileri) çiziyor.
class _TracePainter extends CustomPainter {
  final List<Offset> centers;
  final List<int> path;
  final Offset? livePosition;
  final Color color;
  const _TracePainter({
    required this.centers,
    required this.path,
    required this.livePosition,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (path.isEmpty) return;
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()..color = color;

    for (int i = 0; i < path.length - 1; i++) {
      canvas.drawLine(centers[path[i]], centers[path[i + 1]], linePaint);
    }
    if (livePosition != null) {
      canvas.drawLine(centers[path.last], livePosition!, linePaint);
    }
    for (final i in path) {
      canvas.drawCircle(centers[i], 9, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TracePainter oldDelegate) =>
      oldDelegate.path != path ||
      oldDelegate.livePosition != livePosition ||
      oldDelegate.color != color;
}

/// Klasör 3'ün dördüncü etkinliği: "Karışık Harfler". Kitaptaki 3x3
/// kutulara karışık dizilmiş 9 harften oluşan kelime bulmaca sayfasının
/// karşılığı. 1. Bölüm'de öğrenci hangi kelimenin gizlendiğini bulup
/// yazıyor; 2. Bölüm'de aynı bulmacalar tekrar geliyor ama bu sefer
/// kelimeyi harfleri sırayla parmağıyla çizerek oluşturuyor.
class ScrambledLettersPage extends StatefulWidget {
  const ScrambledLettersPage({super.key});

  @override
  State<ScrambledLettersPage> createState() => _ScrambledLettersPageState();
}

class _ScrambledLettersPageState extends State<ScrambledLettersPage> {
  Color _color = const Color(0xFF0D9488);

  static const List<Color> _colorPalette = [
    Color(0xFF0D9488),
    Color(0xFFEC4899),
    Color(0xFFEA580C),
    Color(0xFF0D9488),
    Color(0xFF7C3AED),
    Color(0xFF2563EB),
  ];
  static const int _basePoints = 50;
  static const int _hintPenalty = 10;
  static const int _maxHints = 3;
  static const int _hintIntervalSec = 30;

  // Kitaptaki örnek heceler: "ela / kan / kaç" — birleştirince
  // "ÇANAKKALE" çıkıyor, sadece anlatım amaçlı, cevap zaten gösterili.
  static const List<String> _exampleLetters = [
    'E',
    'L',
    'A',
    'K',
    'A',
    'N',
    'K',
    'A',
    'Ç',
  ];
  static const String _exampleAnswer = 'çanakkale';

  // Harfler, 2. Bölüm'de parmakla çizerken her kutucuktan bir sonrakine
  // komşu (yan yana/alt-üst/çapraz) gidilecek şekilde "yılan" deseniyle
  // (satır 1 sola→sağa, satır 2 sağa→sola, satır 3 sola→sağa) yerleştirildi
  // — kelimenin harf sırası, ızgarada hep bitişik kutucuklardan geçiyor.
  static const List<_Puzzle> _puzzles = [
    _Puzzle(
      ['T', 'E', 'K', 'L', 'O', 'N', 'O', 'J', 'İ'],
      'teknoloji',
      'Bilimin günlük hayatımıza kazandırdığı araç, makine ve yöntemlerin '
          'tümüne verilen isim.',
    ),
    _Puzzle(
      ['G', 'A', 'L', 'İ', 'B', 'İ', 'Y', 'E', 'T'],
      'galibiyet',
      'Bir yarışmayı, maçı ya da mücadeleyi kazanmaya verilen isim.',
    ),
    _Puzzle(
      ['K', 'Ü', 'T', 'H', 'P', 'Ü', 'A', 'N', 'E'],
      'kütüphane',
      'Kitapların bir arada saklandığı ve okunabildiği yer.',
    ),
    _Puzzle(
      ['M', 'E', 'D', 'İ', 'N', 'E', 'Y', 'E', 'T'],
      'medeniyet',
      'Bir toplumun ulaştığı kültürel ve teknik gelişmişlik düzeyi.',
    ),
    _Puzzle(
      ['M', 'A', 'T', 'A', 'M', 'E', 'T', 'İ', 'K'],
      'matematik',
      'Sayılar, şekiller ve işlemlerle uğraşan bilim dalı.',
    ),
  ];

  _Phase _phase = _Phase.intro;
  bool _hasCompletedOnce = false;

  // 0 = 1. Bölüm (yazarak cevapla), 1 = 2. Bölüm (çizerek cevapla).
  int _bolumIndex = 0;
  int _questionIndex = 0;
  int _correctCount = 0;
  int _totalScore = 0;
  int _attemptCount = 0;
  int _hintsUsed = 0;
  int _elapsedSec = 0;
  Timer? _elapsedTimer;
  Timer? _hintTimer;
  bool _answered = false;
  bool _isCorrect = false;
  bool _revealed = false;
  bool _lastWrong = false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // 2. Bölüm: parmakla çizilen yol.
  List<int> _tracePath = [];
  Offset? _dragLocalPosition;
  bool _traceWrong = false;

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _hintTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _phase = _Phase.question;
      _bolumIndex = 0;
      _questionIndex = 0;
      _correctCount = 0;
      _totalScore = 0;
      _resetQuestionState();
    });
    _startQuestionTimers();
  }

  void _startBolum2() {
    setState(() {
      _phase = _Phase.question;
      _bolumIndex = 1;
      _questionIndex = 0;
      _resetQuestionState();
    });
    _startQuestionTimers();
  }

  void _resetQuestionState() {
    _attemptCount = 0;
    _hintsUsed = 0;
    _answered = false;
    _isCorrect = false;
    _revealed = false;
    _lastWrong = false;
    _controller.clear();
    _tracePath = [];
    _dragLocalPosition = null;
    _traceWrong = false;
  }

  // Her soru başında süre sıfırlanıp yeniden başlıyor; 30 saniyede bir,
  // cevaplanmamışsa ve ipucu hakkı varsa otomatik ipucu geliyor.
  void _startQuestionTimers() {
    _elapsedTimer?.cancel();
    _hintTimer?.cancel();
    setState(() => _elapsedSec = 0);
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSec++);
    });
    _hintTimer = Timer.periodic(const Duration(seconds: _hintIntervalSec), (_) {
      if (!mounted) return;
      if (!_answered && _hintsUsed < _maxHints) _useHint();
    });
  }

  void _stopQuestionTimers() {
    _elapsedTimer?.cancel();
    _hintTimer?.cancel();
  }

  void _useHint() {
    if (_answered || _hintsUsed >= _maxHints) return;
    setState(() => _hintsUsed++);
    SoundManager.playGentleTap();
  }

  void _submitAnswer() {
    if (_answered) return;
    final input = _controller.text;
    if (input.trim().isEmpty) return;
    final puzzle = _puzzles[_questionIndex];
    if (_normalize(input) == _normalize(puzzle.answer)) {
      _handleCorrect();
    } else {
      _handleWrong();
    }
  }

  void _handleCorrect() {
    SoundManager.playCorrect();
    _stopQuestionTimers();
    final points = _basePoints - _hintsUsed * _hintPenalty;
    setState(() {
      _answered = true;
      _isCorrect = true;
      _lastWrong = false;
      _correctCount++;
      _totalScore += points;
    });
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      _nextQuestion();
    });
  }

  void _handleWrong() {
    _attemptCount++;
    if (_attemptCount >= 2) {
      SoundManager.playGentleTap();
      _stopQuestionTimers();
      setState(() {
        _answered = true;
        _isCorrect = false;
        _revealed = true;
      });
    } else {
      SoundManager.playGentleTap();
      setState(() => _lastWrong = true);
    }
  }

  // --- 2. Bölüm: harfleri parmakla çizerek bulma ---

  int? _cellAtPosition(Offset local, Size size) {
    final cellW = size.width / 3;
    final cellH = size.height / 3;
    final col = (local.dx / cellW).floor();
    final row = (local.dy / cellH).floor();
    if (col < 0 || col > 2 || row < 0 || row > 2) return null;
    return row * 3 + col;
  }

  void _traceStart(DragStartDetails details, Size size) {
    if (_answered) return;
    final index = _cellAtPosition(details.localPosition, size);
    if (index == null) return;
    setState(() {
      _tracePath = [index];
      _dragLocalPosition = details.localPosition;
      _traceWrong = false;
    });
  }

  void _traceUpdate(DragUpdateDetails details, Size size) {
    if (_answered) return;
    final index = _cellAtPosition(details.localPosition, size);
    setState(() {
      _dragLocalPosition = details.localPosition;
      if (index != null && !_tracePath.contains(index)) {
        _tracePath.add(index);
      }
    });
  }

  void _traceEnd() {
    if (_answered) return;
    final puzzle = _puzzles[_questionIndex];
    if (_tracePath.length != puzzle.letters.length) {
      // Yarım bırakılmış bir çizim — deneme sayılmadan sadece temizleniyor.
      setState(() {
        _tracePath = [];
        _dragLocalPosition = null;
      });
      return;
    }
    final drawn = _tracePath.map((i) => puzzle.letters[i]).join();
    setState(() => _dragLocalPosition = null);
    if (_normalize(drawn) == _normalize(puzzle.answer)) {
      _handleCorrect();
    } else {
      setState(() => _traceWrong = true);
      Future.delayed(const Duration(milliseconds: 550), () {
        if (!mounted) return;
        setState(() {
          _tracePath = [];
          _traceWrong = false;
        });
      });
      _handleWrong();
    }
  }

  void _nextQuestion() {
    if (_questionIndex < _puzzles.length - 1) {
      setState(() {
        _questionIndex++;
        _resetQuestionState();
      });
      if (_bolumIndex == 0) _focusNode.requestFocus();
      _startQuestionTimers();
    } else if (_bolumIndex == 0) {
      setState(() => _phase = _Phase.bolum2Intro);
    } else {
      _finishAll();
    }
  }

  void _finishAll() {
    _hasCompletedOnce = true;
    final total = _puzzles.length * 2;

    final percent = ((_correctCount / total) * 100).round();
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Karışık Harfler',
      result: '$_correctCount/$total doğru · $_totalScore puan',
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
            Text('Doğru: $_correctCount / $total (%$percent)'),
            const SizedBox(height: 4),
            Text(
              'Toplam Puan: $_totalScore',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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
        appBar: AppBar(
          title: const Text('🔤 Karışık Harfler'),
          actions: [
            IconButton(
              onPressed: () => showExerciseSettingsSheet(
                context,
                currentColor: _color,
                colorOptions: _colorPalette,
                onColorChanged: (c) => setState(() => _color = c),
              ),
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: 'Ayarlar',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: switch (_phase) {
              _Phase.intro => _buildIntro(),
              _Phase.bolum2Intro => _buildBolum2Intro(),
              _Phase.question => _buildQuestion(
                key: ValueKey('q-$_bolumIndex-$_questionIndex'),
              ),
            },
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
                  child: Text(
                    'Etkinlik 4 · 1. Bölüm · Karışık Harfler',
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
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCFBF1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _color, width: 1.5),
                      ),
                      child: const Text(
                        'Amaç: Karışık harfleri zihinde hızlıca '
                        'birleştirip anlamlı bir kelime kurabilmek.\n\n'
                        'Yöntem: Kutudaki 9 harfi kullanarak hangi '
                        'kelimeyi oluşturduğunu bul ve yaz.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF115E59),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildExampleBox(),
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
                          Icon(
                            Icons.info_outline_rounded,
                            color: _color,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '5 tane karışık harf kutumuz var, hepsinde '
                              'hangi kelimenin gizlendiğini bulup '
                              'yazacağız!',
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

  Widget _buildBolum2Intro() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: Text('✏️', style: TextStyle(fontSize: 64))),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '1. Bölümü tamamladık! Şimdi aynı 5 bulmaca tekrar '
                    'gelecek ama bu sefer kelimeyi yazmayacağız — '
                    'harfleri doğru sırayla parmağınla çizerek '
                    'birleştireceksin!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: _color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
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
              ],
            ),
          ),
        );
      },
    );
  }

  // Örnek zaten çözülmüş gösteriliyor, öğrenci mekaniği burada görüyor.
  Widget _buildExampleBox() {
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
          Center(
            child: SizedBox(
              width: 150,
              height: 150,
              child: _letterGrid(_exampleLetters, cellSize: 44, fontSize: 20),
            ),
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              children: [
                const TextSpan(text: 'Bu 9 harfi birleştirince '),
                TextSpan(
                  text: '"${_exampleAnswer.toUpperCase()}"',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16A34A),
                  ),
                ),
                const TextSpan(text: ' kelimesi çıkıyor!'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _letterGrid(
    List<String> letters, {
    required double cellSize,
    required double fontSize,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: letters.length,
      itemBuilder: (context, index) {
        return _GlowLetter(
          key: ValueKey('letter-$index-${letters[index]}'),
          letter: letters[index],
          cellSize: cellSize,
          fontSize: fontSize,
          color: _color,
          delay: Duration(milliseconds: 90 * index),
        );
      },
    );
  }

  // 3 ipucu farklı şeyler açar: 1. ipucu ilk harfi, 2. ipucu kelimenin ne
  // olduğunu anlatan bir tanımı (harf vermez), 3. ipucu son harfi gösterir.
  // Ortadaki harfler hiçbir zaman açılmaz — henüz açılmamış harfler alt
  // çizgili boş kutucuk olarak duruyor.
  Widget _hintRow(String answer) {
    final lastIndex = answer.length - 1;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      children: [
        for (int i = 0; i < answer.length; i++)
          Container(
            width: 24,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: _color, width: 2)),
            ),
            child: Text(
              ((i == 0 && _hintsUsed >= 1) ||
                      (i == lastIndex && _hintsUsed >= 3))
                  ? answer[i].toUpperCase()
                  : '',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _color,
              ),
            ),
          ),
      ],
    );
  }

  // 2. ipucunda gösterilen, kelimenin ne olduğunu anlatan tanım kutusu.
  Widget _clueBox(String clue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, size: 16, color: _color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              clue,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Bölüm: harfleri parmakla sırayla çizerek birleştirme ızgarası.
  Widget _buildTraceGrid(_Puzzle puzzle) {
    const size = Size(240, 240);
    final cellSize = size.width / 3;
    final centers = [
      for (int i = 0; i < 9; i++)
        Offset(
          (i % 3) * cellSize + cellSize / 2,
          (i ~/ 3) * cellSize + cellSize / 2,
        ),
    ];
    final lineColor = _traceWrong
        ? const Color(0xFFE11D48)
        : (_answered && _isCorrect ? const Color(0xFF16A34A) : _color);
    return SizedBox(
      width: size.width,
      height: size.height,
      child: GestureDetector(
        onPanStart: (d) => _traceStart(d, size),
        onPanUpdate: (d) => _traceUpdate(d, size),
        onPanEnd: (_) => _traceEnd(),
        child: Stack(
          children: [
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemCount: puzzle.letters.length,
              itemBuilder: (context, index) {
                final visited = _tracePath.contains(index);
                Color bg = Colors.white;
                Color border = _color.withValues(alpha: 0.35);
                if (visited) {
                  bg = lineColor.withValues(alpha: 0.15);
                  border = lineColor;
                }
                return Container(
                  margin: const EdgeInsets.all(3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: border, width: 1.5),
                  ),
                  child: Text(
                    puzzle.letters[index],
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: visited ? lineColor : _color,
                    ),
                  ),
                );
              },
            ),
            IgnorePointer(
              child: CustomPaint(
                size: size,
                painter: _TracePainter(
                  centers: centers,
                  path: _tracePath,
                  livePosition: _dragLocalPosition,
                  color: lineColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion({required Key key}) {
    final puzzle = _puzzles[_questionIndex];
    final isTrace = _bolumIndex == 1;
    return KeyedSubtree(
      key: key,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          '${_bolumIndex + 1}. Bölüm · Soru '
                          '${_questionIndex + 1}/${_puzzles.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _color,
                          ),
                        ),
                      ),
                      Text(
                        'Puan: $_totalScore',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Text(
                          '⏱ $_elapsedSec sn',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: (_answered || _hintsUsed >= _maxHints)
                            ? null
                            : _useHint,
                        icon: const Icon(Icons.lightbulb_outline, size: 18),
                        label: Text('İpucu ($_hintsUsed/$_maxHints)'),
                        style: TextButton.styleFrom(
                          foregroundColor: _color,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: isTrace
                        ? _buildTraceGrid(puzzle)
                        : SizedBox(
                            width: 220,
                            height: 220,
                            child: _letterGrid(
                              puzzle.letters,
                              cellSize: 64,
                              fontSize: 28,
                            ),
                          ),
                  ),
                  if (_hintsUsed > 0) ...[
                    const SizedBox(height: 16),
                    _hintRow(puzzle.answer),
                  ],
                  if (_hintsUsed >= 2) ...[
                    const SizedBox(height: 12),
                    _clueBox(puzzle.clue),
                  ],
                  if (_hintsUsed >= 1) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.priority_high_rounded,
                            size: 16,
                            color: Colors.amber.shade800,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Dikkat! Kelimeyi bütün olarak görmeye '
                              'çalışalım.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (isTrace)
                    Text(
                      _answered ? '' : 'Harfleri doğru sırayla parmağınla çiz!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: !_answered,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submitAnswer(),
                      onChanged: (_) {
                        if (_lastWrong) setState(() => _lastWrong = false);
                      },
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Kelimeyi yaz...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: _color, width: 2),
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  if (_lastWrong && !_answered)
                    const Center(
                      child: Text(
                        '🤔 Tekrar dene!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFFE11D48),
                        ),
                      ),
                    ),
                  if (_answered && _isCorrect)
                    const Center(
                      child: Text(
                        '🎉 Harikasın, doğru!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  if (_answered && _revealed)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Text.rich(
                        textAlign: TextAlign.center,
                        TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.amber.shade900,
                          ),
                          children: [
                            const TextSpan(text: '📖 Doğrusu: '),
                            TextSpan(
                              text: puzzle.answer.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (!_answered && !isTrace)
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitAnswer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'KONTROL ET',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  else if (_revealed)
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _nextQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'DEVAM ET',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

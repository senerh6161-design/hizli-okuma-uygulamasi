import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';
import '../../widgets/exercise_settings_sheet.dart';

enum _Phase {
  intro,
  ready,
  bolum2Intro,
  flash,
  grid,
  bolum3Intro,
  bolum3Warmup,
  bolum3Ready,
  bolum3Reveal,
  bolum3Quiz,
}

class _TripletRow {
  final String left;
  final String center;
  final String right;
  const _TripletRow(this.left, this.center, this.right);
}

// 3. Bölüm'ün sayma quiz'inde sorulan tek bir soru: "X kaç defa kullanıldı?"
class _CountQuestion {
  final String number;
  final int correctCount;
  const _CountQuestion(this.number, this.correctCount);
}

// 3. Bölüm'de sütunları ayıran dikey kesikli çizgiler.
class _VerticalDashedLinesPainter extends CustomPainter {
  final Color color;
  const _VerticalDashedLinesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6;
    const dashHeight = 6.0;
    const dashSpace = 5.0;
    for (final xFraction in [1 / 3, 2 / 3]) {
      final x = size.width * xFraction;
      double y = 0;
      while (y < size.height) {
        canvas.drawLine(Offset(x, y), Offset(x, y + dashHeight), paint);
        y += dashHeight + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalDashedLinesPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Klasör 4'ün altıncı etkinliği: word_recall_grid_page.dart'ın ("Nerede
/// Gördüm?", Klasör 2 · Etkinlik 10) 3 basamaklı sayı versiyonu. Sabit bir
/// 3x3 sayı karesi var; her turda bu 9 sayıdan biri tek başına kısaca
/// gösterilip kayboluyor, sonra kare tekrar beliriyor — öğrenci o sayının
/// karede NEREDE olduğunu hızlıca bulup dokunmalı. 1. Bölüm 2 ve 3
/// basamaklı karışık sayılarla, 2. Bölüm sadece 3 basamaklı sayılarla —
/// her ikisinde de aynı 9 sayı sabit kalıyor, sadece yerleri karışıyor.
/// 3. Bölüm: kitaptaki 3 sütunlu sayfa gibi — her satırda ortadaki sayıya
/// odaklanıp yan taraftaki BENZER görünüşlü (aynı rakamlar, farklı sırada)
/// sayıları da yakalamaya çalışıyoruz. Önce bir antreman: satırlar sırayla
/// yanıp söner, ortadaki sayının altında odak noktası belirir. Sonra asıl
/// tur: satırlar sırayla ekrana gelir (bazı sayılar birden fazla kez
/// tekrar eder), hepsi göründükten sonra "X kaç defa kullanıldı?" diye
/// 10 soru sorulur. Puansız, süre ölçülür.
class NumberRecallGridPage extends StatefulWidget {
  const NumberRecallGridPage({super.key});

  @override
  State<NumberRecallGridPage> createState() => _NumberRecallGridPageState();
}

class _NumberRecallGridPageState extends State<NumberRecallGridPage> {
  Color _color = const Color(0xFFDC2626);

  static const List<Color> _colorPalette = [
    Color(0xFFDC2626),
    Color(0xFFEC4899),
    Color(0xFFEA580C),
    Color(0xFF0D9488),
    Color(0xFF7C3AED),
    Color(0xFF2563EB),
  ];
  static const int _roundCount = 20;
  static const List<String> _speedLabels = ['Yavaş', 'Orta', 'Hızlı'];
  static const List<int> _flashMsBySpeed = [1500, 1000, 600];
  static const List<int> _answerTimeMsBySpeed = [7000, 5000, 3500];

  // 1. Bölüm: 2 ve 3 basamaklı karışık 9 sayı — her turda aynı 9 sayı,
  // sadece karedeki yerleri karışıyor.
  static const List<String> _numbersMixed = [
    '15', '104', '38', '256', '62', '347', '91', '578', '823', //
  ];

  // 2. Bölüm: sadece 3 basamaklı 9 sayı.
  static const List<String> _numbersThreeDigit = [
    '137', '264', '358', '419', '572', '683', '745', '891', '926', //
  ];

  // 3. Bölüm: her satırda ortadaki sayıyla aynı rakamlardan oluşan,
  // sadece sırası farklı iki "benzer" sayı solda ve sağda.
  static const List<_TripletRow> _tripletRows = [
    _TripletRow('432', '43', '413'),
    _TripletRow('142', '124', '214'),
    _TripletRow('87', '78', '708'),
    _TripletRow('365', '356', '536'),
    _TripletRow('219', '291', '921'),
    _TripletRow('26', '62', '620'),
    _TripletRow('750', '705', '570'),
    _TripletRow('93', '39', '309'),
    _TripletRow('418', '481', '841'),
    _TripletRow('71', '17', '170'),
    _TripletRow('962', '926', '296'),
    _TripletRow('85', '58', '508'),
    _TripletRow('643', '634', '364'),
    _TripletRow('231', '213', '312'),
  ];

  // Sayma quiz'inde sorulacak 10 sayı ve satırlar arasında kaçar kez
  // tekrar edecekleri (hepsi birden fazla kez kullanılıyor).
  static const Map<String, int> _quizTargetCounts = {
    '43': 3,
    '124': 2,
    '78': 3,
    '356': 2,
    '291': 3,
    '62': 2,
    '705': 3,
    '39': 2,
    '481': 3,
    '17': 2,
  };

  final Random _random = Random();
  _Phase _phase = _Phase.intro;
  bool _hasCompletedOnce = false;
  bool _isPaused = false;
  bool _isDemoRound = false;
  int _currentBolum = 1;
  int _speedLevel = 1;
  static const int _demoRoundCount = 10;
  int _demoRoundIndex = 0;

  List<String> _gridNumbers = [];
  String? _lastTarget;
  int _roundIndex = 0;
  int _totalScore = 0;
  int _correctCount = 0;
  int _targetIndex = 0;
  int _elapsedMs = 0;
  Timer? _answerTimer;
  Timer? _tickTimer;
  Timer? _flashTimer;
  int? _selectedIndex;
  bool _answered = false;

  int _bolum3ElapsedSec = 0;
  Timer? _bolum3Ticker;

  // 3. Bölüm antremanı: satır satır yanıp sönme.
  int _warmupRowIndex = -1;
  Timer? _bolum3WarmupTimer;

  // 3. Bölüm asıl turu: satır satır ekrana gelme + sayma quiz'i.
  List<_TripletRow> _bolum3QuizRows = [];
  int _revealRowCount = 0;
  Timer? _revealTimer;
  final ScrollController _revealScrollController = ScrollController();
  List<_CountQuestion> _quizQuestions = [];
  int _quizIndex = 0;
  int _quizCorrect = 0;
  int? _quizSelectedAnswer;
  bool _quizAnswered = false;

  @override
  void dispose() {
    _answerTimer?.cancel();
    _tickTimer?.cancel();
    _flashTimer?.cancel();
    _bolum3Ticker?.cancel();
    _bolum3WarmupTimer?.cancel();
    _revealTimer?.cancel();
    _revealScrollController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _totalScore = 0;
      _correctCount = 0;
    });
    _startBolum(1);
  }

  void _startBolum(int bolum) {
    setState(() {
      _currentBolum = bolum;
      _roundIndex = 0;
    });
    if (bolum == 1) {
      _startDemoRound();
    } else {
      _startRound();
    }
  }

  List<String> _poolForCurrentBolum() =>
      _currentBolum == 1 ? _numbersMixed : _numbersThreeDigit;

  // Antreman turunda hız her zaman sabit ve yavaş — bu tur öğretici,
  // öğrencinin hızına göre değişmemeli.
  static const int _demoFlashMs = 2200;
  static const int _demoRevealDelayMs = 1300;
  static const int _demoRevealHoldMs = 1800;

  void _startRound() {
    _answerTimer?.cancel();
    _tickTimer?.cancel();
    _flashTimer?.cancel();
    final pool = _poolForCurrentBolum();
    _gridNumbers = [...pool]..shuffle(_random);
    int target;
    do {
      target = _random.nextInt(_gridNumbers.length);
    } while (_gridNumbers.length > 1 && _gridNumbers[target] == _lastTarget);
    _lastTarget = _gridNumbers[target];
    setState(() {
      _phase = _Phase.flash;
      _targetIndex = target;
      _selectedIndex = null;
      _answered = false;
    });
    final flashMs = _isDemoRound ? _demoFlashMs : _flashMsBySpeed[_speedLevel];
    _flashTimer = Timer(Duration(milliseconds: flashMs), () {
      if (!mounted) return;
      if (_isDemoRound) {
        _startDemoReveal();
      } else {
        _startAnswerWindow();
      }
    });
  }

  void _startDemoRound() {
    _isDemoRound = true;
    _demoRoundIndex = 0;
    _startRound();
  }

  void _skipDemo() {
    _answerTimer?.cancel();
    _tickTimer?.cancel();
    _flashTimer?.cancel();
    _isDemoRound = false;
    setState(() => _phase = _Phase.ready);
  }

  // Antreman turunda öğrenci aramıyor/dokunmuyor — biz doğru kutuyu
  // yavaşça kendimiz gösteriyoruz, sonra otomatik gerçek turlara geçiyoruz.
  void _startDemoReveal() {
    setState(() {
      _phase = _Phase.grid;
      _selectedIndex = null;
      _answered = false;
    });
    _answerTimer = Timer(const Duration(milliseconds: _demoRevealDelayMs), () {
      if (!mounted) return;
      setState(() {
        _selectedIndex = _targetIndex;
        _answered = true;
      });
      SoundManager.playCorrect();
      Future.delayed(const Duration(milliseconds: _demoRevealHoldMs), () {
        if (!mounted) return;
        if (_demoRoundIndex < _demoRoundCount - 1) {
          setState(() => _demoRoundIndex++);
          _startRound();
        } else {
          _isDemoRound = false;
          setState(() => _phase = _Phase.ready);
        }
      });
    });
  }

  void _startAnswerWindow() {
    setState(() {
      _phase = _Phase.grid;
      _elapsedMs = 0;
    });
    final answerTimeMs = _answerTimeMsBySpeed[_speedLevel];
    _tickTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) return;
      setState(() => _elapsedMs = (_elapsedMs + 80).clamp(0, answerTimeMs));
    });
    _answerTimer = Timer(Duration(milliseconds: answerTimeMs), () {
      if (!mounted) return;
      _answerRound(null);
    });
  }

  void _pauseGame() {
    _answerTimer?.cancel();
    _tickTimer?.cancel();
    _flashTimer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resumeGame() {
    setState(() => _isPaused = false);
    if (_isDemoRound) {
      // Antreman turu basit tekrar-göster mantığında — kaldığı yerden
      // devam etmek yerine o adımı baştan gösteriyoruz, yeterince kısa.
      if (_phase == _Phase.flash) {
        _flashTimer = Timer(const Duration(milliseconds: _demoFlashMs), () {
          if (!mounted) return;
          _startDemoReveal();
        });
      } else if (_phase == _Phase.grid && !_answered) {
        _startDemoReveal();
      }
    } else if (_phase == _Phase.flash) {
      _flashTimer = Timer(
        Duration(milliseconds: _flashMsBySpeed[_speedLevel]),
        () {
          if (!mounted) return;
          _startAnswerWindow();
        },
      );
    } else if (_phase == _Phase.grid) {
      final answerTimeMs = _answerTimeMsBySpeed[_speedLevel];
      final remainingMs = (answerTimeMs - _elapsedMs).clamp(0, answerTimeMs);
      _tickTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
        if (!mounted) return;
        setState(() => _elapsedMs = (_elapsedMs + 80).clamp(0, answerTimeMs));
      });
      _answerTimer = Timer(Duration(milliseconds: remainingMs), () {
        if (!mounted) return;
        _answerRound(null);
      });
    }
  }

  void _answerRound(int? index) {
    if (_answered) return;
    _tickTimer?.cancel();
    _answerTimer?.cancel();
    final isCorrect = index != null && index == _targetIndex;
    setState(() {
      _selectedIndex = index;
      _answered = true;
    });
    if (isCorrect) {
      if (!_isDemoRound) {
        final remainingFraction =
            (1 - (_elapsedMs / _answerTimeMsBySpeed[_speedLevel])).clamp(
              0.0,
              1.0,
            );
        final points = (100 * remainingFraction).round().clamp(20, 100);
        _totalScore += points;
        _correctCount++;
      }
      SoundManager.playCorrect();
    } else {
      SoundManager.playGentleTap();
    }
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_isDemoRound) {
        _isDemoRound = false;
        _startRound();
      } else if (_roundIndex < _roundCount - 1) {
        setState(() => _roundIndex++);
        _startRound();
      } else if (_currentBolum == 1) {
        setState(() => _phase = _Phase.bolum2Intro);
      } else {
        setState(() => _phase = _Phase.bolum3Intro);
      }
    });
  }

  void _skipBolum() {
    _answerTimer?.cancel();
    _tickTimer?.cancel();
    _flashTimer?.cancel();
    if (_currentBolum == 1) {
      setState(() => _phase = _Phase.bolum2Intro);
    } else {
      setState(() => _phase = _Phase.bolum3Intro);
    }
  }

  // Antreman: 3. Bölüm satırları teker teker (orijinal 14 satır, tekrarsız)
  // yanıp söner — öğrenci sağ/sol komşu sayılara bakmaya alışır.
  void _startBolum3Warmup() {
    _bolum3WarmupTimer?.cancel();
    setState(() {
      _phase = _Phase.bolum3Warmup;
      _warmupRowIndex = -1;
    });
    int i = -1;
    _bolum3WarmupTimer = Timer.periodic(const Duration(milliseconds: 700), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      i++;
      if (i >= _tripletRows.length) {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) setState(() => _phase = _Phase.bolum3Ready);
        });
        return;
      }
      setState(() => _warmupRowIndex = i);
    });
  }

  void _skipBolum3Warmup() {
    _bolum3WarmupTimer?.cancel();
    setState(() => _phase = _Phase.bolum3Ready);
  }

  // Bazı sayıları (_quizTargetCounts) birden fazla kez tekrarlayan asıl
  // satır listesini kurar ve karıştırır.
  List<_TripletRow> _buildBolum3QuizRows() {
    final rows = [..._tripletRows];
    for (final row in _tripletRows) {
      final extra = (_quizTargetCounts[row.center] ?? 1) - 1;
      for (int k = 0; k < extra; k++) {
        rows.add(row);
      }
    }
    rows.shuffle(_random);
    return rows;
  }

  List<_CountQuestion> _buildQuizQuestions() {
    final qs =
        _quizTargetCounts.entries
            .map((e) => _CountQuestion(e.key, e.value))
            .toList()
          ..shuffle(_random);
    return qs;
  }

  List<int> _answerOptionsFor(int correct) {
    final options = <int>{correct};
    for (final delta in [-2, -1, 1, 2, 3]) {
      if (options.length >= 4) break;
      final v = correct + delta;
      if (v >= 1) options.add(v);
    }
    return options.toList()..shuffle(_random);
  }

  // Satırlar teker teker ekrana gelir; hepsi bittiğinde sayma quiz'i başlar.
  void _startBolum3Reveal() {
    _bolum3QuizRows = _buildBolum3QuizRows();
    _quizQuestions = _buildQuizQuestions();
    _revealTimer?.cancel();
    _bolum3Ticker?.cancel();
    setState(() {
      _phase = _Phase.bolum3Reveal;
      _revealRowCount = 0;
      _bolum3ElapsedSec = 0;
    });
    _bolum3Ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _bolum3ElapsedSec++);
    });
    int i = 0;
    _revealTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (i >= _bolum3QuizRows.length) {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 700), _startBolum3Quiz);
        return;
      }
      setState(() => _revealRowCount = i + 1);
      i++;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_revealScrollController.hasClients) {
          _revealScrollController.animateTo(
            _revealScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  void _skipBolum3Reveal() {
    _revealTimer?.cancel();
    _startBolum3Quiz();
  }

  void _startBolum3Quiz() {
    _revealTimer?.cancel();
    setState(() {
      _phase = _Phase.bolum3Quiz;
      _quizIndex = 0;
      _quizCorrect = 0;
      _quizSelectedAnswer = null;
      _quizAnswered = false;
    });
  }

  void _answerQuiz(int chosen) {
    if (_quizAnswered) return;
    final q = _quizQuestions[_quizIndex];
    final isCorrect = chosen == q.correctCount;
    setState(() {
      _quizAnswered = true;
      _quizSelectedAnswer = chosen;
      if (isCorrect) _quizCorrect++;
    });
    if (isCorrect) {
      SoundManager.playCorrect();
    } else {
      SoundManager.playGentleTap();
    }
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      if (_quizIndex < _quizQuestions.length - 1) {
        setState(() {
          _quizIndex++;
          _quizAnswered = false;
          _quizSelectedAnswer = null;
        });
      } else {
        _finishBolum3();
      }
    });
  }

  void _finishBolum3() {
    _bolum3Ticker?.cancel();
    _finishAll();
  }

  void _finishAll() {
    _answerTimer?.cancel();
    _tickTimer?.cancel();
    _flashTimer?.cancel();
    _hasCompletedOnce = true;

    final totalRounds = _roundCount * 2;
    final percent = ((_correctCount / totalRounds) * 100).round();
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    SoundManager.playAchievement();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Nerede Gördüm? (Sayılar)',
      result:
          '$_correctCount/$totalRounds doğru · $_totalScore puan · '
          '3. Bölüm: $_quizCorrect/${_quizQuestions.length} doğru '
          '(${_bolum3ElapsedSec}sn)',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('👏 Harikasın! Etkinlik Tamamlandı!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Doğru: $_correctCount / $totalRounds (%$percent)'),
            const SizedBox(height: 4),
            Text(
              'Toplam puan: $_totalScore 🎉',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '3. Bölüm sayma quiz\'i: $_quizCorrect/${_quizQuestions.length} doğru',
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
          title: const Text('🔍 Nerede Gördüm?'),
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
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: switch (_phase) {
                  _Phase.intro => _buildIntro(),
                  _Phase.ready => _buildReady(),
                  _Phase.bolum2Intro => _buildBolum2Intro(),
                  _Phase.flash || _Phase.grid => _buildRound(
                    key: ValueKey(
                      'round-$_currentBolum-$_roundIndex-$_isDemoRound-$_phase',
                    ),
                  ),
                  _Phase.bolum3Intro => _buildBolum3Intro(),
                  _Phase.bolum3Warmup => _buildBolum3Warmup(),
                  _Phase.bolum3Ready => _buildBolum3Ready(),
                  _Phase.bolum3Reveal => _buildBolum3Reveal(),
                  _Phase.bolum3Quiz => _buildBolum3Quiz(),
                },
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
    return _buildIntroScreen(
      badge: 'Etkinlik 6 · 1. Bölüm · Nerede Gördüm?',
      emoji: '🔍',
      instruction:
          'Önce bir sayı tek başına kısaca gösterilecek. Sonra 9 sayılık '
          'kare belirecek — az önce gördüğün sayının karede NEREDE '
          'olduğunu hızlıca bulup dokun! Bu bölümde 2 ve 3 basamaklı '
          'sayılar karışık — aynı 9 sayı hep aynı, sadece yerleri '
          'karışıyor. Başlamadan önce puansız bir antreman turu var.',
      onStart: _startGame,
    );
  }

  Widget _buildReady() {
    return _buildIntroScreen(
      badge: 'Etkinlik 6 · 1. Bölüm',
      emoji: '🎯',
      instruction:
          'Antremanı tamamladık! Şimdi sıra sende — dikkat et, bir sayı '
          'kısaca gösterilecek, sonra karede NEREDE olduğunu hızlıca '
          'bulup dokunacaksın. Hazır mısın?',
      onStart: () {
        setState(() {
          _roundIndex = 0;
          _totalScore = 0;
          _correctCount = 0;
        });
        _startRound();
      },
    );
  }

  Widget _buildBolum2Intro() {
    return _buildIntroScreen(
      badge: 'Etkinlik 6 · 2. Bölüm · Sadece 3 Basamaklı',
      emoji: '🔢',
      instruction:
          'Aynı oyun, bu kez hepsi 3 basamaklı sayı! Yine aynı 9 sayı hep '
          'aynı kalıyor, sadece karedeki yerleri karışıyor. Bir sayı '
          'kısaca gösterilecek, sonra karede NEREDE olduğunu bulup dokun!',
      onStart: () => _startBolum(2),
    );
  }

  Widget _buildIntroScreen({
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
                          Icon(
                            Icons.info_outline_rounded,
                            color: _color,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              instruction,
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
    final remainingFraction = _phase == _Phase.grid
        ? (1 - (_elapsedMs / _answerTimeMsBySpeed[_speedLevel])).clamp(0.0, 1.0)
        : 1.0;
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
                  _isDemoRound
                      ? '🎓 Antreman Turu ${_demoRoundIndex + 1}/$_demoRoundCount'
                      : '$_currentBolum. Bölüm · Tur ${_roundIndex + 1}/$_roundCount',
                  style: TextStyle(fontWeight: FontWeight.bold, color: _color),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isDemoRound ? 'Puansız' : 'Puan: $_totalScore',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _color,
                    ),
                  ),
                  if (!_answered)
                    buildPauseButton(color: _color, onPressed: _pauseGame),
                ],
              ),
            ],
          ),
          if (_isDemoRound) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Text(
                _phase == _Phase.flash
                    ? 'Önce sana bir sayı göstereceğiz, dikkatlice bak...'
                    : (_answered
                          ? 'İşte burada! Sayı buradaymış.'
                          : 'Şimdi nerede olduğunu sana göstereceğiz...'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade900,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          _speedChipRow(),
          const SizedBox(height: 10),
          if (_phase == _Phase.grid && !_isDemoRound)
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
            )
          else
            const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: _phase == _Phase.flash
                  ? Text(
                      _gridNumbers[_targetIndex],
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: _color,
                      ),
                    )
                  : _buildGrid(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _isDemoRound ? _skipDemo : _skipBolum,
              icon: const Icon(Icons.skip_next_rounded),
              label: Text(
                _isDemoRound
                    ? 'ANTREMANI GEÇ'
                    : (_currentBolum == 1 ? '2. BÖLÜME GEÇ' : '3. BÖLÜME GEÇ'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _color,
                side: BorderSide(color: _color),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return SizedBox(
      width: 320,
      height: 320,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _gridNumbers.length,
        itemBuilder: (context, index) {
          final isCorrectCell = index == _targetIndex;
          final isSelected = _selectedIndex == index;
          Color bg = _color.withValues(alpha: 0.08);
          Color border = _color.withValues(alpha: 0.3);
          Color fg = const Color(0xFF0F172A);
          if (_answered) {
            if (isCorrectCell) {
              bg = const Color(0xFF16A34A).withValues(alpha: 0.14);
              border = const Color(0xFF16A34A);
              fg = const Color(0xFF16A34A);
            } else if (isSelected) {
              bg = const Color(0xFFE11D48).withValues(alpha: 0.14);
              border = const Color(0xFFE11D48);
              fg = const Color(0xFFE11D48);
            }
          }
          return GestureDetector(
            onTap: (_answered || _isDemoRound)
                ? null
                : () => _answerRound(index),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border, width: 2),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _gridNumbers[index],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBolum3Intro() {
    return _buildBolum3CenteredScreen(
      emoji: '👁️',
      badge: 'Etkinlik 6 · 3. Bölüm',
      instruction:
          'İki bölümü de bitirdik! Şimdi 3. Bölüm: her satırda 3 sayı var. '
          'Ortadaki sayıya odaklan ve gözünü oynatmadan yanındaki sayılara '
          'da bakmaya çalış — dikkat et, yandaki sayılar ortadakiyle AYNI '
          'rakamlardan oluşuyor ama sırası farklı, kolayca '
          'karıştırabilirsin! Önce bunu bir antremanla göstereceğiz, sonra '
          'sayılar sırayla ekrana gelecek ve bazı sayıların kaç kez '
          'kullanıldığını sana soracağız.',
      onStart: _startBolum3Warmup,
    );
  }

  Widget _buildBolum3Ready() {
    return _buildBolum3CenteredScreen(
      emoji: '🎯',
      badge: 'Etkinlik 6 · 3. Bölüm',
      instruction:
          'Antremanı tamamladık! Şimdi sayılar sırayla ekrana gelecek, '
          'dikkatlice bak. Hepsi geldikten sonra bazı sayıların kaç kez '
          'kullanıldığını sana soracağız. Hazır mısın?',
      onStart: _startBolum3Reveal,
    );
  }

  Widget _buildBolum3CenteredScreen({
    required String emoji,
    required String badge,
    required String instruction,
    required VoidCallback onStart,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 64)),
                ),
                const SizedBox(height: 16),
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _color,
                    ),
                  ),
                ),
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
                    instruction,
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
              ],
            ),
          ),
        );
      },
    );
  }

  // Satır widget'ı — antreman ve reveal aşamalarında ortak kullanılır.
  // `highlighted` true ise satır vurgulanır ve ortadaki sayının altında
  // odak noktası (nokta) belirir.
  // Sağ/sol sayılar tüm ekran genişliğine yayılmasın diye 3 sütun bu
  // sabit genişlikte, ortalanmış bir kutu içinde tutuluyor — böylece
  // birbirine daha yakın görünüyorlar.
  static const double _tripletContentWidth = 220.0;

  Widget _tripletRowWidget(_TripletRow row, {bool highlighted = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      decoration: BoxDecoration(
        color: highlighted ? _color.withValues(alpha: 0.12) : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                row.left,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    row.center,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: _color,
                    ),
                  ),
                  if (highlighted) ...[
                    const SizedBox(height: 3),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                row.right,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBolum3Warmup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '🎓 Antreman · 3. Bölüm',
            style: TextStyle(fontWeight: FontWeight.bold, color: _color),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: Text(
            'Sağındaki ve solundaki sayıları fark et!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.amber.shade900,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Kaydırma yok — sayfa ne kadar sığıyorsa satırlar o kadar
        // yükseklikte sıkıştırılıp tek ekrana sığdırılıyor.
        Expanded(
          child: Center(
            child: SizedBox(
              width: _tripletContentWidth,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final rowHeight =
                      (constraints.maxHeight / _tripletRows.length).clamp(
                        26.0,
                        56.0,
                      );
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _VerticalDashedLinesPainter(
                            color: _color.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (int i = 0; i < _tripletRows.length; i++)
                            SizedBox(
                              height: rowHeight,
                              child: _tripletRowWidget(
                                _tripletRows[i],
                                highlighted: i == _warmupRowIndex,
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: _skipBolum3Warmup,
            icon: const Icon(Icons.skip_next_rounded),
            label: const Text(
              'ANTREMANI GEÇ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _color,
              side: BorderSide(color: _color),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBolum3Reveal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '3. Bölüm · Sayılar Geliyor...',
                style: TextStyle(fontWeight: FontWeight.bold, color: _color),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '⏱ ${_bolum3ElapsedSec}sn',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: Text(
            'Sayılar sırayla geliyor, dikkatlice bak — birazdan bazı '
            'sayıların kaç kez göründüğünü soracağız!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.amber.shade900,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            controller: _revealScrollController,
            child: Center(
              child: SizedBox(
                width: _tripletContentWidth,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _VerticalDashedLinesPainter(
                          color: _color.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        for (int i = 0; i < _revealRowCount; i++)
                          _tripletRowWidget(_bolum3QuizRows[i]),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: _skipBolum3Reveal,
            icon: const Icon(Icons.skip_next_rounded),
            label: const Text(
              'GEÇ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _color,
              side: BorderSide(color: _color),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBolum3Quiz() {
    final q = _quizQuestions[_quizIndex];
    final options = _answerOptionsFor(q.correctCount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Soru ${_quizIndex + 1}/${_quizQuestions.length}',
                style: TextStyle(fontWeight: FontWeight.bold, color: _color),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '⏱ ${_bolum3ElapsedSec}sn',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔢', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                    children: [
                      const TextSpan(text: '"'),
                      TextSpan(
                        text: q.number,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _color,
                        ),
                      ),
                      const TextSpan(text: '" kaç defa kullanıldı?'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final opt in options)
                      _quizOptionButton(opt, q.correctCount),
                  ],
                ),
                if (_quizAnswered) ...[
                  const SizedBox(height: 16),
                  Text(
                    _quizSelectedAnswer == q.correctCount
                        ? '✅ Doğru!'
                        : '❌ Doğrusu: ${q.correctCount}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _quizSelectedAnswer == q.correctCount
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _quizOptionButton(int value, int correct) {
    Color bg = _color.withValues(alpha: 0.08);
    Color border = _color.withValues(alpha: 0.3);
    Color fg = _color;
    if (_quizAnswered) {
      if (value == correct) {
        bg = const Color(0xFF16A34A).withValues(alpha: 0.14);
        border = const Color(0xFF16A34A);
        fg = const Color(0xFF16A34A);
      } else if (value == _quizSelectedAnswer) {
        bg = const Color(0xFFE11D48).withValues(alpha: 0.14);
        border = const Color(0xFFE11D48);
        fg = const Color(0xFFE11D48);
      }
    }
    return SizedBox(
      width: 64,
      height: 56,
      child: OutlinedButton(
        onPressed: _quizAnswered ? null : () => _answerQuiz(value),
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          side: BorderSide(color: border, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          '$value',
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

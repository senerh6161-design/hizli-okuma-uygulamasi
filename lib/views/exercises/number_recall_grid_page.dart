import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';

enum _Phase { intro, bolum2Intro, flash, grid, bolum3Intro, bolum3 }

class _TripletRow {
  final String left;
  final String center;
  final String right;
  const _TripletRow(this.left, this.center, this.right);
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
/// sayıları da yakalamaya çalışıyoruz. Puansız, süre ölçülür.
class NumberRecallGridPage extends StatefulWidget {
  const NumberRecallGridPage({super.key});

  @override
  State<NumberRecallGridPage> createState() => _NumberRecallGridPageState();
}

class _NumberRecallGridPageState extends State<NumberRecallGridPage> {
  static const Color _color = Color(0xFFDC2626);
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

  final Random _random = Random();
  _Phase _phase = _Phase.intro;
  bool _hasCompletedOnce = false;
  bool _isPaused = false;
  bool _isDemoRound = false;
  int _currentBolum = 1;
  int _speedLevel = 1;

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

  @override
  void dispose() {
    _answerTimer?.cancel();
    _tickTimer?.cancel();
    _flashTimer?.cancel();
    _bolum3Ticker?.cancel();
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
    _flashTimer = Timer(
      Duration(milliseconds: _flashMsBySpeed[_speedLevel]),
      () {
        if (!mounted) return;
        _startAnswerWindow();
      },
    );
  }

  void _startDemoRound() {
    _isDemoRound = true;
    _startRound();
  }

  void _skipDemo() {
    _answerTimer?.cancel();
    _tickTimer?.cancel();
    _flashTimer?.cancel();
    _isDemoRound = false;
    _startRound();
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
    if (_phase == _Phase.flash) {
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

  void _startBolum3() {
    _bolum3Ticker?.cancel();
    setState(() {
      _phase = _Phase.bolum3;
      _bolum3ElapsedSec = 0;
    });
    _bolum3Ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _bolum3ElapsedSec++);
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
          '3. Bölüm ${_bolum3ElapsedSec}sn',
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
        appBar: AppBar(title: const Text('🔍 Nerede Gördüm?')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: switch (_phase) {
                  _Phase.intro => _buildIntro(),
                  _Phase.bolum2Intro => _buildBolum2Intro(),
                  _Phase.flash || _Phase.grid => _buildRound(
                    key: ValueKey(
                      'round-$_currentBolum-$_roundIndex-$_isDemoRound-$_phase',
                    ),
                  ),
                  _Phase.bolum3Intro => _buildBolum3Intro(),
                  _Phase.bolum3 => _buildBolum3(),
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
                      ? '🎓 Antreman Turu'
                      : '$_currentBolum. Bölüm · Tur ${_roundIndex + 1}/$_roundCount',
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
                    _isDemoRound ? 'Puansız' : 'Puan: $_totalScore',
                    style: const TextStyle(
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
                    ? 'Önce sana bir sayı göstereceğiz...'
                    : 'Şimdi sıra sende! Nerede olduğunu bul.',
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
          if (_phase == _Phase.grid)
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
                      style: const TextStyle(
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
                side: const BorderSide(color: _color),
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
            onTap: _answered ? null : () => _answerRound(index),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Text('👁️', style: TextStyle(fontSize: 64)),
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
                  child: const Text(
                    'Etkinlik 6 · 3. Bölüm',
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
                  child: const Text(
                    'İki bölümü de bitirdik! Şimdi 3. Bölüm: her satırda 3 '
                    'sayı var. Ortadaki sayıya odaklan ve gözünü oynatmadan '
                    'yanındaki sayılara da bakmaya çalış — dikkat et, '
                    'yandaki sayılar ortadakiyle AYNI rakamlardan oluşuyor '
                    'ama sırası farklı, kolayca karıştırabilirsin!',
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
                    onPressed: _startBolum3,
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

  Widget _buildBolum3() {
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
              child: const Text(
                '3. Bölüm · Benzer Sayılar',
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
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
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
                    for (final row in _tripletRows)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                row.left,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                row.center,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: _color,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                row.right,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _finishBolum3,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text(
              'BİTİRDİM!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
    );
  }
}

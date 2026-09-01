import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';

class _Cell {
  final String top;
  final String? bottom;
  const _Cell(this.top, [this.bottom]);
}

// Ortadaki sütunun kutuları kesikli çizgiyle çevrili — kitaptaki sayfada
// da öğrencinin gözünü sayfanın ortasına odaklaması için böyle.
class _DashedRectPainter extends CustomPainter {
  final Color color;
  const _DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(10),
    );
    final path = Path()..addRRect(rrect);
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) =>
      oldDelegate.color != color;
}

enum _Phase {
  intro,
  tur1,
  tur2,
  tur3,
  tur4Intro,
  tur4Numbers,
  tur4NumbersAnswer,
  tur4Letters,
  tur4LettersAnswer,
}

/// Klasör 3'ün sekizinci etkinliği: "Odaklanma Kutucukları". Kitaptaki
/// 3 sütunlu, ortası kesikli çizgili odaklanma sayfalarının karşılığı —
/// kutucuklar soldan sağa, satır satır sırayla yanıp sönüyor. 1. Tur tek
/// sayı, 2. Tur (kitaptaki gibi) sayı çifti, 3. Tur harf+sayı, 4. Tur ise
/// oyunlaştırılmış: bir hedef sayı/harf kodu kaç kere geçtiğini sayıyoruz.
class FocusBoxPage extends StatefulWidget {
  const FocusBoxPage({super.key});

  @override
  State<FocusBoxPage> createState() => _FocusBoxPageState();
}

class _FocusBoxPageState extends State<FocusBoxPage> {
  static const Color _color = Color(0xFFB91C1C);
  static const List<String> _speedLabels = ['Yavaş', 'Orta', 'Hızlı'];
  static const List<int> _stepMsBySpeed = [900, 600, 350];
  int _speedLevel = 1;

  static const int _cols = 3;

  // 1. Tur: tek sayı.
  static const List<_Cell> _tur1Cells = [
    _Cell('137'),
    _Cell('767'),
    _Cell('538'),
    _Cell('888'),
    _Cell('717'),
    _Cell('996'),
    _Cell('224'),
    _Cell('727'),
    _Cell('444'),
    _Cell('332'),
    _Cell('219'),
    _Cell('536'),
    _Cell('532'),
    _Cell('109'),
    _Cell('534'),
    _Cell('542'),
    _Cell('509'),
    _Cell('543'),
    _Cell('555'),
    _Cell('303'),
    _Cell('508'),
  ];

  // 2. Tur: kitaptaki Etkinlik 11 — sayı çifti.
  static const List<_Cell> _tur2Cells = [
    _Cell('137', '3113'),
    _Cell('767', '1727'),
    _Cell('538', '3553'),
    _Cell('888', '1828'),
    _Cell('717', '8665'),
    _Cell('996', '6996'),
    _Cell('224', '1214'),
    _Cell('727', '7227'),
    _Cell('444', '7447'),
    _Cell('332', '1050'),
    _Cell('219', '9009'),
    _Cell('536', '7317'),
    _Cell('532', '2040'),
    _Cell('109', '8008'),
    _Cell('534', '6346'),
    _Cell('542', '5424'),
    _Cell('509', '3333'),
    _Cell('543', '3434'),
    _Cell('555', '6545'),
    _Cell('303', '3903'),
    _Cell('508', '8180'),
  ];

  // 3. Tur: kitaptaki devamı — harf kodu + sayı.
  static const List<_Cell> _tur3Cells = [
    _Cell('ÖĞRN', '99099'),
    _Cell('İSTN', '88088'),
    _Cell('SKRY', '54544'),
    _Cell('MRMR', '40044'),
    _Cell('BTMN', '12345'),
    _Cell('DŞNC', '19244'),
    _Cell('SRCN', '48752'),
    _Cell('NCPF', '65423'),
    _Cell('KNTN', '48942'),
    _Cell('BLKS', '78564'),
    _Cell('TŞRT', '45128'),
    _Cell('DMTS', '58312'),
    _Cell('CİHN', '34168'),
    _Cell('BGRA', '98784'),
    _Cell('DNGE', '78541'),
    _Cell('TRST', '78542'),
    _Cell('ERZM', '12561'),
    _Cell('KTPH', '23325'),
    _Cell('DATA', '98742'),
    _Cell('MAKF', '18978'),
    _Cell('OSMN', '78121'),
  ];

  // 4. Tur: oyunlaştırılmış sayma — hedef, kaç kez geçtiği belli, aralara
  // farklı sayı/harfler serpiştirilmiş.
  static const String _tur4NumberTarget = '224';
  static const List<String> _tur4NumberSequence = [
    '224',
    '317',
    '542',
    '224',
    '908',
    '671',
    '224',
    '415',
    '733',
    '224',
    '256',
    '890',
    '124',
    '667',
    '224',
    '381',
    '509',
    '743',
    '224',
    '162',
    '398',
  ];
  static const int _tur4NumberCorrectCount = 6;

  static const String _tur4LetterTarget = 'SKRY';
  static const List<String> _tur4LetterSequence = [
    'MRMR',
    'SKRY',
    'BTMN',
    'DŞNC',
    'SKRY',
    'NCPF',
    'KNTN',
    'TŞRT',
    'SKRY',
    'DMTS',
    'CİHN',
    'BGRA',
    'SKRY',
    'DNGE',
    'TRST',
    'ERZM',
    'KTPH',
    'SKRY',
    'DATA',
    'MAKF',
    'OSMN',
  ];
  static const int _tur4LetterCorrectCount = 5;

  _Phase _phase = _Phase.intro;
  bool _hasCompletedOnce = false;
  bool _isPaused = false;

  int _activeIndex = 0;
  Timer? _sweepTimer;
  bool _blinkOn = true;
  Timer? _blinkTimer;

  int _tur4CountSelected = 0;
  bool _tur4Answered = false;

  int _totalMistakes = 0;

  @override
  void dispose() {
    _sweepTimer?.cancel();
    _blinkTimer?.cancel();
    super.dispose();
  }

  int get _currentLength => switch (_phase) {
    _Phase.tur1 => _tur1Cells.length,
    _Phase.tur2 => _tur2Cells.length,
    _Phase.tur3 => _tur3Cells.length,
    _Phase.tur4Numbers => _tur4NumberSequence.length,
    _Phase.tur4Letters => _tur4LetterSequence.length,
    _ => 0,
  };

  void _startTur(_Phase phase) {
    _blinkTimer?.cancel();
    setState(() {
      _phase = phase;
      _activeIndex = 0;
      _blinkOn = true;
    });
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (!mounted) return;
      setState(() => _blinkOn = !_blinkOn);
    });
    _scheduleSweep();
  }

  void _scheduleSweep() {
    _sweepTimer?.cancel();
    _sweepTimer = Timer(
      Duration(milliseconds: _stepMsBySpeed[_speedLevel]),
      () {
        if (!mounted) return;
        SoundManager.playTick();
        if (_activeIndex >= _currentLength - 1) {
          _onTurDone();
        } else {
          setState(() => _activeIndex++);
          _scheduleSweep();
        }
      },
    );
  }

  void _changeSpeed(int level) {
    setState(() => _speedLevel = level);
    if (_phase == _Phase.tur1 ||
        _phase == _Phase.tur2 ||
        _phase == _Phase.tur3 ||
        _phase == _Phase.tur4Numbers ||
        _phase == _Phase.tur4Letters) {
      _scheduleSweep();
    }
  }

  void _pauseGame() {
    _sweepTimer?.cancel();
    _blinkTimer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resumeGame() {
    setState(() => _isPaused = false);
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (!mounted) return;
      setState(() => _blinkOn = !_blinkOn);
    });
    _scheduleSweep();
  }

  void _onTurDone() {
    _sweepTimer?.cancel();
    _blinkTimer?.cancel();
    switch (_phase) {
      case _Phase.tur1:
        _startTur(_Phase.tur2);
      case _Phase.tur2:
        _startTur(_Phase.tur3);
      case _Phase.tur3:
        setState(() => _phase = _Phase.tur4Intro);
      case _Phase.tur4Numbers:
        setState(() {
          _phase = _Phase.tur4NumbersAnswer;
          _tur4Answered = false;
          _tur4CountSelected = 0;
        });
      case _Phase.tur4Letters:
        setState(() {
          _phase = _Phase.tur4LettersAnswer;
          _tur4Answered = false;
          _tur4CountSelected = 0;
        });
      default:
        break;
    }
  }

  void _startTur4Numbers() {
    _startTur(_Phase.tur4Numbers);
  }

  void _submitTur4Answer(int selected, {required bool isLetters}) {
    if (_tur4Answered) return;
    final correct = isLetters
        ? _tur4LetterCorrectCount
        : _tur4NumberCorrectCount;
    setState(() {
      _tur4CountSelected = selected;
      _tur4Answered = true;
    });
    if (selected == correct) {
      SoundManager.playCorrect();
    } else {
      SoundManager.playGentleTap();
      _totalMistakes++;
    }
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (isLetters) {
        _finishAll();
      } else {
        _startTur(_Phase.tur4Letters);
      }
    });
  }

  void _finishAll() {
    _hasCompletedOnce = true;

    const percent = 100;
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Odaklanma Kutucukları',
      result: '4 tur tamamlandı · $_totalMistakes hata',
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
            const Text(
              '4 turun hepsini tamamladık!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text('Toplam hata: $_totalMistakes'),
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
        appBar: AppBar(title: const Text('🎯 Odaklanma Kutucukları')),
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
      case _Phase.intro:
        return _buildIntro();
      case _Phase.tur1:
        return _buildSweep(
          key: const ValueKey('tur1'),
          cells: _tur1Cells,
          label: '1. Tur · Tek Sayı',
        );
      case _Phase.tur2:
        return _buildSweep(
          key: const ValueKey('tur2'),
          cells: _tur2Cells,
          label: '2. Tur · Sayı Çifti',
        );
      case _Phase.tur3:
        return _buildSweep(
          key: const ValueKey('tur3'),
          cells: _tur3Cells,
          label: '3. Tur · Harf ve Sayı',
        );
      case _Phase.tur4Intro:
        return _buildTur4Intro();
      case _Phase.tur4Numbers:
        return _buildCountSweep(
          key: const ValueKey('tur4n'),
          sequence: _tur4NumberSequence,
          target: _tur4NumberTarget,
        );
      case _Phase.tur4NumbersAnswer:
        return _buildCountAnswer(
          target: _tur4NumberTarget,
          correctCount: _tur4NumberCorrectCount,
          isLetters: false,
        );
      case _Phase.tur4Letters:
        return _buildCountSweep(
          key: const ValueKey('tur4l'),
          sequence: _tur4LetterSequence,
          target: _tur4LetterTarget,
        );
      case _Phase.tur4LettersAnswer:
        return _buildCountAnswer(
          target: _tur4LetterTarget,
          correctCount: _tur4LetterCorrectCount,
          isLetters: true,
        );
    }
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
                    'Etkinlik 8 · Odaklanma Kutucukları',
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
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _color, width: 1.5),
                      ),
                      child: const Text(
                        'Amaç: Gözün odaklanma ve farkındalığını '
                        'artırmak.\n\nYöntem: Kutuların ortasına '
                        'odaklanarak, yanıp sönen kutucuğu soldan '
                        'sağa takip edeceğiz.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF7F1D1D),
                        ),
                      ),
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
                      child: const Text(
                        '4 tur var: 1. Tur tek sayı, 2. Tur sayı çifti, '
                        '3. Tur harf ve sayı, 4. Tur ise bir hedefi kaç '
                        'kere gördüğümüzü sayacağımız bir oyun!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: _color,
                          fontWeight: FontWeight.w600,
                        ),
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
                      onPressed: () => _startTur(_Phase.tur1),
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
            onSelected: (_) => _changeSpeed(i),
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

  Widget _buildSweep({
    required Key key,
    required List<_Cell> cells,
    required String label,
  }) {
    return KeyedSubtree(
      key: key,
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
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _color,
                  ),
                ),
              ),
              buildPauseButton(color: _color, onPressed: _pauseGame),
            ],
          ),
          const SizedBox(height: 8),
          _speedChipRow(),
          const SizedBox(height: 12),
          Expanded(child: _grid(cells)),
        ],
      ),
    );
  }

  Widget _buildTur4Intro() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: Text('🎮', style: TextStyle(fontSize: 64))),
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
                    '3 Turu tamamladık! Şimdi 4. Tur\'da bir oyun '
                    'oynayacağız: önce "$_tur4NumberTarget" sayısını, '
                    'sonra "$_tur4LetterTarget" kodunu takip edeceğiz — '
                    'kaç kere geldiğini sayacağız!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
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
                    onPressed: _startTur4Numbers,
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

  Widget _buildCountSweep({
    required Key key,
    required List<String> sequence,
    required String target,
  }) {
    return KeyedSubtree(
      key: key,
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
                  '4. Tur · "$target" kaç kere geliyor?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _color,
                  ),
                ),
              ),
              buildPauseButton(color: _color, onPressed: _pauseGame),
            ],
          ),
          const SizedBox(height: 8),
          _speedChipRow(),
          const SizedBox(height: 12),
          Expanded(
            child: _grid([for (final s in sequence) _Cell(s)], countMode: true),
          ),
        ],
      ),
    );
  }

  Widget _buildCountAnswer({
    required String target,
    required int correctCount,
    required bool isLetters,
  }) {
    final options = <int>{correctCount};
    final rand = Random(correctCount + target.length);
    while (options.length < 4) {
      final candidate = (correctCount - 2 + rand.nextInt(5)).clamp(1, 12);
      options.add(candidate);
    }
    final sortedOptions = options.toList()..sort();
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
                  child: Text(
                    '"$target"',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: _color,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'kaç kere geçti?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (_tur4Answered) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      _tur4CountSelected == correctCount
                          ? '🎉 Harikasın, doğru!'
                          : '📖 Doğrusu: $correctCount',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _tur4CountSelected == correctCount
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFE11D48),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final option in sortedOptions)
                      _countAnswerButton(option, correctCount, isLetters),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _countAnswerButton(int option, int correctCount, bool isLetters) {
    final answered = _tur4Answered;
    final isSelected = _tur4CountSelected == option && answered;
    final isCorrectOption = option == correctCount;
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
        onPressed: answered
            ? null
            : () => _submitTur4Answer(option, isLetters: isLetters),
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
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: fg,
          ),
        ),
      ),
    );
  }

  Widget _grid(List<_Cell> cells, {bool countMode = false}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final cellWidth =
            (constraints.maxWidth - spacing * (_cols - 1)) / _cols;
        final rows = (cells.length / _cols).ceil();
        final cellHeight =
            (constraints.maxHeight - spacing * (rows - 1)) / rows;
        final aspectRatio = cellWidth / cellHeight;
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _cols,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: cells.length,
          itemBuilder: (context, index) {
            final cell = cells[index];
            final isActive = index == _activeIndex;
            final lit = isActive && _blinkOn;
            final isMiddleColumn = index % _cols == 1;
            return Stack(
              children: [
                if (isMiddleColumn)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _DashedRectPainter(
                        color: lit
                            ? Colors.white
                            : _color.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: lit ? _color : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: isMiddleColumn
                        ? null
                        : Border.all(
                            color: lit ? _color : Colors.grey.shade400,
                            width: 1.2,
                          ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cell.top,
                            style: TextStyle(
                              fontSize: countMode ? 20 : 18,
                              fontWeight: FontWeight.bold,
                              color: lit
                                  ? Colors.white
                                  : const Color(0xFF334155),
                            ),
                          ),
                          if (cell.bottom != null)
                            Text(
                              cell.bottom!,
                              style: TextStyle(
                                fontSize: 12,
                                color: lit
                                    ? Colors.white.withValues(alpha: 0.85)
                                    : Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';
import '../../widgets/exercise_settings_sheet.dart';

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

enum _Phase { intro, tur1, tur2, tur3, tur4Intro, tur4 }

class _CountChallenge {
  final String target;
  final List<String> sequence;
  final int correctCount;
  const _CountChallenge(this.target, this.sequence, this.correctCount);
}

/// Klasör 3'ün sekizinci etkinliği: "Odaklanma Kutucukları". Kitaptaki
/// 3 sütunlu, ortası kesikli çizgili odaklanma sayfalarının karşılığı —
/// kutucuklar soldan sağa, satır satır sırayla yanıp sönüyor. 1. Tur tek
/// sayı, 2. Tur (kitaptaki gibi) sayı çifti, 3. Tur harf+sayı (sesli
/// harfleriyle TAM kelimeler), 4. Tur ise oyunlaştırılmış: bir hedef
/// sayı/kelime kaç kere geçtiğini sayıp "BİTİRDİM"e basıyoruz — ne kadar
/// hızlı bitirirsek o kadar çok puan kazanıyoruz (bkz. [_finishTur4Search]).
class FocusBoxPage extends StatefulWidget {
  const FocusBoxPage({super.key});

  @override
  State<FocusBoxPage> createState() => _FocusBoxPageState();
}

class _FocusBoxPageState extends State<FocusBoxPage> {
  // const DEĞİL çünkü öğrenci artık paletten değiştirebiliyor (bkz.
  // AppBar'daki "⋮" -> showExerciseSettingsSheet).
  Color _color = const Color(0xFFB91C1C);

  static const List<Color> _colorPalette = [
    Color(0xFFB91C1C), // kırmızı (varsayılan)
    Color(0xFFEC4899), // pembe
    Color(0xFFEA580C), // turuncu
    Color(0xFF0D9488), // teal
    Color(0xFF7C3AED), // mor
    Color(0xFF2563EB), // mavi
  ];

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

  // 3. Tur: kitaptaki devamı — harf ve sayı. Hoca kısaltılmış (sesli
  // harfsiz) kodlar yerine kelimelerin TAMAMININ yazılmasını istedi.
  static const List<_Cell> _tur3Cells = [
    _Cell('ÖĞRETMEN', '99099'),
    _Cell('İSTANBUL', '88088'),
    _Cell('SAKARYA', '54544'),
    _Cell('MARMARA', '40044'),
    _Cell('BATMAN', '12345'),
    _Cell('DÜŞÜNCE', '19244'),
    _Cell('SARICAN', '48752'),
    _Cell('NECİP', '65423'),
    _Cell('KANTİN', '48942'),
    _Cell('BALIKESİR', '78564'),
    _Cell('TİŞÖRT', '45128'),
    _Cell('DOMATES', '58312'),
    _Cell('CİHAN', '34168'),
    _Cell('BULGARİSTAN', '98784'),
    _Cell('DENGE', '78541'),
    _Cell('TRABZON', '78542'),
    _Cell('ERZURUM', '12561'),
    _Cell('KÜTÜPHANE', '23325'),
    _Cell('DATA', '98742'),
    _Cell('MAKALE', '18978'),
    _Cell('OSMANLI', '78121'),
  ];

  // 4. Tur: oyunlaştırılmış sayma — bir hedef sayı/harf kodu kaç kere
  // geçiyor, öğrenci kutuları kendisi tarayıp sayıyor (yanıp sönme yok).
  // 10 soru: sırayla sayı ve harf kodu hedefleri, sabit tohumla üretilmiş.
  static List<_CountChallenge> _buildChallenges() {
    final numberPool = _tur1Cells.map((c) => c.top).toList();
    final letterPool = _tur3Cells.map((c) => c.top).toList();
    final rand = Random(224);
    final challenges = <_CountChallenge>[];
    for (int i = 0; i < 10; i++) {
      final pool = i.isOdd ? letterPool : numberPool;
      final shuffledPool = [...pool]..shuffle(rand);
      final target = shuffledPool.first;
      final distractors = shuffledPool.skip(1).toList();
      final correctCount = 3 + rand.nextInt(4);
      final rawTotal = correctCount + 10 + rand.nextInt(4);
      // Izgara 3 sütunlu — son satır eksik kalıp boş kutu görünmesin diye
      // toplam hücre sayısını 3'ün katına yuvarlıyoruz.
      final totalCount = rawTotal + ((_cols - rawTotal % _cols) % _cols);
      final sequence = <String>[
        for (int j = 0; j < correctCount; j++) target,
        ...distractors.take(totalCount - correctCount),
      ]..shuffle(rand);
      _breakTripleRows(sequence);
      challenges.add(_CountChallenge(target, sequence, correctCount));
    }
    return challenges;
  }

  // Rastgele karıştırma bazen bir satırın 3 kutusunu da AYNI değerle
  // dolduruyor (hocanın dikkat çektiği durum) — bu satırdaki ortadaki
  // kutuyu başka bir satırdaki farklı bir değerle takas ederek düzeltiyoruz.
  // Takas sadece yer değiştirdiği için hedefin toplam geçiş sayısı
  // (correctCount) değişmiyor.
  static void _breakTripleRows(List<String> sequence) {
    for (int start = 0; start + _cols <= sequence.length; start += _cols) {
      final rowValues = sequence.sublist(start, start + _cols);
      if (rowValues.toSet().length != 1) continue;
      final rowValue = rowValues.first;
      for (int other = 0; other < sequence.length; other++) {
        if (other >= start && other < start + _cols) continue;
        if (sequence[other] == rowValue) continue;
        final swapIndex = start + 1;
        final tmp = sequence[swapIndex];
        sequence[swapIndex] = sequence[other];
        sequence[other] = tmp;
        break;
      }
    }
  }

  final List<_CountChallenge> _challenges = _buildChallenges();

  _Phase _phase = _Phase.intro;
  bool _hasCompletedOnce = false;
  bool _isPaused = false;

  int _activeIndex = 0;
  Timer? _sweepTimer;
  bool _blinkOn = true;
  Timer? _blinkTimer;

  static const int _tur4SearchSeconds = 8;
  int _tur4Index = 0;
  int _tur4CountSelected = 0;
  bool _tur4Answered = false;
  bool _tur4Searching = true;
  int _tur4SecondsLeft = _tur4SearchSeconds;
  Timer? _tur4RevealTimer;
  // "Bitirdim" ile ne kadar erken bitirirsek (kalan saniye ne kadar
  // yüksekse) o kadar çok puan kazanıyoruz.
  int _tur4Score = 0;

  int _totalMistakes = 0;

  @override
  void dispose() {
    _sweepTimer?.cancel();
    _blinkTimer?.cancel();
    _tur4RevealTimer?.cancel();
    super.dispose();
  }

  int get _currentLength => switch (_phase) {
    _Phase.tur1 => _tur1Cells.length,
    _Phase.tur2 => _tur2Cells.length,
    _Phase.tur3 => _tur3Cells.length,
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
        _phase == _Phase.tur3) {
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
      default:
        break;
    }
  }

  void _startTur4() {
    setState(() {
      _phase = _Phase.tur4;
      _tur4Index = 0;
      _tur4Answered = false;
      _tur4CountSelected = 0;
      _tur4Score = 0;
    });
    _scheduleTur4Reveal();
  }

  void _scheduleTur4Reveal() {
    _tur4RevealTimer?.cancel();
    setState(() {
      _tur4Searching = true;
      _tur4SecondsLeft = _tur4SearchSeconds;
    });
    _tur4RevealTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_tur4SecondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _tur4Searching = false;
          _tur4SecondsLeft = 0;
        });
      } else {
        setState(() => _tur4SecondsLeft--);
      }
    });
  }

  // "Bitirdim" butonuna basınca sayma süresini erken bitiriyoruz — kalan
  // saniye ne kadar yüksekse (ne kadar hızlı bitirdiysek) cevap doğru
  // olduğunda o kadar çok puan kazanacağız (bkz. _submitTur4Answer).
  void _finishTur4Search() {
    if (!_tur4Searching) return;
    _tur4RevealTimer?.cancel();
    setState(() => _tur4Searching = false);
  }

  void _submitTur4Answer(int selected) {
    if (_tur4Answered) return;
    final correct = _challenges[_tur4Index].correctCount;
    setState(() {
      _tur4CountSelected = selected;
      _tur4Answered = true;
    });
    if (selected == correct) {
      SoundManager.playCorrect();
      _tur4Score += 10 + _tur4SecondsLeft * 5;
    } else {
      SoundManager.playGentleTap();
      _totalMistakes++;
    }
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_tur4Index >= _challenges.length - 1) {
        _finishAll();
      } else {
        setState(() {
          _tur4Index++;
          _tur4Answered = false;
          _tur4CountSelected = 0;
        });
        _scheduleTur4Reveal();
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
      result: '4 tur tamamlandı · $_tur4Score puan · $_totalMistakes hata',
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
            Text(
              '⭐ 4. Tur puanı: $_tur4Score',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
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
        appBar: AppBar(
          title: const Text('🎯 Odaklanma Kutucukları'),
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
      case _Phase.tur4:
        return _buildTur4Question();
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
                  child: Text(
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
                      child: Text(
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
                  style: TextStyle(fontWeight: FontWeight.bold, color: _color),
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
                    'oynayacağız: her soruda bir hedef sayı ya da kelime '
                    'göreceğiz, kutuları kendimiz tarayıp kaç kere '
                    'geçtiğini sayacağız. Bulduğumuzda "BİTİRDİM"e '
                    'basacağız — ne kadar hızlı bitirirsek o kadar çok '
                    'puan kazanacağız! 10 soru var.',
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
                    onPressed: _startTur4,
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

  List<int> _answerOptionsFor(_CountChallenge challenge) {
    final options = <int>{challenge.correctCount};
    final rand = Random(challenge.correctCount + challenge.target.length);
    while (options.length < 4) {
      final candidate = (challenge.correctCount - 2 + rand.nextInt(5)).clamp(
        1,
        12,
      );
      options.add(candidate);
    }
    return options.toList()..sort();
  }

  Widget _buildTur4Question() {
    final challenge = _challenges[_tur4Index];
    return KeyedSubtree(
      key: ValueKey('tur4-$_tur4Index'),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _tur4Searching
            ? _buildTur4Search(challenge)
            : _buildTur4Answer(challenge),
      ),
    );
  }

  Widget _buildTur4Search(_CountChallenge challenge) {
    return Column(
      key: const ValueKey('search'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Soru ${_tur4Index + 1}/${_challenges.length} · '
                  '"${challenge.target}" kaç kere geçiyor?',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold, color: _color),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Text(
                '⭐ $_tur4Score',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _grid(
            [for (final s in challenge.sequence) _Cell(s)],
            countMode: true,
            blinkEnabled: false,
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🔎 Kutucukları tara ve say...',
                style: TextStyle(fontWeight: FontWeight.bold, color: _color),
              ),
              const SizedBox(height: 4),
              Text(
                '$_tur4SecondsLeft sn sonra cevap seçenekleri gelecek',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            onPressed: _finishTur4Search,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text(
              'BİTİRDİM',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTur4Answer(_CountChallenge challenge) {
    final sortedOptions = _answerOptionsFor(challenge);
    return LayoutBuilder(
      key: const ValueKey('answer'),
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
                    'Soru ${_tur4Index + 1}/${_challenges.length}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '"${challenge.target}"',
                    style: TextStyle(
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
                      _tur4CountSelected == challenge.correctCount
                          ? '🎉 Harikasın, doğru!'
                          : '📖 Doğrusu: ${challenge.correctCount}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _tur4CountSelected == challenge.correctCount
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
                      _countAnswerButton(option, challenge.correctCount),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _countAnswerButton(int option, int correctCount) {
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
        onPressed: answered ? null : () => _submitTur4Answer(option),
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

  Widget _grid(
    List<_Cell> cells, {
    bool countMode = false,
    bool blinkEnabled = true,
  }) {
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
            final isActive = blinkEnabled && index == _activeIndex;
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

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';

enum _Phase { intro, playing, ready }

// Ekrana dağılmış her sayının konumu (0..1 arası oransal x/y), görsel
// stili — kitaptaki sayfa gibi bazı sayılar kalın, bazıları eğik, bazıları
// çember/baklava/altıgen içinde, bir-iki tanesi de dolgulu daire — ve
// rengi: hepsi tek bir renk olmasın diye her sayı kendi rengini alıyor.
class _NumberSpot {
  final int value;
  final double x;
  final double y;
  final int style; // 0 kalın, 1 eğik, 2 çember, 3 baklava, 4 altıgen, 5 dolgulu
  final Color color;
  const _NumberSpot({
    required this.value,
    required this.x,
    required this.y,
    required this.style,
    required this.color,
  });
}

// Baklava (4 kenar) ve altıgen (6 kenar) çerçeveleri aynı basit çokgen
// çizimiyle üretiliyor.
class _PolygonBorderPainter extends CustomPainter {
  final Color color;
  final int sides;
  const _PolygonBorderPainter(this.color, this.sides);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 1;
    for (int i = 0; i < sides; i++) {
      final angle = (2 * pi / sides) * i - pi / 2;
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _PolygonBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Klasör 3'ün ikinci etkinliği: "Sayı Avı" (kitaptaki Schulte tablosu
/// tarzı sayı bulma etkinliğinin karşılığı). Kitapta 1'den 50'ye kadar
/// sayılar sayfaya dağınık şekilde yerleştiriliyor; biz telefon ekranına
/// sığması için 1'den 30'a kadar kullanıyoruz. Öğrenci sayıları 1'den
/// başlayarak sırasıyla, ekranda arayıp dokunarak buluyor — quiz yok,
/// süre kaydediliyor.
class NumberHuntPage extends StatefulWidget {
  const NumberHuntPage({super.key});

  @override
  State<NumberHuntPage> createState() => _NumberHuntPageState();
}

class _NumberHuntPageState extends State<NumberHuntPage> {
  static const Color _color = Color(0xFF1D4ED8);
  static const int _numberCount = 30;
  static const int _demoNumberCount = 30;
  static const double _badgeSize = 40;

  // Antreman otomatik ilerliyor — hızını öğrenci/öğretmen ayarlayabilsin
  // diye seçenek sunuluyor, varsayılan çok hızlı olmasın diye "Orta".
  static const List<String> _demoSpeedLabels = ['Yavaş', 'Orta', 'Hızlı'];
  static const List<int> _demoStepMsBySpeed = [1300, 800, 450];
  int _demoSpeedLevel = 1;

  // Sayılar/kutucuklar tek bir renk (mavi) olmasın diye her turda bu
  // paletten karışık sırayla dağıtılıyor.
  static const List<Color> _colorPalette = [
    Color(0xFF1D4ED8), // mavi
    Color(0xFFDC2626), // kırmızı
    Color(0xFF16A34A), // yeşil
    Color(0xFFF59E0B), // sarı
    Color(0xFFDB2777), // pembe
    Color(0xFF7C3AED), // mor
    Color(0xFF0891B2), // camgöbeği
    Color(0xFFEA580C), // turuncu
  ];

  final Random _random = Random();
  _Phase _phase = _Phase.intro;
  bool _hasCompletedOnce = false;
  bool _isPaused = false;

  // Gerçek 30'luk tur başlamadan önce puansız bir antreman turu
  // gösteriliyor — öğrenci mekaniği önce burada deniyor.
  bool _isDemo = false;

  List<_NumberSpot> _spots = [];
  int _nextTarget = 1;
  int? _wrongFlashValue;
  Timer? _wrongFlashTimer;
  int _elapsedSec = 0;
  Timer? _timer;
  bool _finished = false;
  // Antremanda öğrenci dokunmuyor, biz sırayla otomatik gösteriyoruz —
  // o sadece izliyor.
  Timer? _demoAutoTimer;

  @override
  void dispose() {
    _timer?.cancel();
    _demoAutoTimer?.cancel();
    _wrongFlashTimer?.cancel();
    super.dispose();
  }

  // Palet karışık sırayla, gerekirse tekrar tekrar dağıtılıyor — bu sayede
  // her sayı/kutucuk farklı bir renk alıyor, hepsi tek renk olmuyor.
  List<Color> _randomColorsFor(int count) {
    final colors = <Color>[];
    while (colors.length < count) {
      final shuffled = [..._colorPalette]..shuffle(_random);
      colors.addAll(shuffled);
    }
    return colors.sublist(0, count);
  }

  // Sayılar birbirine çok yakın düşmesin diye her biri için en fazla 40
  // deneme yapılıyor; bir-iki tanesi (kitaptaki gibi) dolgulu daire oluyor.
  List<_NumberSpot> _generateSpots(int count) {
    final list = <_NumberSpot>[];
    final filledIndices = <int>{};
    final filledTarget = min(2, count);
    while (filledIndices.length < filledTarget) {
      filledIndices.add(_random.nextInt(count));
    }
    final colors = _randomColorsFor(count);
    for (int i = 0; i < count; i++) {
      double x = 0.5, y = 0.5;
      for (int attempt = 0; attempt < 40; attempt++) {
        x = 0.08 + _random.nextDouble() * 0.84;
        y = 0.06 + _random.nextDouble() * 0.88;
        final tooClose = list.any((o) {
          final dx = o.x - x;
          final dy = o.y - y;
          return dx * dx + dy * dy < 0.11 * 0.11;
        });
        if (!tooClose) break;
      }
      final style = filledIndices.contains(i) ? 5 : _random.nextInt(5);
      list.add(
        _NumberSpot(value: i + 1, x: x, y: y, style: style, color: colors[i]),
      );
    }
    return list;
  }

  // Gerçek tur başlamadan önce puansız bir antreman turu gösteriliyor —
  // ama öğrenci dokunmuyor, sayılar sırayla kendiliğinden bulunuyor,
  // öğrenci sadece izliyor.
  void _startGame() {
    setState(() {
      _isDemo = true;
      _phase = _Phase.playing;
      _spots = _generateSpots(_demoNumberCount);
      _nextTarget = 1;
      _elapsedSec = 0;
      _finished = false;
    });
    _demoAutoTimer?.cancel();
    _scheduleDemoStep();
  }

  void _scheduleDemoStep() {
    _demoAutoTimer = Timer(
      Duration(milliseconds: _demoStepMsBySpeed[_demoSpeedLevel]),
      () {
        if (!mounted || !_isDemo || _finished) return;
        SoundManager.playPop();
        if (_nextTarget >= _demoNumberCount) {
          _finishDemo();
        } else {
          setState(() => _nextTarget++);
          _scheduleDemoStep();
        }
      },
    );
  }

  void _changeDemoSpeed(int level) {
    _demoAutoTimer?.cancel();
    setState(() => _demoSpeedLevel = level);
    if (!_finished) _scheduleDemoStep();
  }

  void _startRealGame() {
    _timer?.cancel();
    _demoAutoTimer?.cancel();
    setState(() {
      _phase = _Phase.playing;
      _isDemo = false;
      _spots = _generateSpots(_numberCount);
      _nextTarget = 1;
      _elapsedSec = 0;
      _finished = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSec++);
    });
  }

  void _pauseGame() {
    _timer?.cancel();
    _demoAutoTimer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resumeGame() {
    setState(() => _isPaused = false);
    if (_finished) return;
    if (_isDemo) {
      _scheduleDemoStep();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _elapsedSec++);
      });
    }
  }

  void _onTapNumber(int value) {
    if (_finished || _isDemo) return;
    if (value == _nextTarget) {
      SoundManager.playPop();
      if (_nextTarget >= _numberCount) {
        _finishAll();
      } else {
        setState(() => _nextTarget++);
      }
    } else {
      _wrongFlashTimer?.cancel();
      setState(() => _wrongFlashValue = value);
      _wrongFlashTimer = Timer(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() => _wrongFlashValue = null);
      });
    }
  }

  void _finishDemo() {
    _demoAutoTimer?.cancel();
    setState(() => _finished = true);
    SoundManager.playCorrect();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      _goToReady();
    });
  }

  // Antreman bitince (ya da geçilince) doğrudan zamanlı gerçek tura
  // atlamadan önce "şimdi sıra sende" yönergesi gösteriliyor.
  void _goToReady() {
    _demoAutoTimer?.cancel();
    setState(() => _phase = _Phase.ready);
  }

  void _finishAll() {
    _timer?.cancel();
    setState(() => _finished = true);
    _hasCompletedOnce = true;

    const percent = 100;
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Sayı Avı',
      result: '$_elapsedSec sn',
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
            Text(
              'Süre: $_elapsedSec sn',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tebrikler, etkinliği tamamladın!',
              style: TextStyle(fontWeight: FontWeight.bold),
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
        appBar: AppBar(title: const Text('🔍 Sayı Avı')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: switch (_phase) {
                  _Phase.intro => _buildIntro(),
                  _Phase.playing => _buildPlaying(),
                  _Phase.ready => _buildReady(),
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
                    'Sayı Avı',
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
                    const Center(
                      child: Text('🔢', style: TextStyle(fontSize: 64)),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: _color,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Amaç: Gözümüzün algılama hızını ve tarama '
                              'hızını artırmak.\n\nYöntem: Başlamadan önce '
                              'sana puansız, küçük bir antreman turu '
                              'göstereceğiz. Ardından 1\'den 30\'a kadar '
                              'sayıları sırasıyla ekranda arayıp bulacağız — '
                              'en kısa sürede bitirmeye çalışacağız.',
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

  // Antreman bitince (ya da geçilince) doğrudan zamanlı gerçek tura
  // atlamadan önce gösterilen "artık sıra sende" yönerge ekranı.
  Widget _buildReady() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: Text('🎯', style: TextStyle(fontSize: 64))),
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
                    'Şimdi sıra sende! Az önce izlediğin gibi, 1\'den '
                    '30\'a kadar sayıları sırasıyla ekranda arayıp '
                    'bulacaksın — bu sefer süre tutulacak, en kısa '
                    'sürede bitirmeye çalış!',
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
                    onPressed: _startRealGame,
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

  Widget _buildPlaying() {
    final total = _isDemo ? _demoNumberCount : _numberCount;
    final foundCount = _nextTarget - 1;
    return Column(
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
                _finished
                    ? (_isDemo ? 'Antreman bitti!' : 'Tamamlandı!')
                    : '${_isDemo ? '🎓 İzle · ' : ''}'
                          'Sırada: $_nextTarget · $foundCount/$total',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _color,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isDemo)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
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
                if (!_finished)
                  buildPauseButton(color: _color, onPressed: _pauseGame),
              ],
            ),
          ],
        ),
        if (_isDemo && !_finished) ...[
          const SizedBox(height: 8),
          const Text(
            '👀 Önce takip et, sonra sıra sende!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          _demoSpeedChipRow(),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _goToReady,
              child: const Text(
                'Antremanı Geç',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _numbersLayer(),
          ),
        ),
      ],
    );
  }

  Widget _demoSpeedChipRow() {
    return Row(
      children: [
        Text(
          'Hız: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 6),
        for (int i = 0; i < _demoSpeedLabels.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          ChoiceChip(
            label: Text(_demoSpeedLabels[i]),
            selected: _demoSpeedLevel == i,
            onSelected: (_) => _changeDemoSpeed(i),
            selectedColor: _color,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _demoSpeedLevel == i ? Colors.white : _color,
            ),
            backgroundColor: _color.withValues(alpha: 0.08),
            side: BorderSide(
              color: _color.withValues(alpha: _demoSpeedLevel == i ? 1 : 0.3),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ],
    );
  }

  Widget _numbersLayer() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            for (final spot in _spots)
              Positioned(
                key: ValueKey(spot.value),
                left: (spot.x * constraints.maxWidth - _badgeSize / 2).clamp(
                  0,
                  constraints.maxWidth - _badgeSize,
                ),
                top: (spot.y * constraints.maxHeight - _badgeSize / 2).clamp(
                  0,
                  constraints.maxHeight - _badgeSize,
                ),
                child: _numberBadgePop(spot),
              ),
          ],
        );
      },
    );
  }

  // Bulunan sayı bir baloncuk gibi küçülüp solarak silinsin diye.
  Widget _numberBadgePop(_NumberSpot spot) {
    final found = spot.value < _nextTarget;
    return AnimatedScale(
      scale: found ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 260),
      curve: found ? Curves.easeIn : Curves.easeOut,
      child: AnimatedOpacity(
        opacity: found ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 260),
        child: _numberBadge(spot),
      ),
    );
  }

  Widget _numberBadge(_NumberSpot spot) {
    final found = spot.value < _nextTarget;
    final isWrongFlash = _wrongFlashValue == spot.value;
    final borderColor = isWrongFlash ? Colors.red : spot.color;
    final textColor = found
        ? Colors.grey.shade400
        : (isWrongFlash ? Colors.red : spot.color);

    Widget number = Text(
      '${spot.value}',
      style: TextStyle(
        fontSize: 15,
        fontWeight: spot.style == 0 ? FontWeight.w900 : FontWeight.w600,
        fontStyle: spot.style == 1 ? FontStyle.italic : FontStyle.normal,
        color: spot.style == 5 && !found ? Colors.white : textColor,
      ),
    );

    Widget content;
    switch (spot.style) {
      case 2: // çember
        content = Container(
          width: _badgeSize,
          height: _badgeSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: found ? Colors.grey.shade400 : borderColor,
              width: 2,
            ),
          ),
          child: number,
        );
      case 3: // baklava
        content = SizedBox(
          width: _badgeSize,
          height: _badgeSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(_badgeSize, _badgeSize),
                painter: _PolygonBorderPainter(
                  found ? Colors.grey.shade400 : borderColor,
                  4,
                ),
              ),
              number,
            ],
          ),
        );
      case 4: // altıgen
        content = SizedBox(
          width: _badgeSize,
          height: _badgeSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(_badgeSize, _badgeSize),
                painter: _PolygonBorderPainter(
                  found ? Colors.grey.shade400 : borderColor,
                  6,
                ),
              ),
              number,
            ],
          ),
        );
      case 5: // dolgulu daire
        content = Container(
          width: _badgeSize,
          height: _badgeSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: found ? Colors.grey.shade300 : spot.color,
          ),
          child: number,
        );
      default: // 0 kalın, 1 eğik — sade
        content = SizedBox(
          width: _badgeSize,
          height: _badgeSize,
          child: Center(child: number),
        );
    }

    Widget badge = GestureDetector(
      onTap: found ? null : () => _onTapNumber(spot.value),
      child: content,
    );

    // Antremanda sırayla hangi sayının bulunduğu belli olsun diye o an
    // aktif olan sayının etrafına parlak, renkli bir halka ekleniyor.
    final isDemoActive = _isDemo && !_finished && spot.value == _nextTarget;
    if (isDemoActive) {
      badge = Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.amber.shade600, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.55),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: badge,
      );
    }

    return badge;
  }
}

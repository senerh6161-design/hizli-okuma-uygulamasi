import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';

/// "6. Madde" dokümanındaki etkinlik: kelimeler bir daire üzerinde oklarla
/// birbirine bağlı halde durur, öğrenci ok yönünü takip ederek (saat yönü ya
/// da tersi) resmini çeker gibi en kısa sürede okur. Süre: 30 sn, günde iki
/// kez, her seferinde daha hızlı olunması hedeflenir.
class ArrowWordCyclePage extends StatefulWidget {
  const ArrowWordCyclePage({super.key});

  @override
  State<ArrowWordCyclePage> createState() => _ArrowWordCyclePageState();
}

class _WordCycle {
  final List<String> words;
  final bool clockwise;
  const _WordCycle(this.words, this.clockwise);
}

class _ArrowWordCyclePageState extends State<ArrowWordCyclePage> {
  static const List<String> _setA = ['Azimliyim', 'Çalışkanım', 'Başarılıyım', 'Zekiyim'];
  static const List<String> _setB = [
    'Bir Hedef Belirle', 'Son Sürat Çalış', 'Zaman En Büyük Sermaye', 'Kıymetini Bil',
  ];
  static const List<String> _setC = ['Gayretliyim', 'Kararlıyım', 'Sabırlıyım', 'Umutluyum'];

  static const List<List<String>> _wordSets = [_setA, _setB, _setC];

  final Random _random = Random();
  static const int _totalRounds = 3;
  static const int _capSeconds = 30;

  late List<_WordCycle> _rounds;

  // Her turda FARKLI bir kelime seti çıksın diye (aynı setin sadece yönü
  // değişmiş hali değil) 3 seti karıştırıp yöne rastgele atıyoruz.
  List<_WordCycle> _buildRounds() {
    final shuffledSets = List<List<String>>.from(_wordSets)..shuffle(_random);
    return shuffledSets
        .take(_totalRounds)
        .map((set) => _WordCycle(set, _random.nextBool()))
        .toList();
  }
  int _roundIndex = 0;
  bool _isRunning = false;
  int _activeIndex = 0;
  Timer? _pulseTimer;

  // null ise turun kendi varsayılan yönü kullanılır; kullanıcı seçince
  // bütün turlar boyunca o yön kullanılır.
  bool? _directionOverride;
  bool get _effectiveClockwise => _directionOverride ?? _current.clockwise;

  Duration _elapsed = Duration.zero;
  Stopwatch? _stopwatch;
  Timer? _tickTimer;
  final List<double> _roundTimes = [];

  @override
  void initState() {
    super.initState();
    _rounds = _buildRounds();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _pulseTimer?.cancel();
    super.dispose();
  }

  _WordCycle get _current => _rounds[_roundIndex];

  void _start() {
    setState(() {
      _isRunning = true;
      _elapsed = Duration.zero;
      _activeIndex = 0;
    });
    _stopwatch = Stopwatch()..start();
    _tickTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() => _elapsed = _stopwatch!.elapsed);
      if (_elapsed.inSeconds >= _capSeconds) {
        _finishRound(timedOut: true);
      }
    });
    // Kelimeler ok yönünde (saat yönü/tersi) sırayla tek tek yanıp sönsün.
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 550), (_) {
      if (!mounted) return;
      final n = _current.words.length;
      setState(() {
        _activeIndex = _effectiveClockwise
            ? (_activeIndex + 1) % n
            : (_activeIndex - 1 + n) % n;
      });
    });
  }

  void _finishRound({bool timedOut = false}) {
    _tickTimer?.cancel();
    _pulseTimer?.cancel();
    _stopwatch?.stop();
    final seconds = timedOut ? _capSeconds.toDouble() : _stopwatch!.elapsedMilliseconds / 1000;
    SoundManager.playCorrect();
    setState(() {
      _isRunning = false;
      _roundTimes.add(seconds);
    });

    if (_roundIndex < _totalRounds - 1) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text(timedOut ? '⏱️ Süre Doldu' : '✅ ${_roundIndex + 1}. Tur Bitti'),
          content: Text(
            timedOut
                ? '30 saniyede bitiremedin, bir sonraki turda daha hızlı olmayı dene!'
                : '${seconds.toStringAsFixed(1)} saniyede bitirdin. Bir sonraki turda daha hızlı olmaya çalış!',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _roundIndex++);
              },
              child: const Text('Sonraki Tur'),
            ),
          ],
        ),
      );
    } else {
      _finishAll();
    }
  }

  void _finishAll() {
    final avg = _roundTimes.reduce((a, b) => a + b) / _roundTimes.length;
    final score = ((_capSeconds - avg) / _capSeconds * 100).round().clamp(5, 100);
    ProgressManager.recordAttentionScore(score);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Ok Yönlü Kelime Döngüsü',
      result: 'Ort. ${avg.toStringAsFixed(1)} sn · $score puan',
    );
    if (unlocked.isNotEmpty) SoundManager.playAchievement();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🎉 3 Tur Tamamlandı!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < _roundTimes.length; i++)
              Text('${i + 1}. tur: ${_roundTimes[i].toStringAsFixed(1)} sn'),
            const SizedBox(height: 8),
            Text('Ortalama: ${avg.toStringAsFixed(1)} sn',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Puan: $score',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
            if (unlocked.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('🎉 Yeni Başarım Kazandın!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: unlocked.map((a) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                        Text(a.title,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900)),
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
              Navigator.pop(context); // dialogu kapat
              Navigator.pop(context); // Klasör 1'e dön
            },
            child: const Text('Bitir'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _rounds = _buildRounds();
                _roundIndex = 0;
                _roundTimes.clear();
                _elapsed = Duration.zero;
              });
            },
            child: const Text('Yeniden Başlat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = _current.words;
    final n = words.length;

    return Scaffold(
      appBar: AppBar(title: const Text('🔁 Kelime Döngüsü')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tur: ${_roundIndex + 1}/$_totalRounds',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                ),
                Text(
                  'Süre: ${(_elapsed.inMilliseconds / 1000).toStringAsFixed(1)} sn',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _elapsed.inSeconds >= _capSeconds - 5 ? Colors.red : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                const Text('Yön: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(width: 4),
                ChoiceChip(
                  avatar: const Icon(Icons.rotate_right, size: 18),
                  label: const Text('Saat Yönü'),
                  selected: _effectiveClockwise,
                  onSelected: _isRunning
                      ? null
                      : (selected) {
                          if (selected) setState(() => _directionOverride = true);
                        },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: const Icon(Icons.rotate_left, size: 18),
                  label: const Text('Ters Yön'),
                  selected: !_effectiveClockwise,
                  onSelected: _isRunning
                      ? null
                      : (selected) {
                          if (selected) setState(() => _directionOverride = false);
                        },
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = min(constraints.maxWidth, constraints.maxHeight);
                  final center = Offset(constraints.maxWidth / 2, size / 2);
                  final radius = size / 2 - 60;

                  return Stack(
                    children: [
                      CustomPaint(
                        size: Size(constraints.maxWidth, size),
                        painter: _CycleArrowPainter(
                          center: center,
                          radius: radius,
                          count: n,
                          clockwise: _effectiveClockwise,
                        ),
                      ),
                      for (int i = 0; i < n; i++)
                        Builder(builder: (_) {
                          final angle = (2 * pi * i / n) - (pi / 2);
                          final dx = center.dx + radius * cos(angle);
                          final dy = center.dy + radius * sin(angle);
                          final isActive = _isRunning && i == _activeIndex;

                          return Positioned(
                            left: dx - 60,
                            top: dy - (isActive ? 34 : 30),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isActive ? 128 : 120,
                              height: isActive ? 68 : 60,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isActive ? const Color(0xFF4F46E5) : Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF4F46E5),
                                  width: isActive ? 2.5 : 1.5,
                                ),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF4F46E5).withValues(alpha: 0.45),
                                          blurRadius: 14,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  words[i],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isActive ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isRunning ? () => _finishRound() : _start,
                icon: Icon(_isRunning ? Icons.check : Icons.play_arrow),
                label: Text(
                  _isRunning ? 'BİTİRDİM' : 'BAŞLAT',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRunning ? Colors.green.shade600 : const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CycleArrowPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final int count;
  final bool clockwise;

  _CycleArrowPainter({
    required this.center,
    required this.radius,
    required this.count,
    required this.clockwise,
  });

  Offset _pointFor(int i) {
    final angle = (2 * pi * i / count) - (pi / 2);
    return Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4F46E5).withValues(alpha: 0.55)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()..color = const Color(0xFF4F46E5).withValues(alpha: 0.55);

    for (int i = 0; i < count; i++) {
      final j = clockwise ? (i + 1) % count : (i - 1 + count) % count;
      final p1 = _pointFor(i);
      final p2 = _pointFor(j);

      // Kartların üzerine binmesin diye çizgiyi biraz içeri çekiyoruz.
      final dir = (p2 - p1);
      final len = dir.distance;
      if (len == 0) continue;
      final unit = dir / len;
      final start = p1 + unit * 55;
      final end = p2 - unit * 55;

      canvas.drawLine(start, end, paint);

      // Ok başı
      const arrowSize = 10.0;
      final angle = atan2(end.dy - start.dy, end.dx - start.dx);
      final path = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(
          end.dx - arrowSize * cos(angle - pi / 7),
          end.dy - arrowSize * sin(angle - pi / 7),
        )
        ..lineTo(
          end.dx - arrowSize * cos(angle + pi / 7),
          end.dy - arrowSize * sin(angle + pi / 7),
        )
        ..close();
      canvas.drawPath(path, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CycleArrowPainter oldDelegate) =>
      oldDelegate.clockwise != clockwise || oldDelegate.count != count;
}

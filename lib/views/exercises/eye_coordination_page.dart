import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/achievement.dart';
import '../../widgets/completion_pop_scope.dart';

// "Farklı versiyonlar" — hoca hangi ikonla göstermek isterse seçilebilsin
// diye birkaç tema tanımlı. emoji null olan tema (Nokta) orijinal
// videodaki sade mavi noktaya karşılık geliyor.
enum _IconTheme { dot, star, heart, smiley, apple }

extension on _IconTheme {
  String get label {
    switch (this) {
      case _IconTheme.dot:
        return 'Nokta';
      case _IconTheme.star:
        return 'Yıldız';
      case _IconTheme.heart:
        return 'Kalp';
      case _IconTheme.smiley:
        return 'Gülen Yüz';
      case _IconTheme.apple:
        return 'Elma';
    }
  }

  String? get emoji {
    switch (this) {
      case _IconTheme.dot:
        return null;
      case _IconTheme.star:
        return '⭐';
      case _IconTheme.heart:
        return '❤️';
      case _IconTheme.smiley:
        return '😊';
      case _IconTheme.apple:
        return '🍎';
    }
  }
}

enum _Speed { slow, normal, fast }

extension on _Speed {
  int get stepMs {
    switch (this) {
      case _Speed.slow:
        return 900;
      case _Speed.normal:
        return 600;
      case _Speed.fast:
        return 350;
    }
  }

  String get label {
    switch (this) {
      case _Speed.slow:
        return 'Yavaş';
      case _Speed.normal:
        return 'Orta';
      case _Speed.fast:
        return 'Hızlı';
    }
  }
}

/// Göz Koordinasyonu Egzersizi: ekrandaki bağlı noktalar arasında,
/// aktif nokta sırayla ilerler. Kullanıcı başını oynatmadan, sadece
/// gözleriyle aktif noktayı takip eder. Kelime bazlı Hızlı Okuma
/// egzersizlerinden ÖNCE bir ısınma turu olarak düşünülmüştür.
class EyeCoordinationPage extends StatefulWidget {
  const EyeCoordinationPage({super.key});

  @override
  State<EyeCoordinationPage> createState() => _EyeCoordinationPageState();
}

class _EyeCoordinationPageState extends State<EyeCoordinationPage> {
  // Farklı rota şablonları (fraksiyonel koordinat: 0.0-1.0). "Farklı Rota"
  // butonuyla aralarında geçiş yapılabilir.
  static const List<List<Offset>> _pathTemplates = [
    [
      Offset(0.15, 0.10), Offset(0.42, 0.10), Offset(0.20, 0.32),
      Offset(0.20, 0.82), Offset(0.40, 0.82), Offset(0.40, 0.45),
      Offset(0.58, 0.65), Offset(0.66, 0.15), Offset(0.85, 0.10),
      Offset(0.85, 0.82),
    ],
    [
      Offset(0.85, 0.12), Offset(0.55, 0.12), Offset(0.78, 0.35),
      Offset(0.78, 0.85), Offset(0.55, 0.85), Offset(0.55, 0.48),
      Offset(0.35, 0.68), Offset(0.28, 0.18), Offset(0.10, 0.12),
      Offset(0.10, 0.85),
    ],
    [
      Offset(0.50, 0.08), Offset(0.85, 0.25), Offset(0.68, 0.50),
      Offset(0.88, 0.80), Offset(0.50, 0.65), Offset(0.32, 0.88),
      Offset(0.12, 0.62), Offset(0.30, 0.38), Offset(0.12, 0.15),
      Offset(0.50, 0.32),
    ],
  ];

  static const int _totalLaps = 3;

  final Random _random = Random();
  late List<Offset> _points;
  _IconTheme _theme = _IconTheme.dot;
  _Speed _speed = _Speed.normal;

  int _currentIndex = 0;
  int _lapsCompleted = 0;
  Timer? _timer;
  bool _isRunning = false;
  bool _hasCompletedOnce = false;

  @override
  void initState() {
    super.initState();
    _points = _pathTemplates[_random.nextInt(_pathTemplates.length)];
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      _isRunning = true;
      _currentIndex = 0;
      _lapsCompleted = 0;
    });
    _timer = Timer.periodic(Duration(milliseconds: _speed.stepMs), (t) {
      if (!mounted) return;
      if (_currentIndex >= _points.length - 1) {
        final nextLap = _lapsCompleted + 1;
        if (nextLap >= _totalLaps) {
          _finish();
          return;
        }
        setState(() {
          _currentIndex = 0;
          _lapsCompleted = nextLap;
        });
      } else {
        setState(() => _currentIndex++);
      }
    });
  }

  void _finish() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _lapsCompleted = _totalLaps;
      _hasCompletedOnce = true;
    });

    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Göz Koordinasyonu (${_theme.label})',
      result: '$_totalLaps tur tamamlandı',
    );
    if (unlocked.isNotEmpty && mounted) {
      _showAchievementSnackBar(unlocked);
    }
  }

  void _stop() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _shufflePath() {
    _timer?.cancel();
    setState(() {
      _points = _pathTemplates[_random.nextInt(_pathTemplates.length)];
      _currentIndex = 0;
      _lapsCompleted = 0;
      _isRunning = false;
    });
  }

  void _showAchievementSnackBar(List<Achievement> unlocked) {
    final names = unlocked.map((a) => a.title).join(', ');
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🏆 Yeni başarım: $names'),
        backgroundColor: Colors.amber.shade800,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompletionPopScope(
      isCompleted: () => _hasCompletedOnce,
      child: Scaffold(
      appBar: AppBar(title: const Text('👁️ Göz Koordinasyonu')),
      body: Column(
        children: [
          // İKON TEMASI SEÇİCİ ("farklı versiyonlar")
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _IconTheme.values.map((t) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t.emoji != null ? '${t.emoji} ${t.label}' : t.label),
                      selected: _theme == t,
                      onSelected: (selected) {
                        if (selected) setState(() => _theme = t);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // HIZ SEÇİCİ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: Colors.white,
            child: Row(
              children: _Speed.values.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(s.label),
                    selected: _speed == s,
                    onSelected: (selected) {
                      if (selected) setState(() => _speed = s);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          if (_isRunning)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Tur: ${_lapsCompleted + 1}/$_totalLaps',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
              ),
            ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(constraints.maxWidth, constraints.maxHeight);
                    return Stack(
                      children: [
                        CustomPaint(
                          size: size,
                          painter: _PathPainter(points: _points),
                        ),
                        ..._points.asMap().entries.map((entry) {
                          final index = entry.key;
                          final point = entry.value;
                          final isActive = _isRunning && index == _currentIndex;
                          final nodeSize = isActive ? 56.0 : 46.0;
                          return Positioned(
                            left: point.dx * size.width - nodeSize / 2,
                            top: point.dy * size.height - nodeSize / 2,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: nodeSize,
                              height: nodeSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive ? const Color(0xFF4F46E5) : Colors.white,
                                border: Border.all(
                                  color: isActive ? const Color(0xFF4F46E5) : Colors.indigo.shade200,
                                  width: isActive ? 0 : 2,
                                ),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF4F46E5).withValues(alpha: 0.4),
                                          blurRadius: 14,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: _theme.emoji != null
                                    ? Text(
                                        _theme.emoji!,
                                        style: TextStyle(fontSize: isActive ? 26 : 20),
                                      )
                                    : Container(
                                        width: isActive ? 16 : 12,
                                        height: isActive ? 16 : 12,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isActive ? Colors.white : const Color(0xFF4F46E5),
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
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _shufflePath,
                    icon: const Icon(Icons.shuffle),
                    label: const Text('Farklı Rota'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isRunning ? _stop : _start,
                    icon: Icon(_isRunning ? Icons.stop : Icons.play_arrow),
                    label: Text(
                      _isRunning ? 'DURDUR' : 'BAŞLAT',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  final List<Offset> points;

  _PathPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = Offset(points[i].dx * size.width, points[i].dy * size.height);
      final p2 = Offset(points[i + 1].dx * size.width, points[i + 1].dy * size.height);
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) => oldDelegate.points != points;
}
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/achievement.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';

// "Farklı versiyonlar" — hoca hangi ikonla göstermek isterse seçilebilsin
// diye birkaç tema tanımlı. emoji null olan tema (Nokta) orijinal
// videodaki sade mavi noktaya karşılık geliyor.
enum _IconTheme { dot, star, smiley, apple }

extension on _IconTheme {
  String get label {
    switch (this) {
      case _IconTheme.dot:
        return 'Nokta';
      case _IconTheme.star:
        return 'Yıldız';
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
      case _IconTheme.smiley:
        return '😊';
      case _IconTheme.apple:
        return '🍎';
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
      Offset(0.15, 0.10),
      Offset(0.42, 0.10),
      Offset(0.20, 0.32),
      Offset(0.20, 0.82),
      Offset(0.40, 0.82),
      Offset(0.40, 0.45),
      Offset(0.58, 0.65),
      Offset(0.66, 0.15),
      Offset(0.85, 0.10),
      Offset(0.85, 0.82),
    ],
    [
      Offset(0.85, 0.12),
      Offset(0.55, 0.12),
      Offset(0.78, 0.35),
      Offset(0.78, 0.85),
      Offset(0.55, 0.85),
      Offset(0.55, 0.48),
      Offset(0.35, 0.68),
      Offset(0.28, 0.18),
      Offset(0.10, 0.12),
      Offset(0.10, 0.85),
    ],
    [
      Offset(0.50, 0.08),
      Offset(0.85, 0.25),
      Offset(0.68, 0.50),
      Offset(0.88, 0.80),
      Offset(0.50, 0.65),
      Offset(0.32, 0.88),
      Offset(0.12, 0.62),
      Offset(0.30, 0.38),
      Offset(0.12, 0.15),
      Offset(0.50, 0.32),
    ],
  ];

  static const int _totalLaps = 3;

  // Hoca dokümanındaki diğer etkinliklerle aynı mantık: yavaş başla, her
  // turda otomatik hızlan. Artık kullanıcı manuel hız seçmiyor.
  static const List<int> _lapStepMs = [900, 600, 350];
  static const List<String> _lapLabels = ['Yavaş', 'Orta', 'Hızlı'];

  final Random _random = Random();
  late List<Offset> _points;
  // Her BAŞLAT'ta 3 tur için 3 FARKLI rota karıştırılıp sıraya konur — tur
  // boyunca hep aynı rotayı görme sorunu böyle çözülür, her tur ayrı şekil.
  late List<List<Offset>> _lapRoutes;
  _IconTheme _theme = _IconTheme.dot;

  int _currentIndex = 0;
  int _lapsCompleted = 0;
  Timer? _timer;
  bool _isRunning = false;
  bool _isPaused = false;
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
    // 3 turun her biri kendi rotasını alsın diye şablonlar karıştırılıp
    // sıraya konur (3 şablon, 3 tur — hiçbiri tekrar etmez).
    _lapRoutes = List<List<Offset>>.from(_pathTemplates)..shuffle(_random);
    setState(() {
      _isRunning = true;
      _currentIndex = 0;
      _lapsCompleted = 0;
      _points = _lapRoutes[0];
    });
    _scheduleTick();
  }

  void _scheduleTick() {
    final stepMs = _lapStepMs[_lapsCompleted.clamp(0, _lapStepMs.length - 1)];
    _timer = Timer(Duration(milliseconds: stepMs), () {
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
          _points = _lapRoutes[nextLap];
        });
      } else {
        setState(() => _currentIndex++);
      }
      _scheduleTick();
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

  void _pauseRun() {
    _timer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resumeRun() {
    setState(() => _isPaused = false);
    _scheduleTick();
  }

  // Koşu SIRASINDA rota değiştirmek, egzersizi en baştan sıfırlayıp
  // öğrencinin o ana kadarki turunu boşa çıkarıyordu — bu yüzden buton
  // sadece BOŞTAYKEN (henüz başlamamışken) önizleme rotasını değiştirir;
  // koşarken devre dışı bırakılır (bkz. build'deki onPressed).
  void _shufflePath() {
    if (_isRunning) return;
    setState(() {
      _points = _pathTemplates[_random.nextInt(_pathTemplates.length)];
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
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(title: const Text('👁️ Göz Koordinasyonu')),
        body: Stack(
          children: [
            Column(
              children: [
                // Yönerge şeridi
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.remove_red_eye_rounded,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Başını oynatmadan, sadece gözlerinle aktif noktayı takip et.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1E3A8A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_isRunning)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Tur: ${_lapsCompleted + 1}/$_totalLaps',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0D9488,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '⚡ ${_lapLabels[_lapsCompleted.clamp(0, _lapLabels.length - 1)]}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D9488),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        buildPauseButton(
                          color: const Color(0xFF2563EB),
                          onPressed: _pauseRun,
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2563EB,
                            ).withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final size = Size(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            );
                            return Stack(
                              children: [
                                CustomPaint(
                                  size: size,
                                  painter: _PathPainter(points: _points),
                                ),
                                ..._points.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final point = entry.value;
                                  final isActive =
                                      _isRunning && index == _currentIndex;
                                  final nodeSize = isActive ? 56.0 : 44.0;
                                  return Positioned(
                                    left: point.dx * size.width - nodeSize / 2,
                                    top: point.dy * size.height - nodeSize / 2,
                                    // Bilerek animasyonsuz (Container, AnimatedContainer
                                    // DEĞİL): büyüyüp küçülme geçişi bir öncekinin
                                    // hâlâ küçülmekte olduğu bir anda yeni noktanın
                                    // büyümeye başlamasına, yani iki noktanın bir an
                                    // üst üste binmiş gibi görünmesine yol açıyordu.
                                    // Anlık geçiş bunu kökten çözer.
                                    child: Container(
                                      width: nodeSize,
                                      height: nodeSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isActive
                                            ? const Color(0xFF2563EB)
                                            : const Color(0xFFEFF6FF),
                                        border: Border.all(
                                          color: isActive
                                              ? const Color(0xFF2563EB)
                                              : const Color(0xFF93C5FD),
                                          width: isActive ? 0 : 2,
                                        ),
                                        boxShadow: isActive
                                            ? [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFF2563EB,
                                                  ).withValues(alpha: 0.4),
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
                                                style: TextStyle(
                                                  fontSize: isActive ? 26 : 18,
                                                ),
                                              )
                                            : Container(
                                                width: isActive ? 16 : 10,
                                                height: isActive ? 16 : 10,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isActive
                                                      ? Colors.white
                                                      : const Color(0xFF2563EB),
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
                ),

                // Alt kontrol paneli: ikon teması + aksiyon butonları bir arada
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 12,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Görsel Teması',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _IconTheme.values.map((t) {
                            final selected = _theme == t;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(
                                  t.emoji != null
                                      ? '${t.emoji} ${t.label}'
                                      : t.label,
                                ),
                                selected: selected,
                                onSelected: (sel) {
                                  if (sel) setState(() => _theme = t);
                                },
                                selectedColor: const Color(
                                  0xFF2563EB,
                                ).withValues(alpha: 0.15),
                                labelStyle: TextStyle(
                                  color: selected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF475569),
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                side: BorderSide(
                                  color: selected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFE2E8F0),
                                ),
                                backgroundColor: const Color(0xFFF8FAFC),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isRunning ? null : _shufflePath,
                              icon: const Icon(Icons.shuffle),
                              label: const Text('Farklı Rota'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2563EB),
                                side: const BorderSide(
                                  color: Color(0xFF2563EB),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _isRunning ? _stop : _start,
                              icon: Icon(
                                _isRunning ? Icons.stop : Icons.play_arrow,
                              ),
                              label: Text(
                                _isRunning ? 'DURDUR' : 'BAŞLAT',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                elevation: 4,
                                shadowColor: const Color(
                                  0xFF2563EB,
                                ).withValues(alpha: 0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isPaused)
              buildPauseOverlay(
                color: const Color(0xFF2563EB),
                onResume: _resumeRun,
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
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = Offset(points[i].dx * size.width, points[i].dy * size.height);
      final p2 = Offset(
        points[i + 1].dx * size.width,
        points[i + 1].dy * size.height,
      );
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) =>
      oldDelegate.points != points;
}

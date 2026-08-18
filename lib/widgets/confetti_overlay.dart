import 'dart:math';
import 'package:flutter/material.dart';

/// Büyük bir başarı anında ("oturum tamamlandı", "yeni rekor" gibi)
/// ekranın üstüne kısa süreliğine konfeti patlatır. Harici paket kullanmaz —
/// basit fizikli, kendi çizdiğimiz parçacıklarla çalışır.
void showConfetti(BuildContext context) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ConfettiBurst(onDone: () => entry.remove()),
  );
  overlay.insert(entry);
}

class _Particle {
  double x; // 0..1 genişlik oranı
  double y; // 0..1 yükseklik oranı
  final double vx;
  final double vy;
  final double rotationSpeed;
  double rotation;
  final Color color;
  final double size;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotationSpeed,
    required this.rotation,
    required this.color,
    required this.size,
  });
}

class _ConfettiBurst extends StatefulWidget {
  final VoidCallback onDone;
  const _ConfettiBurst({required this.onDone});

  @override
  State<_ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<_ConfettiBurst> with SingleTickerProviderStateMixin {
  static const List<Color> _palette = [
    Color(0xFFF59E0B),
    Color(0xFF4F46E5),
    Color(0xFF10B981),
    Color(0xFFEF4444),
    Color(0xFF3B82F6),
    Color(0xFFEC4899),
  ];

  late final AnimationController _controller;
  late final List<_Particle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(70, (_) {
      return _Particle(
        x: _random.nextDouble(),
        y: -0.05 - _random.nextDouble() * 0.2,
        vx: (_random.nextDouble() - 0.5) * 0.25,
        vy: 0.55 + _random.nextDouble() * 0.5,
        rotationSpeed: (_random.nextDouble() - 0.5) * 8,
        rotation: _random.nextDouble() * pi * 2,
        color: _palette[_random.nextInt(_palette.length)],
        size: 6 + _random.nextDouble() * 6,
      );
    });

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..addListener(() {
        for (final p in _particles) {
          p.y += p.vy * 0.016;
          p.x += p.vx * 0.016;
          p.rotation += p.rotationSpeed * 0.016;
        }
        setState(() {});
      })
      ..forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _ConfettiPainter(_particles),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      if (p.y > 1.1) continue;
      paint.color = p.color;
      final center = Offset(p.x * size.width, p.y * size.height);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(p.rotation);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}

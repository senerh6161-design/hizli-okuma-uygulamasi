import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';

enum CircularMode { numbers12, numbers20, days, months }

extension on CircularMode {
  String get label {
    switch (this) {
      case CircularMode.numbers12:
        return '1-12 Sayı';
      case CircularMode.numbers20:
        return '1-20 Sayı';
      case CircularMode.days:
        return 'Günler';
      case CircularMode.months:
        return 'Aylar';
    }
  }

  List<String> get sequence {
    switch (this) {
      case CircularMode.numbers12:
        return List.generate(12, (i) => '${i + 1}');
      case CircularMode.numbers20:
        return List.generate(20, (i) => '${i + 1}');
      case CircularMode.days:
        return const [
          'PAZARTESİ', 'SALI', 'ÇARŞAMBA', 'PERŞEMBE', 'CUMA', 'CUMARTESİ', 'PAZAR',
        ];
      case CircularMode.months:
        return const [
          'OCAK', 'ŞUBAT', 'MART', 'NİSAN', 'MAYIS', 'HAZİRAN',
          'TEMMUZ', 'AĞUSTOS', 'EYLÜL', 'EKİM', 'KASIM', 'ARALIK',
        ];
    }
  }
}

/// Dairesel Sayı/Gün/Ay Sıralama: öğretmen dokümanındaki "3., 4. ve 5.
/// Etkinlik" — sayılar/günler/aylar bir daire üzerine dağıtılır, önce doğru
/// sırayla 3 kez (her seferinde hızlanarak) gösterilir, sonra öğrenci
/// karışık yerleşimi doğru sırayla en kısa sürede tıklamaya çalışır. Her
/// turda öğelerin yerleri yeniden karışır.
class CircularSequencePage extends StatefulWidget {
  // Hangi modların bu sayfada gösterileceği. Tek modlu verilirse mod
  // seçici gizlenir ve o tek aktivite olarak açılır (hocanın "1-12 ve
  // 1-20 ayrı etkinlik" isteğine göre).
  final List<CircularMode> availableModes;
  final String appBarTitle;

  const CircularSequencePage({
    super.key,
    this.availableModes = CircularMode.values,
    this.appBarTitle = '🔄 Dairesel Sıralama',
  });

  @override
  State<CircularSequencePage> createState() => _CircularSequencePageState();
}

class _CircularSequencePageState extends State<CircularSequencePage> {
  final Random _random = Random();

  late CircularMode _mode = widget.availableModes.first;
  late List<String> _positions; // dairedeki her yuvanın gösterdiği öğe

  bool _isDemoing = false;
  int _demoLap = 0;
  int _demoIndex = 0;
  Timer? _demoTimer;
  bool _hasCompletedOnce = false;

  bool _isPlaying = false;
  int _targetIndex = 0;
  Duration _elapsed = Duration.zero;
  Stopwatch? _stopwatch;
  Timer? _tickTimer;
  int? _wrongTapIndex;
  int? _bestMs;

  static const List<int> _demoStepMs = [700, 500, 350];

  @override
  void initState() {
    super.initState();
    _resetPositions();
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }

  void _resetPositions() {
    _positions = List.from(_mode.sequence);
  }

  void _changeMode(CircularMode mode) {
    _demoTimer?.cancel();
    _tickTimer?.cancel();
    setState(() {
      _mode = mode;
      _isDemoing = false;
      _isPlaying = false;
      _targetIndex = 0;
      _elapsed = Duration.zero;
      _bestMs = null;
      _resetPositions();
    });
  }

  void _startDemo() {
    _demoTimer?.cancel();
    // Doküman görsellerinde de sayılar/günler/aylar dairede KARIŞIK
    // duruyor — izleme turunda da gerçek oyundaki gibi dağınık yerleşim
    // kullanılır, sadece hangi yuvanın sırada olduğu vurgulanır.
    final shuffled = List<String>.from(_mode.sequence)..shuffle(_random);
    setState(() {
      _isDemoing = true;
      _isPlaying = false;
      _positions = shuffled;
      _demoLap = 0;
      _demoIndex = 0;
    });
    _scheduleDemoStep();
  }

  void _scheduleDemoStep() {
    final stepMs = _demoStepMs[_demoLap.clamp(0, _demoStepMs.length - 1)];
    _demoTimer = Timer(Duration(milliseconds: stepMs), () {
      if (!mounted) return;
      final n = _mode.sequence.length;
      if (_demoIndex >= n - 1) {
        if (_demoLap >= _demoStepMs.length - 1) {
          setState(() => _isDemoing = false);
          return;
        }
        setState(() {
          _demoLap++;
          _demoIndex = 0;
        });
      } else {
        setState(() => _demoIndex++);
      }
      _scheduleDemoStep();
    });
  }

  void _startPlay() {
    _demoTimer?.cancel();
    final shuffled = List<String>.from(_mode.sequence)..shuffle(_random);
    setState(() {
      _isDemoing = false;
      _isPlaying = true;
      _positions = shuffled;
      _targetIndex = 0;
      _elapsed = Duration.zero;
      _wrongTapIndex = null;
    });
    _stopwatch = Stopwatch()..start();
    _tickTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() => _elapsed = _stopwatch!.elapsed);
    });
  }

  void _onTapSlot(int index) {
    if (!_isPlaying) return;
    final expected = _mode.sequence[_targetIndex];
    if (_positions[index] == expected) {
      SoundManager.playCorrect();
      final n = _mode.sequence.length;
      if (_targetIndex == n - 1) {
        _finish();
      } else {
        setState(() => _targetIndex++);
      }
    } else {
      SoundManager.playGentleTap();
      setState(() => _wrongTapIndex = index);
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) setState(() => _wrongTapIndex = null);
      });
    }
  }

  void _finish() {
    _tickTimer?.cancel();
    _stopwatch?.stop();
    final ms = _stopwatch?.elapsedMilliseconds ?? 0;
    setState(() {
      _isPlaying = false;
      _hasCompletedOnce = true;
      if (_bestMs == null || ms < _bestMs!) _bestMs = ms;
    });

    SoundManager.playSuccess();
    final n = _mode.sequence.length;
    final seconds = ms / 1000;
    // Referans hız: öğe başına 2.5 sn. Daha hızlıysan skor 100'ün üzerine çıkar.
    final score = ((n * 2.5) / seconds * 100).round().clamp(10, 300);
    ProgressManager.recordAttentionScore(score.clamp(0, 100));

    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Dairesel Sıralama (${_mode.label})',
      result: '${seconds.toStringAsFixed(1)} sn · $score puan',
    );
    if (unlocked.isNotEmpty) SoundManager.playAchievement();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🎉 Tamamlandı!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mod: ${_mode.label}'),
            const SizedBox(height: 6),
            Text('Süre: ${seconds.toStringAsFixed(1)} sn'),
            Text('Puan: $score'),
            if (_bestMs == ms) ...[
              const SizedBox(height: 8),
              const Text('🏆 YENİ REKOR!',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ],
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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _targetIndex = 0;
                _elapsed = Duration.zero;
                _resetPositions();
              });
            },
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = _positions.length;
    final activeIndex = _isDemoing ? _positions.indexOf(_mode.sequence[_demoIndex]) : -1;

    return CompletionPopScope(
      isCompleted: () => _hasCompletedOnce,
      child: Scaffold(
      appBar: AppBar(title: Text(widget.appBarTitle)),
      body: Column(
        children: [
          if (widget.availableModes.length > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: widget.availableModes.map((m) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(m.label),
                        selected: _mode == m,
                        onSelected: (selected) {
                          if (selected) _changeMode(m);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isPlaying
                      ? 'Sırada: ${_mode.sequence[_targetIndex]}'
                      : (_isDemoing ? 'İzle: ${_demoLap + 1}. tur' : 'Hazır mısın?'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                ),
                Text(
                  'Süre: ${(_elapsed.inMilliseconds / 1000).toStringAsFixed(1)} sn',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                if (_bestMs != null)
                  Text(
                    '🏆 ${(_bestMs! / 1000).toStringAsFixed(1)} sn',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = min(constraints.maxWidth, constraints.maxHeight);
                  final center = Offset(constraints.maxWidth / 2, size / 2 + 10);
                  final radius = size / 2 - 40;
                  final nodeSize = n > 14 ? 48.0 : 68.0;

                  return Stack(
                    children: [
                      Positioned(
                        left: center.dx - 34,
                        top: center.dy - 20,
                        child: SizedBox(
                          width: 68,
                          child: Text(
                            _isPlaying ? '${_targetIndex + 1}/$n' : (_isDemoing ? '👀' : 'Başla ↓'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                          ),
                        ),
                      ),
                      for (int i = 0; i < n; i++)
                        Builder(builder: (_) {
                          final angle = (2 * pi * i / n) - (pi / 2);
                          final dx = center.dx + radius * cos(angle) - nodeSize / 2;
                          final dy = center.dy + radius * sin(angle) - nodeSize / 2;

                          final isDemoActive = _isDemoing && i == activeIndex;
                          final isWrong = _wrongTapIndex == i;
                          final passedInPlay = _isPlaying &&
                              _mode.sequence.indexOf(_positions[i]) < _targetIndex;

                          Color bg = const Color(0xFFEFF6FF);
                          Color border = const Color(0xFF93C5FD);
                          Color textColor = const Color(0xFF0F172A);
                          if (isDemoActive) {
                            bg = const Color(0xFF2563EB);
                            textColor = Colors.white;
                          } else if (isWrong) {
                            bg = Colors.red.shade400;
                            textColor = Colors.white;
                          } else if (passedInPlay) {
                            bg = Colors.green.shade500;
                            textColor = Colors.white;
                          }

                          return Positioned(
                            left: dx,
                            top: dy,
                            child: GestureDetector(
                              onTap: () => _onTapSlot(i),
                              child: AnimatedContainer(
                                // En hızlı turda yuvalar arası 350ms var;
                                // geçiş bu kadar yakın olursa bir önceki
                                // vurgu tam sönmeden yenisi başlıyor.
                                duration: const Duration(milliseconds: 90),
                                width: nodeSize,
                                height: nodeSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: bg,
                                  border: Border.all(color: border, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Text(
                                      _positions[i],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: n > 14 ? 12 : 16,
                                        color: textColor,
                                      ),
                                    ),
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
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isPlaying ? null : _startDemo,
                    icon: const Icon(Icons.visibility),
                    label: const Text('İZLE'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isPlaying ? null : _startPlay,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('BAŞLA', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
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

import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';

enum _Phase { intro, playing }

class _AnagramQuestion {
  final String scrambled;
  final String answer; // normalize edilmiş (büyük harf, Türkçe İ/I) hali
  final String hint1;
  final String hint2;
  final String hint3;
  const _AnagramQuestion({
    required this.scrambled,
    required this.answer,
    required this.hint1,
    required this.hint2,
    required this.hint3,
  });
}

/// Klasör 2'nin dokuzuncu etkinliği: "Kelimelerle Saklambaç Oynuyorum".
/// Verilen harflerin hepsini kullanarak (ek almadan) yeni bir kelime
/// bulmaya çalışıyor. Her 30 saniyede bir ipucu açılıyor, ne kadar erken
/// bulursa o kadar çok puan kazanıyor (100 → 90 → 80 → 70).
class AnagramWordHuntPage extends StatefulWidget {
  const AnagramWordHuntPage({super.key});

  @override
  State<AnagramWordHuntPage> createState() => _AnagramWordHuntPageState();
}

class _AnagramWordHuntPageState extends State<AnagramWordHuntPage> {
  static const Color _color = Color(0xFF475569);
  static const int _hintIntervalSec = 30;
  static const int _maxHints = 3;
  static const int _timeoutSec = _hintIntervalSec * (_maxHints + 1); // 120

  static const List<_AnagramQuestion> _questions = [
    _AnagramQuestion(
      scrambled: 'KASLI CAN',
      answer: 'SALINCAK',
      hint1: 'İlk harfi S, son harfi K',
      hint2: 'Çocuk parkında bulunur.',
      hint3: 'İlk üç harfi: Sal…',
    ),
    _AnagramQuestion(
      scrambled: 'DEVE NİL',
      answer: 'ELDİVEN',
      hint1: 'İlk harfi E, son harfi N',
      hint2: 'Ellerimiz üşüyünce…',
      hint3: 'İlk üç harfi: Eld…',
    ),
    _AnagramQuestion(
      scrambled: 'YASTIK ERİ',
      answer: 'KIRTASİYE',
      hint1: 'İlk harfi K, son harfi E',
      hint2: 'Okul ihtiyaçlarımızı alırız.',
      hint3: 'İlk üç harfi: Kır…',
    ),
  ];

  _Phase _phase = _Phase.intro;
  bool _hasCompletedOnce = false;
  bool _isPaused = false;

  int _roundIndex = 0;
  int _totalScore = 0;
  int _elapsedSec = 0;
  Timer? _timer;
  final TextEditingController _controller = TextEditingController();
  bool _answered = false;
  int _lastPoints = 0;
  bool _timedOut = false;
  String? _feedback;
  // Öğrenci "İPUCU AL" butonuna basmadıkça ipucu ekranda görünmüyor —
  // sadece süresi geldiğinde buton aktif oluyor.
  int _hintsRequested = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  _AnagramQuestion get _question => _questions[_roundIndex];

  String _normalize(String s) {
    return s
        .trim()
        .replaceAll('i', 'İ')
        .replaceAll('ı', 'I')
        .toUpperCase()
        .replaceAll(RegExp(r'\s+'), '');
  }

  // Süreye göre KAÇ ipucu artık alınabilir durumda (kilidi açılmış) —
  // ekranda görünmesi için öğrencinin yine de butona basması gerekiyor.
  int get _hintsUnlocked =>
      (_elapsedSec ~/ _hintIntervalSec).clamp(0, _maxHints);

  void _requestHint() {
    if (_hintsRequested >= _hintsUnlocked) return;
    setState(() => _hintsRequested++);
  }

  int _pointsForElapsed(int sec) {
    if (sec < 30) return 100;
    if (sec < 60) return 90;
    if (sec < 90) return 80;
    return 70;
  }

  void _startGame() {
    setState(() {
      _phase = _Phase.playing;
      _roundIndex = 0;
      _totalScore = 0;
    });
    _startRound();
  }

  void _startRound() {
    _timer?.cancel();
    setState(() {
      _elapsedSec = 0;
      _answered = false;
      _timedOut = false;
      _feedback = null;
      _lastPoints = 0;
      _hintsRequested = 0;
      _controller.clear();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSec++);
      if (_elapsedSec >= _timeoutSec) _timeoutRound();
    });
  }

  void _pauseGame() {
    _timer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resumeGame() {
    setState(() => _isPaused = false);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSec++);
      if (_elapsedSec >= _timeoutSec) _timeoutRound();
    });
  }

  void _submit() {
    if (_answered) return;
    final input = _normalize(_controller.text);
    if (input.isEmpty) return;
    if (input == _question.answer) {
      _timer?.cancel();
      final points = _pointsForElapsed(_elapsedSec);
      _totalScore += points;
      SoundManager.playCorrect();
      setState(() {
        _answered = true;
        _lastPoints = points;
      });
      Future.delayed(const Duration(milliseconds: 1600), _nextRoundOrFinish);
    } else {
      SoundManager.playGentleTap();
      setState(() => _feedback = 'Yanlış, tekrar dene!');
    }
  }

  void _timeoutRound() {
    _timer?.cancel();
    SoundManager.playGentleTap();
    setState(() {
      _answered = true;
      _timedOut = true;
      _lastPoints = 0;
    });
    Future.delayed(const Duration(milliseconds: 2200), _nextRoundOrFinish);
  }

  void _nextRoundOrFinish() {
    if (!mounted) return;
    if (_roundIndex < _questions.length - 1) {
      setState(() => _roundIndex++);
      _startRound();
    } else {
      _finishAll();
    }
  }

  void _finishAll() {
    _timer?.cancel();
    _hasCompletedOnce = true;

    final maxScore = _questions.length * 100;
    final percent = ((_totalScore / maxScore) * 100).round();
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Kelimelerle Saklambaç Oynuyorum',
      result: '$_totalScore puan (%$percent)',
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
              'Toplam puan: $_totalScore / $maxScore (%$percent)',
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
        appBar: AppBar(title: const Text('🙈 Kelimelerle Saklambaç Oynuyorum')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _phase == _Phase.intro
                    ? _buildIntro()
                    : _buildRound(key: ValueKey('round-$_roundIndex')),
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
                    'Etkinlik 9 · Kelimelerle Saklambaç Oynuyorum',
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
                      child: Text('🙈', style: TextStyle(fontSize: 64)),
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
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: _color,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Sana verilen tüm harfleri kullanarak yeni bir kelime bul! '
                                  'Bulduğun kelime ek almamış olmalı. İlk 30 saniyede ipucu '
                                  'yok — 100 puan! Cevap gelmezse 30 saniyede bir yeni bir '
                                  'ipucu açılır (en fazla 3 tane), her ipucundan sonra puan '
                                  'biraz azalır (90 → 80 → 70). İpucu açık olduğunda "İPUCU '
                                  'AL" butonuna basarak görebilirsin — sıradaki ipucuya 10 '
                                  'saniyeden az kalınca geri sayım da gösterilir.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Örnek: KALEM = EMLAK',
                            style: TextStyle(
                              fontSize: 13,
                              color: _color,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
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

  // İpucu butonu HER ZAMAN görünür (bulunması kolay olsun diye): kilidi
  // açılmış ama henüz istenmemiş bir ipucu varsa aktif "İPUCU AL" olarak
  // görünür; kilidi henüz açılmadıysa gri/pasif halde kalan süreyi
  // gösterir; tüm ipuçları alındıysa gizlenir.
  Widget _hintButton() {
    if (_hintsRequested >= _maxHints) return const SizedBox(height: 36);
    final pending = _hintsUnlocked > _hintsRequested;
    if (pending) {
      return SizedBox(
        height: 36,
        child: OutlinedButton.icon(
          onPressed: _requestHint,
          icon: const Icon(Icons.lightbulb_outline, size: 16),
          label: const Text(
            'İPUCU AL',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.amber.shade800,
            side: BorderSide(color: Colors.amber.shade400),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
        ),
      );
    }
    final nextThreshold = (_hintsUnlocked + 1) * _hintIntervalSec;
    final remaining = (nextThreshold - _elapsedSec).clamp(0, _hintIntervalSec);
    return SizedBox(
      height: 36,
      child: OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.lock_clock_outlined, size: 16),
        label: Text(
          'İPUCU ($remaining sn)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        style: OutlinedButton.styleFrom(
          disabledForegroundColor: Colors.grey.shade500,
          side: BorderSide(color: Colors.grey.shade300),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }

  Widget _buildRound({required Key key}) {
    final q = _question;
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
                  'Soru ${_roundIndex + 1}/${_questions.length}',
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
                    'Puan: $_totalScore',
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
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < _hintsRequested; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Text(
                            '💡 ${[q.hint1, q.hint2, q.hint3][i]}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (!_answered) _hintButton(),
                    const SizedBox(height: 12),
                    Text(
                      q.scrambled,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _controller,
                        enabled: !_answered,
                        textAlign: TextAlign.center,
                        textCapitalization: TextCapitalization.characters,
                        onSubmitted: (_) => _submit(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Cevabını yaz…',
                          filled: true,
                          fillColor: _color.withValues(alpha: 0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: _color.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!_answered)
                      SizedBox(
                        width: 260,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _color,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'GÖNDER',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    if (_feedback != null && !_answered)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _feedback!,
                          style: const TextStyle(
                            color: Color(0xFFE11D48),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (_answered)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _timedOut
                              ? '⏰ Süre doldu! Doğrusu: ${q.answer}'
                              : '✅ Doğru! +$_lastPoints puan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _timedOut
                                ? const Color(0xFFE11D48)
                                : const Color(0xFF16A34A),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

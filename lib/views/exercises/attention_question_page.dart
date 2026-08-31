import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';

enum _Phase { intro, playing }

class _AttentionQuestion {
  final String baseWord;
  final List<String> options;
  final int correctIndex;
  // true: "... harfleriyle YAZILABİLECEK kelime hangisidir?"
  // false: "... harfleriyle hangi kelime YAZILAMAZ?"
  final bool asksCanWrite;
  const _AttentionQuestion({
    required this.baseWord,
    required this.options,
    required this.correctIndex,
    required this.asksCanWrite,
  });
}

/// Klasör 2'nin altıncı etkinliği: "Dikkat Sorusu". Öğretmenin verdiği 3
/// harf-karıştırma (anagram) sorusu: bir kelimenin harfleriyle hangi
/// seçeneğin yazılabildiğini (ya da SALİM örneğinde yazılAMADIĞINI) bulmak.
/// Yanlış cevapta ışıklı+sesli uyarı, doğru cevapta hıza göre puan var.
class AttentionQuestionPage extends StatefulWidget {
  const AttentionQuestionPage({super.key});

  @override
  State<AttentionQuestionPage> createState() => _AttentionQuestionPageState();
}

class _AttentionQuestionPageState extends State<AttentionQuestionPage> {
  static const Color _color = Color(0xFF16A34A);
  static const List<String> _optionLabels = ['A', 'B', 'C', 'D'];
  static const List<int> _roundTimeMsBySpeed = [12000, 8000, 5000];
  static const List<String> _speedLabels = ['Yavaş', 'Orta', 'Hızlı'];

  static const List<_AttentionQuestion> _questions = [
    _AttentionQuestion(
      baseWord: 'DİKEN',
      options: ['Dilek', 'Direk', 'Kendi', 'Diren'],
      correctIndex: 2,
      asksCanWrite: true,
    ),
    _AttentionQuestion(
      baseWord: 'MİRZA',
      options: ['Zamir', 'Tamir', 'Miras', 'Zalim'],
      correctIndex: 0,
      asksCanWrite: true,
    ),
    _AttentionQuestion(
      baseWord: 'SALİM',
      options: ['İslam', 'Misal', 'Milas', 'Selim'],
      correctIndex: 3,
      asksCanWrite: false,
    ),
  ];

  _Phase _phase = _Phase.intro;
  bool _hasCompletedOnce = false;
  bool _isPaused = false;
  int _speedLevel = 1;

  int _roundIndex = 0;
  int _totalScore = 0;
  int _correctCount = 0;
  int _elapsedMs = 0;
  Timer? _roundTimer;
  Timer? _tickTimer;
  int? _selectedIndex;
  bool _answered = false;
  bool _flashWrong = false;
  Timer? _flashTimer;

  @override
  void dispose() {
    _roundTimer?.cancel();
    _tickTimer?.cancel();
    _flashTimer?.cancel();
    super.dispose();
  }

  _AttentionQuestion get _question => _questions[_roundIndex];

  void _startGame() {
    setState(() {
      _phase = _Phase.playing;
      _roundIndex = 0;
      _totalScore = 0;
      _correctCount = 0;
    });
    _startRound();
  }

  void _startRound() {
    _roundTimer?.cancel();
    _tickTimer?.cancel();
    _flashTimer?.cancel();
    setState(() {
      _elapsedMs = 0;
      _selectedIndex = null;
      _answered = false;
      _flashWrong = false;
    });
    final totalMs = _roundTimeMsBySpeed[_speedLevel];
    _tickTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) return;
      setState(() => _elapsedMs = (_elapsedMs + 80).clamp(0, totalMs));
    });
    _roundTimer = Timer(Duration(milliseconds: totalMs), () {
      if (!mounted) return;
      _answer(null);
    });
  }

  void _pauseGame() {
    _roundTimer?.cancel();
    _tickTimer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resumeGame() {
    final totalMs = _roundTimeMsBySpeed[_speedLevel];
    final remainingMs = (totalMs - _elapsedMs).clamp(0, totalMs);
    setState(() => _isPaused = false);
    _tickTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) return;
      setState(() => _elapsedMs = (_elapsedMs + 80).clamp(0, totalMs));
    });
    _roundTimer = Timer(Duration(milliseconds: remainingMs), () {
      if (!mounted) return;
      _answer(null);
    });
  }

  void _answer(int? index) {
    if (_answered) return;
    _roundTimer?.cancel();
    _tickTimer?.cancel();
    final totalMs = _roundTimeMsBySpeed[_speedLevel];
    final isCorrect = index != null && index == _question.correctIndex;
    int points = 0;
    setState(() {
      _selectedIndex = index;
      _answered = true;
    });
    if (isCorrect) {
      final remainingFraction = (1 - (_elapsedMs / totalMs)).clamp(0.0, 1.0);
      points = (100 * remainingFraction).round().clamp(20, 100);
      _totalScore += points;
      _correctCount++;
      SoundManager.playCorrect();
    } else {
      // Yanlış cevapta ışıklı (yanıp sönen) ve sesli uyarı.
      SoundManager.playGentleTap();
      _flashWarning();
    }
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      if (_roundIndex < _questions.length - 1) {
        setState(() => _roundIndex++);
        _startRound();
      } else {
        _finishAll();
      }
    });
  }

  void _flashWarning() {
    int ticks = 0;
    _flashTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _flashWrong = !_flashWrong);
      ticks++;
      if (ticks >= 6) {
        timer.cancel();
        setState(() => _flashWrong = false);
      }
    });
  }

  void _finishAll() {
    _roundTimer?.cancel();
    _tickTimer?.cancel();
    _flashTimer?.cancel();
    _hasCompletedOnce = true;

    final percent = ((_correctCount / _questions.length) * 100).round();
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Dikkat Sorusu',
      result: '$_correctCount/${_questions.length} doğru · $_totalScore puan',
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
            Text('Doğru: $_correctCount / ${_questions.length} (%$percent)'),
            const SizedBox(height: 4),
            Text(
              'Toplam puan: $_totalScore',
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
        appBar: AppBar(title: const Text('🧠 Dikkat Sorusu')),
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
                    'Etkinlik 6 · Dikkat Sorusu',
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
                      child: Text('🧠', style: TextStyle(fontSize: 88)),
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
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: _color,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sana bir kelime verilecek, altında 4 benzer kelime çıkacak. '
                              'Hangisinin aynı harflerle yazılabildiğini (bazen '
                              'yazılAMADIĞINI) bul! Ne kadar hızlı bulursan o kadar çok '
                              'dikkat puanı kazanırsın — yanlış seçersen ekran '
                              'yanıp sönerek uyarır.',
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
    final totalMs = _roundTimeMsBySpeed[_speedLevel];
    final remainingFraction = (1 - (_elapsedMs / totalMs)).clamp(0.0, 1.0);
    final q = _question;
    final questionText = q.asksCanWrite
        ? '"${q.baseWord}" harfleriyle yazılabilecek kelime hangisidir?'
        : '"${q.baseWord}" harfleriyle hangi kelime yazılamaz?';
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
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '⏱ ${(remainingFraction * totalMs / 1000).ceil()} sn',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (!_answered)
                    buildPauseButton(color: _color, onPressed: _pauseGame),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
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
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: _flashWrong
                            ? const Color(0xFFFCA5A5)
                            : _color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _flashWrong
                              ? const Color(0xFFDC2626)
                              : _color.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        questionText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        for (int i = 0; i < q.options.length; i++)
                          _optionButton(i),
                      ],
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

  Widget _optionButton(int index) {
    final q = _question;
    final isSelected = _selectedIndex == index;
    final isCorrectOption = index == q.correctIndex;
    Color bg = _color.withValues(alpha: 0.08);
    Color border = _color.withValues(alpha: 0.3);
    Color fg = _color;
    if (_answered) {
      if (isCorrectOption) {
        bg = const Color(0xFF16A34A).withValues(alpha: 0.14);
        border = const Color(0xFF16A34A);
        fg = const Color(0xFF16A34A);
      } else if (isSelected) {
        bg = const Color(0xFFE11D48).withValues(alpha: 0.14);
        border = const Color(0xFFE11D48);
        fg = const Color(0xFFE11D48);
      }
    }
    return SizedBox(
      width: 150,
      height: 52,
      child: OutlinedButton(
        onPressed: _answered ? null : () => _answer(index),
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          side: BorderSide(color: border, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          '${_optionLabels[index]}) ${q.options[index]}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: fg,
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';

enum _Phase { intro, playing, bolum2Intro, bolum2 }

class _ScrambledPuzzle {
  final List<String> letters; // 3x3 karışık harfler
  final String answer;
  final String clue;
  const _ScrambledPuzzle(this.letters, this.answer, this.clue);
}

// Öğrenci yazdığı cevabı büyük/küçük harf ve Türkçe İ/I farkına takılmadan
// karşılaştırabilsin diye önce Türkçe'ye özgü harfler normalize ediliyor.
String _normalizeSc(String s) {
  return s.trim().replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
}

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

/// Klasör 4'ün üçüncü etkinliği: attention_question_page.dart'ın (Klasör
/// 2 · Etkinlik 6) aynı mantığı, yeni kelimelerle: bir kelimenin
/// harfleriyle (harflerin TAMAMI değil, sadece o kelimede BULUNAN
/// harflerden, her harf en fazla o kelimedeki kadar) hangi seçeneğin
/// yazılabildiğini (ya da MERAK örneğinde hangisinin yazılAMADIĞINI)
/// bulmak. Yanlış cevapta ışıklı+sesli uyarı, doğru cevapta hıza göre puan.
class AttentionQuestion2Page extends StatefulWidget {
  const AttentionQuestion2Page({super.key});

  @override
  State<AttentionQuestion2Page> createState() => _AttentionQuestion2PageState();
}

class _AttentionQuestion2PageState extends State<AttentionQuestion2Page> {
  static const Color _color = Color(0xFF16A34A);
  static const List<String> _optionLabels = ['A', 'B', 'C', 'D'];
  static const List<int> _roundTimeMsBySpeed = [12000, 8000, 5000];
  static const List<String> _speedLabels = ['Yavaş', 'Orta', 'Hızlı'];

  static const List<_AttentionQuestion> _questions = [
    _AttentionQuestion(
      baseWord: 'MERAK',
      options: ['Kar', 'Kral', 'Kare', 'Ark'],
      correctIndex: 1,
      asksCanWrite: false,
    ),
    _AttentionQuestion(
      baseWord: 'SAMET',
      options: ['Temas', 'Satış', 'Sepet', 'Tabak'],
      correctIndex: 0,
      asksCanWrite: true,
    ),
    _AttentionQuestion(
      baseWord: 'HALİS',
      options: ['Hisar', 'Silah', 'Hilal', 'Alış'],
      correctIndex: 1,
      asksCanWrite: true,
    ),
    _AttentionQuestion(
      baseWord: 'RESİM',
      options: ['Mısır', 'Sirke', 'Reçel', 'Resmi'],
      correctIndex: 3,
      asksCanWrite: true,
    ),
    _AttentionQuestion(
      baseWord: 'İHTAR',
      options: ['Hatır', 'Rahat', 'Tarih', 'Tıraş'],
      correctIndex: 2,
      asksCanWrite: true,
    ),
  ];

  // 2. Bölüm: "Karışık Harfler" (scrambled_letters_page.dart ile aynı
  // mantık) — 3x3 kutudaki 9 harften kelimeyi bulmak. Harfler satır1
  // soldan sağa, satır2 sağdan sola, satır3 soldan sağa "yılan" deseniyle
  // yerleştirildi, böylece kelimenin harf sırası ızgarada hep bitişik
  // kutucuklardan geçiyor.
  static const List<_ScrambledPuzzle> _scrambledPuzzles = [
    _ScrambledPuzzle(
      ['C', 'U', 'M', 'T', 'R', 'A', 'E', 'S', 'İ'],
      'cumartesi',
      'Haftanın, pazardan önce gelen ve okulun tatil olduğu günü.',
    ),
    _ScrambledPuzzle(
      ['B', 'U', 'Z', 'L', 'O', 'D', 'A', 'B', 'I'],
      'buzdolabı',
      'Yiyecekleri soğuk tutup bozulmasını önleyen ev eşyası.',
    ),
    _ScrambledPuzzle(
      ['B', 'A', 'T', 'N', 'A', 'T', 'İ', 'Y', 'E'],
      'battaniye',
      'Üşüyünce üstümüze örttüğümüz kalın, sıcak tutan örtü.',
    ),
    _ScrambledPuzzle(
      ['M', 'A', 'N', 'L', 'A', 'D', 'İ', 'N', 'A'],
      'mandalina',
      'Kışın yediğimiz, kolay soyulan küçük ve tatlı turunçgil meyvesi.',
    ),
    _ScrambledPuzzle(
      ['K', 'I', 'R', 'N', 'A', 'L', 'G', 'I', 'Ç'],
      'kırlangıç',
      'Baharda gelip evlerin saçak altına yuva yapan göçmen küçük kuş.',
    ),
    _ScrambledPuzzle(
      ['M', 'U', 'H', 'L', 'L', 'A', 'E', 'B', 'İ'],
      'muhallebi',
      'Sütle ve pirinç unuyla yapılan, kaşıkla yenen sütlü bir tatlı.',
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

  // 2. Bölüm: Karışık Harfler.
  static const int _scBasePoints = 50;
  static const int _scHintPenalty = 10;
  static const int _scMaxHints = 3;
  static const int _scHintIntervalSec = 30;

  int _scPuzzleIndex = 0;
  int _scTotalScore = 0;
  int _scCorrectCount = 0;
  int _scAttemptCount = 0;
  int _scHintsUsed = 0;
  int _scElapsedSec = 0;
  Timer? _scElapsedTimer;
  Timer? _scHintTimer;
  bool _scAnswered = false;
  bool _scCorrect = false;
  bool _scLastWrong = false;
  final TextEditingController _scController = TextEditingController();
  final FocusNode _scFocusNode = FocusNode();

  @override
  void dispose() {
    _roundTimer?.cancel();
    _tickTimer?.cancel();
    _flashTimer?.cancel();
    _scElapsedTimer?.cancel();
    _scHintTimer?.cancel();
    _scController.dispose();
    _scFocusNode.dispose();
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
        setState(() => _phase = _Phase.bolum2Intro);
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

  void _startBolum2() {
    setState(() {
      _phase = _Phase.bolum2;
      _scPuzzleIndex = 0;
      _scTotalScore = 0;
      _scCorrectCount = 0;
      _scResetPuzzleState();
    });
    _scStartTimers();
    _scFocusNode.requestFocus();
  }

  void _scResetPuzzleState() {
    _scAttemptCount = 0;
    _scHintsUsed = 0;
    _scAnswered = false;
    _scCorrect = false;
    _scLastWrong = false;
    _scController.clear();
  }

  void _scStartTimers() {
    _scElapsedTimer?.cancel();
    _scHintTimer?.cancel();
    setState(() => _scElapsedSec = 0);
    _scElapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _scElapsedSec++);
    });
    _scHintTimer = Timer.periodic(const Duration(seconds: _scHintIntervalSec), (
      _,
    ) {
      if (!mounted) return;
      if (!_scAnswered && _scHintsUsed < _scMaxHints) _scUseHint();
    });
  }

  void _scStopTimers() {
    _scElapsedTimer?.cancel();
    _scHintTimer?.cancel();
  }

  void _scUseHint() {
    if (_scAnswered || _scHintsUsed >= _scMaxHints) return;
    setState(() => _scHintsUsed++);
    SoundManager.playGentleTap();
  }

  void _scSubmitAnswer() {
    if (_scAnswered) return;
    final input = _scController.text;
    if (input.trim().isEmpty) return;
    final puzzle = _scrambledPuzzles[_scPuzzleIndex];
    if (_normalizeSc(input) == _normalizeSc(puzzle.answer)) {
      _scHandleCorrect();
    } else {
      _scHandleWrong();
    }
  }

  void _scHandleCorrect() {
    SoundManager.playCorrect();
    _scStopTimers();
    final points = _scBasePoints - _scHintsUsed * _scHintPenalty;
    setState(() {
      _scAnswered = true;
      _scCorrect = true;
      _scLastWrong = false;
      _scCorrectCount++;
      _scTotalScore += points;
    });
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      _scNextPuzzle();
    });
  }

  void _scHandleWrong() {
    _scAttemptCount++;
    if (_scAttemptCount >= 2) {
      SoundManager.playGentleTap();
      _scStopTimers();
      setState(() {
        _scAnswered = true;
        _scCorrect = false;
      });
    } else {
      SoundManager.playGentleTap();
      setState(() => _scLastWrong = true);
    }
  }

  void _scNextPuzzle() {
    if (_scPuzzleIndex < _scrambledPuzzles.length - 1) {
      setState(() {
        _scPuzzleIndex++;
        _scResetPuzzleState();
      });
      _scFocusNode.requestFocus();
      _scStartTimers();
    } else {
      _finishAll();
    }
  }

  void _finishAll() {
    _roundTimer?.cancel();
    _tickTimer?.cancel();
    _flashTimer?.cancel();
    _scStopTimers();
    _hasCompletedOnce = true;

    final totalCorrect = _correctCount + _scCorrectCount;
    final totalQuestions = _questions.length + _scrambledPuzzles.length;
    final grandTotalScore = _totalScore + _scTotalScore;
    final percent = ((totalCorrect / totalQuestions) * 100).round();
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Dikkat Sorusu (Anagram)',
      result: '$totalCorrect/$totalQuestions doğru · $grandTotalScore puan',
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
            Text('Doğru: $totalCorrect / $totalQuestions (%$percent)'),
            const SizedBox(height: 4),
            Text(
              'Toplam puan: $grandTotalScore',
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
                child: switch (_phase) {
                  _Phase.intro => _buildIntro(),
                  _Phase.playing => _buildRound(
                    key: ValueKey('round-$_roundIndex'),
                  ),
                  _Phase.bolum2Intro => _buildBolum2Intro(),
                  _Phase.bolum2 => _buildBolum2(
                    key: ValueKey('sc-$_scPuzzleIndex'),
                  ),
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
                    'Etkinlik 3 · Dikkat Sorusu',
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
                              'Sana bir kelime verilecek, altında 4 seçenek çıkacak. '
                              'Hangisinin o kelimenin harfleriyle yazılabildiğini '
                              '(bazen yazılAMADIĞINI) bul! Ne kadar hızlı bulursan o '
                              'kadar çok dikkat puanı kazanırsın — yanlış seçersen '
                              'ekran yanıp sönerek uyarır.',
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

  Widget _buildBolum2Intro() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: Text('🔤', style: TextStyle(fontSize: 72))),
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
                    '1. Bölümü bitirdik! Şimdi 2. Bölüm: Karışık Harfler. '
                    'Her kutuda 3x3 karışık dizilmiş 9 harf var — bu '
                    'harflerle hangi kelimenin yazıldığını bulup yazacaksın. '
                    'Takılırsan ipucu alabilirsin!',
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
                    onPressed: _startBolum2,
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

  Widget _buildBolum2({required Key key}) {
    final puzzle = _scrambledPuzzles[_scPuzzleIndex];
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
                  '2. Bölüm · ${_scPuzzleIndex + 1}/${_scrambledPuzzles.length}',
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
                    'Puan: $_scTotalScore',
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
                      '⏱ ${_scElapsedSec}sn',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final side = constraints.maxWidth.clamp(0.0, 300.0);
                      return SizedBox(
                        width: side,
                        height: side,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: puzzle.letters.length,
                          itemBuilder: (context, i) {
                            return Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _color.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _color.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                puzzle.letters[i],
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: _color,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_scHintsUsed >= 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        '💡 ${puzzle.clue}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ),
                  if (_scHintsUsed >= 2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'İlk harf: ${puzzle.answer[0].toUpperCase()}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ),
                  TextField(
                    controller: _scController,
                    focusNode: _scFocusNode,
                    enabled: !_scAnswered,
                    textAlign: TextAlign.center,
                    onSubmitted: (_) => _scSubmitAnswer(),
                    decoration: InputDecoration(
                      hintText: 'Kelimeyi yaz...',
                      filled: true,
                      fillColor: _scLastWrong
                          ? const Color(0xFFFCA5A5)
                          : _color.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (_scAnswered) ...[
                    const SizedBox(height: 12),
                    Text(
                      _scCorrect
                          ? '🎉 Harikasın, doğru!'
                          : '📖 Doğrusu: ${puzzle.answer}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _scCorrect
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFE11D48),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              (_scAnswered || _scHintsUsed >= _scMaxHints)
                              ? null
                              : _scUseHint,
                          icon: const Icon(Icons.lightbulb_outline, size: 18),
                          label: Text('İpucu ($_scHintsUsed/$_scMaxHints)'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.amber.shade800,
                            side: BorderSide(color: Colors.amber.shade400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _scAnswered ? null : _scSubmitAnswer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _color,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'CEVAPLA',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

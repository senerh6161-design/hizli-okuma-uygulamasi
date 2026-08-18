import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';

class _AttentionQuestion {
  final String prompt;
  final List<String> options;
  final int correctIndex;
  const _AttentionQuestion(this.prompt, this.options, this.correctIndex);
}

/// Mobil uygulama dokümanındaki "Dikkat Sorusu" etkinliği: verilen kelimenin
/// harfleriyle yazılabilecek/yazılamayacak kelimeyi bulma bulmacası. Yanlış
/// seçimde ışıklı+sesli uyarı verilir, doğruyu ne kadar hızlı bulursa o kadar
/// çok dikkat puanı kazanır.
class AttentionQuestionsPage extends StatefulWidget {
  const AttentionQuestionsPage({super.key});

  @override
  State<AttentionQuestionsPage> createState() => _AttentionQuestionsPageState();
}

class _AttentionQuestionsPageState extends State<AttentionQuestionsPage> {
  static const List<_AttentionQuestion> _questions = [
    _AttentionQuestion(
      '"İNSAN" harfleriyle yazılabilecek kelime hangisidir?',
      ['Nişan', 'İnsaf', 'Sinan', 'Lisan'],
      2,
    ),
    _AttentionQuestion(
      '"KATİP" harfleriyle hangi kelime yazılamaz?',
      ['Kitap', 'Patik', 'Takip', 'Rakip'],
      3,
    ),
    _AttentionQuestion(
      '"KALEM" harfleriyle hangi kelime yazılamaz?',
      ['Kelime', 'Emlak', 'Amel', 'Mal'],
      0,
    ),
    _AttentionQuestion(
      '"DENİZ" harfleriyle hangi kelime yazılamaz?',
      ['Din', 'Zindan', 'İz', 'Dize'],
      1,
    ),
    _AttentionQuestion(
      '"ORMAN" harfleriyle hangi kelime yazılamaz?',
      ['Mor', 'Ora', 'Manto', 'Nar'],
      2,
    ),
    _AttentionQuestion(
      '"TAKIM" harfleriyle hangi kelime yazılamaz?',
      ['Kitap', 'Kat', 'Tak', 'Mat'],
      0,
    ),
    _AttentionQuestion(
      '"BALIK" harfleriyle hangi kelime yazılamaz?',
      ['Bal', 'Balkon', 'Kal', 'Alık'],
      1,
    ),
    _AttentionQuestion(
      '"PENCERE" harfleriyle hangi kelime yazılamaz?',
      ['Ne', 'Cep', 'Perde', 'Nere'],
      2,
    ),
    _AttentionQuestion(
      '"ANAHTAR" harfleriyle hangi kelime yazılamaz?',
      ['Hantal', 'Nar', 'Tan', 'Hata'],
      0,
    ),
    _AttentionQuestion(
      '"SANDALYE" harfleriyle hangi kelime yazılamaz?',
      ['Ada', 'Selam', 'Yalan', 'Dans'],
      1,
    ),
  ];

  bool _showIntro = true;
  bool _hasCompletedOnce = false;
  int _index = 0;
  int _totalScore = 0;
  int? _wrongIndex;
  int? _correctFlashIndex;
  int _wrongAttempts = 0;

  Stopwatch _stopwatch = Stopwatch();
  Timer? _uiTimer;

  void _startQuestions() {
    setState(() {
      _showIntro = false;
      _stopwatch = Stopwatch()..start();
    });
    _uiTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  void _selectOption(int optionIndex) {
    final q = _questions[_index];
    if (optionIndex == q.correctIndex) {
      SoundManager.playCorrect();
      final seconds = _stopwatch.elapsedMilliseconds / 1000;
      final points = (100 - (seconds * 8) - (_wrongAttempts * 15)).round().clamp(10, 100);
      _totalScore += points;
      setState(() => _correctFlashIndex = optionIndex);

      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        if (_index < _questions.length - 1) {
          setState(() {
            _index++;
            _wrongAttempts = 0;
            _correctFlashIndex = null;
            _stopwatch = Stopwatch()..start();
          });
        } else {
          _finish();
        }
      });
    } else {
      SoundManager.playGentleTap();
      setState(() {
        _wrongIndex = optionIndex;
        _wrongAttempts++;
      });
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _wrongIndex = null);
      });
    }
  }

  void _finish() {
    _hasCompletedOnce = true;
    _uiTimer?.cancel();
    final maxScore = _questions.length * 100;
    final percent = (_totalScore / maxScore * 100).round();
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Dikkat Soruları',
      result: '$_totalScore/$maxScore puan',
    );
    if (unlocked.isNotEmpty) SoundManager.playAchievement();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🎉 Tüm Sorular Tamamlandı!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Toplam Puan: $_totalScore / $maxScore (%$percent)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                _index = 0;
                _totalScore = 0;
                _wrongAttempts = 0;
                _stopwatch = Stopwatch()..start();
              });
              _uiTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
                if (mounted) setState(() {});
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
    return CompletionPopScope(
      isCompleted: () => _hasCompletedOnce,
      child: Scaffold(
      appBar: AppBar(title: const Text('❓ Dikkat Soruları')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _showIntro ? _buildIntro() : _buildQuestion(),
      ),
      ),
    );
  }

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nasıl Oynanır?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(
          'Sana bir kelimenin harfleri verilecek. 4 seçenekten hangisinin bu '
          'harflerle yazılabileceğini (ya da yazılamayacağını) bulman gerekiyor. '
          'Ne kadar hızlı ve doğru bulursan o kadar çok dikkat puanı kazanırsın!',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'ÖRNEK',
            style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '"ELMAS" harfleriyle hangi kelime yazılamaz?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.4,
          children: [
            _exampleOption('A) Selma', false),
            _exampleOption('B) Selam', false),
            _exampleOption('C) Emsal', false),
            _exampleOption('D) Selim', true),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '"Selim" yazılamaz çünkü içindeki İ harfi "ELMAS" kelimesinde yok. '
          'Diğer üçü (Selma, Selam, Emsal) sadece "ELMAS"ın harflerini kullanıyor.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _startQuestions,
            icon: const Icon(Icons.play_arrow),
            label: const Text('ANLADIM, BAŞLA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _exampleOption(String label, bool isCorrect) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.shade500 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCorrect ? Colors.green.shade500 : Colors.grey.shade300, width: 2),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: isCorrect ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    final q = _questions[_index];
    final elapsed = _stopwatch.elapsedMilliseconds / 1000;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Soru ${_index + 1}/${_questions.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                  ),
                ),
                Text(
                  '${elapsed.toStringAsFixed(1)} sn',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              q.prompt,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              'Ne kadar hızlı bulursan o kadar çok dikkat puanı kazanırsın!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.builder(
                itemCount: q.options.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 2,
                ),
                itemBuilder: (context, index) {
                  final isWrong = _wrongIndex == index;
                  final isCorrectFlash = _correctFlashIndex == index;
                  Color bg = Colors.white;
                  Color textColor = Colors.black87;
                  if (isWrong) {
                    bg = Colors.red.shade400;
                    textColor = Colors.white;
                  } else if (isCorrectFlash) {
                    bg = Colors.green.shade500;
                    textColor = Colors.white;
                  }
                  return InkWell(
                    onTap: _correctFlashIndex != null ? null : () => _selectOption(index),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
                        ],
                      ),
                      child: Text(
                        '${String.fromCharCode(65 + index)}) ${q.options[index]}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/comprehension_data.dart';
import '../../models/progress_manager.dart';
import '../../models/achievement.dart';
import '../../models/settings_manager.dart';
import '../../models/sound_manager.dart';
import '../../models/audio_manager.dart';
import '../../widgets/confetti_overlay.dart';
import '../../widgets/reading_theme_picker.dart';
import '../../widgets/word_definition_sheet.dart';

class ComprehensionPage extends StatefulWidget {
  // Belirli bir metinle açılmak istersen (ör. Hızlı Okuma'da az önce
  // gerçek metin modunda okuduğun paragraf) doldur. Boş bırakılırsa
  // havuzdan rastgele bir metin seçilir.
  final ReadingPassage? passage;

  // true ise "1. AŞAMA: METNİ OKUYUN" adımı atlanır ve doğrudan sorulara
  // geçilir — Hızlı Okuma'da metni zaten okumuş olan kullanıcı için.
  final bool skipReadingPhase;

  // Konu Seçimi ekranından gelen ilgi alanı (ör. 'uzay', 'spor'). Boşsa
  // tüm konulardan rastgele bir metin seçilir.
  final String? topicId;

  const ComprehensionPage({
    super.key,
    this.passage,
    this.skipReadingPhase = false,
    this.topicId,
  });

  @override
  State<ComprehensionPage> createState() => _ComprehensionPageState();
}

class _ComprehensionPageState extends State<ComprehensionPage> {
  final Random random = Random();

  late ReadingPassage currentPassage;
  String? selectedTopicId;
  String? _lastPassageId; // Art arda aynı metnin çıkmasını önlemek için
  bool isReadingPhase = true; // Önce okuma aşaması, sonra soru aşaması
  int questionIndex = 0;
  int score = 0;
  DateTime? _readingStartedAt;
  double? _lastWpm;
  int? _lastWordCount;
  // Sorular veride hep aynı sırada (çoğunlukla Doğru-Yanlış-Doğru) —
  // çocuk bu kalıbı fark edip okumadan cevaplayabiliyordu. Okuma bitip
  // sorulara geçilince KARIŞTIRILMIŞ bir kopya kullanılır.
  List<Map<String, dynamic>> _quizQuestions = [];

  // Sırayı karıştırmak yetmiyordu: her metnin havuzunda hep 2 Doğru + 1
  // Yanlış cümle vardı, bu yüzden çocuk sırayla "Doğru" deyip her seferinde
  // garanti 2/3 alabiliyordu. Bunu kırmak için her metnin 4 aday sorusu
  // (2 Doğru + 2 Yanlış) var; her denemede rastgele ya 2D+1Y ya da 1D+2Y
  // seçilir — hangi oranın çıkacağı da önceden tahmin edilemez.
  List<Map<String, dynamic>> _pickQuizQuestions(
    List<Map<String, dynamic>> pool,
  ) {
    final trueOnes = pool.where((q) => q['correct'] == 0).toList()
      ..shuffle(random);
    final falseOnes = pool.where((q) => q['correct'] == 1).toList()
      ..shuffle(random);
    final wantTwoTrue = random.nextBool();
    final picked = wantTwoTrue
        ? [...trueOnes.take(2), ...falseOnes.take(1)]
        : [...trueOnes.take(1), ...falseOnes.take(2)];
    return picked..shuffle(random);
  }

  @override
  void initState() {
    super.initState();
    selectedTopicId = widget.topicId;
    if (widget.passage != null) {
      currentPassage = widget.passage!;
      isReadingPhase = !widget.skipReadingPhase;
      questionIndex = 0;
      score = 0;
      _quizQuestions = _pickQuizQuestions(currentPassage.questions);
      if (isReadingPhase) {
        _readingStartedAt = DateTime.now();
        AudioManager.startAmbient();
      }
    } else {
      _loadRandomPassage();
    }
  }

  void _loadRandomPassage() {
    final pool = ComprehensionData.passagesForTopic(selectedTopicId);
    // Konuya (ya da tüm havuza) göre rastgele bir metin seçilir. Havuzda
    // birden fazla metin varsa, art arda AYNI metnin çıkmamasına çalışılır.
    ReadingPassage next = pool[random.nextInt(pool.length)];
    if (pool.length > 1) {
      int guard = 0;
      while (next.id == _lastPassageId && guard < 5) {
        next = pool[random.nextInt(pool.length)];
        guard++;
      }
    }
    _lastPassageId = next.id;
    setState(() {
      currentPassage = next;
      isReadingPhase = true;
      questionIndex = 0;
      score = 0;
      _quizQuestions = _pickQuizQuestions(next.questions);
      _readingStartedAt = DateTime.now();
      _lastWpm = null;
      _lastWordCount = null;
    });
    AudioManager.startAmbient();
  }

  @override
  void dispose() {
    AudioManager.stopAmbient();
    super.dispose();
  }

  void answer(int selectedIndex) {
    final isCorrect = selectedIndex == _quizQuestions[questionIndex]['correct'];
    if (isCorrect) {
      score++;
      SoundManager.playCorrect();
    } else {
      SoundManager.playGentleTap();
    }

    if (questionIndex < _quizQuestions.length - 1) {
      setState(() {
        questionIndex++;
      });
    } else {
      _finish();
    }
  }

  void _finish() {
    final totalQuestions = _quizQuestions.length;
    final scorePercent = ((score / totalQuestions) * 100).round();

    // Hızlı okuma temposu bu sonuca göre değişecek mi, önce/sonra çarpanını
    // karşılaştırarak anlıyoruz.
    final previousAdjustment = ProgressManager.speedAdjustment;
    final unlocked = ProgressManager.recordComprehensionResult(
      correct: score,
      total: totalQuestions,
    );
    final newAdjustment = ProgressManager.speedAdjustment;

    SoundManager.playSuccess();
    if (unlocked.isNotEmpty) {
      SoundManager.playAchievement();
    }
    if (scorePercent >= 90) showConfetti(context);

    final String feedbackMessage;
    final Color feedbackColor;
    if (newAdjustment > previousAdjustment) {
      feedbackMessage =
          '🚀 Harika anlama! Bir sonraki Hızlı Okuma turunda tempo biraz artacak.';
      feedbackColor = Colors.green;
    } else if (newAdjustment < previousAdjustment) {
      feedbackMessage =
          '🐢 Anlama biraz düştü, bir sonraki turda tempoyu yavaşlatıyoruz — önce anlamak önemli.';
      feedbackColor = Colors.orange;
    } else {
      feedbackMessage = '👍 Dengedesin, Hızlı Okuma temposu aynı kalıyor.';
      feedbackColor = Color(0xFF2563EB);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('📝 Test Sonucu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Metin: ${currentPassage.title}'),
            const SizedBox(height: 8),
            Text(
              '$totalQuestions sorudan $score tanesini doğru yaptınız.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Anlama Oranı: %$scorePercent',
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: feedbackColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                feedbackMessage,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: feedbackColor,
                ),
              ),
            ),
            if (_lastWpm != null && _lastWordCount != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 Karne',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _karneRow(
                      'Anlama Seviyesi',
                      _comprehensionLevel(scorePercent),
                    ),
                    _karneRow('Okuma Hızı', '${_lastWpm!.round()} kelime/dk'),
                    _karneRow('Okunan Kelime', '$_lastWordCount kelime'),
                  ],
                ),
              ),
            ],
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
              _loadRandomPassage(); // Yeni farklı metne geç (aynı konudan)
            },
            child: const Text('Yeni Metin & Test'),
          ),
        ],
      ),
    );
  }

  String _comprehensionLevel(int percent) {
    if (percent >= 90) return 'Mükemmel';
    if (percent >= 75) return 'Çok İyi';
    if (percent >= 60) return 'İyi';
    if (percent >= 40) return 'Orta';
    return 'Gelişmeli';
  }

  Widget _karneRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E40AF),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📝 Anlama Testi')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: isReadingPhase ? _buildReadingView() : _buildQuizView(),
      ),
    );
  }

  // 1. AŞAMA: PARAGRAF OKUMA EKRANI
  Widget _buildReadingView() {
    final topic = ComprehensionData.topicById(currentPassage.topic);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '1. AŞAMA: METNİ OKUYUN',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            if (topic != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${topic.emoji} ${topic.title}',
                  style: TextStyle(
                    color: Colors.amber.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const Spacer(),
            IconButton(
              onPressed: () =>
                  showReadingThemePicker(context, () => setState(() {})),
              icon: const Icon(Icons.palette_outlined),
              tooltip: 'Metin rengini değiştir',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          currentPassage.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              Icons.touch_app_rounded,
              size: 14,
              color: Colors.grey.shade500,
            ),
            const SizedBox(width: 4),
            Text(
              'Anlamını bilmediğin bir kelimeye dokun!',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: SettingsManager.readingBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: SettingsManager.readingBorderColor,
                      ),
                    ),
                    child: buildInteractiveText(
                      context,
                      currentPassage.content,
                      accentColor: SettingsManager.readingAccentColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: SettingsManager.readingAccentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              final wordCount = currentPassage.content
                  .trim()
                  .split(RegExp(r'\s+'))
                  .length;
              final rawElapsedSec = _readingStartedAt == null
                  ? 0.0
                  : DateTime.now()
                            .difference(_readingStartedAt!)
                            .inMilliseconds /
                        1000;
              // Çok hızlı geçilse bile (test amaçlı vs.) bir tahmin
              // gösterebilmek için süreyi mantıklı bir alt sınıra sabitliyoruz.
              final elapsedSec = rawElapsedSec < 5 ? 5.0 : rawElapsedSec;
              setState(() {
                isReadingPhase = false; // Sorulara geç
                _lastWordCount = wordCount;
                _lastWpm = wordCount / (elapsedSec / 60);
              });
              AudioManager.stopAmbient();
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text(
              'OKUDUM, TESTE GEÇ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  // 2. AŞAMA: SORU ÇÖZME EKRANI
  Widget _buildQuizView() {
    final currentQuestion = _quizQuestions[questionIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Soru ${questionIndex + 1}/${_quizQuestions.length}',
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              currentPassage.title,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          currentQuestion['question'],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 25),
        Expanded(
          child: ListView.builder(
            itemCount: currentQuestion['answers'].length,
            itemBuilder: (context, index) {
              final isTrueFalse = currentQuestion['answers'].length == 2;
              final label = isTrueFalse
                  ? (index == 0 ? 'D' : 'Y')
                  : String.fromCharCode(65 + index);
              final optionColor = isTrueFalse
                  ? (index == 0 ? Colors.green.shade700 : Colors.red.shade700)
                  : Colors.black87;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(18),
                    alignment: isTrueFalse
                        ? Alignment.center
                        : Alignment.centerLeft,
                    side: BorderSide(color: optionColor.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => answer(index),
                  child: Text(
                    '$label) ${currentQuestion['answers'][index]}',
                    style: TextStyle(
                      fontSize: isTrueFalse ? 18 : 15,
                      fontWeight: FontWeight.bold,
                      color: optionColor,
                    ),
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

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/comprehension_data.dart';
import '../../models/progress_manager.dart';

enum _TestPhase { intro, reading, quiz, result }

/// Makine hızında (RSVP) değil, kullanıcının KENDİ doğal temposunda ölçüm
/// yapar: gerçek bir metni normal hızında okur, "Bittim" der, süre ölçülür.
/// Ardından birkaç kontrol sorusuyla gerçekten anlayıp anlamadığı kontrol
/// edilir — hızlı ama anlamadan geçenlerin WPM'i otomatik aşağı çekilir.
/// Sonuç, ProgressManager.personalWpmBaseline olarak kaydedilir ve
/// LevelPage'deki tüm seviyeler bundan sonra bu gerçek sayıya göre
/// hesaplanır (okul yaş grubu ortalaması yerine).
class WpmTestPage extends StatefulWidget {
  const WpmTestPage({super.key});

  @override
  State<WpmTestPage> createState() => _WpmTestPageState();
}

class _WpmTestPageState extends State<WpmTestPage> {
  final Random _random = Random();

  late ReadingPassage _passage;
  _TestPhase _phase = _TestPhase.intro;

  DateTime? _readingStartedAt;
  Timer? _tickTimer;
  int _elapsedSeconds = 0;

  int _questionIndex = 0;
  int _score = 0;

  int _measuredWpm = 0;
  int _finalWpm = 0;
  int _comprehensionPercent = 0;

  @override
  void initState() {
    super.initState();
    _passage = ComprehensionData.passages[_random.nextInt(ComprehensionData.passages.length)];
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  void _startReading() {
    setState(() {
      _phase = _TestPhase.reading;
      _elapsedSeconds = 0;
      _readingStartedAt = DateTime.now();
    });
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
    });
  }

  void _finishReading() {
    _tickTimer?.cancel();
    final started = _readingStartedAt;
    final elapsedSecondsPrecise = started == null
        ? _elapsedSeconds.toDouble()
        : DateTime.now().difference(started).inMilliseconds / 1000.0;

    final wordCount = _passage.content
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    final minutes = max(elapsedSecondsPrecise / 60.0, 0.05); // sıfıra bölünmeyi engelle
    _measuredWpm = (wordCount / minutes).round().clamp(40, 1200).toInt();

    setState(() {
      _phase = _TestPhase.quiz;
      _questionIndex = 0;
      _score = 0;
    });
  }

  void _answer(int selectedIndex) {
    if (selectedIndex == _passage.questions[_questionIndex]['correct']) {
      _score++;
    }
    if (_questionIndex < _passage.questions.length - 1) {
      setState(() => _questionIndex++);
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    final total = _passage.questions.length;
    _comprehensionPercent = total == 0 ? 100 : ((_score / total) * 100).round();

    // Hızlı ama anlamadan okumuşsa ölçülen hıza tam güvenmiyoruz —
    // bu, "hızlı okuma" değil "kelime atlama" olabilir.
    int adjusted = _measuredWpm;
    if (_comprehensionPercent < 50) {
      adjusted = (_measuredWpm * 0.75).round();
    } else if (_comprehensionPercent < 70) {
      adjusted = (_measuredWpm * 0.9).round();
    }
    _finalWpm = adjusted.clamp(60, 900).toInt();

    ProgressManager.setPersonalWpmBaseline(_finalWpm);
    ProgressManager.addCompletedExercise(
      type: 'Seviye Ölçümü',
      result: '$_finalWpm WPM · %$_comprehensionPercent anlama',
    );

    setState(() => _phase = _TestPhase.result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🎯 Seviyeni Ölç')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: switch (_phase) {
            _TestPhase.intro => _buildIntro(),
            _TestPhase.reading => _buildReading(),
            _TestPhase.quiz => _buildQuiz(),
            _TestPhase.result => _buildResult(),
          },
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Column(
      children: [
        const Spacer(),
        const Icon(Icons.timer_outlined, size: 64, color: Color(0xFF4F46E5)),
        const SizedBox(height: 20),
        const Text(
          'Gerçek Okuma Hızını Ölçelim',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'Sana kısa bir metin göstereceğiz. Kendi normal hızında oku, bitirince '
          'altındaki butona bas. Ardından birkaç soru sorup gerçekten anlayıp '
          'anlamadığını kontrol edeceğiz. Sonuca göre Hızlı Okuma seviyelerini '
          'SENİN için ayarlayacağız.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.5),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _startReading,
            icon: const Icon(Icons.play_arrow),
            label: const Text(
              'TESTİ BAŞLAT',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _passage.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$_elapsedSeconds sn',
                style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                _passage.content,
                style: const TextStyle(fontSize: 17, height: 1.6, color: Colors.black87),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _finishReading,
            icon: const Icon(Icons.check),
            label: const Text(
              'OKUDUM, BİTTİM',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuiz() {
    final q = _passage.questions[_questionIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'KONTROL SORUSU ${_questionIndex + 1}/${_passage.questions.length}',
            style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          q['question'],
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 25),
        Expanded(
          child: ListView.builder(
            itemCount: q['answers'].length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(18),
                    alignment: Alignment.centerLeft,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _answer(index),
                  child: Text(
                    '${String.fromCharCode(65 + index)}) ${q['answers'][index]}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
        const SizedBox(height: 16),
        const Text(
          'Ölçüm Tamamlandı! 🎯',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                '$_finalWpm',
                style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
              ),
              const Text('Kişisel Taban Hızın (WPM)', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 10),
              Text(
                'Anlama: %$_comprehensionPercent',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Bundan sonra Hızlı Okuma seviyelerin bu hıza göre hesaplanacak — okul '
          'seviyesi ortalaması yerine SENİN gerçek hızın kullanılacak.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Devam Et', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}
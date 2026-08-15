import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';

/// Öğretmen dokümanındaki "Etkinlik 8'in kelime versiyonu": satır üstünde
/// akan kelimeler, bazı kelimeler (ör. "Hikaye") etkinlik sonuna kadar
/// belirli bir sayıda tekrarlanır. Akış 3 tur gösterildikten sonra öğrenciye
/// "X kelimesi kaç kez tekrarlandı?" diye 3 soru sorulur.
class WordFlowCountingPage extends StatefulWidget {
  const WordFlowCountingPage({super.key});

  @override
  State<WordFlowCountingPage> createState() => _WordFlowCountingPageState();
}

class _WordFlowCountingPageState extends State<WordFlowCountingPage> {
  // Hocanın verdiği kelime havuzu (23x7 tablo).
  static const List<String> _wordPool = [
    'Anlam', 'Kavram', 'Hikaye', 'Şiir', 'Efsane', 'Deyim', 'Betimleme',
    'Tema', 'Konu', 'Fiil', 'Çarpma', 'Oran', 'Olay', 'Biyografi',
    'Doğru', 'Bölme', 'Çember', 'Kesir', 'Paralel', 'Hacim', 'Molekül',
    'Üçgen', 'Kare', 'Atom', 'Karışım', 'Enerji', 'Kuvvet', 'Çözünürlük',
    'Elektrik', 'Devre', 'Çekim', 'İskelet', 'Kalıtım', 'Haber', 'Solunum',
    'Denge', 'Kültür', 'Devlet', 'Anayasa', 'İklim', 'Barış', 'Kimyasal',
    'Savaş', 'Türkiye', 'Kıta', 'Deniz', 'Kuzey', 'Şehir', 'Cumhuriyet',
    'Yaklaşım', 'Mera', 'Akarsu', 'Nehir', 'Kasaba', 'Tarih', 'Coğrafya',
    'Temsilci', 'Kapsam', 'Üslup', 'Eleştiri', 'Tezat', 'Abartı', 'Yarımada',
    'Özgün', 'Termal', 'Bağlam', 'İfade', 'Anlatım', 'Duygu', 'Yakınçağ',
    'Derinlik', 'Gözlem', 'İzlenim', 'Tartışma', 'İletişim', 'Söylem', 'Bağımsızlık',
    'Özdeyiş', 'Boylam', 'Önyargı', 'Mantık', 'Sonuç', 'Çelişki', 'Vatandaşlık',
    'Süreç', 'Aşama', 'Delta', 'Sezgi', 'Miras', 'Nitelik', 'Kurgulamak',
    'Nicelik', 'Belirgin', 'Direnç', 'Harita', 'Reklam', 'Sosyal', 'Farkındalık',
    'Tarım', 'Sulama', 'Toprak', 'Sağlık', 'Egzersiz', 'Sonuç', 'Karşılaştırma',
    'Medya', 'Gelişme', 'Deney', 'Öğrenci', 'Meclis', 'Kütle', 'Sorgulamak',
    'Spor', 'Müzik', 'Trafik', 'Protein', 'Kırsal', 'Mineral', 'Vurgulamak',
    'Giriş', 'Tekil', 'Soyut', 'Eklem', 'Tiyatro', 'Somut', 'Karakter',
    'İlim', 'Sinir', 'Sinema', 'Damar', 'Hasat', 'Atasözü', 'Sürükleyici',
    'Sanat', 'Tekrar', 'Tümleç', 'Zarf', 'Cümle', 'Kültür', 'Fotosentez',
    'Heyelan', 'Zamir', 'Görenek', 'Krater', 'Levha', 'Bütçe', 'Adaptasyon',
    'Vitamin', 'Çoğul', 'Sıfat', 'Uydu', 'Galaksi', 'Gelenek', 'Medeniyet',
    'Özne', 'Yıldız', 'Yankı', 'Frekans', 'Yansıma', 'Yüklem', 'Okyanus',
  ];

  // Hocanın örnekteki tekrar sayıları: "Galaksi 20, Öğrenci 12, şiir 15,
  // spor 9, yıldız 8, Türkiye 18..." + örnek olarak verilen "Hikaye" 15.
  static const Map<String, int> _targetCounts = {
    'Hikaye': 15,
    'Galaksi': 20,
    'Öğrenci': 12,
    'Şiir': 15,
    'Spor': 9,
    'Yıldız': 8,
    'Türkiye': 18,
  };

  static const int _totalPasses = 3;
  static const int _lineIntervalMs = 1500;
  static const int _wordsPerLine = 7;
  static const int _fillerWordCount = 22;

  final Random _random = Random();
  late List<List<String>> _lines;

  bool _isRunning = false;
  bool _showQuestions = false;
  int _pass = 0;
  int _lineIndex = 0;
  Timer? _timer;

  late List<MapEntry<String, int>> _questionTargets;
  int _questionIndex = 0;
  int _correctCount = 0;
  int? _selectedOption;
  bool? _lastWasCorrect;

  @override
  void initState() {
    super.initState();
    _prepareSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _prepareSession() {
    final bag = <String>[];
    _targetCounts.forEach((word, count) {
      bag.addAll(List.filled(count, word));
    });

    final fillerPool = _wordPool.where((w) => !_targetCounts.containsKey(w)).toList()
      ..shuffle(_random);
    for (final word in fillerPool.take(_fillerWordCount)) {
      final repeat = _random.nextBool() ? 3 : 5;
      bag.addAll(List.filled(repeat, word));
    }

    bag.shuffle(_random);

    final lines = <List<String>>[];
    for (int i = 0; i < bag.length; i += _wordsPerLine) {
      final end = min(i + _wordsPerLine, bag.length);
      final chunk = bag.sublist(i, end);
      if (chunk.length < _wordsPerLine && lines.isNotEmpty) {
        lines.last.addAll(chunk);
      } else {
        lines.add(chunk);
      }
    }
    _lines = lines;

    _questionTargets = (_targetCounts.entries.toList()..shuffle(_random)).take(3).toList();
    _questionIndex = 0;
    _correctCount = 0;
    _selectedOption = null;
    _lastWasCorrect = null;
    _isRunning = false;
    _showQuestions = false;
    _pass = 0;
    _lineIndex = 0;
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      _isRunning = true;
      _showQuestions = false;
      _pass = 0;
      _lineIndex = 0;
    });
    _timer = Timer.periodic(const Duration(milliseconds: _lineIntervalMs), (_) {
      if (!mounted) return;
      if (_lineIndex >= _lines.length - 1) {
        if (_pass >= _totalPasses - 1) {
          _timer?.cancel();
          setState(() {
            _isRunning = false;
            _showQuestions = true;
          });
          return;
        }
        setState(() {
          _pass++;
          _lineIndex = 0;
        });
      } else {
        setState(() => _lineIndex++);
      }
    });
  }

  List<int> _optionsFor(int correct) {
    final options = <int>{correct};
    while (options.length < 4) {
      final delta = (_random.nextInt(6) + 1) * (_random.nextBool() ? 1 : -1);
      final candidate = correct + delta;
      if (candidate > 0) options.add(candidate);
    }
    final list = options.toList()..shuffle(_random);
    return list;
  }

  void _answerQuestion(int chosen, int correct) {
    if (_selectedOption != null) return;
    final isCorrect = chosen == correct;
    setState(() {
      _selectedOption = chosen;
      _lastWasCorrect = isCorrect;
      if (isCorrect) _correctCount++;
    });
    if (isCorrect) {
      SoundManager.playCorrect();
    } else {
      SoundManager.playGentleTap();
    }

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_questionIndex < _questionTargets.length - 1) {
        setState(() {
          _questionIndex++;
          _selectedOption = null;
          _lastWasCorrect = null;
        });
      } else {
        _finish();
      }
    });
  }

  void _finish() {
    final total = _questionTargets.length;
    final percent = (_correctCount / total * 100).round();
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Kelime Akışı (Sayma)',
      result: '$_correctCount/$total doğru · %$percent',
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
            Text('Doğru: $_correctCount / $total (%$percent)',
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
              setState(() => _prepareSession());
            },
            child: const Text('Yeniden Başlat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🌊 Kelime Akışı')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _showQuestions ? _buildQuestionView() : _buildFlowView(),
      ),
    );
  }

  Widget _buildFlowView() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _isRunning ? 'Tur: ${_pass + 1}/$_totalPasses' : 'Hazır',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
              ),
            ),
            Text(
              'Bazı kelimeler çok kez geçecek, sonunda kaç kez geçtiği sorulacak!',
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Expanded(
          child: Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.3, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Wrap(
                  key: ValueKey('$_pass-$_lineIndex-$_isRunning'),
                  alignment: WrapAlignment.center,
                  spacing: 14,
                  runSpacing: 10,
                  children: _isRunning
                      ? _lines[_lineIndex]
                          .map((w) => Text(
                                w,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ))
                          .toList()
                      : [
                          const Text(
                            'BAŞLAT\'a bas',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isRunning ? null : _start,
            icon: const Icon(Icons.play_arrow),
            label: const Text('BAŞLAT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _buildQuestionView() {
    final target = _questionTargets[_questionIndex];
    final options = _optionsFor(target.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Soru ${_questionIndex + 1}/${_questionTargets.length}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5), fontSize: 16),
        ),
        const SizedBox(height: 24),
        Text(
          '"${target.key}" kelimesi kaç kez tekrarlandı?',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 30),
        Expanded(
          child: GridView.builder(
            itemCount: options.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.6,
            ),
            itemBuilder: (context, index) {
              final value = options[index];
              final isSelected = _selectedOption == value;
              Color bg = Colors.white;
              Color textColor = Colors.black87;
              if (isSelected) {
                bg = (_lastWasCorrect ?? false) ? Colors.green.shade500 : Colors.red.shade400;
                textColor = Colors.white;
              }
              return InkWell(
                onTap: () => _answerQuestion(value, target.value),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: Text(
                    '$value',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: textColor),
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

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';

class _ObjectItem {
  final String name;
  final String emoji;
  const _ObjectItem(this.name, this.emoji);
}

/// Öğretmen dokümanındaki nesne akışı etkinliği: satır üstünde hareketli
/// nesneler akar (en az 10 nesne/satır), bazı nesneler defalarca tekrarlanır.
/// 2 tur gösterildikten sonra "X nesnesi kaç kez gösterildi?" diye 3 soru
/// sorulur. Bu etkinliğin kelime versiyonu "Kelime Akışı"dır.
class ObjectFlowCountingPage extends StatefulWidget {
  const ObjectFlowCountingPage({super.key});

  @override
  State<ObjectFlowCountingPage> createState() => _ObjectFlowCountingPageState();
}

class _ObjectFlowCountingPageState extends State<ObjectFlowCountingPage> {
  // Hocanın dokümanındaki nesne listesi.
  static const List<_ObjectItem> _objectPool = [
    _ObjectItem('Kalem', '🖊️'),
    _ObjectItem('Silgi', '🧼'),
    _ObjectItem('Kitap', '📕'),
    _ObjectItem('Çanta', '🎒'),
    _ObjectItem('Kalemlik', '🧰'),
    _ObjectItem('Suluk', '🧴'),
    _ObjectItem('Tenis Topu', '🎾'),
    _ObjectItem('Basketbol Topu', '🏀'),
    _ObjectItem('Futbol Topu', '⚽'),
    _ObjectItem('Akıllı Tahta', '🖥️'),
    _ObjectItem('Kalemtıraş', '✂️'),
    _ObjectItem('Cep Telefonu', '📱'),
    _ObjectItem('Defter', '📓'),
    _ObjectItem('Beslenme Çantası', '🍱'),
    _ObjectItem('Ayraç', '🔖'),
    _ObjectItem('Fosforlu Kalem', '🖍️'),
    _ObjectItem('Tost', '🥪'),
    _ObjectItem('Dosya', '📁'),
    _ObjectItem('Cetvel', '📏'),
    _ObjectItem('Küre Dünya', '🌍'),
    _ObjectItem('İskelet', '💀'),
    _ObjectItem('Yangın Tüpü', '🧯'),
    _ObjectItem('Mikroskop', '🔬'),
    _ObjectItem('Sıra', '🪑'),
    _ObjectItem('Oyuncak Ayı', '🧸'),
    _ObjectItem('Duvar Saati', '🕐'),
    _ObjectItem('Ay Yıldız Bayrak', '🇹🇷'),
    _ObjectItem('Sarı Yeşil Elma', '🍏'),
    _ObjectItem('Sarı Limon', '🍋'),
  ];

  // Doğrudan doğrulanabilir bir örnek doküman değeri yok, doğrudan
  // dokümanın verdiği "kitap kaç kez gösterildi" örneğiyle uyumlu bir hedef
  // seti seçildi.
  static const Map<String, int> _targetCounts = {
    'Kitap': 14,
    'Kalem': 10,
    'Silgi': 7,
  };

  static const int _totalPasses = 2;
  static const int _lineIntervalMs = 1500;
  static const int _itemsPerLine = 10;
  static const int _fillerObjectCount = 18;

  final Random _random = Random();
  late List<List<_ObjectItem>> _lines;

  bool _isRunning = false;
  bool _showQuestions = false;
  bool _hasCompletedOnce = false;
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

  _ObjectItem _byName(String name) => _objectPool.firstWhere((o) => o.name == name);

  void _prepareSession() {
    final bag = <_ObjectItem>[];
    _targetCounts.forEach((name, count) {
      bag.addAll(List.filled(count, _byName(name)));
    });

    final fillerPool = _objectPool.where((o) => !_targetCounts.containsKey(o.name)).toList()
      ..shuffle(_random);
    for (final item in fillerPool.take(_fillerObjectCount)) {
      final repeat = _random.nextBool() ? 3 : 5;
      bag.addAll(List.filled(repeat, item));
    }

    bag.shuffle(_random);

    final lines = <List<_ObjectItem>>[];
    for (int i = 0; i < bag.length; i += _itemsPerLine) {
      final end = min(i + _itemsPerLine, bag.length);
      final chunk = bag.sublist(i, end);
      if (chunk.length < _itemsPerLine && lines.isNotEmpty) {
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
    _hasCompletedOnce = true;
    final total = _questionTargets.length;
    final percent = (_correctCount / total * 100).round();
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Nesne Akışı (Sayma)',
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
    return CompletionPopScope(
      isCompleted: () => _hasCompletedOnce,
      child: Scaffold(
      appBar: AppBar(title: const Text('📦 Nesne Akışı')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _showQuestions ? _buildQuestionView() : _buildFlowView(),
      ),
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
              'Bazı nesneler çok kez geçecek, sonunda kaç kez geçtiği sorulacak!',
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ],
        ),
        const Spacer(),
        Container(
          width: double.infinity,
          height: 110,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: !_isRunning
                  ? const Text(
                      'BAŞLAT\'a bas',
                      key: ValueKey('idle'),
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey),
                    )
                  : SingleChildScrollView(
                      key: ValueKey('$_pass-$_lineIndex'),
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _lines[_lineIndex].map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(item.emoji, style: const TextStyle(fontSize: 44)),
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ),
        ),
        const Spacer(),
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
    final emoji = _byName(target.key).emoji;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Soru ${_questionIndex + 1}/${_questionTargets.length}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5), fontSize: 16),
        ),
        const SizedBox(height: 24),
        Center(child: Text(emoji, style: const TextStyle(fontSize: 52))),
        const SizedBox(height: 12),
        Text(
          '"${target.key}" nesnesi kaç kez gösterildi?',
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

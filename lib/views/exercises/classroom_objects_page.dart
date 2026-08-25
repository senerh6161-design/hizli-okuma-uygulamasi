import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';

enum _Phase {
  streamIntro,
  stream,
  quizIntro,
  quiz,
  memoryIntro,
  memoryShow,
  memoryRound,
}

class _NamedObject {
  final String emoji;
  final String name;
  const _NamedObject(this.emoji, this.name);
}

class _StreamItem {
  final int id;
  final _NamedObject obj;
  final int lane;
  const _StreamItem(this.id, this.obj, this.lane);
}

/// Klasör 2'nin yedinci etkinliği: "Sınıf Eşyaları". İki bölüm:
/// 1) Satır Akışı — Etkinlik 2/3'teki mekanizmanın bir tık hızlandırılmış
/// ve 30 sn uzatılmış (90 sn) hali, sonunda "kaç kez gösterildi?" quizi,
/// 2) Dikkat ve Hafıza — 5 nesne 10 sn gösterilir, sonra her saniye biri
/// eksilerek gösterilir, öğrenci hangisinin eksildiğini bulmaya çalışır.
class ClassroomObjectsPage extends StatefulWidget {
  const ClassroomObjectsPage({super.key});

  @override
  State<ClassroomObjectsPage> createState() => _ClassroomObjectsPageState();
}

class _ClassroomObjectsPageState extends State<ClassroomObjectsPage> {
  static const Color _color = Color(0xFF65A30D);
  static const List<String> _speedLabels = ['Yavaş', 'Orta', 'Hızlı'];

  // Klasör 2 · Etkinlik 2/3'teki Satır Akışı'ndan bir tık daha hızlı.
  static const List<int> _streamSpawnMsBySpeed = [600, 420, 270];
  static const List<int> _streamTravelMsBySpeed = [1900, 1350, 900];
  static const int _streamDurationSec = 90; // 60 + 30 sn
  // Yönergeden sonra sorulara geçmeden önceki kısa hatırlatma gösterimi.
  static const int _replayDurationSec = 25;

  static const List<_NamedObject> _streamPool = [
    _NamedObject('✏️', 'Kalem'),
    _NamedObject('📚', 'Kitap'),
    _NamedObject('🎒', 'Çanta'),
    _NamedObject('🧴', 'Suluk'),
    _NamedObject('🎾', 'Tenis topu'),
    _NamedObject('🏀', 'Basketbol topu'),
    _NamedObject('⚽', 'Futbol topu'),
    _NamedObject('📱', 'Cep telefonu'),
    _NamedObject('📓', 'Defter'),
    _NamedObject('🔖', 'Ayraç'),
    _NamedObject('🥪', 'Tost'),
    _NamedObject('📁', 'Dosya'),
    _NamedObject('🌍', 'Küre (Dünya)'),
    _NamedObject('🧯', 'Yangın tüpü'),
    _NamedObject('🔬', 'Mikroskop'),
    _NamedObject('🪑', 'Sıra'),
    _NamedObject('📺', 'Akıllı tahta'),
    _NamedObject('🍱', 'Beslenme çantası'),
    _NamedObject('🖍️', 'Fosforlu kalem'),
  ];

  // 2. Bölüm'de kullanılan 5 nesne — 1. Bölüm'ün soru havuzundan farklı.
  static const List<_NamedObject> _memoryPool = [
    _NamedObject('🧸', 'Oyuncak ayı'),
    _NamedObject('🕰️', 'Duvar saati'),
    _NamedObject('🇹🇷', 'Ay yıldız bayrak'),
    _NamedObject('🍏', 'Yeşil elma'),
    _NamedObject('🍋', 'Sarı limon'),
  ];

  static const int _quizRoundCount = 3;
  static const int _memoryRoundCount = 4; // 5 nesne → 4 eksiltme adımı

  final Random _random = Random();
  _Phase _phase = _Phase.streamIntro;
  bool _hasCompletedOnce = false;
  bool _isReplay = false;
  int _speedLevel = 1;

  // 1. Bölüm: Satır Akışı.
  // Nesneler tek çizgide üst üste binmesin diye birkaç dikey "şerit"
  // arasında dönüşümlü olarak beliriyor.
  static const int _streamLaneCount = 3;
  int _nextStreamId = 0;
  int _lastStreamLane = -1;
  final List<_StreamItem> _streamItems = [];
  final List<_NamedObject> _streamBag = [];
  _NamedObject? _lastStreamObj;
  Timer? _streamSpawnTimer;
  Timer? _streamCountdownTimer;
  int _streamElapsedSec = 0;
  final Map<String, int> _showCounts = {};

  // 1. Bölüm · 2. Tur: Quiz.
  int _quizRoundIndex = 0;
  int _quizScore = 0;
  late _NamedObject _quizAsked;
  List<int> _quizOptions = const [];
  int? _quizSelected;
  bool _quizAnswered = false;

  // 2. Bölüm: Dikkat ve Hafıza.
  List<_NamedObject> _memoryRemovalOrder = [];
  int _memoryRoundIndex = 0;
  int _memoryScore = 0;
  bool _memoryShowingSet = true;
  int? _memorySelectedIndex;
  bool _memoryAnswered = false;
  Timer? _memoryTimer;

  @override
  void dispose() {
    _streamSpawnTimer?.cancel();
    _streamCountdownTimer?.cancel();
    _memoryTimer?.cancel();
    super.dispose();
  }

  // ---------------- 1. BÖLÜM: Satır Akışı ----------------

  // Yönergeden sonra soru sormadan önce nesneler bir kez daha (daha kısa
  // süreyle) gösteriliyor — öğrenci hatırlamadan direkt soruyla
  // karşılaşmıyor.
  void _startReplay() {
    _startStream(isReplay: true);
  }

  void _startStream({bool isReplay = false}) {
    _streamCountdownTimer?.cancel();
    _streamSpawnTimer?.cancel();
    if (!isReplay) _showCounts.clear();
    _streamBag.clear();
    _lastStreamObj = null;
    setState(() {
      _phase = _Phase.stream;
      _isReplay = isReplay;
      _streamElapsedSec = 0;
      _streamItems.clear();
    });
    final duration = isReplay ? _replayDurationSec : _streamDurationSec;
    _streamCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _streamElapsedSec++);
      if (_streamElapsedSec >= duration) _finishStream();
    });
    _streamSpawnTimer = Timer.periodic(
      Duration(milliseconds: _streamSpawnMsBySpeed[_speedLevel]),
      (_) {
        if (!mounted) return;
        final id = _nextStreamId++;
        final obj = _nextStreamObj();
        _showCounts[obj.name] = (_showCounts[obj.name] ?? 0) + 1;
        int lane = _random.nextInt(_streamLaneCount);
        if (_streamLaneCount > 1) {
          while (lane == _lastStreamLane) {
            lane = _random.nextInt(_streamLaneCount);
          }
        }
        _lastStreamLane = lane;
        setState(() => _streamItems.add(_StreamItem(id, obj, lane)));
        Timer(Duration(milliseconds: _streamTravelMsBySpeed[_speedLevel]), () {
          if (!mounted) return;
          setState(() => _streamItems.removeWhere((s) => s.id == id));
        });
      },
    );
  }

  // "Shuffle bag": havuzun karışık bir kopyasını tüketip bitince yeniden
  // dolduruyor — saf rastgelelik gibi bir nesnenin çok fazla tekrar
  // etmesine izin vermiyor, her tur her nesne tam bir kez çıkıyor. Yeni
  // turun ilk elemanı bir öncekiyle aynıysa yer değiştiriliyor ki aynı
  // nesne art arda (yan yana) gelmesin.
  _NamedObject _nextStreamObj() {
    if (_streamBag.isEmpty) {
      _streamBag.addAll(_streamPool);
      _streamBag.shuffle(_random);
      if (_streamBag.length > 1 && _streamBag.last == _lastStreamObj) {
        final tmp = _streamBag.last;
        _streamBag[_streamBag.length - 1] = _streamBag[0];
        _streamBag[0] = tmp;
      }
    }
    final next = _streamBag.removeLast();
    _lastStreamObj = next;
    return next;
  }

  void _finishStream() {
    _streamCountdownTimer?.cancel();
    _streamSpawnTimer?.cancel();
    if (_isReplay) {
      _streamItems.clear();
      _startQuiz();
      return;
    }
    setState(() {
      _streamItems.clear();
      _phase = _Phase.quizIntro;
    });
  }

  // ---------------- 1. BÖLÜM · 2. TUR: Quiz ----------------

  void _startQuiz() {
    setState(() {
      _phase = _Phase.quiz;
      _quizRoundIndex = 0;
      _quizScore = 0;
    });
    _startQuizRound();
  }

  void _startQuizRound() {
    final asked = _streamPool[_random.nextInt(_streamPool.length)];
    final correctCount = _showCounts[asked.name] ?? 0;
    // Doğru sayı 0'a veya üst sınıra çok yakınsa rastgele deneme sonsuz
    // döngüye girebiliyordu (4 farklı sayı asla bulunamıyordu) — bu
    // yüzden olası tüm değerlerden karışık örnekleme yapılıyor.
    const maxOption = 30;
    final otherValues = [
      for (int i = 0; i <= maxOption; i++)
        if (i != correctCount) i,
    ]..shuffle(_random);
    setState(() {
      _quizAsked = asked;
      _quizOptions = [correctCount, ...otherValues.take(3)]..shuffle(_random);
      _quizSelected = null;
      _quizAnswered = false;
    });
  }

  void _answerQuiz(int selected) {
    if (_quizAnswered) return;
    final correctCount = _showCounts[_quizAsked.name] ?? 0;
    final isCorrect = selected == correctCount;
    setState(() => _quizSelected = selected);
    if (isCorrect) {
      SoundManager.playCorrect();
      _quizScore++;
    } else {
      SoundManager.playGentleTap();
    }
    setState(() => _quizAnswered = true);
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      if (_quizRoundIndex < _quizRoundCount - 1) {
        setState(() => _quizRoundIndex++);
        _startQuizRound();
      } else {
        setState(() => _phase = _Phase.memoryIntro);
      }
    });
  }

  // ---------------- 2. BÖLÜM: Dikkat ve Hafıza ----------------

  void _startMemory() {
    _memoryRemovalOrder = [..._memoryPool]..shuffle(_random);
    setState(() {
      _phase = _Phase.memoryShow;
      _memoryRoundIndex = 0;
      _memoryScore = 0;
    });
    _memoryTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      _startMemoryRound();
    });
  }

  List<_NamedObject> get _memoryCurrentSet {
    final removedSoFar = _memoryRemovalOrder.take(_memoryRoundIndex).toSet();
    return _memoryPool.where((o) => !removedSoFar.contains(o)).toList();
  }

  void _startMemoryRound() {
    _memoryTimer?.cancel();
    setState(() {
      _phase = _Phase.memoryRound;
      _memoryShowingSet = true;
      _memorySelectedIndex = null;
      _memoryAnswered = false;
    });
    _memoryTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _memoryShowingSet = false);
    });
  }

  void _answerMemory(int index) {
    if (_memoryAnswered) return;
    final correct = _memoryRemovalOrder[_memoryRoundIndex];
    final selected = _memoryPool[index];
    final isCorrect = selected == correct;
    setState(() => _memorySelectedIndex = index);
    if (isCorrect) {
      SoundManager.playCorrect();
      _memoryScore++;
    } else {
      SoundManager.playGentleTap();
    }
    setState(() => _memoryAnswered = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      if (_memoryRoundIndex < _memoryRoundCount - 1) {
        setState(() => _memoryRoundIndex++);
        _startMemoryRound();
      } else {
        _finishAll();
      }
    });
  }

  void _finishAll() {
    _streamCountdownTimer?.cancel();
    _streamSpawnTimer?.cancel();
    _memoryTimer?.cancel();
    _hasCompletedOnce = true;

    final totalCorrect = _quizScore + _memoryScore;
    final totalRounds = _quizRoundCount + _memoryRoundCount;
    final percent = ((totalCorrect / totalRounds) * 100).round();
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Sınıf Eşyaları',
      result:
          'Quiz: $_quizScore/$_quizRoundCount · Hafıza: $_memoryScore/$_memoryRoundCount',
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
            Text('Kaç Kez Sorusu: $_quizScore / $_quizRoundCount'),
            Text('Hafıza Sorusu: $_memoryScore / $_memoryRoundCount'),
            const SizedBox(height: 4),
            Text(
              'Toplam: %$percent',
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
              setState(() => _phase = _Phase.streamIntro);
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
        appBar: AppBar(title: const Text('🎒 Sınıf Eşyaları')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _Phase.streamIntro:
        return KeyedSubtree(
          key: const ValueKey('stream-intro'),
          child: _buildStreamIntro(),
        );
      case _Phase.stream:
        return KeyedSubtree(
          key: const ValueKey('stream-flow'),
          child: _buildStreamFlow(),
        );
      case _Phase.quizIntro:
        return KeyedSubtree(
          key: const ValueKey('quiz-intro'),
          child: _buildQuizIntro(),
        );
      case _Phase.quiz:
        return KeyedSubtree(
          key: ValueKey('quiz-flow-$_quizRoundIndex'),
          child: _buildQuizFlow(),
        );
      case _Phase.memoryIntro:
        return KeyedSubtree(
          key: const ValueKey('memory-intro'),
          child: _buildMemoryIntro(),
        );
      case _Phase.memoryShow:
        return KeyedSubtree(
          key: const ValueKey('memory-show'),
          child: _buildMemoryShow(),
        );
      case _Phase.memoryRound:
        return KeyedSubtree(
          key: ValueKey('memory-round-$_memoryRoundIndex'),
          child: _buildMemoryRound(),
        );
    }
  }

  Widget _buildIntro({
    required String badge,
    required String emoji,
    required String instruction,
    required VoidCallback onStart,
    bool showSpeed = true,
  }) {
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
                  child: Text(
                    badge,
                    style: const TextStyle(
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
                    Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 64)),
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
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: _color,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              instruction,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showSpeed) ...[
                      const SizedBox(height: 12),
                      _speedChipRow(),
                    ],
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: onStart,
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

  Widget _buildStreamIntro() {
    return _buildIntro(
      badge: '1. Bölüm · Satır Akışı',
      emoji: '➡️',
      instruction:
          'Sınıf eşyaları satır üzerinde hızlıca akıp geçecek. Başını oynatmadan, '
          'sadece gözlerinle takip et — 90 saniye sürecek. Bazı eşyalar birden '
          'çok kez geçecek, dikkatli ol!',
      onStart: _startStream,
    );
  }

  Widget _buildQuizIntro() {
    return _buildIntro(
      badge: '1. Bölüm · 2. Tur · Kaç Kez?',
      emoji: '❓',
      instruction:
          'Eşyalar kısa bir süre daha akacak, sonra az önce gördüğün eşyalardan '
          'bazılarının kaç kez ekrandan geçtiğini soracağız. Doğru cevap puan kazandırır!',
      onStart: _startReplay,
      showSpeed: false,
    );
  }

  Widget _buildMemoryIntro() {
    return _buildIntro(
      badge: '2. Bölüm · Dikkat ve Hafıza',
      emoji: '🧠',
      instruction:
          'Amaç: Dikkat ve odaklanmayı geliştirmek. Önce 5 eşya 10 saniye '
          'gösterilecek. Sonra her saniye bir eşya eksilerek gösterilecek — '
          'her seferinde hangisinin eksildiğini zihninden bulmaya çalış!',
      onStart: _startMemory,
      showSpeed: false,
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

  Widget _skipButton(VoidCallback onSkip) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onSkip,
        icon: const Icon(Icons.skip_next_rounded),
        label: const Text(
          'SONRAKİ BÖLÜM',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _color,
          side: const BorderSide(color: _color),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _stageHeader(String badge, {String? timerText}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            badge,
            style: const TextStyle(fontWeight: FontWeight.bold, color: _color),
          ),
        ),
        if (timerText != null)
          Text(
            timerText,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.orange,
            ),
          ),
      ],
    );
  }

  Widget _buildStreamFlow() {
    final duration = _isReplay ? _replayDurationSec : _streamDurationSec;
    final remaining = duration - _streamElapsedSec;
    return Column(
      children: [
        _stageHeader(
          _isReplay ? '1. Bölüm · Hatırlatma' : '1. Bölüm · Satır Akışı',
          timerText: 'Süre: $remaining sn',
        ),
        const SizedBox(height: 10),
        _speedChipRow(),
        const SizedBox(height: 12),
        Expanded(
          child: Center(
            // Tabletlerde bu alan çok uzayabiliyor — üst sınır koyup
            // ortalayarak kutunun ekrana orantısız yayılmasını önlüyoruz.
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 460),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Center(
                          child: Container(
                            width: double.infinity,
                            height: 2,
                            color: _color.withValues(alpha: 0.2),
                          ),
                        ),
                        for (final item in _streamItems)
                          TweenAnimationBuilder<double>(
                            key: ValueKey(item.id),
                            // Kitap okuma mantığıyla: yeni nesne sağdan
                            // girip sola doğru akıyor.
                            tween: Tween(begin: 1.0, end: -1.0),
                            duration: Duration(
                              milliseconds: _streamTravelMsBySpeed[_speedLevel],
                            ),
                            curve: Curves.linear,
                            builder: (context, t, _) {
                              // Şeritler arası sabit piksel mesafe
                              // kullanılıyor (kutunun yüksekliğine göre
                              // ORANLI değil) — büyük tabletlerde kutu çok
                              // uzadığında şeritler birbirinden uzaklaşıp
                              // ekrana dağılmasın diye.
                              final laneOffset =
                                  (item.lane - (_streamLaneCount - 1) / 2) *
                                  44.0;
                              return Align(
                                alignment: Alignment(t, 0),
                                child: Transform.translate(
                                  offset: Offset(0, laneOffset),
                                  child: Text(
                                    item.obj.emoji,
                                    style: const TextStyle(fontSize: 38),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _skipButton(_finishStream),
      ],
    );
  }

  Widget _buildQuizFlow() {
    return Column(
      children: [
        _stageHeader('Soru ${_quizRoundIndex + 1}/$_quizRoundCount'),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_quizAsked.emoji, style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 8),
                  Text(
                    '"${_quizAsked.name}"',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'kaç kez gösterildi?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final option in _quizOptions)
                        _numberButton(
                          option,
                          _showCounts[_quizAsked.name] ?? 0,
                          isSelected: _quizSelected == option,
                          answered: _quizAnswered,
                          onTap: () => _answerQuiz(option),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _numberButton(
    int option,
    int correct, {
    required bool isSelected,
    required bool answered,
    required VoidCallback onTap,
  }) {
    final isCorrectOption = option == correct;
    Color bg = _color.withValues(alpha: 0.08);
    Color border = _color.withValues(alpha: 0.3);
    Color fg = _color;
    if (answered && isCorrectOption) {
      bg = const Color(0xFF16A34A).withValues(alpha: 0.12);
      border = const Color(0xFF16A34A);
      fg = const Color(0xFF16A34A);
    } else if (answered && isSelected && !isCorrectOption) {
      bg = const Color(0xFFE11D48).withValues(alpha: 0.12);
      border = const Color(0xFFE11D48);
      fg = const Color(0xFFE11D48);
    }
    return SizedBox(
      width: 64,
      height: 64,
      child: OutlinedButton(
        onPressed: answered ? null : onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          side: BorderSide(color: border, width: 2),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          '$option',
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: fg,
          ),
        ),
      ),
    );
  }

  Widget _buildMemoryShow() {
    return Column(
      children: [
        _stageHeader('2. Bölüm · İlk Gösterim (10 sn)'),
        Expanded(
          child: Center(
            child: Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [for (final obj in _memoryPool) _memoryObjectTile(obj)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _memoryObjectTile(_NamedObject obj) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(obj.emoji, style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 4),
        Text(
          obj.name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMemoryRound() {
    return Column(
      children: [
        _stageHeader(
          '2. Bölüm · Tur ${_memoryRoundIndex + 1}/$_memoryRoundCount',
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Center(
            child: _memoryShowingSet
                ? Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final obj in _memoryCurrentSet)
                        _memoryObjectTile(obj),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Az önce hangi nesne kayboldu?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            for (int i = 0; i < _memoryPool.length; i++)
                              _memoryAnswerButton(i),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _memoryAnswerButton(int index) {
    final obj = _memoryPool[index];
    final correct = _memoryRemovalOrder[_memoryRoundIndex];
    final isCorrectOption = obj == correct;
    final isSelected = _memorySelectedIndex == index;
    Color bg = _color.withValues(alpha: 0.08);
    Color border = _color.withValues(alpha: 0.3);
    Color fg = _color;
    if (_memoryAnswered) {
      if (isCorrectOption) {
        bg = const Color(0xFF16A34A).withValues(alpha: 0.12);
        border = const Color(0xFF16A34A);
        fg = const Color(0xFF16A34A);
      } else if (isSelected) {
        bg = const Color(0xFFE11D48).withValues(alpha: 0.12);
        border = const Color(0xFFE11D48);
        fg = const Color(0xFFE11D48);
      }
    }
    return SizedBox(
      width: 130,
      height: 76,
      child: OutlinedButton(
        onPressed: _memoryAnswered ? null : () => _answerMemory(index),
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          side: BorderSide(color: border, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(obj.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 2),
            Text(
              obj.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

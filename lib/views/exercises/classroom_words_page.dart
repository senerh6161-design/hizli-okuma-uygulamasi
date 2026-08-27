import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';

enum _Phase { streamIntro, stream, quizIntro, quiz }

/// Klasör 2'nin sekizinci etkinliği: Etkinlik 7'nin (Sınıf Eşyaları) KELİME
/// versiyonu — aynı Satır Akışı + "kaç kez gösterildi?" quiz yapısı, ama
/// tamamen farklı bir kelime havuzuyla, bir tık daha hızlı ve süresi 1
/// dakika daha uzun (150 sn). Altı kelime ("umut", "sevgi", "tatlı",
/// "kardeş", "empati", "gülümse") çok daha sık, geri kalanlar birkaç kez
/// geçiyor — quiz bu altı kelimeden 3'ünü, GERÇEK gösterim sayısıyla sorar.
class ClassroomWordsPage extends StatefulWidget {
  const ClassroomWordsPage({super.key});

  @override
  State<ClassroomWordsPage> createState() => _ClassroomWordsPageState();
}

class _ClassroomWordsPageState extends State<ClassroomWordsPage> {
  static const Color _color = Color(0xFF0284C7);
  static const List<String> _speedLabels = ['Yavaş', 'Orta', 'Hızlı'];

  // Kelimeler satırda tek tek bu sıklıkta belirir.
  static const List<int> _streamSpawnMsBySpeed = [650, 450, 280];
  static const int _streamDurationSec = 150; // 90 + 60 sn
  // Yönergeden sonra sorulara geçmeden önceki kısa hatırlatma gösterimi.
  static const int _replayDurationSec = 30;

  // Bu kelimeler çok daha sık geçsin diye ağırlıklı (weighted) havuza
  // kendi sayılarınca ekleniyor — quiz bunlardan 3'ünü soruyor.
  static const Map<String, int> _specialWords = {
    'umut': 20,
    'sevgi': 19,
    'tatlı': 15,
    'kardeş': 10,
    'empati': 18,
    'gülümse': 25,
  };

  // Geri kalan kelimeler — her biri turda birkaç (3-5) kez geçiyor.
  static const List<String> _fillerWords = [
    'Bakteri',
    'Hijyen',
    'Güzel',
    'Zanaat',
    'Cenk',
    'Zafer',
    'Ekosistem',
    'Samimi',
    'Zeybek',
    'Hünkâr',
    'Türkmen',
    'Kalpak',
    'Sindirim',
    'Dingin',
    'Hançer',
    'Meslek',
    'Kervan',
    'Güven',
    'Metabolizma',
    'Ahilik',
    'Sancak',
    'Şefkat',
    'Değer',
    'Bağlılık',
    'Bağışıklık',
    'Ferah',
    'Yemin',
    'Tüccar',
    'Töre',
    'Aşiret',
    'Hastalık',
    'Kaftan',
    'Neşe',
    'Yiğit',
    'Korkut',
    'Ödev',
    'Mikroskop',
    'Destan',
    'Barış',
    'Huzur',
    'Sıcaklık',
    'Element',
    'Dostluk',
    'Proje',
    'Saat',
    'Konu',
    'Çizim',
    'Test',
    'Malazgirt',
    'Sınav',
    'Harita',
    'Fırça',
    'Desen',
    'Nota',
    'Melodi',
    'Mutluluk',
    'Takvim',
    'Çeviri',
    'Odak',
    'Uzantı',
    'Ulusal',
    'Varsayım',
    'Organizma',
    'Tuval',
    'Öngörü',
    'Gelgit',
    'Yükümlü',
    'Özenti',
    'Yavan',
    'Nezaket',
    'Metot',
    'Kalıcı',
    'Özdeş',
    'Maksat',
    'Yargı',
    'Sağduyu',
    'Yapıtaşı',
    'Kuşku',
    'İmge',
    'Dipnot',
    'İrade',
    'Lirik',
    'Alternatif',
    'Yapaylık',
    'Drama',
    'Boyut',
    'Deneyim',
    'Coşkun',
    'Kaynak',
    'Perspektif',
    'Yenilik',
    'Kanaat',
    'Mahlas',
    'Ayrıntı',
    'Kaygı',
    'Anlatım',
    'Kompozisyon',
    'Yinele',
    'Kalıp',
    'Özlü',
    'Sanal',
    'Kitle',
    'Klişe',
    'Enstrüman',
    'Trajedi',
    'Rastgele',
    'Çalışma',
    'Simge',
    'Sentez',
    'Biçim',
    'Jimnastik',
    'Otorite',
    'Sulh',
    'Taslak',
    'Analiz',
    'Yalın',
    'Antrenman',
    'Özveri',
    'Garp',
    'İrdele',
    'Ocak',
    'Özerk',
    'Peygamber',
    'Koşul',
    'Çehre',
    'Hüzün',
    'Alaca',
    'Sığ',
    'Hicret',
    'Üstünkörü',
    'Katmerli',
    'İvedi',
    'Hoşgörü',
    'Çelişki',
    'Bulgu',
    'İleti',
    'Terennüm',
    'İzlenim',
    'Örtük',
    'Seçkin',
    'Çevik',
    'İkilem',
    'Refleks',
    'Tökezlemek',
    'İrkilmek',
    'Faktör',
    'Arşiv',
    'Karşıt',
    'Motif',
    'Özlem',
    'Örselenmek',
  ];

  static const int _quizRoundCount = 3;

  final Random _random = Random();
  _Phase _phase = _Phase.streamIntro;
  bool _hasCompletedOnce = false;
  bool _isPaused = false;
  bool _isReplay = false;
  int _speedLevel = 1;

  // 1. Bölüm: Satır Akışı — Klasör 1'deki "Nesne Akışı" ile aynı mantık:
  // kelimeler soldan sağa TEK TEK belirip sabit bir satırda yan yana
  // durur (uçuşup kaymaz), satır dolunca hepsi birden kaybolup yeniden
  // başlar.
  static const int _itemsPerLine = 5;
  static const int _rowPauseMs = 700;
  List<String> _currentLine = const [];
  int _lineItemIndex = 0;
  Timer? _streamTimer;
  Timer? _streamCountdownTimer;
  int _streamElapsedSec = 0;
  final Map<String, int> _showCounts = {};
  List<String> _weightedPool = const [];

  // 2. Tur: Quiz.
  int _quizRoundIndex = 0;
  int _quizScore = 0;
  List<String> _quizWords = const [];
  late String _quizAsked;
  List<int> _quizOptions = const [];
  int? _quizSelected;
  bool _quizAnswered = false;

  @override
  void dispose() {
    _streamTimer?.cancel();
    _streamCountdownTimer?.cancel();
    super.dispose();
  }

  List<String> _buildWeightedPool() {
    final pool = <String>[];
    _specialWords.forEach((word, count) {
      for (int i = 0; i < count; i++) {
        pool.add(word);
      }
    });
    for (final word in _fillerWords) {
      final reps = 3 + _random.nextInt(3); // 3..5
      for (int i = 0; i < reps; i++) {
        pool.add(word);
      }
    }
    return pool;
  }

  // ---------------- 1. BÖLÜM: Satır Akışı ----------------

  void _startReplay() {
    _startStream(isReplay: true);
  }

  void _startStream({bool isReplay = false}) {
    _streamCountdownTimer?.cancel();
    _streamTimer?.cancel();
    if (!isReplay) _showCounts.clear();
    _weightedPool = _buildWeightedPool();
    setState(() {
      _phase = _Phase.stream;
      _isReplay = isReplay;
      _streamElapsedSec = 0;
      _currentLine = _generateLine();
      _lineItemIndex = 1; // ilk kelime hemen belirsin
    });
    final duration = isReplay ? _replayDurationSec : _streamDurationSec;
    _streamCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _streamElapsedSec++);
      if (_streamElapsedSec >= duration) _finishStream();
    });
    _scheduleStreamReveal();
  }

  List<String> _generateLine() {
    return List.generate(_itemsPerLine, (_) {
      final word = _weightedPool[_random.nextInt(_weightedPool.length)];
      _showCounts[word] = (_showCounts[word] ?? 0) + 1;
      return word;
    });
  }

  // Aktif satırdaki kelimeler TEK TEK belirir; satır tamamen dolunca kısa
  // bir süre öylece durup öğrenciye bakma fırsatı verir, sonra hepsi
  // birden kaybolup yeni satır aynı şekilde tek tek belirmeye başlar.
  void _scheduleStreamReveal() {
    if (!mounted || _phase != _Phase.stream) return;
    final rowComplete = _lineItemIndex >= _currentLine.length;
    final delay = rowComplete
        ? _rowPauseMs
        : _streamSpawnMsBySpeed[_speedLevel];
    _streamTimer = Timer(Duration(milliseconds: delay), () {
      if (!mounted || _phase != _Phase.stream) return;
      if (rowComplete) {
        setState(() {
          _currentLine = _generateLine();
          _lineItemIndex = 1;
        });
      } else {
        setState(() => _lineItemIndex++);
      }
      _scheduleStreamReveal();
    });
  }

  void _finishStream() {
    _streamCountdownTimer?.cancel();
    _streamTimer?.cancel();
    if (_isReplay) {
      _startQuiz();
      return;
    }
    setState(() {
      _phase = _Phase.quizIntro;
    });
  }

  // ---------------- 2. TUR: Quiz ----------------

  void _startQuiz() {
    _quizWords = _specialWords.keys.toList()..shuffle(_random);
    setState(() {
      _phase = _Phase.quiz;
      _quizRoundIndex = 0;
      _quizScore = 0;
    });
    _startQuizRound();
  }

  void _startQuizRound() {
    final asked = _quizWords[_quizRoundIndex];
    final correctCount = _showCounts[asked] ?? 0;
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
    final correctCount = _showCounts[_quizAsked] ?? 0;
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
        _finishAll();
      }
    });
  }

  void _finishAll() {
    _streamCountdownTimer?.cancel();
    _streamTimer?.cancel();
    _hasCompletedOnce = true;

    final percent = ((_quizScore / _quizRoundCount) * 100).round();
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Sınıf Eşyaları · Kelime',
      result: 'Quiz: $_quizScore/$_quizRoundCount doğru (%$percent)',
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
            Text('Doğru: $_quizScore / $_quizRoundCount (%$percent)'),
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

  void _pauseGame() {
    _streamCountdownTimer?.cancel();
    _streamTimer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resumeGame() {
    setState(() => _isPaused = false);
    if (_phase == _Phase.stream) {
      final duration = _isReplay ? _replayDurationSec : _streamDurationSec;
      _streamCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _streamElapsedSec++);
        if (_streamElapsedSec >= duration) _finishStream();
      });
      _scheduleStreamReveal();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompletionPopScope(
      isCompleted: () => _hasCompletedOnce,
      child: Scaffold(
        appBar: AppBar(title: const Text('📝 Sınıf Eşyaları · Kelime')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildBody(),
              ),
              if (_isPaused)
                buildPauseOverlay(color: _color, onResume: _resumeGame),
            ],
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
          'Kelimeler soldan sağa tek tek belirip satırda yan yana duracak. '
          'Satır dolunca hepsi birden kaybolup yeniden başlayacak — 2,5 '
          'dakika sürecek. Bazı kelimeler çok daha sık geçecek, dikkatli ol!',
      onStart: _startStream,
    );
  }

  Widget _buildQuizIntro() {
    return _buildIntro(
      badge: '2. Tur · Kaç Kez?',
      emoji: '❓',
      instruction:
          'Kelimeler kısa bir süre daha akacak, sonra az önce gördüğün '
          'kelimelerden bazılarının kaç kez ekrandan geçtiğini soracağız. '
          'Doğru cevap puan kazandırır!',
      onStart: _startReplay,
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

  Widget _stageHeader(
    String badge, {
    String? timerText,
    bool showPause = false,
  }) {
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (timerText != null)
              Text(
                timerText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.orange,
                ),
              ),
            if (showPause)
              buildPauseButton(color: _color, onPressed: _pauseGame),
          ],
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
          showPause: true,
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                    ),
                  ],
                ),
                // Klasör 1'deki Nesne Akışı gibi: kelimeler soldan sağa TEK
                // TEK belirip sabit bir satırda yan yana durur, uçuşmaz.
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    runSpacing: 12,
                    children: [
                      for (int i = 0; i < _lineItemIndex; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey('stream-$i-${_currentLine[i]}'),
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 220),
                            builder: (context, value, child) => Opacity(
                              opacity: value,
                              child: Transform.scale(
                                scale: 0.8 + 0.2 * value,
                                child: child,
                              ),
                            ),
                            child: Text(
                              _currentLine[i],
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _color,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
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
                  Text(
                    '"$_quizAsked"',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'kelimesi kaç kez gösterildi?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final option in _quizOptions) _numberButton(option),
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

  Widget _numberButton(int option) {
    final correct = _showCounts[_quizAsked] ?? 0;
    final isSelected = _quizSelected == option;
    final isCorrectOption = option == correct;
    Color bg = _color.withValues(alpha: 0.08);
    Color border = _color.withValues(alpha: 0.3);
    Color fg = _color;
    if (_quizAnswered) {
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
      width: 64,
      height: 64,
      child: OutlinedButton(
        onPressed: _quizAnswered ? null : () => _answerQuiz(option),
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
}

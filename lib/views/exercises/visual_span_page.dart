import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';

enum _Phase { streamIntro, stream, scatterIntro, scatter, quizIntro, quiz }

class _SpanObject {
  final int id;
  final String emoji;
  final double x;
  final double y;
  const _SpanObject(this.id, this.emoji, this.x, this.y);
}

/// Klasör 2'nin ikinci etkinliği: "Görsel Genişlik". Öğretmen dokümanındaki
/// alt bölümlerin uyarlaması:
/// 1) Klasör 1'deki "Nesne Akışı" gibi satır üzerinde akan nesneler — bu kez
/// daha hızlı ve daha uzun süreli,
/// 2) Ekranın her yerine dağılmış en az 5 nesne, öğrenci merkez noktaya
/// bakarak çevresel görüşüyle onları algılamaya çalışır — her gösterimde
/// nesnelerin yerleri değişir,
/// 3) Aynı mekanikle kısa bir gösterim yapılır, ardından "kaç tane [X]
/// gördün?" diye sorulur, doğru cevap puan kazandırır.
class VisualSpanPage extends StatefulWidget {
  const VisualSpanPage({super.key});

  @override
  State<VisualSpanPage> createState() => _VisualSpanPageState();
}

class _VisualSpanPageState extends State<VisualSpanPage> {
  static const int _stageDurationSec = 60;
  static const Color _color = Color(0xFF0D9488);
  static const List<String> _speedLabels = ['Yavaş', 'Orta', 'Hızlı'];

  // 1. Bölüm: satırdaki nesneler ne sıklıkta tek tek belirir — hız
  // arttıkça kısalır.
  static const List<int> _streamSpawnMsBySpeed = [700, 500, 320];

  // 2. ve 3. Bölüm: her "gösterim" (flash) ne kadar ekranda kalıyor.
  static const List<int> _flashMsBySpeed = [1500, 1000, 650];

  static const int _spanObjectCount = 6;
  static const List<String> _objectEmojis = [
    '😊',
    '🎾',
    '⭐',
    '❤️',
    '⚽',
    '🍎',
    '🍌',
    '🏀',
    '🚗',
    '🎈',
    '📏',
    '🐶',
  ];
  static const int _quizRoundCount = 5;

  final Random _random = Random();
  _Phase _phase = _Phase.streamIntro;
  bool _hasCompletedOnce = false;
  bool _isPaused = false;
  int _speedLevel = 1;

  int _elapsedSec = 0;
  Timer? _countdownTimer;

  // 1. Bölüm: Satır Akışı — Klasör 1'deki "Nesne Akışı" ile aynı mantık:
  // nesneler soldan sağa TEK TEK belirip sabit bir satırda yan yana durur
  // (uçuşup kaymaz), satır dolunca hepsi birden kaybolup yeniden başlar.
  static const int _itemsPerLine = 5;
  static const int _rowPauseMs = 700;
  List<String> _currentLine = const [];
  int _lineItemIndex = 0;
  final List<String> _streamBag = [];
  String? _lastStreamEmoji;
  Timer? _streamTimer;

  // 2. Bölüm: Görsel Alan (puansız, dağınık gösterim).
  int _nextObjectId = 0;
  List<_SpanObject> _scatterObjects = [];
  Timer? _scatterTimer;

  // 3. Bölüm: Quiz — aynı dağınık gösterim + "kaç tane X gördün?" sorusu.
  int _quizRoundIndex = 0;
  int _quizScore = 0;
  List<_SpanObject> _quizObjects = [];
  Map<String, int> _quizCounts = {};
  String _quizAskedEmoji = _objectEmojis.first;
  List<int> _quizOptions = const [];
  int? _quizSelected;
  // Önce hangi nesneyi sayacağı duyurulur, sonra dağınık gösterim yapılır,
  // en son soru sorulur — öğrenci neyi sayacağını bilmeden gösterime
  // başlamıyor.
  bool _quizAnnouncing = true;
  bool _quizShowingObjects = true;
  Timer? _quizFlashTimer;
  static const int _quizAnnounceMs = 1400;

  @override
  void initState() {
    super.initState();
    // Bu etkinlikte yan (yatay) çevirme ZORUNLU değil, sadece isteğe
    // bağlı serbest bırakılıyor — öğrenci telefonu yan çevirirse ekran da
    // buna uyum sağlar, çevirmezse dikey kalmaya devam eder.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _streamTimer?.cancel();
    _scatterTimer?.cancel();
    _quizFlashTimer?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  // ---------------- 1. BÖLÜM: Satır Akışı ----------------

  void _startStream() {
    _countdownTimer?.cancel();
    _streamTimer?.cancel();
    _streamBag.clear();
    _lastStreamEmoji = null;
    setState(() {
      _phase = _Phase.stream;
      _elapsedSec = 0;
      _currentLine = _generateLine();
      _lineItemIndex = 1; // ilk nesne hemen belirsin
    });
    _startCountdownTimer(_finishStream);
    _scheduleStreamReveal();
  }

  void _startCountdownTimer(VoidCallback onExpire) {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSec++);
      if (_elapsedSec >= _stageDurationSec) onExpire();
    });
  }

  // Aynı satırda aynı nesnenin iki kez görünmesini istemiyoruz — bag'den
  // gelen aday satırda zaten varsa atlanıp bir sonraki çekilir (havuz
  // 12 öğe, satır 5 öğe olduğu için bu neredeyse hiç tekrar gerektirmez).
  List<String> _generateLine() {
    final line = <String>[];
    while (line.length < _itemsPerLine) {
      final candidate = _nextStreamEmoji();
      if (!line.contains(candidate)) line.add(candidate);
    }
    return line;
  }

  // Aktif satırdaki nesneler TEK TEK belirir; satır tamamen dolunca kısa
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

  // "Shuffle bag": havuzun karışık bir kopyasını tüketip bitince yeniden
  // dolduruyor — saf rastgelelik gibi bir nesnenin çok fazla tekrar
  // etmesine izin vermiyor, her tur her nesne tam bir kez çıkıyor. Yeni
  // turun ilk elemanı bir öncekiyle aynıysa yer değiştiriliyor ki aynı
  // nesne art arda (yan yana) gelmesin.
  String _nextStreamEmoji() {
    if (_streamBag.isEmpty) {
      _streamBag.addAll(_objectEmojis);
      _streamBag.shuffle(_random);
      if (_streamBag.length > 1 && _streamBag.last == _lastStreamEmoji) {
        final tmp = _streamBag.last;
        _streamBag[_streamBag.length - 1] = _streamBag[0];
        _streamBag[0] = tmp;
      }
    }
    final next = _streamBag.removeLast();
    _lastStreamEmoji = next;
    return next;
  }

  void _finishStream() {
    _countdownTimer?.cancel();
    _streamTimer?.cancel();
    setState(() {
      _phase = _Phase.scatterIntro;
    });
  }

  // ---------------- 2. BÖLÜM: Görsel Alan (puansız) ----------------

  void _startScatter() {
    _countdownTimer?.cancel();
    _scatterTimer?.cancel();
    setState(() {
      _phase = _Phase.scatter;
      _elapsedSec = 0;
      _scatterObjects = [];
    });
    _startCountdownTimer(_finishScatter);
    _scheduleScatterFlash();
  }

  void _scheduleScatterFlash() {
    // Bu zincir kendi kendini yeniden tetikleyen bir Timer dizisi — bölüm
    // değiştiği anda HER adımda kontrol edilmezse, geçiş sırasında bir
    // adım daha tetiklenip 3. Bölüm'e geçerken gereksiz setState/rebuild
    // tetikleyip BAŞLA'ya dokunmayı bazen kaçırtabiliyordu.
    if (!mounted || _phase != _Phase.scatter) return;
    setState(() => _scatterObjects = _generateSpanObjects());
    _scatterTimer = Timer(
      Duration(milliseconds: _flashMsBySpeed[_speedLevel]),
      () {
        if (!mounted || _phase != _Phase.scatter) return;
        setState(() => _scatterObjects = []);
        _scatterTimer = Timer(const Duration(milliseconds: 350), () {
          if (!mounted || _phase != _Phase.scatter) return;
          _scheduleScatterFlash();
        });
      },
    );
  }

  // Nesneler ekranın her yerine dağılıyor ama merkez odak noktasının
  // üstüne binmiyor, birbirlerine de çok yakın düşmüyor. 2. Bölüm çok zor
  // olmasın diye nesneler odak noktasından FAZLA uzağa gitmiyor (eskiden
  // ekranın kenarlarına kadar dağılıyordu).
  List<_SpanObject> _generateSpanObjects() {
    final list = <_SpanObject>[];
    for (int i = 0; i < _spanObjectCount; i++) {
      double x = 0.5, y = 0.5;
      for (int attempt = 0; attempt < 30; attempt++) {
        x = 0.2 + _random.nextDouble() * 0.6;
        y = 0.22 + _random.nextDouble() * 0.56;
        final dxCenter = x - 0.5;
        final dyCenter = y - 0.5;
        final tooCloseToCenter =
            dxCenter * dxCenter + dyCenter * dyCenter < 0.13 * 0.13;
        final tooCloseToOther = list.any((o) {
          final dx = o.x - x;
          final dy = o.y - y;
          return dx * dx + dy * dy < 0.13 * 0.13;
        });
        if (!tooCloseToCenter && !tooCloseToOther) break;
      }
      final emoji = _objectEmojis[_random.nextInt(_objectEmojis.length)];
      list.add(_SpanObject(_nextObjectId++, emoji, x, y));
    }
    return list;
  }

  void _finishScatter() {
    _countdownTimer?.cancel();
    _scatterTimer?.cancel();
    setState(() {
      _scatterObjects = [];
      _phase = _Phase.quizIntro;
    });
  }

  // ---------------- 3. BÖLÜM: Quiz ----------------

  void _startQuiz() {
    setState(() {
      _phase = _Phase.quiz;
      _quizRoundIndex = 0;
      _quizScore = 0;
    });
    _startQuizRound();
  }

  void _startQuizRound() {
    _quizFlashTimer?.cancel();
    final objects = _generateSpanObjects();
    final counts = <String, int>{};
    for (final o in objects) {
      counts[o.emoji] = (counts[o.emoji] ?? 0) + 1;
    }
    final asked = _objectEmojis[_random.nextInt(_objectEmojis.length)];
    final correctCount = counts[asked] ?? 0;
    // Doğru sayı 0'a veya _spanObjectCount'a çok yakınsa rastgele deneme
    // sonsuz döngüye girebiliyordu (4 farklı sayı asla bulunamıyordu) —
    // bu yüzden olası tüm değerlerden karışık örnekleme yapılıyor.
    final otherValues = [
      for (int i = 0; i <= _spanObjectCount; i++)
        if (i != correctCount) i,
    ]..shuffle(_random);
    final options = [correctCount, ...otherValues.take(3)]..shuffle(_random);

    setState(() {
      _quizObjects = objects;
      _quizCounts = counts;
      _quizAskedEmoji = asked;
      _quizOptions = options;
      _quizSelected = null;
      _quizAnnouncing = true;
      _quizShowingObjects = false;
    });

    _quizFlashTimer = Timer(const Duration(milliseconds: _quizAnnounceMs), () {
      if (!mounted) return;
      setState(() {
        _quizAnnouncing = false;
        _quizShowingObjects = true;
      });
      _quizFlashTimer = Timer(
        Duration(milliseconds: _flashMsBySpeed[_speedLevel]),
        () {
          if (!mounted) return;
          setState(() => _quizShowingObjects = false);
        },
      );
    });
  }

  void _answerQuiz(int selected) {
    if (_quizSelected != null) return;
    final correctCount = _quizCounts[_quizAskedEmoji] ?? 0;
    final isCorrect = selected == correctCount;
    setState(() => _quizSelected = selected);
    if (isCorrect) {
      SoundManager.playCorrect();
      _quizScore++;
    } else {
      SoundManager.playGentleTap();
    }
    Future.delayed(const Duration(milliseconds: 1200), () {
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
    _countdownTimer?.cancel();
    _streamTimer?.cancel();
    _scatterTimer?.cancel();
    _quizFlashTimer?.cancel();
    _hasCompletedOnce = true;

    final percent = ((_quizScore / _quizRoundCount) * 100).round();
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Görsel Genişlik',
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
            Text('Quiz sonucu: $_quizScore / $_quizRoundCount (%$percent)'),
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
              setState(() {
                _phase = _Phase.streamIntro;
                _elapsedSec = 0;
                _quizScore = 0;
                _quizRoundIndex = 0;
              });
            },
            child: const Text('Yeniden Başlat'),
          ),
        ],
      ),
    );
  }

  void _pauseGame() {
    _countdownTimer?.cancel();
    _streamTimer?.cancel();
    _scatterTimer?.cancel();
    _quizFlashTimer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resumeGame() {
    setState(() => _isPaused = false);
    switch (_phase) {
      case _Phase.stream:
        _startCountdownTimer(_finishStream);
        _scheduleStreamReveal();
      case _Phase.scatter:
        _startCountdownTimer(_finishScatter);
        _scheduleScatterFlash();
      case _Phase.quiz:
        if (_quizAnnouncing) {
          _quizFlashTimer = Timer(
            const Duration(milliseconds: _quizAnnounceMs),
            () {
              if (!mounted) return;
              setState(() {
                _quizAnnouncing = false;
                _quizShowingObjects = true;
              });
              _quizFlashTimer = Timer(
                Duration(milliseconds: _flashMsBySpeed[_speedLevel]),
                () {
                  if (!mounted) return;
                  setState(() => _quizShowingObjects = false);
                },
              );
            },
          );
        } else if (_quizShowingObjects) {
          _quizFlashTimer = Timer(
            Duration(milliseconds: _flashMsBySpeed[_speedLevel]),
            () {
              if (!mounted) return;
              setState(() => _quizShowingObjects = false);
            },
          );
        }
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompletionPopScope(
      isCompleted: () => _hasCompletedOnce,
      child: Scaffold(
        appBar: AppBar(title: const Text('👁️ Görsel Genişlik')),
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
      case _Phase.scatterIntro:
        return KeyedSubtree(
          key: const ValueKey('scatter-intro'),
          child: _buildScatterIntro(),
        );
      case _Phase.scatter:
        return KeyedSubtree(
          key: const ValueKey('scatter-flow'),
          child: _buildScatterFlow(),
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

  // Dar/kısa ekranlarda taşma olmasın diye kaydırılabilir, gruplar
  // arasında (sığdığı sürece) boşluk bırakan ortak intro şablonu.
  Widget _buildIntro({
    required String badge,
    required String emoji,
    required String instruction,
    required VoidCallback onStart,
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
          'Nesneler soldan sağa tek tek belirip satırda yan yana duracak. Satır '
          'dolunca hepsi birden kaybolup yeniden başlayacak — hız arttıkça '
          'daha hızlı belirecekler!',
      onStart: _startStream,
    );
  }

  Widget _buildScatterIntro() {
    return _buildIntro(
      badge: '2. Bölüm · Görsel Alan',
      emoji: '🎯',
      instruction:
          'Ortadaki noktaya sabit bak, gözlerini oynatma. Nesneler ekranın her '
          'yerinde kısaca belirip kaybolacak — onları çevresel görüşünle '
          'fark etmeye çalış!',
      onStart: _startScatter,
    );
  }

  Widget _buildQuizIntro() {
    return _buildIntro(
      badge: '3. Bölüm · Ne Kadar Gördün?',
      emoji: '❓',
      instruction:
          'Aynı şekilde ortadaki noktaya bak. Nesneler kısaca görünecek, sonra '
          'kaybolup sana "kaç tane gördün?" diye soracağız — doğru cevap puan '
          'kazandırır!',
      onStart: _startQuiz,
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
    bool showTimer = true,
    bool showPause = true,
  }) {
    final remaining = _stageDurationSec - _elapsedSec;
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
            if (showTimer)
              Text(
                'Süre: $remaining sn',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: remaining <= 10 ? Colors.red : Colors.orange,
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
    return Column(
      children: [
        _stageHeader('1. Bölüm · Satır Akışı'),
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
                // Klasör 1'deki Nesne Akışı gibi: nesneler soldan sağa TEK
                // TEK belirip sabit bir satırda yan yana durur, uçuşmaz.
                // Bilerek Center DEĞİL, sola yaslı: ortalanmış olsaydı her
                // yeni nesne eklendiğinde satırın tamamı yeniden ortalanıp
                // nesneler "ortadan çıkıyormuş" gibi kayıyordu.
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    alignment: WrapAlignment.start,
                    runSpacing: 12,
                    children: [
                      for (int i = 0; i < _lineItemIndex; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
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
                              style: const TextStyle(fontSize: 40),
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

  // Merkez odak noktası — 2. ve 3. Bölüm'de öğrencinin gözünü sabit
  // tutması gereken yer.
  Widget _centerFocusDot() {
    return Center(
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _color,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(color: _color.withValues(alpha: 0.5), blurRadius: 8),
          ],
        ),
      ),
    );
  }

  Widget _spanObjectsLayer(List<_SpanObject> objects) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            for (final o in objects)
              Positioned(
                key: ValueKey(o.id),
                left: o.x * constraints.maxWidth - 22,
                top: o.y * constraints.maxHeight - 22,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  builder: (context, t, child) =>
                      Opacity(opacity: t, child: child),
                  child: Text(o.emoji, style: const TextStyle(fontSize: 34)),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildScatterFlow() {
    return Column(
      children: [
        _stageHeader('2. Bölüm · Görsel Alan'),
        const SizedBox(height: 10),
        _speedChipRow(),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Stack(
              children: [_centerFocusDot(), _spanObjectsLayer(_scatterObjects)],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _skipButton(_finishScatter),
      ],
    );
  }

  Widget _buildQuizFlow() {
    return Column(
      children: [
        _stageHeader(
          '3. Bölüm · Soru ${_quizRoundIndex + 1}/$_quizRoundCount',
          showTimer: false,
          showPause:
              !_quizAnnouncing && _quizShowingObjects && _quizSelected == null,
        ),
        const SizedBox(height: 10),
        _speedChipRow(),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _quizAnnouncing
                ? _buildQuizAnnounce()
                : (_quizShowingObjects
                      ? Stack(
                          children: [
                            _centerFocusDot(),
                            _spanObjectsLayer(_quizObjects),
                          ],
                        )
                      : _buildQuizQuestion()),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizAnnounce() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Şimdi bunu sayacaksın:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Text(_quizAskedEmoji, style: const TextStyle(fontSize: 72)),
        ],
      ),
    );
  }

  Widget _buildQuizQuestion() {
    final correctCount = _quizCounts[_quizAskedEmoji] ?? 0;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_quizAskedEmoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          const Text(
            'Kaç tane gördün?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              for (final option in _quizOptions)
                _quizOptionButton(option, correctCount),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quizOptionButton(int option, int correctCount) {
    final answered = _quizSelected != null;
    final isSelected = _quizSelected == option;
    final isCorrectOption = option == correctCount;
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
        onPressed: answered ? null : () => _answerQuiz(option),
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

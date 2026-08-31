import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';

enum _Phase {
  reactionIntro,
  reaction,
  zigzagIntro,
  zigzag,
  crossZigzagIntro,
  crossZigzag,
}

/// Klasör 2'nin ilk etkinliği: "Hızlı Top / Gülümseyen Yüz". Öğretmen
/// dokümanındaki alt bölümlerin uyarlaması:
/// 1) "Hızlı Görüş" — puansız, dokunma gerektirmeyen bir görsel algı
/// egzersizi: tek bir nesne sırayla satır başı/ortası/sonu, çapraz (X),
/// aşağıdan yukarı ve yukarıdan aşağı noktalarda çeyrek saniyeliğine
/// belirip kayboluyor, öğrenci sadece izliyor,
/// 2) "Zikzak Takip" — kitaptaki dağınık nokta ağı deseninde cümleler
/// sırayla gösterilir (Etkinlik 6 tarzı), aktif nokta kendiliğinden sırayla
/// vurgulanır, öğrenci gözleriyle takip eder (her cümle 60 sn),
/// 3) "Çapraz Zikzak" — kelimeler iki satırda, çapraz (X) çizgilerle
/// bağlı durur (Etkinlik 7 tarzı), aynı şekilde takip edilir.
class QuickFocusZigzagPage extends StatefulWidget {
  const QuickFocusZigzagPage({super.key});

  @override
  State<QuickFocusZigzagPage> createState() => _QuickFocusZigzagPageState();
}

class _QuickFocusZigzagPageState extends State<QuickFocusZigzagPage> {
  // Öğrenci bir aşamayı bitirmeden diğerine geçemesin diye SONRAKİ BÖLÜM
  // (skip) butonu kaldırıldı — her aşama tam 30 saniye sürüyor.
  static const int _stageDurationSec = 30;

  // Hızı öğrenci kendi seçer — her 3 bölüm de bu ortak seviyeden besleniyor,
  // değişiklik bir sonraki tetiklemede devreye girer.
  static const List<String> _speedLabels = [
    'Yavaş',
    'Orta',
    'Hızlı',
    'Çok Hızlı',
  ];
  static const List<int> _zigzagStepMsBySpeed = [1300, 900, 600, 400];
  int _speedLevel = 1;

  // 1. Bölüm: Hızlı Görüş — tek bir nesne çok kısa süreliğine belirip
  // kayboluyor. Puansız, dokunma gerektirmeyen bir görsel algı egzersizi.
  // Aşamalar sırayla işleniyor: satır başı → ortası → sonu → çapraz (X) →
  // aşağıdan yukarı → yukarıdan aşağı. Koordinatlar 0..1 aralığında,
  // kutunun genişlik/yüksekliğine oranlı. Gösterim süresi de hız
  // seviyesine göre değişir.
  // Çok Hızlı: 250ms görünür + 0ms boşluk = tam 1 saniyede 4 nesne.
  static const List<int> _flashVisibleMsBySpeed = [400, 300, 250, 250];
  static const List<int> _flashGapMsBySpeed = [400, 300, 250, 0];
  static const List<List<Offset>> _flashStagePoints = [
    // Sabit konumlu aşamalarda (satır başı/ortası/sonu) nesne tek bir kez
    // belirip kayboluyor — aynı noktada tekrar tekrar gösterilirse "yanıp
    // sönme" gibi göründüğü için bilerek tek noktalı liste kullanılıyor.
    [Offset(0.15, 0.5)],
    [Offset(0.5, 0.5)],
    [Offset(0.85, 0.5)],
    [
      Offset(0.15, 0.15),
      Offset(0.5, 0.5),
      Offset(0.85, 0.85),
      Offset(0.85, 0.15),
      Offset(0.5, 0.5),
      Offset(0.15, 0.85),
    ],
    [
      Offset(0.5, 0.85),
      Offset(0.5, 0.65),
      Offset(0.5, 0.5),
      Offset(0.5, 0.35),
      Offset(0.5, 0.15),
    ],
    [
      Offset(0.5, 0.15),
      Offset(0.5, 0.35),
      Offset(0.5, 0.5),
      Offset(0.5, 0.65),
      Offset(0.5, 0.85),
    ],
  ];
  static const List<String> _flashStageLabels = [
    'Satır Başı',
    'Satır Ortası',
    'Satır Sonu',
    'Çapraz',
    'Aşağıdan Yukarı',
    'Yukarıdan Aşağı',
  ];

  // "Zikzak Takip" cümleleri sırayla işler, her biri kendi turu (60 sn).
  static const List<List<String>> _zigzagSentences = [
    // Öğretmenin "Etkinlik 6" sayfasındaki dağınık nokta ağı — bağlantı
    // çizgilerini doğru sırayla takip edince oluşan cümle.
    [
      'Bir',
      'hedefim',
      'var:',
      'daha',
      'hızlı',
      'anlamak,',
      'sürekli',
      'daha',
      'hızlı',
      'öğrenmek',
      've',
      'daha',
      'hızlı',
      'okumak,',
      'daha',
      'da',
      'yükselmek',
      've',
      'başarılı',
      'olmak...',
      'çünkü',
      'hız',
      'çağındayız,',
      'geride',
      'kalmamak',
      'gerek...',
    ],
  ];

  // "Çapraz Zikzak" (3. Bölüm): kelimeler iki sabit satırda durur, her
  // sütunda üst-alt çapraz (X) çizgilerle komşu sütuna bağlanır. Okuma
  // sırası sütun sütun ilerler, her sütunda tek satır (sırayla üst-alt-
  // üst-alt...) okunur — sütun indeksi çift ise üst, tek ise alt.
  static const List<List<String>> _crossZigzagTop = [
    ['Başarmak', 'başarının', 'İlk', 'çünkü', 'kendine', 'başarı da', 'inanç'],
    ['Kitap', 'anla', 'güneşidir,', 'al', 'ışığı,', 'uygula', 'ilacıdır.'],
    [
      'Zahmetsiz',
      'zorluk',
      'olmaz,',
      'kolaylık',
      'yemek',
      'baş',
      'dikensiz',
      'başarı',
      'olmaz,',
    ],
  ];
  static const List<List<String>> _crossZigzagBottom = [
    ['yarısıdır.', 'için', 'inanmak', 'şart', 'yoktur', 'inanmalısın', 'yoksa'],
    [
      'okuduğunu',
      'hayatımızın',
      'not',
      'ruhumuzun',
      'öğrendiğini',
      'aklımızın',
      'oku',
    ],
    [
      'yani',
      'rahmet',
      'olmadan',
      'emeksiz',
      'olmaz,',
      'olmaz,',
      'koymadan',
      'gül',
      'olmaz.',
    ],
  ];

  // Zikzak bölümleri uygulamanın kendi ana marka rengini (indigo) kullanır.
  static const Color _zigzagColor = Color(0xFF4F46E5);

  _Phase _phase = _Phase.reactionIntro;
  bool _hasCompletedOnce = false;
  bool _isPaused = false;

  // Ortak: her bölümün 60 sn'lik geri sayımı.
  int _elapsedSec = 0;
  Timer? _countdownTimer;

  // 1. Bölüm: Hızlı Görüş.
  int _flashStageIndex = 0;
  int _flashPointIndex = 0;
  Offset? _flashPosition; // null: aradaki boşluk (nesne görünmüyor)
  Timer? _flashTimer;

  // 2. Bölüm: Zikzak Takip — cümleler sırayla.
  static const int _zigzagWordsPerRow = 5;
  static const double _zigzagRowHeight = 130.0;
  int _zigzagRoundIndex = 0;
  int _zigzagActiveIndex = 0;
  Timer? _zigzagTimer;
  final ScrollController _zigzagScrollController = ScrollController();

  // 3. Bölüm: Çapraz Zikzak — aynı zamanlama mekanizması (_zigzagActiveIndex,
  // _zigzagTimer) yeniden kullanılır, sadece hangi cümlede olduğumuz ayrı
  // tutulur.
  int _crossZigzagRoundIndex = 0;

  @override
  void initState() {
    super.initState();
    _syncOrientationForPhase();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _flashTimer?.cancel();
    _zigzagTimer?.cancel();
    _zigzagScrollController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  // Sadece 3. Bölüm (Çapraz Zikzak) genişlik istiyor — o yüzden yatay
  // sadece o bölümde açılıyor, diğer bölümlerde dikeyde kalınıyor.
  void _syncOrientationForPhase() {
    final needsLandscape =
        _phase == _Phase.crossZigzagIntro || _phase == _Phase.crossZigzag;
    SystemChrome.setPreferredOrientations(
      needsLandscape
          ? [
              DeviceOrientation.portraitUp,
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
    );
  }

  // ---------------- 1. BÖLÜM: Hızlı Görüş ----------------
  // Puansız, dokunma gerektirmeyen bir görsel algı egzersizi: tek bir
  // nesne sırasıyla farklı aşamalarda (satır başı/ortası/sonu, çapraz,
  // aşağıdan yukarı, yukarıdan aşağı) çeyrek saniyeliğine belirip
  // kayboluyor. Öğrenci sadece izliyor, gözünü o noktaya götürüyor.

  void _startFlashSequence() {
    _countdownTimer?.cancel();
    _flashTimer?.cancel();
    setState(() {
      _phase = _Phase.reaction;
      _flashStageIndex = 0;
      _flashPointIndex = 0;
      _flashPosition = null;
    });
    _scheduleNextFlash();
  }

  void _scheduleNextFlash() {
    if (!mounted || _phase != _Phase.reaction) return;
    if (_flashStageIndex >= _flashStagePoints.length) {
      _finishFlashSequence();
      return;
    }
    final points = _flashStagePoints[_flashStageIndex];
    setState(() => _flashPosition = points[_flashPointIndex]);
    _flashTimer = Timer(
      Duration(milliseconds: _flashVisibleMsBySpeed[_speedLevel]),
      () {
        if (!mounted || _phase != _Phase.reaction) return;
        setState(() => _flashPosition = null);
        _flashTimer = Timer(
          Duration(milliseconds: _flashGapMsBySpeed[_speedLevel]),
          () {
            if (!mounted || _phase != _Phase.reaction) return;
            _flashPointIndex++;
            if (_flashPointIndex >= points.length) {
              _flashPointIndex = 0;
              _flashStageIndex++;
            }
            _scheduleNextFlash();
          },
        );
      },
    );
  }

  void _finishFlashSequence() {
    _countdownTimer?.cancel();
    _flashTimer?.cancel();
    setState(() {
      _flashPosition = null;
      _zigzagRoundIndex = 0;
      _phase = _Phase.zigzagIntro;
    });
    _syncOrientationForPhase();
  }

  // ---------------- 2. BÖLÜM: Zikzak Takip (cümleler) ----------------

  void _startZigzagRound() {
    _countdownTimer?.cancel();
    setState(() {
      _phase = _Phase.zigzag;
      _elapsedSec = 0;
      _zigzagActiveIndex = 0;
    });
    _syncOrientationForPhase();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _zigzagScrollController.hasClients) {
        _zigzagScrollController.jumpTo(0);
      }
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSec++);
      if (_elapsedSec >= _stageDurationSec) _finishZigzagRound();
    });
    _scheduleZigzagStep(_zigzagSentences[_zigzagRoundIndex].length);
  }

  void _scheduleZigzagStep(int total) {
    _zigzagTimer = Timer(
      Duration(milliseconds: _zigzagStepMsBySpeed[_speedLevel]),
      () {
        if (!mounted) return;
        final next = _zigzagActiveIndex + 1;
        // Çapraz Zikzak'ta cümle bir kez okununca başa DÖNMÜYOR — otomatik
        // olarak sıradaki cümleye geçiyor (ya da son cümleyse bitiyor).
        if (_phase == _Phase.crossZigzag && next >= total) {
          _finishCrossZigzagRound();
          return;
        }
        setState(() => _zigzagActiveIndex = next % total);
        if (_phase == _Phase.zigzag) _scrollZigzagToActive();
        _scheduleZigzagStep(total);
      },
    );
  }

  // Uzun cümleler satırlara bölündüğü için, aktif kelime alt satıra
  // geçtiğinde görünüm de onunla birlikte kaysın — takip kopmasın.
  void _scrollZigzagToActive() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_zigzagScrollController.hasClients) return;
      final row = _zigzagActiveIndex ~/ _zigzagWordsPerRow;
      final targetY = row * _zigzagRowHeight;
      final viewport = _zigzagScrollController.position.viewportDimension;
      final targetOffset = (targetY - viewport / 2 + _zigzagRowHeight / 2)
          .clamp(0.0, _zigzagScrollController.position.maxScrollExtent);
      _zigzagScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _finishZigzagRound() {
    _countdownTimer?.cancel();
    _zigzagTimer?.cancel();
    if (_zigzagRoundIndex < _zigzagSentences.length - 1) {
      setState(() {
        _zigzagRoundIndex++;
        _phase = _Phase.zigzagIntro;
      });
    } else {
      setState(() {
        _crossZigzagRoundIndex = 0;
        _phase = _Phase.crossZigzagIntro;
      });
    }
    _syncOrientationForPhase();
  }

  // ---------------- 3. BÖLÜM: Çapraz Zikzak (cümleler) ----------------

  void _startCrossZigzagRound() {
    _countdownTimer?.cancel();
    setState(() {
      _phase = _Phase.crossZigzag;
      _elapsedSec = 0;
      _zigzagActiveIndex = 0;
    });
    _syncOrientationForPhase();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSec++);
      if (_elapsedSec >= _stageDurationSec) _finishCrossZigzagRound();
    });
    // Çizgiler sadece "gidiş" yönünde değil — son sütuna varınca çizgi
    // GERİ dönüp bu kez öbür satırı takip ederek başa kadar devam ediyor
    // (ör. "...inanmalısın, inanç yoksa başarı da yoktur, çünkü..."). Bu
    // yüzden toplam adım sayısı 2×sütun: gidiş + dönüş.
    _scheduleZigzagStep(_crossZigzagTop[_crossZigzagRoundIndex].length * 2);
  }

  void _finishCrossZigzagRound() {
    _countdownTimer?.cancel();
    _zigzagTimer?.cancel();
    if (_crossZigzagRoundIndex < _crossZigzagTop.length - 1) {
      // Aynı bölüm içinde bir sonraki cümleye geçerken tekrar BAŞLA
      // ekranı istenmiyor — doğrudan sonraki cümleyle devam ediliyor.
      _crossZigzagRoundIndex++;
      _startCrossZigzagRound();
    } else {
      _finishAll();
    }
  }

  void _finishAll() {
    _countdownTimer?.cancel();
    _zigzagTimer?.cancel();
    _hasCompletedOnce = true;

    // 1. Bölüm artık puansız (izleme amaçlı) olduğu için dikkat puanı,
    // tamamlanan zikzak cümle sayısına dayanıyor.
    ProgressManager.recordAttentionScore(100);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Hızlı Odaklanma',
      result:
          'Hızlı Görüş tamamlandı · ${_zigzagSentences.length} zikzak cümlesi tamamlandı',
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
            const Text('Hızlı Görüş bölümü tamamlandı.'),
            Text(
              'Zikzak Takip\'in ${_zigzagSentences.length} cümlesi de tamamlandı.',
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
              Navigator.pop(context); // dialogu kapat
              Navigator.pop(
                context,
                true,
              ); // geri dön, tamamlandı olarak işaretle
            },
            child: const Text('Bitir'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _phase = _Phase.reactionIntro;
                _flashStageIndex = 0;
                _flashPointIndex = 0;
                _flashPosition = null;
                _elapsedSec = 0;
                _zigzagRoundIndex = 0;
                _zigzagActiveIndex = 0;
                _crossZigzagRoundIndex = 0;
              });
              _syncOrientationForPhase();
            },
            child: const Text('Yeniden Başlat'),
          ),
        ],
      ),
    );
  }

  void _pauseGame() {
    _countdownTimer?.cancel();
    _flashTimer?.cancel();
    _zigzagTimer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resumeGame() {
    setState(() => _isPaused = false);
    switch (_phase) {
      case _Phase.reaction:
        _scheduleNextFlash();
      case _Phase.zigzag:
        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          setState(() => _elapsedSec++);
          if (_elapsedSec >= _stageDurationSec) _finishZigzagRound();
        });
        _scheduleZigzagStep(_zigzagSentences[_zigzagRoundIndex].length);
      case _Phase.crossZigzag:
        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          setState(() => _elapsedSec++);
          if (_elapsedSec >= _stageDurationSec) _finishCrossZigzagRound();
        });
        _scheduleZigzagStep(_crossZigzagTop[_crossZigzagRoundIndex].length * 2);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final needsLandscape =
        _phase == _Phase.crossZigzagIntro || _phase == _Phase.crossZigzag;
    // Yatay modda dikey alan kısıtlı — üst çubuk daha az yer kaplasın diye
    // küçültülüyor, kelimelere daha fazla alan kalıyor.
    return CompletionPopScope(
      isCompleted: () => _hasCompletedOnce,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('😊 Hızlı Odaklanma'),
          toolbarHeight: needsLandscape ? 40 : kToolbarHeight,
          titleTextStyle: needsLandscape
              ? const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                )
              : null,
        ),
        body: Padding(
          padding: EdgeInsets.all(needsLandscape ? 12 : 20),
          child: OrientationBuilder(
            builder: (context, orientation) {
              if (needsLandscape && orientation == Orientation.portrait) {
                return _buildRotatePrompt();
              }
              return Stack(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildBody(),
                  ),
                  if (_isPaused)
                    buildPauseOverlay(
                      color: const Color(0xFF2563EB),
                      onResume: _resumeGame,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRotatePrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            builder: (context, t, child) {
              return Transform.rotate(angle: t * 1.5708, child: child);
            },
            child: const Icon(
              Icons.screen_rotation_rounded,
              size: 88,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Telefonunu yan çevir',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu etkinlik yatay ekranda daha rahat oynanır.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _Phase.reactionIntro:
        return KeyedSubtree(
          key: const ValueKey('reaction-intro'),
          child: _buildReactionIntro(),
        );
      case _Phase.reaction:
        return KeyedSubtree(
          key: const ValueKey('reaction-flow'),
          child: _buildReactionFlow(),
        );
      case _Phase.zigzagIntro:
        return KeyedSubtree(
          key: ValueKey('zigzag-intro-$_zigzagRoundIndex'),
          child: _buildZigzagIntro(),
        );
      case _Phase.zigzag:
        return KeyedSubtree(
          key: ValueKey('zigzag-flow-$_zigzagRoundIndex'),
          child: _buildZigzagFlow(),
        );
      case _Phase.crossZigzagIntro:
        return KeyedSubtree(
          key: ValueKey('cross-zigzag-intro-$_crossZigzagRoundIndex'),
          child: _buildCrossZigzagIntro(),
        );
      case _Phase.crossZigzag:
        return KeyedSubtree(
          key: ValueKey('cross-zigzag-flow-$_crossZigzagRoundIndex'),
          child: _buildCrossZigzagFlow(),
        );
    }
  }

  Widget _buildIntro({
    required String badge,
    required Color color,
    required String emoji,
    required String instruction,
    required VoidCallback onStart,
    Widget? extra,
  }) {
    // Dar (yatay) ekranlarda içerik sığmayabilir — Spacer() ile taşma riski
    // vardı. Bunun yerine kaydırılabilir bir kolon kullanılıyor: içerik
    // sığarsa gruplar arasında boşluk bırakılır (spaceBetween), sığmazsa
    // BAŞLA butonu ekran dışında KALMAZ, sadece kaydırılır.
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
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Amaç/Yöntem kutusu ekranın ORTASINDA, emojiyle
                    // birlikte tek grup olarak duruyor — sayfanın en
                    // üstüne sıkışmıyor.
                    if (extra != null) ...[extra, const SizedBox(height: 16)],
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
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: color,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              instruction,
                              style: TextStyle(
                                fontSize: 13,
                                color: color,
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
                        backgroundColor: color,
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

  Widget _buildReactionIntro() {
    return _buildIntro(
      badge: '1. Bölüm · Hızlı Görüş',
      color: const Color(0xFF2563EB),
      emoji: '😊',
      instruction:
          'Ekranda bir nesne çok kısa süreliğine belirip kaybolacak. Dokunmana '
          'gerek yok, sadece izle — gözünü nesnenin göründüğü noktaya götür!',
      onStart: _startFlashSequence,
      extra: _speedChipRow(const Color(0xFF2563EB)),
    );
  }

  Widget _buildZigzagIntro() {
    return _buildIntro(
      badge:
          '2. Bölüm · Zikzak Takip · Cümle ${_zigzagRoundIndex + 1}/${_zigzagSentences.length}',
      color: _zigzagColor,
      emoji: '🔀',
      instruction:
          'Noktalar ekranda dağınık duracak, aktif olan kendiliğinden sırayla '
          'vurgulanacak. Başını oynatmadan, sadece gözlerinle noktayı takip et — doğru sırayla '
          'okuyunca bir cümle oluşacak. 60 saniye sürecek!',
      onStart: _startZigzagRound,
      extra: _buildAmacYontemBox(seconds: 10),
    );
  }

  // Kitaptaki sayfaların başındaki "Amaç / Yöntem" kutusu — öğretmenin
  // görselinde olduğu gibi.
  Widget _buildAmacYontemBox({required int seconds}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E7FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4F46E5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text.rich(
            textAlign: TextAlign.center,
            TextSpan(
              style: const TextStyle(fontSize: 13, color: Color(0xFF312E81)),
              children: [
                const TextSpan(
                  text: 'Amaç: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(
                  text: 'Gözün hareketlerini ve odaklanmasını hızlandırmak.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text.rich(
            textAlign: TextAlign.center,
            TextSpan(
              style: const TextStyle(fontSize: 13, color: Color(0xFF312E81)),
              children: [
                const TextSpan(
                  text: 'Yöntem: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      'Noktalardaki kelimeleri birleştirerek sayfayı $seconds saniyede bitiriniz.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrossZigzagIntro() {
    return _buildIntro(
      badge:
          '3. Bölüm · Çapraz Zikzak · Cümle ${_crossZigzagRoundIndex + 1}/${_crossZigzagTop.length}',
      color: _zigzagColor,
      emoji: '✖️',
      instruction:
          'Kelimeler iki satırda, çapraz (X) çizgilerle bağlı duracak. Aktif olan kendiliğinden '
          'sırayla vurgulanacak — gözlerinle çapraz çizgiyi takip et, doğru sırayla okuyunca bir '
          'cümle oluşacak. Cümle bitince otomatik olarak sıradaki cümleye geçilecek!',
      onStart: _startCrossZigzagRound,
      extra: _buildAmacYontemBox(seconds: 30),
    );
  }

  Widget _speedChipRow(Color color) {
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
            selectedColor: color,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _speedLevel == i ? Colors.white : color,
            ),
            backgroundColor: color.withValues(alpha: 0.08),
            side: BorderSide(
              color: color.withValues(alpha: _speedLevel == i ? 1 : 0.3),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ],
    );
  }

  Widget _buildReactionFlow() {
    const color = Color(0xFF2563EB);
    final stageCount = _flashStagePoints.length;
    final stageLabel = _flashStageIndex < _flashStageLabels.length
        ? _flashStageLabels[_flashStageIndex]
        : _flashStageLabels.last;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '1. Bölüm · Hızlı Görüş',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ),
            buildPauseButton(color: color, onPressed: _pauseGame),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Aşama ${(_flashStageIndex + 1).clamp(1, stageCount)}/$stageCount · $stageLabel',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (_flashStageIndex / stageCount).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 10),
        _speedChipRow(color),
        const SizedBox(height: 12),
        Text(
          'Sadece izle, dokunmana gerek yok.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: 12),
        // Kutulu bir kart DEĞİL: nesne gerçekten ekranın her tarafında
        // (tüm boş alanda) belirsin diye sınırsız, tam alanlı — sadece
        // arka plana yumuşak bir gradyan verildi, sönük durmasın.
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.06),
                  const Color(0xFF0D9488).withValues(alpha: 0.06),
                ],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final pos = _flashPosition;
                return Stack(
                  children: [
                    if (pos != null)
                      Positioned(
                        left: pos.dx * constraints.maxWidth - 32,
                        top: pos.dy * constraints.maxHeight - 32,
                        child: IgnorePointer(child: _reactionBubble()),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // Aktif (yanıp sönen) hedef canlı ve büyük duruyor; diğerleri sadece
  // dikkat dağıtıcı olarak soluk ve sabit kalıyor — öğrenci ikisini
  // ayırt edip doğru olana basmaya çalışıyor.
  // Flaş anında beliren tek nesne — sıçrayan/büyüyen bir animasyon YOK
  // (hızlı turlarda "yanıp sönüyor" gibi göründüğü için kaldırıldı):
  // nesne olduğu gibi belirip, olduğu gibi kayboluyor.
  Widget _reactionBubble() {
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF3C4), Color(0xFFFFCA28)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.55),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Text('😊', style: TextStyle(fontSize: 30)),
    );
  }

  Widget _buildZigzagFlow() {
    final labels = _zigzagSentences[_zigzagRoundIndex];
    final color = _zigzagColor;
    final badge =
        '2. Bölüm · Zikzak Takip · Cümle ${_zigzagRoundIndex + 1}/${_zigzagSentences.length}';
    final n = labels.length;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Süre: ${_stageDurationSec - _elapsedSec} sn',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: (_stageDurationSec - _elapsedSec) <= 10
                        ? Colors.red
                        : Colors.orange,
                  ),
                ),
                buildPauseButton(color: color, onPressed: _pauseGame),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        _speedChipRow(color),
        const SizedBox(height: 12),
        Expanded(
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                // Uzun cümleler TEK satıra sıkıştırılınca noktalar üst
                // üste biniyordu — bu yüzden kelimeler birkaç kelimelik
                // SATIRLARA bölünüyor (her satır kendi içinde çapraz
                // zikzak yapar), gerekirse dikeyde kaydırılır. Böylece
                // her kelime, cümle ne kadar uzun olursa olsun, her zaman
                // büyük ve oranlı kalır.
                const wordsPerRow = _zigzagWordsPerRow;
                const rowHeight = _zigzagRowHeight;
                final numRows = (n / wordsPerRow).ceil();
                final canvasHeight = max(
                  constraints.maxHeight,
                  numRows * rowHeight + 40,
                );
                final positions = List.generate(n, (i) {
                  final row = i ~/ wordsPerRow;
                  final rowStart = row * wordsPerRow;
                  final itemsInRow = min(wordsPerRow, n - rowStart);
                  final colInRow = i - rowStart;
                  final x = itemsInRow <= 1
                      ? w / 2
                      : (colInRow / (itemsInRow - 1)) * (w - 110) + 55;
                  final y =
                      row * rowHeight +
                      (colInRow.isEven ? rowHeight * 0.3 : rowHeight * 0.75);
                  return Offset(x, y);
                });
                return SingleChildScrollView(
                  controller: _zigzagScrollController,
                  child: SizedBox(
                    width: w,
                    height: canvasHeight,
                    child: Stack(
                      children: [
                        CustomPaint(
                          size: Size(w, canvasHeight),
                          painter: _ZigzagPainter(
                            positions: positions,
                            color: color,
                          ),
                        ),
                        // Kitaptaki gibi: bağlantı noktası küçük bir nokta,
                        // kelime/sayı de bu noktanın TAM ÜSTÜNDE duruyor —
                        // büyük renkli kutu değil.
                        for (int i = 0; i < n; i++)
                          Builder(
                            builder: (_) {
                              final isActive = i == _zigzagActiveIndex;
                              return Positioned(
                                left: positions[i].dx - 55,
                                top: positions[i].dy - 40,
                                child: SizedBox(
                                  width: 110,
                                  child: Text(
                                    labels[i],
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.visible,
                                    style: TextStyle(
                                      fontWeight: isActive
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      fontSize: isActive ? 20 : 16,
                                      color: isActive
                                          ? color
                                          : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        for (int i = 0; i < n; i++)
                          Builder(
                            builder: (_) {
                              final isActive = i == _zigzagActiveIndex;
                              final dotSize = isActive ? 22.0 : 14.0;
                              return Positioned(
                                left: positions[i].dx - dotSize / 2,
                                top: positions[i].dy - dotSize / 2,
                                child: Container(
                                  width: dotSize,
                                  height: dotSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isActive
                                        ? color
                                        : const Color(0xFF334155),
                                    boxShadow: isActive
                                        ? [
                                            BoxShadow(
                                              color: color.withValues(
                                                alpha: 0.5,
                                              ),
                                              blurRadius: 12,
                                              spreadRadius: 3,
                                            ),
                                          ]
                                        : [],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCrossZigzagFlow() {
    final top = _crossZigzagTop[_crossZigzagRoundIndex];
    final bottom = _crossZigzagBottom[_crossZigzagRoundIndex];
    final color = _zigzagColor;
    final n = top.length;
    final badge =
        '3. Bölüm · Çapraz Zikzak · Cümle ${_crossZigzagRoundIndex + 1}/${_crossZigzagTop.length}';
    // Yatay modda dikey alan kısıtlı olduğu için üst kısım (rozet/hız
    // satırı) daha az yer kaplayacak şekilde sıkıştırıldı; kart yana
    // KAYMAZ — kelimeler her zaman ekran genişliğine sığacak şekilde
    // yerleştirilir.
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 12,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Süre: ${_stageDurationSec - _elapsedSec} sn',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: (_stageDurationSec - _elapsedSec) <= 10
                        ? Colors.red
                        : Colors.orange,
                  ),
                ),
                buildPauseButton(color: color, onPressed: _pauseGame),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        _speedChipRow(color),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Tuval her zaman ekranın TAM genişliğinde — yatay kaydırma
                // yok, sütun payı kelime sayısına göre otomatik ayarlanıyor.
                final canvasWidth = constraints.maxWidth;
                final h = constraints.maxHeight;
                final colWidth = canvasWidth / n;
                final topY = h * 0.28;
                final bottomY = h * 0.72;
                // Kelime sayısı arttıkça sütun payı daralıyor — etiket
                // genişliği ve yazı boyutu buna göre küçültülüyor ki
                // komşu kelimeler birbirine girmesin.
                final labelWidth = (colWidth - 6).clamp(48.0, 120.0);
                final baseFont = colWidth < 90 ? 13.0 : 16.0;
                final activeFont = colWidth < 90 ? 16.0 : 20.0;
                final xs = List.generate(n, (i) => i * colWidth + colWidth / 2);
                final topPositions = List.generate(
                  n,
                  (i) => Offset(xs[i], topY),
                );
                final bottomPositions = List.generate(
                  n,
                  (i) => Offset(xs[i], bottomY),
                );

                List<Widget> node(
                  Offset pos,
                  String label,
                  bool isActive,
                  bool labelAbove,
                ) {
                  final dotSize = isActive ? 22.0 : 14.0;
                  return [
                    Positioned(
                      left: pos.dx - labelWidth / 2,
                      top: labelAbove ? pos.dy - 36 : pos.dy + 16,
                      child: SizedBox(
                        width: labelWidth,
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: isActive ? activeFont : baseFont,
                            color: isActive ? color : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: pos.dx - dotSize / 2,
                      top: pos.dy - dotSize / 2,
                      child: Container(
                        width: dotSize,
                        height: dotSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? color : const Color(0xFF334155),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 12,
                                    spreadRadius: 3,
                                  ),
                                ]
                              : [],
                        ),
                      ),
                    ),
                  ];
                }

                // Okuma çizgisi önce sağa doğru gider (sütun sütun, çiftse
                // üst tekse alt), son sütunda GERİ döner ve bu kez öbür
                // satırı takip ederek başa kadar devam eder — ör.
                // "...inanmalısın, inanç yoksa başarı da yoktur, çünkü...".
                final int activeCol;
                final bool activeIsTop;
                if (_zigzagActiveIndex < n) {
                  activeCol = _zigzagActiveIndex;
                  activeIsTop = activeCol.isEven;
                } else {
                  activeCol = n - 1 - (_zigzagActiveIndex - n);
                  activeIsTop = !activeCol.isEven;
                }

                return Stack(
                  children: [
                    CustomPaint(
                      size: Size(canvasWidth, h),
                      painter: _CrossZigzagPainter(
                        topPositions: topPositions,
                        bottomPositions: bottomPositions,
                        color: color,
                      ),
                    ),
                    for (int i = 0; i < n; i++) ...[
                      ...node(
                        topPositions[i],
                        top[i],
                        activeCol == i && activeIsTop,
                        true,
                      ),
                      ...node(
                        bottomPositions[i],
                        bottom[i],
                        activeCol == i && !activeIsTop,
                        false,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ZigzagPainter extends CustomPainter {
  final List<Offset> positions;
  final Color color;
  _ZigzagPainter({required this.positions, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < positions.length - 1; i++) {
      canvas.drawLine(positions[i], positions[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ZigzagPainter oldDelegate) =>
      oldDelegate.positions != positions || oldDelegate.color != color;
}

class _CrossZigzagPainter extends CustomPainter {
  final List<Offset> topPositions;
  final List<Offset> bottomPositions;
  final Color color;
  _CrossZigzagPainter({
    required this.topPositions,
    required this.bottomPositions,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    // Her komşu sütun çifti arasında bir X çizilir: üst(i)-alt(i+1) ve
    // alt(i)-üst(i+1) — kitaptaki çapraz zikzak deseninin aynısı.
    for (int i = 0; i < topPositions.length - 1; i++) {
      canvas.drawLine(topPositions[i], bottomPositions[i + 1], paint);
      canvas.drawLine(bottomPositions[i], topPositions[i + 1], paint);
    }
    // Son sütunun üst-alt kelimesi birbirine BAĞLI görünsün diye dikey
    // bir çizgiyle birleştiriliyor — "kopuk/boşluktaymış" hissi kalmasın.
    if (topPositions.isNotEmpty) {
      canvas.drawLine(topPositions.last, bottomPositions.last, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CrossZigzagPainter oldDelegate) =>
      oldDelegate.topPositions != topPositions ||
      oldDelegate.bottomPositions != bottomPositions ||
      oldDelegate.color != color;
}

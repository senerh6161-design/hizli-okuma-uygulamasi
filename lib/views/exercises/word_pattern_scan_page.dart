import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';

class _WordPair {
  final String top;
  final String bottom;
  const _WordPair(this.top, this.bottom);
}

enum _Direction { leftToRight, rightToLeft, bottomToTop, topToBottom }

enum _Phase { warmup, ready, exercise, bolum2Intro, bolum2 }

// 2. Bölüm'de kutucukların ortasından geçen dikey kesikli çizgi — kitaptaki
// gibi gözün satır ortasına kilitlenip yatay görüş alanıyla kelimeleri
// algılaması için.
class _VerticalDashedLinePainter extends CustomPainter {
  final Color color;
  const _VerticalDashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    const dashHeight = 6.0;
    const dashSpace = 5.0;
    double y = 0;
    final x = size.width / 2;
    while (y < size.height) {
      canvas.drawLine(Offset(x, y), Offset(x, y + dashHeight), paint);
      y += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalDashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Klasör 4'ün birinci etkinliği: "Kelime Kalıpları Tarama". Kitaptaki
/// Etkinlik 4/5'in karşılığı — Klasör 3'ün "Kelime Çiftleri Tarama"sıyla
/// (word_pair_scan_page) aynı mantık: her kutuda ortadaki noktaya
/// odaklanarak algılanacak iki kelime kalıbı var. Sabit bir kutucuk
/// sırayla dört yönde geziniyor: soldan sağa, sağdan sola, aşağıdan
/// yukarı, yukarıdan aşağı. Kitaptaki 5 sayfanın (her biri kendi
/// renk/çerçeve stiliyle) her biri bu dört yönle taranıyor.
class WordPatternScanPage extends StatefulWidget {
  const WordPatternScanPage({super.key});

  @override
  State<WordPatternScanPage> createState() => _WordPatternScanPageState();
}

class _WordPatternScanPageState extends State<WordPatternScanPage> {
  static const Color _color = Color(0xFF0369A1);
  static const List<String> _speedLabels = [
    'Yavaş',
    'Orta',
    'Hızlı',
    'Çok Hızlı',
  ];
  static const List<int> _stepMsBySpeed = [1100, 750, 450, 320];
  static const List<_Direction> _directions = [
    _Direction.leftToRight,
    _Direction.rightToLeft,
    _Direction.bottomToTop,
    _Direction.topToBottom,
  ];
  static const List<String> _directionLabels = [
    'Soldan Sağa',
    'Sağdan Sola',
    'Aşağıdan Yukarı',
    'Yukarıdan Aşağı',
  ];
  static const int _cols = 2;

  // Kitaptaki Etkinlik 4, 1. sayfa.
  static const List<_WordPair> _page1 = [
    _WordPair('Okudukça', 'Okuyunca'),
    _WordPair('Okuyorsak', 'Okumalıyız'),
    _WordPair('Okumuştur', 'Okuyacaktı'),
    _WordPair('Okuldayım', 'Okullarımız'),
    _WordPair('Okulunuzda', 'Okunanlar'),
    _WordPair('Okumazlar', 'Okurların'),
    _WordPair('İnanmalıyım', 'İnancımın'),
    _WordPair('İnanacaksınız', 'İnanırsanız'),
    _WordPair('Kazananların', 'Kazandıkların'),
    _WordPair('Kazancımız', 'Kazanımlar'),
    _WordPair('Yazmalıydınız', 'Yazarlarınız'),
    _WordPair('Yazılılanlar', 'Yazacaklar'),
    _WordPair('Öğretimimiz', 'Öğreneceklerimiz'),
    _WordPair('Sabrettikleriniz', 'Sabırsızlığımız'),
    _WordPair('Sabrediniz', 'Sabırlılarla'),
    _WordPair('Öğrendiğinizde', 'Öğrettiklerimiz'),
  ];

  // Kitaptaki Etkinlik 4, 2. sayfa.
  static const List<_WordPair> _page2 = [
    _WordPair('Okuyordunuz', 'Okuyormuşsunuz'),
    _WordPair('Başaracaksınız', 'Başarılılarla'),
    _WordPair('Okullarından', 'Okullarımızdaki'),
    _WordPair('Okullarınızın', 'Okuyorlarken'),
    _WordPair('Sabırlı mısın?', 'Sabredecektiniz'),
    _WordPair('Başardığımızda', 'Başlayacağız'),
    _WordPair('Başaranlardan', 'Başlayanlardır'),
    _WordPair('İnsanlarımız', 'İnandıklarımız'),
    _WordPair('Kazanınca', 'Kazanırsanız'),
    _WordPair('Kazanmalıyım', 'Kazanmanın'),
    _WordPair('Yazar mısınız?', 'Yazlıkta mısın?'),
    _WordPair('Yazılınca', 'Yazdığınızdan'),
    _WordPair('Öğretenlerin', 'Öğretmenlerin'),
    _WordPair('Öğreneceksiniz', 'Öğretecekseniz'),
    _WordPair('Düşüncelerimiz', 'Düşündükleriniz'),
    _WordPair('Kararlarınızda', 'Kararlaştırmak'),
  ];

  // Kitaptaki Etkinlik 5, 1. sayfa.
  static const List<_WordPair> _page3 = [
    _WordPair('Okuyabilirim', 'Oturuverin'),
    _WordPair('Bakakaldım', 'Kalakaldım'),
    _WordPair('Dershanelerde', 'Yazıhanemizin'),
    _WordPair('Kırıkkaleliler', 'Kırşehirlilerden'),
    _WordPair('Vatanseverler', 'Kendisiyle barışık'),
    _WordPair('Azledildi', 'Emrettiler'),
    _WordPair('Sabreylemek', 'Şükreylemek'),
    _WordPair('Zikrettiler', 'Bahsedilecekler'),
    _WordPair('Hissetmek', 'Hissedilmek'),
    _WordPair('Halletmek', 'Zannetmek'),
    _WordPair('Karagöz', 'Paragöz'),
    _WordPair('Açıkgöz', 'Cingöz'),
    _WordPair('Beşiktaş', 'Kabataş'),
    _WordPair('Darmadağın', 'Karmakarışık'),
    _WordPair('Horozibiği', 'Keçiboynuzu'),
    _WordPair('Kuşburnu', 'Kargaburnu'),
  ];

  // Kitaptaki Etkinlik 5, 2. sayfa.
  static const List<_WordPair> _page4 = [
    _WordPair('Düşünüver', 'Yapadursun'),
    _WordPair('Alışılagelmiş', 'Düşeyazmış'),
    _WordPair('Buzdolapta', 'Dönme dolapta'),
    _WordPair('Kütüphanenin', "Kâğıthane'de"),
    _WordPair('Hükmolundu', 'Keşfedilecek'),
    _WordPair('Kaydedilmek', 'Nakledilmek'),
    _WordPair('Reddolundu', 'Reddeyledi'),
    _WordPair('Affettiniz', 'Affedildiniz'),
    _WordPair('Anaerkil', 'Ataerkil'),
    _WordPair('Günaydın', 'Tünaydın'),
    _WordPair('Babayiği', 'Delikanlı'),
    _WordPair('Civciv', 'Cızbız'),
    _WordPair('Akdeniz', 'Karadeniz'),
    _WordPair('Aslanpençesi', 'Civanperçemi'),
    _WordPair('Tavukgöğsü', 'Vezirparmağı'),
    _WordPair('Beştaş', 'Dokuztaş'),
  ];

  // Kitaptaki Etkinlik 5, 3. sayfa.
  static const List<_WordPair> _page5 = [
    _WordPair('Çıkageldi', 'Süregelir'),
    _WordPair('Yazadurun', 'Gidedursunlar'),
    _WordPair('Alinazik', 'Ayşekadın'),
    _WordPair('Düşünebilmek', 'Yapabilmek'),
    _WordPair('Günebakan', 'Dalgakıran'),
    _WordPair('Gökdelen', 'Yelkovan'),
    _WordPair('Okuryazar', 'Uyurgezer'),
    _WordPair('Gecekondu', 'Dedikodu'),
    _WordPair('Gaziantep', 'Kahramanmaraş'),
    _WordPair('Kaptıkaçtı', 'Oldubitti'),
    _WordPair('Biçerdöver', 'Konargöçer'),
    _WordPair('Çanakkale', 'Gümüşhane'),
    _WordPair('Kızılırmak', 'Yeşilırmak'),
    _WordPair('Mirasyedi', 'Serdengeçti'),
  ];

  late final List<List<_WordPair>> _pages = [
    _page1,
    _page2,
    _page3,
    _page4,
    _page5,
  ];

  // Kitaptaki Etkinlik 8 — 1. Etkinliğin 2. Bölümü: dikey odak okuma.
  // Satırlar giderek uzuyor, öğrenci ortadaki kesikli çizgiye odaklanıp
  // yatay görüş alanıyla tüm satırı tek bakışta yakalamaya çalışıyor.
  static const List<String> _bolum2Lines = [
    'Hayatta',
    'Değişmeyen hedefim',
    'Sürekli yükselmek',
    'Her gün düzenli okumak',
    'Ve daha çok öğrenmek...',
    'Düşünebilmek için öğrenmek',
    'Hissedebilmek için öğrenmek',
    'Kendimi keşfedebilmek için öğrenmek...',
    'Bunun için sadece hedefime kilitleneceğim',
    'Her türlü zorluğa ve engele sabredeceğim',
    'Hedefe ulaşmak için asla pes etmek yok',
    'Zamanın tekrarının olmadığının farkındayım',
    'Bugün benim en büyük rakibim: Dünkü BEN!',
  ];
  static const List<String> _bolum2Words = ['İrade', 'Özgü', 'Öznel'];

  _Phase _phase = _Phase.warmup;
  bool _hasCompletedOnce = false;
  bool _isPaused = false;
  int _speedLevel = 1;

  int _pageIndex = 0;
  int _directionIndex = 0;
  int _activeIndex = 0;
  Timer? _sweepTimer;
  bool _blinkOn = true;
  Timer? _blinkTimer;

  int _bolum2ElapsedSec = 0;
  Timer? _bolum2Ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startWarmup());
  }

  @override
  void dispose() {
    _sweepTimer?.cancel();
    _blinkTimer?.cancel();
    _bolum2Ticker?.cancel();
    super.dispose();
  }

  List<_WordPair> get _currentPairs =>
      _phase == _Phase.warmup ? _page1.take(8).toList() : _pages[_pageIndex];

  int get _currentRows => (_currentPairs.length / _cols).ceil();

  List<int> _sweepOrder(_Direction dir) {
    final cellCount = _currentPairs.length;
    final rows = _currentRows;
    final order = <int>[];
    switch (dir) {
      case _Direction.leftToRight:
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < _cols; c++) {
            final i = r * _cols + c;
            if (i < cellCount) order.add(i);
          }
        }
      case _Direction.rightToLeft:
        for (int r = 0; r < rows; r++) {
          for (int c = _cols - 1; c >= 0; c--) {
            final i = r * _cols + c;
            if (i < cellCount) order.add(i);
          }
        }
      case _Direction.bottomToTop:
        for (int c = 0; c < _cols; c++) {
          for (int r = rows - 1; r >= 0; r--) {
            final i = r * _cols + c;
            if (i < cellCount) order.add(i);
          }
        }
      case _Direction.topToBottom:
        for (int c = 0; c < _cols; c++) {
          for (int r = 0; r < rows; r++) {
            final i = r * _cols + c;
            if (i < cellCount) order.add(i);
          }
        }
    }
    return order;
  }

  late List<int> _sweepIndices = [];

  void _startWarmup() {
    setState(() {
      _phase = _Phase.warmup;
      _directionIndex = 0;
    });
    _startDirection();
  }

  void _startExercise() {
    setState(() {
      _phase = _Phase.exercise;
      _pageIndex = 0;
      _directionIndex = 0;
    });
    _startDirection();
  }

  void _startDirection() {
    _sweepTimer?.cancel();
    _blinkTimer?.cancel();
    _sweepIndices = _sweepOrder(_directions[_directionIndex]);
    setState(() {
      _activeIndex = 0;
      _blinkOn = true;
    });
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 420), (_) {
      if (!mounted) return;
      setState(() => _blinkOn = !_blinkOn);
    });
    _scheduleStep();
  }

  void _scheduleStep() {
    _sweepTimer?.cancel();
    _sweepTimer = Timer(
      Duration(milliseconds: _stepMsBySpeed[_speedLevel]),
      () {
        if (!mounted) return;
        SoundManager.playTick();
        if (_activeIndex >= _sweepIndices.length - 1) {
          _onDirectionDone();
        } else {
          setState(() => _activeIndex++);
          _scheduleStep();
        }
      },
    );
  }

  void _onDirectionDone() {
    if (_directionIndex < _directions.length - 1) {
      setState(() => _directionIndex++);
      _startDirection();
      return;
    }
    if (_phase == _Phase.warmup) {
      _blinkTimer?.cancel();
      setState(() => _phase = _Phase.ready);
      return;
    }
    if (_pageIndex < _pages.length - 1) {
      setState(() {
        _pageIndex++;
        _directionIndex = 0;
      });
      _startDirection();
    } else {
      setState(() => _phase = _Phase.bolum2Intro);
    }
  }

  void _startBolum2() {
    _bolum2Ticker?.cancel();
    setState(() {
      _phase = _Phase.bolum2;
      _bolum2ElapsedSec = 0;
    });
    _bolum2Ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _bolum2ElapsedSec++);
    });
  }

  void _finishBolum2() {
    _bolum2Ticker?.cancel();
    _finishAll();
  }

  void _changeSpeed(int level) {
    setState(() {
      _speedLevel = level;
      _activeIndex = 0;
    });
    _sweepTimer?.cancel();
    _scheduleStep();
  }

  void _pauseGame() {
    _sweepTimer?.cancel();
    _blinkTimer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resumeGame() {
    setState(() => _isPaused = false);
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 420), (_) {
      if (!mounted) return;
      setState(() => _blinkOn = !_blinkOn);
    });
    _scheduleStep();
  }

  void _finishAll() {
    _sweepTimer?.cancel();
    _blinkTimer?.cancel();
    _hasCompletedOnce = true;

    const percent = 100;
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Kelime Kalıpları Tarama',
      result:
          '${_pages.length} sayfa · 4 yön · 2. Bölüm ${_bolum2ElapsedSec}sn',
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
            Text(
              '${_pages.length} sayfayı 4 yönden taradık, sonra dikey odak '
              'okumayı $_bolum2ElapsedSec saniyede bitirdik!',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
              _startWarmup();
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
        appBar: AppBar(title: const Text('🔎 Kelime Kalıpları Tarama')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: switch (_phase) {
                  _Phase.warmup => _buildScan(
                    key: ValueKey('warmup-$_directionIndex'),
                    pageStyle: 0,
                  ),
                  _Phase.ready => _buildReady(),
                  _Phase.exercise => _buildScan(
                    key: ValueKey('ex-$_pageIndex-$_directionIndex'),
                    pageStyle: _pageIndex,
                  ),
                  _Phase.bolum2Intro => _buildBolum2Intro(),
                  _Phase.bolum2 => _buildBolum2(),
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

  Widget _speedChipRow() {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        Text(
          'Hız: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
        for (int i = 0; i < _speedLabels.length; i++)
          ChoiceChip(
            label: Text(_speedLabels[i]),
            selected: _speedLevel == i,
            onSelected: (_) => _changeSpeed(i),
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
    );
  }

  Widget _buildScan({required Key key, required int pageStyle}) {
    final isWarmup = _phase == _Phase.warmup;
    final pairs = _currentPairs;
    return KeyedSubtree(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isWarmup
                        ? '🎓 Antreman · ${_directionLabels[_directionIndex]}'
                        : '1. Bölüm · Sayfa ${_pageIndex + 1}/${_pages.length} · '
                              '${_directionLabels[_directionIndex]}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              buildPauseButton(color: _color, onPressed: _pauseGame),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (int i = 0; i < _directions.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= _directionIndex
                        ? _color
                        : _color.withValues(alpha: 0.15),
                  ),
                ),
              ],
            ],
          ),
          if (isWarmup) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _color, width: 1.2),
              ),
              child: const Text.rich(
                TextSpan(
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF0C4A6E)),
                  children: [
                    TextSpan(
                      text: 'Amaç: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                          'Farklı eklerle oluşturulan kelime kalıplarını en '
                          'kısa sürede algılayabilmek, gözün dikey görüş '
                          'alanını (DİGA) genişletmek.\n',
                    ),
                    TextSpan(
                      text: 'Yöntem: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                          'Kutu içindeki noktaya odaklanarak iki kelimeyi '
                          'tek bakışta yakalamaya çalış. Anlamını düşünüp '
                          'durma, kelimenin şekline hızlıca bak ve geç — '
                          'zamanla anlam kendiliğinden ortaya çıkacak. '
                          'Önce antremanı yapacağız, sonra sıra sende — 5 '
                          'sayfayı da bu şekilde tarayacaksın!',
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          _speedChipRow(),
          const SizedBox(height: 12),
          Expanded(child: _grid(pairs, pageStyle)),
        ],
      ),
    );
  }

  Widget _buildReady() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: Text('🎯', style: TextStyle(fontSize: 64))),
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
                    'Antremanı tamamladık! Şimdi sıra sende — az önce '
                    'izlediğin gibi kutucuğu takip ederek 5 sayfayı da 4 '
                    'yönde tarayacaksın.',
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
                    onPressed: _startExercise,
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
                const Center(
                  child: Text('👁️', style: TextStyle(fontSize: 64)),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF9C3),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFCA8A04),
                      width: 1.2,
                    ),
                  ),
                  child: const Text.rich(
                    TextSpan(
                      style: TextStyle(fontSize: 13, color: Color(0xFF713F12)),
                      children: [
                        TextSpan(
                          text: '2. Bölüm: Dikey Odak Okuma\n\n',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        TextSpan(
                          text: 'Amaç: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'Gözün yatay görüş alanını artırabilmek ve '
                              'içten seslendirmeyi önlemek.\n',
                        ),
                        TextSpan(
                          text: 'Yöntem: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'Ortadaki kesikli çizgiye odaklanarak, '
                              'satırların ortasından tek bakışta daha fazla '
                              'kelime algılamaya çalış — kelimeleri içinden '
                              'seslendirmeden!\n',
                        ),
                        TextSpan(
                          text: 'Süre: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: '5-7 saniye içinde bitirmeye çalış.'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 12.5, color: _color),
                      children: [
                        const TextSpan(
                          text: 'Bugün öğrenmemiz gereken üç kelime: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: _bolum2Words.join(', ')),
                      ],
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

  Widget _buildBolum2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '2. Bölüm · Dikey Odak Okuma',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold, color: _color),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '⏱ ${_bolum2ElapsedSec}sn',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _VerticalDashedLinePainter(
                      color: _color.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                Column(
                  children: [
                    for (final line in _bolum2Lines) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF9C3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFCA8A04)),
                        ),
                        child: Text(
                          line,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF713F12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _finishBolum2,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text(
              'BİTİRDİM!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
    );
  }

  // Kutucuklar makul bir boyutta (88-140) tutuluyor ama az satırlı
  // sayfalarda (ör. antreman) satırlar arasına eşit boşluk dağıtılarak
  // ızgara tüm ekran yüksekliğini dolduruyor; sığmayan sayfalar
  // kaydırılabiliyor.
  Widget _grid(List<_WordPair> pairs, int pageStyle) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final rows = (pairs.length / _cols).ceil();
        final cellWidth =
            (constraints.maxWidth - spacing * (_cols - 1)) / _cols;
        final rawCellHeight =
            (constraints.maxHeight - spacing * (rows - 1)) / rows;
        final cellHeight = rawCellHeight.clamp(72.0, 130.0);
        final fits =
            cellHeight * rows + spacing * (rows - 1) <=
            constraints.maxHeight + 0.5;

        Widget cellAt(int r, int c) {
          final index = r * _cols + c;
          if (index >= pairs.length) return SizedBox(width: cellWidth);
          final pair = pairs[index];
          final isActive =
              index ==
              (_sweepIndices.isEmpty ? -1 : _sweepIndices[_activeIndex]);
          final lit = isActive && _blinkOn;
          return SizedBox(
            width: cellWidth,
            height: cellHeight,
            child: _pairBox(pair, lit: lit, pageStyle: pageStyle),
          );
        }

        final rowWidgets = <Widget>[
          for (int r = 0; r < rows; r++)
            Row(
              children: [
                for (int c = 0; c < _cols; c++) ...[
                  if (c > 0) const SizedBox(width: spacing),
                  cellAt(r, c),
                ],
              ],
            ),
        ];

        final content = Column(
          mainAxisAlignment: fits
              ? MainAxisAlignment.spaceEvenly
              : MainAxisAlignment.start,
          children: [
            for (int i = 0; i < rowWidgets.length; i++) ...[
              if (i > 0 && !fits) const SizedBox(height: spacing),
              rowWidgets[i],
            ],
          ],
        );

        return fits ? content : SingleChildScrollView(child: content);
      },
    );
  }

  Widget _pairBox(_WordPair pair, {required bool lit, required int pageStyle}) {
    Color bg;
    Color border;
    Color fg;
    switch (pageStyle) {
      case 1: // Etkinlik 4, 2. sayfa (yeşil)
        bg = const Color(0xFFB6E38A);
        border = const Color(0xFF2F6B1A);
        fg = const Color(0xFF1B3A0E);
      case 2: // Etkinlik 5, 1. sayfa (şeftali)
        bg = const Color(0xFFE3AC7C);
        border = const Color(0xFF7C4A22);
        fg = const Color(0xFF3E230E);
      case 3: // Etkinlik 5, 2. sayfa (sarı)
        bg = const Color(0xFFF2DE86);
        border = const Color(0xFF8A6D1A);
        fg = const Color(0xFF4A3A08);
      case 4: // Etkinlik 5, 3. sayfa (pembe)
        bg = const Color(0xFFE2B6D8);
        border = const Color(0xFF7B2E67);
        fg = const Color(0xFF3D1733);
      default: // Etkinlik 4, 1. sayfa (beyaz)
        bg = Colors.white;
        border = Colors.black87;
        fg = const Color(0xFF1E293B);
    }
    if (lit) {
      bg = _color;
      fg = Colors.white;
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: lit ? _color : border, width: 1.4),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                pair.top,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: fg,
                ),
              ),
              Text('•', style: TextStyle(fontSize: 12, color: fg)),
              Text(
                pair.bottom,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

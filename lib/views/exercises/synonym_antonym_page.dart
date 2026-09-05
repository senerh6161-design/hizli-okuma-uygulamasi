import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';
import '../../widgets/exercise_settings_sheet.dart';

enum _Phase { intro, running, reveal }

// Her sayfa: eşleşen kutucuklar (eş anlamlı ya da zıt anlamlı kelime
// çiftleri), kendi amaç/yöntem/not yönergesiyle birlikte (kitaptaki
// Etkinlik 4/5'in karşılığı).
class _PairPage {
  final String amac;
  final String yontem;
  final String note;
  final List<List<String>> boxes;
  // Sayfadaki kutuların çoğu eş (ya da zıt) anlamlıyken, aralarına
  // kasıtlı olarak karışan TEK farklı çift — sayfa bitince bir kutucukta
  // gösteriliyor.
  final String oddPair;
  final bool isSynonymPage;
  const _PairPage({
    required this.amac,
    required this.yontem,
    required this.note,
    required this.boxes,
    required this.oddPair,
    required this.isSynonymPage,
  });
}

/// Klasör 3'ün ilk etkinliği: "Eş ve Zıt Anlamlı Kelimeler" (kitaptaki
/// Etkinlik 4 ve 5'in karşılığı). Klasör 2 · Etkinlik 7'nin Kelime
/// Kutucukları bölümüyle AYNI mekanik — quiz yok, öğrenci kendi hızında
/// okuyup "Bitirdim" diyor, süresi kaydediliyor:
/// 1. Sayfa — eş anlamlı kelime çiftleri,
/// 2. Sayfa — zıt anlamlı kelime çiftleri.
class SynonymAntonymPage extends StatefulWidget {
  const SynonymAntonymPage({super.key});

  @override
  State<SynonymAntonymPage> createState() => _SynonymAntonymPageState();
}

class _SynonymAntonymPageState extends State<SynonymAntonymPage> {
  Color _color = const Color(0xFF15803D);

  static const List<Color> _colorPalette = [
    Color(0xFF15803D),
    Color(0xFFEC4899),
    Color(0xFFEA580C),
    Color(0xFF0D9488),
    Color(0xFF7C3AED),
    Color(0xFF2563EB),
  ];
  static const List<String> _speedLabels = [
    'Yavaş',
    'Orta',
    'Hızlı',
    'Çok Hızlı',
  ];
  static const List<int> _stepMsBySpeed = [1600, 1100, 700, 400];
  int _speedLevel = 1;

  // Kutu içindeki yazı boyutu — en büyük seçenekte bile taşmasın diye
  // FittedBox ile birlikte kullanılıyor.
  static const List<String> _textSizeLabels = ['Küçük', 'Orta', 'Büyük'];
  static const List<double> _textSizeValues = [11, 14, 18];
  int _textSizeLevel = 1;

  static const List<_PairPage> _pages = [
    _PairPage(
      amac: 'Yatay göz hareketlerini hızlandırmak ve dikkatimizi artırmak.',
      yontem:
          'Kutucuklardaki kelimelerin altına bakarak sayfayı 10 saniyede '
          'bitireceğiz.',
      note:
          'Bu etkinliği üç defa yapacağız. Her seferinde, bir saniye dahi '
          'olsa daha hızlı olmaya çalışacağız.',
      oddPair: 'soru=cevap',
      isSynonymPage: true,
      boxes: [
        ['amaç=gaye', 'mühim=önemli'],
        ['yoksul=fakir', 'olanak=imkan'],
        ['kıymetli=değerli', 'uygun=münasip'],
        ['yaşlı=ihtiyar', 'cesur=yürekli'],
        ['güç=kuvvet', 'anlam=mana'],
        ['uzak=ırak', 'yetenek=kabiliyet'],
        ['ün=şöhret', 'meşhur=ünlü'],
        ['çaba=gayret', 'etki=tesir'],
        ['ilginç=enteresan', 'evvel=önce'],
        ['yüz=çehre', 'yanıt=cevap'],
        ['sevinç=neşe', 'cömert=eli açık'],
        ['cimri=pinti', 'keder=elem'],
        ['zafer=galibiyet', 'soru=cevap'],
        ['savaş=harp', 'anı=hatıra'],
        ['yurt=vatan', 'şart=koşul'],
        ['sınır=hudut', 'hediye=armağan'],
      ],
    ),
    _PairPage(
      amac: 'Görüş açımızı genişletmek ve dikkatimizi artırmak.',
      yontem:
          'Kutucuklardaki kelimelerin altına bakarak sayfayı 10 saniyede '
          'bitireceğiz.',
      note:
          'Hızlı okuyabilmek için, her gün yeni kelimeler öğrenmeyi '
          'ihmal etmeyelim!',
      oddPair: 'özgür=hür',
      isSynonymPage: false,
      boxes: [
        ['gelmek—gitmek', 'gülmek—ağlamak'],
        ['sıcak—soğuk', 'doğru—yanlış'],
        ['hızlı—yavaş', 'zengin—fakir'],
        ['uzun—kısa', 'kolay—zor'],
        ['tatlı—acı', 'savaş—barış'],
        ['büyük—küçük', 'dolu—boş'],
        ['ağır—hafif', 'yeni—eski'],
        ['genç—yaşlı', 'sert—yumuşak'],
        ['temiz—kirli', 'özgür=hür'],
        ['cesur—korkak', 'cömert—cimri'],
        ['derin—sığ', 'karanlık—aydınlık'],
        ['kuru—ıslak', 'erken—geç'],
        ['seyrek—sık', 'başlamak—bitirmek'],
        ['doğal—yapay', 'düzenli—dağınık'],
        ['gerçek—sahte', 'neşeli—üzgün'],
        ['geçmiş—gelecek', 'aktif—pasif'],
      ],
    ),
  ];

  _Phase _phase = _Phase.intro;
  bool _hasCompletedOnce = false;
  bool _isPaused = false;

  int _pageIndex = 0;
  // Her sayfa üst üste 3 kez tekrarlanıyor (notta söz verildiği gibi) —
  // her denemenin süresi ayrı ayrı kaydediliyor.
  static const int _attemptsPerPage = 3;
  int _attemptIndex = 0;
  final List<List<int>> _attemptTimes = List.generate(_pages.length, (_) => []);
  Timer? _timer;
  int _elapsedSec = 0;
  bool _finished = false;
  int _activeStep = 0;
  Timer? _stepTimer;
  // Nokta artık sadece ilk kutuda beliriyor (yönü gösterip kayboluyor) —
  // ondan sonra aktif kutu yanıp sönerek kendini belli ediyor.
  bool _blinkOn = true;
  Timer? _blinkTimer;

  _PairPage get _page => _pages[_pageIndex];

  @override
  void dispose() {
    _timer?.cancel();
    _stepTimer?.cancel();
    _blinkTimer?.cancel();
    super.dispose();
  }

  void _startPage() {
    _stepTimer?.cancel();
    _blinkTimer?.cancel();
    setState(() {
      _phase = _Phase.running;
      _elapsedSec = 0;
      _finished = false;
      _activeStep = 0;
      _blinkOn = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSec++);
    });
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (!mounted) return;
      setState(() => _blinkOn = !_blinkOn);
    });
    _scheduleStep();
  }

  // Nokta önce kutudaki soldaki kelimenin, sonra sağdaki kelimenin altına
  // zıplıyor, ardından bir sonraki kutuya geçiyor.
  void _scheduleStep() {
    final totalSteps = _page.boxes.length * 2;
    if (_activeStep >= totalSteps - 1) return;
    _stepTimer = Timer(Duration(milliseconds: _stepMsBySpeed[_speedLevel]), () {
      if (!mounted || _phase != _Phase.running) return;
      setState(() => _activeStep++);
      _scheduleStep();
    });
  }

  void _finishPage() {
    if (_finished) return;
    _timer?.cancel();
    _stepTimer?.cancel();
    _blinkTimer?.cancel();
    setState(() => _finished = true);
    _attemptTimes[_pageIndex].add(_elapsedSec);
    SoundManager.playCorrect();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_attemptIndex < _attemptsPerPage - 1) {
        // Bu sayfanın son denemesi değil — BAŞLA ekranı göstermeden aynı
        // sayfayı kendiliğinden baştan başlatıyoruz.
        _attemptIndex++;
        _startPage();
      } else {
        // Sayfanın son (3.) denemesi bitti — farklı kutuyu bir kutucukta
        // gösterip sonra bir sonraki sayfaya geçiyoruz.
        setState(() => _phase = _Phase.reveal);
      }
    });
  }

  void _advanceAfterPage() {
    if (!mounted) return;
    if (_pageIndex < _pages.length - 1) {
      setState(() {
        _pageIndex++;
        _attemptIndex = 0;
        _phase = _Phase.intro;
      });
    } else {
      _finishAll();
    }
  }

  void _pauseGame() {
    _timer?.cancel();
    _stepTimer?.cancel();
    _blinkTimer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resumeGame() {
    setState(() => _isPaused = false);
    if (_phase == _Phase.running && !_finished) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _elapsedSec++);
      });
      _blinkTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
        if (!mounted) return;
        setState(() => _blinkOn = !_blinkOn);
      });
      _scheduleStep();
    }
  }

  // Hız değişince öğrenci sayfanın başına dönsün diye nokta/kutu ilerlemesi
  // sıfırlanıp yeniden başlatılıyor.
  void _changeSpeed(int level) {
    if (_phase == _Phase.running && !_finished) {
      _stepTimer?.cancel();
      _blinkTimer?.cancel();
      setState(() {
        _speedLevel = level;
        _activeStep = 0;
        _blinkOn = true;
      });
      _blinkTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
        if (!mounted) return;
        setState(() => _blinkOn = !_blinkOn);
      });
      _scheduleStep();
    } else {
      setState(() => _speedLevel = level);
    }
  }

  void _finishAll() {
    _timer?.cancel();
    _stepTimer?.cancel();
    _blinkTimer?.cancel();
    _hasCompletedOnce = true;

    const percent = 100;
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final summary = _attemptTimes
        .map((times) => times.map((t) => '$t sn').join(', '))
        .join(' · ');
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Eş ve Zıt Anlamlı Kelimeler',
      result: 'Sayfalar: $summary',
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
            for (int i = 0; i < _attemptTimes.length; i++)
              Text(
                'Sayfa ${i + 1} Denemeleri: '
                '${_attemptTimes[i].map((t) => "$t sn").join(", ")}',
              ),
            const SizedBox(height: 8),
            const Text(
              'Tebrikler, etkinliği tamamladın!',
              style: TextStyle(fontWeight: FontWeight.bold),
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
              setState(() {
                _phase = _Phase.intro;
                _pageIndex = 0;
                _attemptIndex = 0;
                for (final times in _attemptTimes) {
                  times.clear();
                }
              });
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
        appBar: AppBar(
          title: const Text('🔤 Eş ve Zıt Anlamlı Kelimeler'),
          actions: [
            IconButton(
              onPressed: () => showExerciseSettingsSheet(
                context,
                currentColor: _color,
                colorOptions: _colorPalette,
                onColorChanged: (c) => setState(() => _color = c),
              ),
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: 'Ayarlar',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: switch (_phase) {
                  _Phase.intro => KeyedSubtree(
                    key: ValueKey('intro-$_pageIndex'),
                    child: _buildIntro(),
                  ),
                  _Phase.running => KeyedSubtree(
                    key: ValueKey('running-$_pageIndex'),
                    child: _buildRunning(),
                  ),
                  _Phase.reveal => KeyedSubtree(
                    key: ValueKey('reveal-$_pageIndex'),
                    child: _buildReveal(),
                  ),
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

  Widget _buildIntro() {
    final isSynonymPage = _pageIndex == 0;
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
                    '${_pageIndex + 1}. Sayfa · '
                    '${isSynonymPage ? "Eş Anlamlı Kelimeler" : "Zıt Anlamlı Kelimeler"}'
                    ' · Deneme ${_attemptIndex + 1}/$_attemptsPerPage',
                    style: TextStyle(
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
                      child: Text(
                        isSynonymPage ? '🟰' : '↔️',
                        style: const TextStyle(fontSize: 64),
                      ),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: _color,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Amaç: ${_page.amac}\n\nYöntem: ${_page.yontem}'
                              '\n\n${_page.note} Altında zıplayan noktayı '
                              'takip edeceğiz — hızımızı aşağıdan kendimiz '
                              'ayarlayabiliriz!',
                              style: TextStyle(
                                fontSize: 13,
                                color: _color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _speedChipRow(),
                    const SizedBox(height: 10),
                    _textSizeChipRow(),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _startPage,
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

  // Sayfanın 3 denemesi bitince, aralarına karışmış farklı çifti soru
  // sormadan, doğrudan gösteren bir bilgi kutusu.
  Widget _buildReveal() {
    final page = _page;
    final pageKind = page.isSynonymPage ? 'eş anlamlı' : 'zıt anlamlı';
    final oddKind = page.isSynonymPage ? 'zıt anlamlı' : 'eş anlamlı';
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: Text('🔍', style: TextStyle(fontSize: 56))),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aralarına Karışan Farklı Çift',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.amber.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.amber.shade900,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  'Bu sayfadaki kutuların hepsi $pageKind '
                                  'kelimelerdi, ama ',
                            ),
                            TextSpan(
                              text: '"${page.oddPair}"',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: ' aslında $oddKind bir çiftti.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Okurken bunu fark ettiysen, tebrikler — çok '
                        'dikkatlisin! Fark etmediysen hiç sorun değil, '
                        'bir dahaki sayfada gözünü dört açarsın 😉',
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _advanceAfterPage,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(
                      'DEVAM ET',
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

  Widget _textSizeChipRow() {
    return Row(
      children: [
        Text(
          'Yazı: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 6),
        for (int i = 0; i < _textSizeLabels.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          ChoiceChip(
            label: Text(_textSizeLabels[i]),
            selected: _textSizeLevel == i,
            onSelected: (_) => setState(() => _textSizeLevel = i),
            selectedColor: _color,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _textSizeLevel == i ? Colors.white : _color,
            ),
            backgroundColor: _color.withValues(alpha: 0.08),
            side: BorderSide(
              color: _color.withValues(alpha: _textSizeLevel == i ? 1 : 0.3),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ],
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
      ],
    );
  }

  Widget _buildRunning() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_pageIndex + 1}. Sayfa · Deneme ${_attemptIndex + 1}/'
                '$_attemptsPerPage · Kutu ${_activeStep ~/ 2 + 1}/'
                '${_page.boxes.length}',
                style: TextStyle(fontWeight: FontWeight.bold, color: _color),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Süre: $_elapsedSec sn',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.orange,
                  ),
                ),
                buildPauseButton(color: _color, onPressed: _pauseGame),
              ],
            ),
          ],
        ),
        if (_attemptIndex > 0) ...[
          const SizedBox(height: 6),
          Text(
            'Önceki: '
            '${_attemptTimes[_pageIndex].map((t) => "$t sn").join(", ")} '
            '— bu sefer daha hızlı olmaya çalışalım!',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
        ],
        const SizedBox(height: 8),
        _speedChipRow(),
        const SizedBox(height: 6),
        _textSizeChipRow(),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _directionHint(),
                for (int i = 0; i < _page.boxes.length; i++)
                  _pairBlock(_page.boxes[i], activeItem: _activeStep - i * 2),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _finished ? null : _finishPage,
            icon: Icon(
              _finished ? Icons.check_circle : Icons.check_circle_outline,
            ),
            label: Text(
              _finished ? 'Tamamlandı! ($_elapsedSec sn)' : 'BİTİRDİM',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _color,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _color,
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // İlk satırın üstünde, okuma yönünü gösteren mavi nokta → ok → mavi nokta.
  Widget _directionHint() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Expanded(child: Center(child: _DirectionDot())),
          const Icon(
            Icons.arrow_forward_rounded,
            size: 18,
            color: Color(0xFF38BDF8),
          ),
          const Expanded(child: Center(child: _DirectionDot())),
        ],
      ),
    );
  }

  // activeItem < 0: bu kutuda aktif öğe yok. Aksi halde 0 = soldaki,
  // 1 = sağdaki kutu aktif. Nokta SADECE ilk kutuda (_activeStep == 0)
  // beliriyor — yönü gösterip kayboluyor, çünkü her satırda yeniden
  // belirip kaybolması listeyi "kaydırıyormuş" gibi görünmesine sebep
  // oluyordu. Ondan sonra aktif kutu yanıp sönerek kendini belli ediyor.
  Widget _pairBlock(List<String> pair, {required int activeItem}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _pairCell(pair[0], isActive: activeItem == 0)),
              const SizedBox(width: 10),
              Expanded(child: _pairCell(pair[1], isActive: activeItem == 1)),
            ],
          ),
          if (activeItem >= 0 && _activeStep == 0)
            _activeDot(alignment: activeItem == 0 ? -0.5 : 0.5),
        ],
      ),
    );
  }

  Widget _pairCell(String text, {bool isActive = false}) {
    final blinkLit = isActive && _blinkOn;
    return AnimatedScale(
      scale: isActive ? 1.06 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: blinkLit ? const Color(0xFFC5E8A0) : const Color(0xFFDFF3CC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? _color : const Color(0xFFA9D888),
            width: isActive ? 2 : 1,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: _textSizeValues[_textSizeLevel],
              color: isActive ? _color : const Color(0xFF2E5A1C),
            ),
          ),
        ),
      ),
    );
  }

  Widget _activeDot({double alignment = 0.0}) {
    return Align(
      alignment: Alignment(alignment, 0),
      child: TweenAnimationBuilder<double>(
        key: ValueKey(_activeStep),
        tween: Tween(begin: 0.4, end: 1.0),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        builder: (context, value, child) =>
            Transform.scale(scale: value, child: child),
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: _color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _color.withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectionDot extends StatelessWidget {
  const _DirectionDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: Color(0xFF38BDF8),
        shape: BoxShape.circle,
      ),
    );
  }
}

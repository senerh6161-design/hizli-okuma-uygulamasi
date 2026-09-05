import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';
import '../../widgets/exercise_settings_sheet.dart';

enum _Phase { zigzagIntro, zigzag, wordBoxIntro, wordBox }

// 1. Bölüm'deki zikzak okuma şeridinin sağı sivri, solu çentikli okçuk
// (banner) şeklini çiziyor — kitaptaki dönüşümlü mavi/sarı şeritlerin
// görünümünü taklit ediyor.
class _ChevronBannerClipper extends CustomClipper<Path> {
  const _ChevronBannerClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final notch = h / 2.2;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(w - notch, 0)
      ..lineTo(w, h / 2)
      ..lineTo(w - notch, h)
      ..lineTo(0, h)
      ..lineTo(notch, h / 2)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// 2. Bölüm'de kullanılan bir sayfa: eşleşen kelime/ifade kutucukları,
// kendi amaç/yöntem yönergesiyle birlikte (kitaptaki Etkinlik 2/3'ün
// karşılığı).
class _WordBoxPage {
  final String amac;
  final String yontem;
  final String note;
  final List<List<String>> pairs;
  const _WordBoxPage({
    required this.amac,
    required this.yontem,
    required this.note,
    required this.pairs,
  });
}

/// Klasör 2'nin yedinci etkinliği: "Göz Hızı" (eskiden "Sınıf Eşyaları" —
/// nesne temalı içerik kaldırılınca isim de güncellendi). İkisi de
/// kitaptaki görüş açısı/göz hızı alıştırmaları — quiz yok, öğrenci kendi
/// hızında okuyup "Bitirdim" diyor, süresi kaydediliyor:
/// 1) Zikzak Okuma — dönüşümlü mavi/sarı şeritler halinde bir metin,
/// 2) Kelime Kutucukları — iki sütun halinde eşleşen kelime/ifade
/// kutucukları, iki ayrı sayfa, hedef: sayfa başına 10 saniye.
class ClassroomObjectsPage extends StatefulWidget {
  const ClassroomObjectsPage({super.key});

  @override
  State<ClassroomObjectsPage> createState() => _ClassroomObjectsPageState();
}

class _ClassroomObjectsPageState extends State<ClassroomObjectsPage> {
  Color _color = const Color(0xFF65A30D);

  static const List<Color> _colorPalette = [
    Color(0xFF65A30D),
    Color(0xFFEC4899),
    Color(0xFFEA580C),
    Color(0xFF0D9488),
    Color(0xFF7C3AED),
    Color(0xFF2563EB),
  ];

  // Öğrenci takip edebilsin diye her iki bölümde de aktif satır/kutu
  // otomatik ilerliyor (altında zıplayan bir nokta ve hafif büyüyen bir
  // vurguyla) — hızı öğrenci kendi seçiyor.
  static const List<String> _speedLabels = ['Yavaş', 'Orta', 'Hızlı'];
  static const List<int> _stepMsBySpeed = [1600, 1100, 700];
  int _speedLevel = 1;

  // Bir satırda/kutuda birden fazla kelime öbeği olabildiği için nokta
  // satır satır değil, tek tek kelime öbeği bazında ilerliyor. Bu iki
  // yardımcı, her grubun düz adım listesindeki başlangıç indeksini ve
  // toplam adım sayısını hesaplıyor.
  static List<int> _groupStarts(List<List<String>> groups) {
    final starts = <int>[];
    int cursor = 0;
    for (final g in groups) {
      starts.add(cursor);
      cursor += g.length;
    }
    return starts;
  }

  static int _groupTotalSteps(List<List<String>> groups) =>
      groups.fold(0, (sum, g) => sum + g.length);

  static int _lineIndexForStep(List<int> starts, int step) {
    int line = 0;
    for (int i = 0; i < starts.length; i++) {
      if (starts[i] <= step) line = i;
    }
    return line;
  }

  // 1. Bölüm: Zikzak Okuma. Her satır 1 ya da 2 kısa cümle parçası
  // içeriyor; şeritler sırayla mavi/sarı dönüşüyor.
  static const Color _zigzagBlue = Color(0xFFB9E0F5);
  static const Color _zigzagYellow = Color(0xFFF6E9A8);
  static const List<List<String>> _zigzagLines = [
    ['Çalışırsam'],
    ['kazanırım,', 'azmedersem'],
    ['başarırım.', 'Umudumu'],
    ['kaybetmemeliyim.', 'Sürekli'],
    ['çalışmalıyım.', 'Her zorluktan'],
    ['sonra', 'kolaylık,'],
    ['her yokuşun', 'ardından'],
    ['bir iniş,', 'her zahmetten'],
    ['sonra', 'bir rahmet,'],
    ['olacağını', 'biliyorum.'],
    ['O halde', 'pes etmemeli,'],
    ['vazgeçmemeli,', 'sabrederek'],
    ['devam etmeli,', 'başarana kadar'],
    ['yılmamalı,', 'çalışmaya'],
    ['devam etmeliyim'],
  ];

  // 2. Bölüm: Kelime Kutucukları — kitaptaki Etkinlik 2 ve Etkinlik 3.
  static const List<_WordBoxPage> _wordBoxPages = [
    _WordBoxPage(
      amac:
          'Yatay göz hareketlerini hızlandırmak ve görüş açımızı genişletmek.',
      yontem:
          'Kutucuklardaki kelimelerin altına bakarak sayfayı 10 saniyede bitiriniz.',
      note:
          'Bu etkinliği günde üç defa yapmalısınız. Her seferinde, bir saniye '
          'dahi olsa daha hızlı olmalısınız.',
      pairs: [
        ['Oku, düşün', 'Planla ve uygula'],
        ['Değer verdiğin', 'Kadar değerlisin'],
        ['Bugünü düşün', 'Zaman hayattır'],
        ['İncinsenden de', 'İncitme'],
        ['Örnek birisin', 'Aferin, harikasın'],
        ['Sen bir kartalsın', 'Hedefin yüce'],
        ['Hızlı oku', 'Hızlı öğren'],
        ['Okul hayatı', 'Hayatın okulu'],
        ['Her şeye rağmen', 'Başaracağım'],
        ['İnsan demek', 'Dikkat demek'],
        ['Bugünü düşün', 'Yarını planla'],
        ['Umudunu kaybetme', 'Zafer yakındır'],
        ['İyi ki varsın', 'Sen özelsin'],
        ['Mutluluğun sırrı', 'Sende saklı'],
        ['Sabret şükret', 'Sabahı bekle'],
        ['Başarmak cesaret', 'Tembellik esaret'],
      ],
    ),
    _WordBoxPage(
      amac: 'Görüş açımızı genişleterek gözümüze ritim kazandırmak.',
      yontem:
          'Kutucuklardaki kelimelerin altına bakarak sayfayı 10 saniyede bitiriniz.',
      note:
          'Kelimeleri tek tek değil, gruplar halinde okumaya dikkat edelim lütfen!',
      pairs: [
        ['halı kilim', 'uzun köprü'],
        ['orman gülü', 'komşu ülke'],
        ['yakacak kömür', 'canlı balık'],
        ['sevgi yolu', 'yeşil orman'],
        ['bundan böyle', 'yol yapımı'],
        ['bayram geldi', 'yönetim kurulu'],
        ['bilge insan', 'tel örgü'],
        ['çalışkan insan', 'kitap kurdu'],
        ['terbiyeli çocuk', 'nereden nereye'],
        ['güzel ülke', 'taze simit'],
        ['çok ciddi', 'elden ele'],
        ['açık alın', 'hesap devri'],
        ['bahar geldi', 'günden güne'],
        ['gece gündüz', 'beyaz dişler'],
        ['karlı dağlar', 'pazar yeri'],
        ['bilgi gücü', 'diş hekimi'],
      ],
    ),
  ];

  _Phase _phase = _Phase.zigzagIntro;
  bool _hasCompletedOnce = false;
  bool _isPaused = false;

  // 1. Bölüm: Zikzak Okuma.
  Timer? _zigzagTimer;
  int _zigzagElapsedSec = 0;
  bool _zigzagFinished = false;
  int _zigzagActiveStep = 0; // satır değil, kelime/kelime grubu adımı
  Timer? _zigzagStepTimer;

  // 2. Bölüm: Kelime Kutucukları. Her sayfa üst üste 3 kez tekrarlanıyor
  // (notta söz verildiği gibi) — her denemenin süresi ayrı kaydediliyor.
  int _wordBoxPageIndex = 0;
  static const int _wordBoxAttemptsPerPage = 3;
  int _wordBoxAttemptIndex = 0;
  final List<List<int>> _wordBoxAttemptTimes = List.generate(
    _wordBoxPages.length,
    (_) => [],
  );
  Timer? _wordBoxTimer;
  int _wordBoxElapsedSec = 0;
  bool _wordBoxFinished = false;
  int _wordBoxActiveStep = 0; // kutu değil, tek kelime adımı
  Timer? _wordBoxStepTimer;
  // Nokta ilk kutunun altında bir kere zıplayıp yönü gösterdikten sonra
  // kayboluyor (her satırda yeniden belirmesi listeyi "kaydırıyormuş" gibi
  // görünmesine sebep oluyordu) — ondan sonra aktif kutu bunun yerine
  // yanıp sönerek kendini belli ediyor.
  bool _wordBoxBlinkOn = true;
  Timer? _wordBoxBlinkTimer;

  @override
  void dispose() {
    _zigzagTimer?.cancel();
    _zigzagStepTimer?.cancel();
    _wordBoxTimer?.cancel();
    _wordBoxStepTimer?.cancel();
    _wordBoxBlinkTimer?.cancel();
    super.dispose();
  }

  // ---------------- 1. BÖLÜM: Zikzak Okuma ----------------

  void _startZigzag() {
    _zigzagStepTimer?.cancel();
    setState(() {
      _phase = _Phase.zigzag;
      _zigzagElapsedSec = 0;
      _zigzagFinished = false;
      _zigzagActiveStep = 0;
    });
    _zigzagTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _zigzagElapsedSec++);
    });
    _scheduleZigzagStep();
  }

  // Öğrenci takip edebilsin diye altındaki nokta hızını kendisinin seçtiği
  // hızda otomatik olarak bir sonraki kelime/kelime öbeğinin altına
  // zıplıyor (satırda 2 öbek varsa önce soldaki, sonra sağdaki, sonra
  // bir sonraki satır). Son adıma ulaşınca durur — öğrenci yine de
  // kendi "BİTİRDİM"e basar.
  void _scheduleZigzagStep() {
    final totalSteps = _groupTotalSteps(_zigzagLines);
    if (_zigzagActiveStep >= totalSteps - 1) return;
    _zigzagStepTimer = Timer(
      Duration(milliseconds: _stepMsBySpeed[_speedLevel]),
      () {
        if (!mounted || _phase != _Phase.zigzag) return;
        setState(() => _zigzagActiveStep++);
        _scheduleZigzagStep();
      },
    );
  }

  void _finishZigzag() {
    if (_zigzagFinished) return;
    _zigzagTimer?.cancel();
    _zigzagStepTimer?.cancel();
    setState(() => _zigzagFinished = true);
    SoundManager.playCorrect();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _phase = _Phase.wordBoxIntro);
    });
  }

  // ---------------- 2. BÖLÜM: Kelime Kutucukları ----------------

  void _startWordBoxPage() {
    _wordBoxStepTimer?.cancel();
    _wordBoxBlinkTimer?.cancel();
    setState(() {
      _phase = _Phase.wordBox;
      _wordBoxElapsedSec = 0;
      _wordBoxFinished = false;
      _wordBoxActiveStep = 0;
      _wordBoxBlinkOn = true;
    });
    _wordBoxTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _wordBoxElapsedSec++);
    });
    _wordBoxBlinkTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (!mounted) return;
      setState(() => _wordBoxBlinkOn = !_wordBoxBlinkOn);
    });
    _scheduleWordBoxStep();
  }

  // Nokta önce kutudaki soldaki kelimenin, sonra sağdaki kelimenin altına
  // zıplıyor, ardından bir sonraki kutuya geçiyor.
  void _scheduleWordBoxStep() {
    final totalSteps = _wordBoxPages[_wordBoxPageIndex].pairs.length * 2;
    if (_wordBoxActiveStep >= totalSteps - 1) return;
    _wordBoxStepTimer = Timer(
      Duration(milliseconds: _stepMsBySpeed[_speedLevel]),
      () {
        if (!mounted || _phase != _Phase.wordBox) return;
        setState(() => _wordBoxActiveStep++);
        _scheduleWordBoxStep();
      },
    );
  }

  void _finishWordBoxPage() {
    if (_wordBoxFinished) return;
    _wordBoxTimer?.cancel();
    _wordBoxStepTimer?.cancel();
    _wordBoxBlinkTimer?.cancel();
    setState(() => _wordBoxFinished = true);
    _wordBoxAttemptTimes[_wordBoxPageIndex].add(_wordBoxElapsedSec);
    SoundManager.playCorrect();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_wordBoxAttemptIndex < _wordBoxAttemptsPerPage - 1) {
        // Bu sayfanın son denemesi değil — aynı sayfayı tekrar deneyeceğiz.
        setState(() {
          _wordBoxAttemptIndex++;
          _phase = _Phase.wordBoxIntro;
        });
      } else if (_wordBoxPageIndex < _wordBoxPages.length - 1) {
        setState(() {
          _wordBoxPageIndex++;
          _wordBoxAttemptIndex = 0;
          _phase = _Phase.wordBoxIntro;
        });
      } else {
        _finishAll();
      }
    });
  }

  void _finishAll() {
    _zigzagTimer?.cancel();
    _zigzagStepTimer?.cancel();
    _wordBoxTimer?.cancel();
    _wordBoxStepTimer?.cancel();
    _wordBoxBlinkTimer?.cancel();
    _hasCompletedOnce = true;

    const percent = 100;
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final wordBoxSummary = _wordBoxAttemptTimes
        .map((times) => times.map((t) => '$t sn').join(', '))
        .join(' · ');
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Göz Hızı',
      result: 'Zikzak: $_zigzagElapsedSec sn · Kutucuklar: $wordBoxSummary',
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
            Text('Zikzak Okuma Süresi: $_zigzagElapsedSec sn'),
            for (int i = 0; i < _wordBoxAttemptTimes.length; i++)
              Text(
                'Kutucuklar · Sayfa ${i + 1} Denemeleri: '
                '${_wordBoxAttemptTimes[i].map((t) => "$t sn").join(", ")}',
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
                _phase = _Phase.zigzagIntro;
                _wordBoxPageIndex = 0;
                _wordBoxAttemptIndex = 0;
                for (final times in _wordBoxAttemptTimes) {
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

  void _pauseGame() {
    _zigzagTimer?.cancel();
    _zigzagStepTimer?.cancel();
    _wordBoxTimer?.cancel();
    _wordBoxStepTimer?.cancel();
    _wordBoxBlinkTimer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resumeGame() {
    setState(() => _isPaused = false);
    switch (_phase) {
      case _Phase.zigzag:
        if (!_zigzagFinished) {
          _zigzagTimer = Timer.periodic(const Duration(seconds: 1), (_) {
            if (!mounted) return;
            setState(() => _zigzagElapsedSec++);
          });
          _scheduleZigzagStep();
        }
      case _Phase.wordBox:
        if (!_wordBoxFinished) {
          _wordBoxTimer = Timer.periodic(const Duration(seconds: 1), (_) {
            if (!mounted) return;
            setState(() => _wordBoxElapsedSec++);
          });
          _wordBoxBlinkTimer = Timer.periodic(
            const Duration(milliseconds: 450),
            (_) {
              if (!mounted) return;
              setState(() => _wordBoxBlinkOn = !_wordBoxBlinkOn);
            },
          );
          _scheduleWordBoxStep();
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
        appBar: AppBar(
          title: const Text('👀 Göz Hızı'),
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
      case _Phase.zigzagIntro:
        return KeyedSubtree(
          key: const ValueKey('zigzag-intro'),
          child: _buildZigzagIntro(),
        );
      case _Phase.zigzag:
        return KeyedSubtree(
          key: const ValueKey('zigzag-flow'),
          child: _buildZigzagFlow(),
        );
      case _Phase.wordBoxIntro:
        return KeyedSubtree(
          key: ValueKey('wordbox-intro-$_wordBoxPageIndex'),
          child: _buildWordBoxIntro(),
        );
      case _Phase.wordBox:
        return KeyedSubtree(
          key: ValueKey('wordbox-flow-$_wordBoxPageIndex'),
          child: _buildWordBoxFlow(),
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
                              instruction,
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

  Widget _buildZigzagIntro() {
    return _buildIntro(
      badge: '1. Bölüm · Zikzak Okuma',
      emoji: '👁️',
      instruction:
          'Amaç: Yatay göz hareketlerini hızlandırmak ve görüş açımızı '
          'genişletmek.\n\nYöntem: Önce soldan sağa, sonra sayfanın '
          'ortasından aşağı doğru bakarak ve içten seslendirmeden en kısa '
          'sürede bitirmeye çalış (hedef: 5-7 saniye). Altında zıplayan '
          'noktayı takip et — hızını aşağıdan kendin ayarlayabilirsin!',
      onStart: _startZigzag,
    );
  }

  Widget _buildWordBoxIntro() {
    final page = _wordBoxPages[_wordBoxPageIndex];
    final previousTimes = _wordBoxAttemptTimes[_wordBoxPageIndex];
    final encouragement = previousTimes.isEmpty
        ? ''
        : '\n\nÖnceki denemelerin: '
              '${previousTimes.map((t) => "$t sn").join(", ")} — bu sefer '
              'daha hızlı olmaya çalışalım!';
    return _buildIntro(
      badge:
          '2. Bölüm · Sayfa ${_wordBoxPageIndex + 1}/${_wordBoxPages.length} '
          '· Deneme ${_wordBoxAttemptIndex + 1}/$_wordBoxAttemptsPerPage',
      emoji: '🟩',
      instruction:
          'Amaç: ${page.amac}\n\nYöntem: ${page.yontem}\n\n${page.note} '
          'Altında zıplayan noktayı takip et — hızını aşağıdan kendin '
          'ayarlayabilirsin!$encouragement',
      onStart: _startWordBoxPage,
    );
  }

  // Hız değişince öğrenci sayfanın başına dönsün diye aktif adım sıfırlanıp
  // akış yeni hızla baştan planlanıyor — farklı hızların karışması yerine
  // her zaman tek bir tutarlı hızda tekrar baştan izleniyor.
  void _changeSpeed(int level) {
    if (_phase == _Phase.zigzag) {
      _zigzagStepTimer?.cancel();
      setState(() {
        _speedLevel = level;
        _zigzagActiveStep = 0;
      });
      _scheduleZigzagStep();
    } else if (_phase == _Phase.wordBox) {
      _wordBoxStepTimer?.cancel();
      setState(() {
        _speedLevel = level;
        _wordBoxActiveStep = 0;
      });
      _scheduleWordBoxStep();
    } else {
      setState(() => _speedLevel = level);
    }
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
            style: TextStyle(fontWeight: FontWeight.bold, color: _color),
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

  Widget _buildZigzagFlow() {
    final lineStarts = _groupStarts(_zigzagLines);
    final activeLine = _lineIndexForStep(lineStarts, _zigzagActiveStep);
    return Column(
      children: [
        _stageHeader(
          '1. Bölüm · Satır ${activeLine + 1}/${_zigzagLines.length}',
          timerText: 'Süre: $_zigzagElapsedSec sn',
          showPause: true,
        ),
        const SizedBox(height: 10),
        _speedChipRow(),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (int i = 0; i < _zigzagLines.length; i++)
                  _zigzagLineBlock(i, _zigzagActiveStep - lineStarts[i]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _zigzagFinished ? null : _finishZigzag,
            icon: Icon(
              _zigzagFinished ? Icons.check_circle : Icons.check_circle_outline,
            ),
            label: Text(
              _zigzagFinished
                  ? 'Tamamlandı! ($_zigzagElapsedSec sn)'
                  : 'BİTİRDİM',
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

  // offset < 0: bu satırda aktif öbek yok. Aksi halde 0 = soldaki
  // (ya da tek) öbek, 1 = sağdaki öbek aktif demek.
  Widget _zigzagLineBlock(int index, int offset) {
    final phrases = _zigzagLines[index];
    final isLineActive = offset >= 0 && offset < phrases.length;
    return Column(
      children: [
        _zigzagLineBanner(index, activePhrase: isLineActive ? offset : -1),
        const SizedBox(height: 4),
        if (isLineActive)
          _activeDot(
            alignment: phrases.length == 1 ? 0.0 : (offset == 0 ? -0.6 : 0.6),
          ),
      ],
    );
  }

  Widget _zigzagLineBanner(int index, {required int activePhrase}) {
    final phrases = _zigzagLines[index];
    final color = index.isEven ? _zigzagBlue : _zigzagYellow;
    final isLineActive = activePhrase >= 0;

    Widget phraseText(int p) {
      final active = activePhrase == p;
      return AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: active ? 17 : 15,
          color: active ? _color : Colors.black87,
        ),
        child: Text(phrases[p]),
      );
    }

    final banner = ClipPath(
      clipper: const _ChevronBannerClipper(),
      child: Container(
        width: double.infinity,
        height: 46,
        color: color,
        padding: const EdgeInsets.symmetric(horizontal: 34),
        alignment: Alignment.center,
        child: phrases.length == 1
            ? phraseText(0)
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [phraseText(0), phraseText(1)],
              ),
      ),
    );
    // Aktif satır hafifçe büyür — hangi satırda olduğunu belirginleştirir.
    return AnimatedScale(
      scale: isLineActive ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: banner,
    );
  }

  // Altında zıplayan, öğrencinin takip etmesi gereken nokta. `alignment`
  // -1..1 arası yatay konumu belirler: tek öbekli satırda/kutuda 0
  // (ortada), iki öbekli satırda/kutuda soldaki için negatif, sağdaki
  // için pozitif — nokta önce soldakinin, sonra sağdakinin altına zıplar.
  Widget _activeDot({double alignment = 0.0}) {
    final stepKey = _phase == _Phase.zigzag
        ? _zigzagActiveStep
        : _wordBoxActiveStep;
    return Align(
      alignment: Alignment(alignment, 0),
      child: TweenAnimationBuilder<double>(
        key: ValueKey(stepKey),
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

  Widget _buildWordBoxFlow() {
    final page = _wordBoxPages[_wordBoxPageIndex];
    final activePair = _wordBoxActiveStep ~/ 2;
    final activeWordInPair = _wordBoxActiveStep % 2;
    return Column(
      children: [
        _stageHeader(
          '2. Bölüm · Sayfa ${_wordBoxPageIndex + 1}/${_wordBoxPages.length} · '
          'Deneme ${_wordBoxAttemptIndex + 1}/$_wordBoxAttemptsPerPage · '
          'Kutu ${activePair + 1}/${page.pairs.length}',
          timerText: 'Süre: $_wordBoxElapsedSec sn',
          showPause: true,
        ),
        const SizedBox(height: 8),
        _speedChipRow(),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _wordBoxDirectionHint(),
                for (int i = 0; i < page.pairs.length; i++)
                  _wordBoxBlock(
                    page.pairs[i],
                    activeWord: i == activePair ? activeWordInPair : -1,
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
            onPressed: _wordBoxFinished ? null : _finishWordBoxPage,
            icon: Icon(
              _wordBoxFinished
                  ? Icons.check_circle
                  : Icons.check_circle_outline,
            ),
            label: Text(
              _wordBoxFinished
                  ? 'Tamamlandı! ($_wordBoxElapsedSec sn)'
                  : 'BİTİRDİM',
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
  Widget _wordBoxDirectionHint() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Expanded(child: Center(child: _WordBoxDot())),
          const Icon(
            Icons.arrow_forward_rounded,
            size: 18,
            color: Color(0xFF38BDF8),
          ),
          const Expanded(child: Center(child: _WordBoxDot())),
        ],
      ),
    );
  }

  // activeWord < 0: bu kutuda aktif kelime yok. Aksi halde 0 = soldaki,
  // 1 = sağdaki kelime aktif. Nokta SADECE ilk kutuda (_wordBoxActiveStep
  // == 0) beliriyor — yönü gösterdikten sonra kayboluyor, çünkü her
  // satırda yeniden belirip kaybolması listeyi "kaydırıyormuş" gibi bir
  // görünüme sebep oluyordu. Ondan sonra aktif kutu yanıp sönerek kendini
  // belli ediyor.
  Widget _wordBoxBlock(List<String> pair, {required int activeWord}) {
    return Column(
      children: [
        _wordBoxRow(pair, activeWord: activeWord),
        if (activeWord >= 0 && _wordBoxActiveStep == 0)
          _activeDot(alignment: activeWord == 0 ? -0.5 : 0.5),
      ],
    );
  }

  Widget _wordBoxRow(List<String> pair, {required int activeWord}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: _wordBoxCell(pair[0], isActive: activeWord == 0)),
          const SizedBox(width: 10),
          Expanded(child: _wordBoxCell(pair[1], isActive: activeWord == 1)),
        ],
      ),
    );
  }

  Widget _wordBoxCell(String text, {bool isActive = false}) {
    // Aktif kutu yanıp sönerek kendini belli ediyor — nokta artık sadece
    // ilk kutuda göründüğü için, buradan sonrasında tek gösterge bu.
    final blinkLit = isActive && _wordBoxBlinkOn;
    return AnimatedScale(
      scale: isActive ? 1.06 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: blinkLit ? const Color(0xFFC5E8A0) : const Color(0xFFDFF3CC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? _color : const Color(0xFFA9D888),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isActive ? _color : const Color(0xFF2E5A1C),
          ),
        ),
      ),
    );
  }
}

class _WordBoxDot extends StatelessWidget {
  const _WordBoxDot();

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

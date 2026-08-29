import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';

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
  static const Color _color = Color(0xFF65A30D);

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

  // 2. Bölüm: Kelime Kutucukları.
  int _wordBoxPageIndex = 0;
  final List<int> _wordBoxTimes = [];
  Timer? _wordBoxTimer;
  int _wordBoxElapsedSec = 0;
  bool _wordBoxFinished = false;

  @override
  void dispose() {
    _zigzagTimer?.cancel();
    _wordBoxTimer?.cancel();
    super.dispose();
  }

  // ---------------- 1. BÖLÜM: Zikzak Okuma ----------------

  void _startZigzag() {
    setState(() {
      _phase = _Phase.zigzag;
      _zigzagElapsedSec = 0;
      _zigzagFinished = false;
    });
    _zigzagTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _zigzagElapsedSec++);
    });
  }

  void _finishZigzag() {
    if (_zigzagFinished) return;
    _zigzagTimer?.cancel();
    setState(() => _zigzagFinished = true);
    SoundManager.playCorrect();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _phase = _Phase.wordBoxIntro);
    });
  }

  // ---------------- 2. BÖLÜM: Kelime Kutucukları ----------------

  void _startWordBoxPage() {
    setState(() {
      _phase = _Phase.wordBox;
      _wordBoxElapsedSec = 0;
      _wordBoxFinished = false;
    });
    _wordBoxTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _wordBoxElapsedSec++);
    });
  }

  void _finishWordBoxPage() {
    if (_wordBoxFinished) return;
    _wordBoxTimer?.cancel();
    setState(() => _wordBoxFinished = true);
    _wordBoxTimes.add(_wordBoxElapsedSec);
    SoundManager.playCorrect();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_wordBoxPageIndex < _wordBoxPages.length - 1) {
        setState(() {
          _wordBoxPageIndex++;
          _phase = _Phase.wordBoxIntro;
        });
      } else {
        _finishAll();
      }
    });
  }

  void _finishAll() {
    _zigzagTimer?.cancel();
    _wordBoxTimer?.cancel();
    _hasCompletedOnce = true;

    const percent = 100;
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final wordBoxSummary = _wordBoxTimes.map((t) => '$t sn').join(' · ');
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
            for (int i = 0; i < _wordBoxTimes.length; i++)
              Text(
                'Kutucuklar · Sayfa ${i + 1} Süresi: ${_wordBoxTimes[i]} sn',
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
                _wordBoxTimes.clear();
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
    _wordBoxTimer?.cancel();
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
        }
      case _Phase.wordBox:
        if (!_wordBoxFinished) {
          _wordBoxTimer = Timer.periodic(const Duration(seconds: 1), (_) {
            if (!mounted) return;
            setState(() => _wordBoxElapsedSec++);
          });
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
        appBar: AppBar(title: const Text('👀 Göz Hızı')),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget _buildZigzagIntro() {
    return _buildIntro(
      badge: '1. Bölüm · Zikzak Okuma',
      emoji: '👁️',
      instruction:
          'Amaç: Yatay göz hareketlerini hızlandırmak ve görüş açımızı '
          'genişletmek.\n\nYöntem: Önce soldan sağa, sonra sayfanın '
          'ortasından aşağı doğru bakarak ve içten seslendirmeden en kısa '
          'sürede bitirmeye çalış (hedef: 5-7 saniye).',
      onStart: _startZigzag,
    );
  }

  Widget _buildWordBoxIntro() {
    final page = _wordBoxPages[_wordBoxPageIndex];
    return _buildIntro(
      badge:
          '2. Bölüm · Sayfa ${_wordBoxPageIndex + 1}/${_wordBoxPages.length}',
      emoji: '🟩',
      instruction:
          'Amaç: ${page.amac}\n\nYöntem: ${page.yontem}\n\n${page.note}',
      onStart: _startWordBoxPage,
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

  Widget _buildZigzagFlow() {
    return Column(
      children: [
        _stageHeader(
          '1. Bölüm · Zikzak Okuma',
          timerText: 'Süre: $_zigzagElapsedSec sn',
          showPause: true,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (int i = 0; i < _zigzagLines.length; i++) ...[
                  _zigzagLineBanner(i),
                  if (i < _zigzagLines.length - 1) _zigzagArrowMarker(i),
                ],
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

  Widget _zigzagLineBanner(int index) {
    final phrases = _zigzagLines[index];
    final color = index.isEven ? _zigzagBlue : _zigzagYellow;
    return ClipPath(
      clipper: const _ChevronBannerClipper(),
      child: Container(
        width: double.infinity,
        height: 46,
        color: color,
        padding: const EdgeInsets.symmetric(horizontal: 34),
        alignment: Alignment.center,
        child: phrases.length == 1
            ? Text(
                phrases[0],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    phrases[0],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    phrases[1],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Satır aralarındaki küçük üçgen işaretler, kitaptaki gibi göz akışının
  // dönüşümlü olarak sola-sağa kaydığını gösteriyor.
  Widget _zigzagArrowMarker(int index) {
    return Align(
      alignment: index.isEven
          ? const Alignment(-0.5, 0)
          : const Alignment(0.5, 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          '▲',
          style: TextStyle(fontSize: 12, color: _color.withValues(alpha: 0.7)),
        ),
      ),
    );
  }

  Widget _buildWordBoxFlow() {
    final page = _wordBoxPages[_wordBoxPageIndex];
    return Column(
      children: [
        _stageHeader(
          '2. Bölüm · Sayfa ${_wordBoxPageIndex + 1}/${_wordBoxPages.length}',
          timerText: 'Süre: $_wordBoxElapsedSec sn',
          showPause: true,
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _wordBoxDirectionHint(),
                for (final pair in page.pairs) _wordBoxRow(pair),
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

  Widget _wordBoxRow(List<String> pair) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: _wordBoxCell(pair[0])),
          const SizedBox(width: 10),
          Expanded(child: _wordBoxCell(pair[1])),
        ],
      ),
    );
  }

  Widget _wordBoxCell(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF7CB342),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Color(0xFF0F3D1E),
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

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';

enum _Phase { zigzagIntro, zigzag, memoryIntro, memoryShow, memoryRound }

class _NamedObject {
  final String emoji;
  final String name;
  const _NamedObject(this.emoji, this.name);
}

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

/// Klasör 2'nin yedinci etkinliği: "Sınıf Eşyaları". İki bölüm:
/// 1) Zikzak Okuma — kitaptaki yatay göz hareketi metnini dönüşümlü
/// mavi/sarı şeritler halinde gösterip öğrencinin kendi hızında, içten
/// seslendirmeden en kısa sürede okumasını istiyor (Etkinlik 2'deki Satır
/// Akışı ile aynı olduğu için o mekanizma kaldırıldı, yerine bu geldi),
/// 2) Dikkat ve Hafıza — 5 nesne 10 sn gösterilir, sonra her saniye biri
/// eksilerek gösterilir, öğrenci hangisinin eksildiğini bulmaya çalışır.
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

  // 2. Bölüm'de kullanılan 5 nesne.
  static const List<_NamedObject> _memoryPool = [
    _NamedObject('🧸', 'Oyuncak ayı'),
    _NamedObject('🕰️', 'Duvar saati'),
    _NamedObject('🇹🇷', 'Ay yıldız bayrak'),
    _NamedObject('🍏', 'Yeşil elma'),
    _NamedObject('🍋', 'Sarı limon'),
  ];

  static const int _memoryRoundCount = 4; // 5 nesne → 4 eksiltme adımı

  final Random _random = Random();
  _Phase _phase = _Phase.zigzagIntro;
  bool _hasCompletedOnce = false;
  bool _isPaused = false;

  // 1. Bölüm: Zikzak Okuma.
  Timer? _zigzagTimer;
  int _zigzagElapsedSec = 0;
  bool _zigzagFinished = false;

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
    _zigzagTimer?.cancel();
    _memoryTimer?.cancel();
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
      setState(() => _phase = _Phase.memoryIntro);
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
    _zigzagTimer?.cancel();
    _memoryTimer?.cancel();
    _hasCompletedOnce = true;

    final percent = ((_memoryScore / _memoryRoundCount) * 100).round();
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Sınıf Eşyaları',
      result:
          'Zikzak okuma: $_zigzagElapsedSec sn · Hafıza: $_memoryScore/$_memoryRoundCount',
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
              setState(() => _phase = _Phase.zigzagIntro);
            },
            child: const Text('Yeniden Başlat'),
          ),
        ],
      ),
    );
  }

  void _pauseGame() {
    _zigzagTimer?.cancel();
    _memoryTimer?.cancel();
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
      case _Phase.memoryShow:
        _memoryTimer = Timer(const Duration(seconds: 10), () {
          if (!mounted) return;
          _startMemoryRound();
        });
      case _Phase.memoryRound:
        if (_memoryShowingSet) {
          _memoryTimer = Timer(const Duration(seconds: 1), () {
            if (!mounted) return;
            setState(() => _memoryShowingSet = false);
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
        appBar: AppBar(title: const Text('🎒 Sınıf Eşyaları')),
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

  Widget _buildMemoryIntro() {
    return _buildIntro(
      badge: '2. Bölüm · Dikkat ve Hafıza',
      emoji: '🧠',
      instruction:
          'Amaç: Dikkat ve odaklanmayı geliştirmek. Önce 5 eşya 10 saniye '
          'gösterilecek. Sonra her saniye bir eşya eksilerek gösterilecek — '
          'her seferinde hangisinin eksildiğini zihninden bulmaya çalış!',
      onStart: _startMemory,
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

  Widget _buildMemoryShow() {
    return Column(
      children: [
        _stageHeader('2. Bölüm · İlk Gösterim (10 sn)', showPause: true),
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
          showPause: _memoryShowingSet && !_memoryAnswered,
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

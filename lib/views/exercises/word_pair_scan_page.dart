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

// Sayfalardan biri (1. sayfa) kitaptaki gibi kesikli çizgiyle çevrili.
class _DashedRectPainter extends CustomPainter {
  final Color color;
  const _DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(10),
    );
    final path = Path()..addRRect(rrect);
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) =>
      oldDelegate.color != color;
}

enum _Phase { warmup, exercise }

/// Klasör 3'ün dokuzuncu etkinliği: "Kelime Çiftleri Tarama". Kitaptaki
/// Etkinlik 1/2/3'ün karşılığı — her kutuda ortadaki noktaya odaklanarak
/// algılanacak iki kelime var. Sabit bir kutucuk sırayla dört yönde
/// geziniyor: önce soldan sağa, sonra sağdan sola, sonra aşağıdan
/// yukarıya, en son yukarıdan aşağıya. Kitaptaki 3 sayfanın (her biri
/// kendi renk/çerçeve stiliyle) her biri bu dört yönle taranıyor.
class WordPairScanPage extends StatefulWidget {
  const WordPairScanPage({super.key});

  @override
  State<WordPairScanPage> createState() => _WordPairScanPageState();
}

class _WordPairScanPageState extends State<WordPairScanPage> {
  static const Color _color = Color(0xFF65A30D);
  static const List<String> _speedLabels = [
    'Yavaş',
    'Orta',
    'Hızlı',
    'Çok Hızlı',
  ];
  static const List<int> _stepMsBySpeed = [1100, 750, 450, 220];
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
  static const int _cols = 4;

  // Kitaptaki Etkinlik 1.
  static const List<_WordPair> _page1 = [
    _WordPair('Sevgi', 'Saygı'),
    _WordPair('Silgi', 'Bilgi'),
    _WordPair('Çizgi', 'Dizgi'),
    _WordPair('Döngü', 'Görgü'),
    _WordPair('Çalgı', 'Salgı'),
    _WordPair('Etki', 'Bitki'),
    _WordPair('Çengi', 'Dergi'),
    _WordPair('Dolgu', 'Bulgu'),
    _WordPair('Halbuki', 'Mademki'),
    _WordPair('Çalgı', 'Sargı'),
    _WordPair('Katkı', 'Atkı'),
    _WordPair('Baskı', 'Askı'),
    _WordPair('Vergi', 'Sergi'),
    _WordPair('Sezgi', 'Ezgi'),
    _WordPair('Yergi', 'Sürgü'),
    _WordPair('Sorgu', 'Yazgı'),
    _WordPair('Eski', 'Püskü'),
    _WordPair('Belki', 'Sanki'),
    _WordPair('Yetki', 'Biçki'),
    _WordPair('Çünkü', 'Süngü'),
    _WordPair('Hangi', 'Keski'),
    _WordPair('Mevki', 'Tilki'),
    _WordPair('Coşku', 'Korku'),
    _WordPair('Tutku', 'Utku'),
  ];

  // Kitaptaki Etkinlik 2.
  static const List<_WordPair> _page2 = [
    _WordPair('Gezgin', 'Bilgin'),
    _WordPair('Soygun', 'Bozgun'),
    _WordPair('Yangın', 'Kızgın'),
    _WordPair('Bitkin', 'Yetkin'),
    _WordPair('Sezgin', 'Bezgin'),
    _WordPair('Etkin', 'Seçkin'),
    _WordPair('Yatkın', 'Katkın'),
    _WordPair('Vurgun', 'Yorgun'),
    _WordPair('Üzgün', 'Süzgün'),
    _WordPair('Saygın', 'Baygın'),
    _WordPair('Kırgın', 'Dargın'),
    _WordPair('Solgun', 'Olgun'),
    _WordPair('Keskin', 'Sürgün'),
    _WordPair('Salgın', 'Dalgın'),
    _WordPair('Dolgun', 'Durgun'),
    _WordPair('Bezgin', 'Dizgin'),
    _WordPair('Baskın', 'Taşkın'),
    _WordPair('Bıçkın', 'Kaçkın'),
    _WordPair('Düzgün', 'Dingin'),
    _WordPair('Zengin', 'Engin'),
  ];

  // Kitaptaki Etkinlik 3.
  static const List<_WordPair> _page3 = [
    _WordPair('Birlik', 'Dirlik'),
    _WordPair('Benlik', 'Senlik'),
    _WordPair('İkilik', 'Beşlik'),
    _WordPair('Güvenlik', 'İşçilik'),
    _WordPair('Güzellik', 'Çirkinlik'),
    _WordPair('Özgürlük', 'Güvenirlik'),
    _WordPair('Kalemlik', 'Şekerlik'),
    _WordPair('Yolluk', 'Tuzluk'),
    _WordPair('Bolluk', 'Darlık'),
    _WordPair('Odunluk', 'Çamurluk'),
    _WordPair('Bilgelik', 'Bilimsellik'),
    _WordPair('Birliktelik', 'Beraberlik'),
    _WordPair('İyilik', 'Kötülük'),
    _WordPair('Yüreklilik', 'Sessizlik'),
    _WordPair('Saygınlık', 'Çalışkanlık'),
    _WordPair('Aydınlık', 'Karanlık'),
    _WordPair('Yaşlılık', 'Delikanlılık'),
    _WordPair('Öğrencilik', 'Seçkinlik'),
    _WordPair('Yazlık', 'Kışlık'),
    _WordPair('Zenginlik', 'Fakirlik'),
    _WordPair('İncelik', 'Çiçeklik'),
    _WordPair('Sağlık', 'Hastalık'),
    _WordPair('Yemeklik', 'Sebzelik'),
    _WordPair('Etkinlik', 'Yetkinlik'),
  ];

  late final List<List<_WordPair>> _pages = [_page1, _page2, _page3];

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startWarmup());
  }

  @override
  void dispose() {
    _sweepTimer?.cancel();
    _blinkTimer?.cancel();
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
      _startExercise();
      return;
    }
    if (_pageIndex < _pages.length - 1) {
      setState(() {
        _pageIndex++;
        _directionIndex = 0;
      });
      _startDirection();
    } else {
      _finishAll();
    }
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
      type: 'Kelime Çiftleri Tarama',
      result: '${_pages.length} sayfa · 4 yön',
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
              '${_pages.length} sayfayı da 4 yönden tarayarak bitirdik!',
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
        appBar: AppBar(title: const Text('🔎 Kelime Çiftleri Tarama')),
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
                  _Phase.exercise => _buildScan(
                    key: ValueKey('ex-$_pageIndex-$_directionIndex'),
                    pageStyle: _pageIndex,
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
                        : 'Sayfa ${_pageIndex + 1}/${_pages.length} · '
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
          const SizedBox(height: 8),
          _speedChipRow(),
          const SizedBox(height: 12),
          Expanded(child: _grid(pairs, pageStyle)),
        ],
      ),
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
        final cellHeight = rawCellHeight.clamp(88.0, 140.0);
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
            child: _pairBox(
              pair,
              lit: lit,
              isActive: isActive,
              pageStyle: pageStyle,
            ),
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

  Widget _pairBox(
    _WordPair pair, {
    required bool lit,
    required bool isActive,
    required int pageStyle,
  }) {
    Color bg;
    Color border;
    Color fg;
    switch (pageStyle) {
      case 1:
        bg = const Color(0xFFE3A857);
        border = const Color(0xFF92400E);
        fg = const Color(0xFF451A03);
      case 2:
        bg = const Color(0xFFDDA0DD);
        border = const Color(0xFF6B21A8);
        fg = const Color(0xFF3B0764);
      default:
        bg = Colors.white;
        border = Colors.grey.shade400;
        fg = const Color(0xFF334155);
    }
    if (lit) {
      bg = _color;
      fg = Colors.white;
    }
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: pageStyle == 0
            ? null
            : Border.all(color: lit ? _color : border, width: 1.4),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
    if (pageStyle != 0) return content;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _DashedRectPainter(
              color: lit ? _color : Colors.grey.shade400,
            ),
          ),
        ),
        content,
      ],
    );
  }
}

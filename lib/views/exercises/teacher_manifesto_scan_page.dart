import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';
import '../../widgets/exercise_settings_sheet.dart';
import '../../widgets/word_definition_sheet.dart';

enum _Direction { leftToRight, rightToLeft, bottomToTop, topToBottom }

enum _Phase { intro, warmup, ready, exercise, readIntro, read }

/// Klasör 4'ün yedinci etkinliği: "Ben Bir Öğretmenim" metni. Kitaptaki
/// 3 sütunlu sayfaların karşılığı — telefon ekranına sığmadığı için
/// word_pattern_scan_page/exam_word_group_scan_page'deki gibi 2 sütun
/// olarak gösteriliyor. Aynı mantık: antreman, sonra sıra sende, her
/// sayfa 4 yönde (soldan sağa/sağdan sola/aşağıdan yukarı/yukarıdan
/// aşağı) taranıyor. Sütunlar soldan sağa okununca tek bir akan metin
/// oluşturuyor (satır bazlı bölünmüş bir öğretmen manifestosu).
class TeacherManifestoScanPage extends StatefulWidget {
  const TeacherManifestoScanPage({super.key});

  @override
  State<TeacherManifestoScanPage> createState() =>
      _TeacherManifestoScanPageState();
}

class _TeacherManifestoScanPageState extends State<TeacherManifestoScanPage> {
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
  static const List<int> _stepMsBySpeed = [1000, 700, 480, 320];
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

  // Kitaptaki 3 sayfa (169-171), her sayfada 3 sütun. Sütunlar soldan
  // sağa okununca akan tek bir metin oluşturuyor.
  static const List<List<String>> _columns = [
    // Sayfa 169 - 1. sütun
    [
      'Ben bir öğretmenim,',
      'dolmalıyım. O apaydınlık',
      'Her zaman yanında',
      'sınırlandırmamalıyım.',
      'iki yüzü gibi,',
      'Ben bir öğretmenim,',
      'İkisi birleşince',
      'Ben de öğrencilerimle',
      'Bir zincirin halkaları gibi',
      'düşünceyi anlatmalıyız.',
      'tamamlamalıyız.',
      'gelecek için',
      'Ben bir öğretmenim,',
      'Kötülüklerden korumalıyım.',
      'söndürecek tüm fırtınalara',
      'yeşertmeliyim ümitlerini.',
      'cesaretlerini,',
    ],
    // Sayfa 169 - 2. sütun
    [
      'öğrencilerimin minicik',
      'zihinlerine kelime kelime',
      'olmalıyım onların.',
      'Ben ve öğrencilerim',
      'kalem ve silgi gibi,',
      'toprak suya hasret,',
      'nice güzelliklerle',
      'bir olmalıyım ve',
      'kenetlenmeliyiz. Bir',
      'Bir kalem ve silgi gibi',
      'Yani bir noktada',
      've değerlerimiz için',
      'bir fanus olmalıyım,',
      'Heveslerini kıracak,',
      'kalkan olmalıyım.',
      'Bir coşan deniz gibi',
      'öz güvenlerini',
    ],
    // Sayfa 169 - 3. sütun
    [
      'yüreklerine hece hece',
      'bilgi olarak akmalıyım.',
      'Sadece sınıfla ve okulla',
      'bir sayfanın',
      'toprak ve su gibiyiz.',
      'su toprağa...',
      'süslenir tüm dünya.',
      'yüreklerimiz bir atmalı.',
      'kitabın sayfaları gibi bir',
      'birbirimizi',
      'vatan için, bayrak için,',
      'birleşmeliyiz.',
      'temiz düşüncelerine.',
      'umutlarını, hayallerini',
      'Bir güneş gibi',
      'dalgalandırmalıyım',
      've tüm hayallerini.',
    ],
    // Sayfa 170 - 1. sütun
    [
      'Bir rüzgar gibi',
      'Gökkuşağı gibi',
      'Ben bir öğretmenim,',
      'Anahtar olmadan',
      'İki anahtar,',
      'açacak onlara',
      'Birincisi, inanmak;',
      'kendini küçük gören,',
      'sahip olsa da',
      'Tıpkı bisiklet',
      'bisiklet sürmekten',
      'gerektiğini anlatmalıyım.',
      'inanmadığımız sürece',
      'anlatmalıyım.',
      'çalışmanın, başarlı olmanın',
      'işlemeliyim zihinlerine.',
      'Ben bir öğretmenim,',
      'kandırılabileceklerini ve',
    ],
    // Sayfa 170 - 2. sütun
    [
      'hareketlendirmeliyim.',
      'renklendirmeliyim,',
      '"başarı kapısı"nın',
      'kapının kırılacağını',
      'başarı kapılarını',
      've başarı',
      'ikincisi çalışmak...',
      'kendini tanımayan',
      'başaramayacağını',
      'sürmek isteyen;',
      'vazgeçen çocuk gibi.',
      'Herkes bize inansa da',
      'küçük bir engeli bile',
      'Çalışma isteği',
      'ta kendisi olduğunu',
      'Çalışmayı sevdirmeliyim',
      'hata yapabileceklerini,',
      'insanların bazen',
    ],
    // Sayfa 170 - 3. sütun
    [
      'tüm hayatlarını.',
      'tüm geleceklerini.',
      'anahtarlarını öğretmeliyim',
      'hatırlatmalıyım onlara.',
      'sonuna kadar',
      'kucaklayacak onları.',
      'Kendine inanmayan,',
      'tüm imkanlara',
      'hatırlatmalıyım.',
      'fakat düşerim korkusuyla',
      'Kendisine inanması',
      'biz kendimize',
      'aşamayacağımızı',
      'aşılamalıyım onlara ve',
      'nakış nakış',
      'onları yüreklendirmeliyim.',
      'bazen kaybedebileceklerini,',
      'göründüğü gibi',
    ],
    // Sayfa 171 - 1. sütun
    [
      'çıkmayacağını',
      'alınan dersin,',
      'öğrenilen tecrübelerin,',
      'olduğunu da anlatmalıyım.',
      'hazırlıklı olmalarını',
      'Her duyduğu,',
      'olmadığı konusunda',
      'Ben bir öğretmenim,',
      'aralarında dostluk',
      'hayatın huzuru;',
      'zihinlerine işlemeliyim.',
      'parantez içinde',
      'Ben bir öğretmenim,',
      'vazgeçmemelerini,',
      'haksızlığa karşı',
      'Ben bir öğretmenim,',
      'paradan, makamdan',
      'gerektiğini, insana değer',
    ],
    // Sayfa 171 - 2. sütun
    [
      'hatırlatmalıyım onlara.',
      'doğru kadar;',
      'başarı kadar;',
      'Hayatın tüm akıntılarına',
      'öğretmeliyim onlara.',
      'her okuduğu bilginin ve',
      'onları bilinçlendirmeliyim.',
      'kitapları sevdirmeliyim',
      'kurmalarını sağlamalıyım.',
      'başarının, aklın anahtarı',
      'Her kitabın faydalı',
      'hafızalarına',
      'haklı olduklarında',
      'her zaman haklının',
      'öğrencilerime',
      've kazançtan önce',
      'vermemiz gerektiğini',
    ],
    // Sayfa 171 - 3. sütun
    [
      'Yalnız hatadan',
      'başarısızlıktan',
      'değerli, faydalı ve önemli',
      've tehlikelerine karşı da',
      'haberin gerçek ve doğru',
      'onlara. Kitaplarla',
      'Kitaplar ruhun ve',
      'olduğunu titizlikle',
      'olmadığını da',
      'not düşmeliyim.',
      'mücadeleden asla',
      'yanında olmaları ve',
      'işlemeliyim yüreklerine.',
      'her şeyden önce',
      'insan olmamız',
      've ilk önce',
    ],
  ];

  // Kitaptaki gerçek sayfa grupları (3'er sütun) — taramanın 2 sütunluk
  // ekran bölünmesinden bağımsız, "dümdüz okuma" bölümünde metni doğru
  // sırayla (satır satır, sütun sütun) birleştirmek için kullanılıyor.
  static const List<List<int>> _bookPages = [
    [0, 1, 2], // Sayfa 169
    [3, 4, 5], // Sayfa 170
    [6, 7, 8], // Sayfa 171
  ];

  String get _fullText {
    final buffer = StringBuffer();
    for (final page in _bookPages) {
      int maxLen = 0;
      for (final c in page) {
        if (_columns[c].length > maxLen) maxLen = _columns[c].length;
      }
      for (int r = 0; r < maxLen; r++) {
        for (final c in page) {
          if (r < _columns[c].length) {
            if (buffer.isNotEmpty) buffer.write(' ');
            buffer.write(_columns[c][r]);
          }
        }
      }
    }
    return buffer.toString();
  }

  static const List<Color> _bgByRole = [
    Color(0xFFDCFCE7),
    Color(0xFFDBEAFE),
    Color(0xFFFEF9C3),
  ];
  static const List<Color> _borderByRole = [
    Color(0xFF15803D),
    Color(0xFF1D4ED8),
    Color(0xFFCA8A04),
  ];

  // Ekrana 3 yerine 2 sütun sığdığı için sütunlar ikişer ikişer eşlenip
  // sayfalara bölündü (9 sütun -> 4 ikili + 1 tekli = 5 sayfa).
  late final List<List<int>> _pages = [
    for (int i = 0; i < _columns.length; i += 2)
      if (i + 1 < _columns.length) [i, i + 1] else [i],
  ];

  _Phase _phase = _Phase.intro;
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
  void dispose() {
    _sweepTimer?.cancel();
    _blinkTimer?.cancel();
    super.dispose();
  }

  List<int> get _currentColumns =>
      _phase == _Phase.warmup ? [0, 1] : _pages[_pageIndex];

  int get _currentRows {
    final cols = _currentColumns;
    int maxLen = 0;
    for (final c in cols) {
      final len = _phase == _Phase.warmup ? 8 : _columns[c].length;
      if (len > maxLen) maxLen = len;
    }
    return maxLen;
  }

  String? _cellText(int row, int col) {
    final cols = _currentColumns;
    if (col >= cols.length) return null;
    final lines = _columns[cols[col]];
    if (row >= (_phase == _Phase.warmup ? 8 : lines.length)) return null;
    return lines[row];
  }

  List<int> _sweepOrder(_Direction dir) {
    final rows = _currentRows;
    final order = <int>[];
    bool exists(int r, int c) => _cellText(r, c) != null;
    switch (dir) {
      case _Direction.leftToRight:
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < _cols; c++) {
            if (exists(r, c)) order.add(r * _cols + c);
          }
        }
      case _Direction.rightToLeft:
        for (int r = 0; r < rows; r++) {
          for (int c = _cols - 1; c >= 0; c--) {
            if (exists(r, c)) order.add(r * _cols + c);
          }
        }
      case _Direction.bottomToTop:
        for (int c = 0; c < _cols; c++) {
          for (int r = rows - 1; r >= 0; r--) {
            if (exists(r, c)) order.add(r * _cols + c);
          }
        }
      case _Direction.topToBottom:
        for (int c = 0; c < _cols; c++) {
          for (int r = 0; r < rows; r++) {
            if (exists(r, c)) order.add(r * _cols + c);
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
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 380), (_) {
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

  void _skipWarmup() {
    _sweepTimer?.cancel();
    _blinkTimer?.cancel();
    setState(() => _phase = _Phase.ready);
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
      setState(() => _phase = _Phase.readIntro);
    }
  }

  void _startRead() {
    setState(() => _phase = _Phase.read);
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
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 380), (_) {
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
      type: 'Ben Bir Öğretmenim',
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
        appBar: AppBar(
          title: const Text('👩‍🏫 Ben Bir Öğretmenim'),
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
                  _Phase.intro => _buildIntro(),
                  _Phase.warmup => _buildScan(
                    key: ValueKey('warmup-$_directionIndex'),
                  ),
                  _Phase.ready => _buildReady(),
                  _Phase.exercise => _buildScan(
                    key: ValueKey('ex-$_pageIndex-$_directionIndex'),
                  ),
                  _Phase.readIntro => _buildReadIntro(),
                  _Phase.read => _buildRead(),
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

  Widget _buildScan({required Key key}) {
    final isWarmup = _phase == _Phase.warmup;
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
                    style: TextStyle(
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
          Expanded(child: _grid()),
          if (isWarmup) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _skipWarmup,
                icon: const Icon(Icons.skip_next_rounded),
                label: const Text(
                  'ANTREMANI GEÇ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _color,
                  side: BorderSide(color: _color),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIntro() {
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
                    'Etkinlik 7 · Ben Bir Öğretmenim',
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
                    const Center(
                      child: Text('👩‍🏫', style: TextStyle(fontSize: 72)),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _color, width: 1.2),
                      ),
                      child: const Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF14532D),
                          ),
                          children: [
                            TextSpan(
                              text: 'Amaç: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  'Gözümüze ritim kazandırmak ve geriye '
                                  'dönüşü önlemek.\n',
                            ),
                            TextSpan(
                              text: 'Yöntem: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  'Bölünmüş alanlardaki kelimelerin '
                                  'ortasına odaklanarak kelime gruplarını '
                                  'tek bakışta algıla. Önce antremanı '
                                  'yapacağız, sonra sıra sende — 5 sayfayı '
                                  'da bu şekilde tarayacaksın!',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _speedChipRow(),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _startWarmup,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text(
                        'ANTREMANA GEÇ',
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
                const Center(
                  child: Text('👩‍🏫', style: TextStyle(fontSize: 64)),
                ),
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
                  child: Text(
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

  Widget _buildReadIntro() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: Text('📖', style: TextStyle(fontSize: 64))),
                const SizedBox(height: 16),
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
                    'Etkinlik 7 · Şimdi Sen Okuyacaksın',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _color,
                    ),
                  ),
                ),
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
                  child: Text(
                    '5 sayfayı 4 yönde taradık! Şimdi sen okuyacaksın — az '
                    'önce parçalar hâlinde gördüğün metnin tamamını normal, '
                    'akıcı bir şekilde baştan sona oku.',
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
                    onPressed: _startRead,
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

  Widget _buildRead() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '📖 Şimdi Sen Okuyacaksın',
            style: TextStyle(fontWeight: FontWeight.bold, color: _color),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: buildInteractiveText(
              context,
              _fullText,
              accentColor: _color,
              style: const TextStyle(
                fontSize: 17,
                height: 1.7,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _finishAll,
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

  Widget _grid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final rows = _currentRows;
        final cols = _currentColumns;
        final cellWidth =
            (constraints.maxWidth - spacing * (_cols - 1)) / _cols;
        final rawCellHeight =
            (constraints.maxHeight - spacing * (rows - 1)) / rows;
        final cellHeight = rawCellHeight.clamp(34.0, 60.0);

        Widget cellAt(int r, int c) {
          final text = _cellText(r, c);
          if (text == null) return SizedBox(width: cellWidth);
          final index = r * _cols + c;
          final isActive =
              index ==
              (_sweepIndices.isEmpty ? -1 : _sweepIndices[_activeIndex]);
          final lit = isActive && _blinkOn;
          final role = c < cols.length ? cols[c] % 3 : 0;
          return SizedBox(
            width: cellWidth,
            height: cellHeight,
            child: _cell(text, lit: lit, role: role),
          );
        }

        final rowWidgets = <Widget>[
          for (int r = 0; r < rows; r++)
            Padding(
              padding: EdgeInsets.only(bottom: r < rows - 1 ? spacing : 0),
              child: Row(
                children: [
                  for (int c = 0; c < _cols; c++) ...[
                    if (c > 0) const SizedBox(width: spacing),
                    cellAt(r, c),
                  ],
                ],
              ),
            ),
        ];

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: rowWidgets,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cell(String text, {required bool lit, required int role}) {
    Color bg = lit ? _color : _bgByRole[role];
    Color fg = lit ? Colors.white : _borderByRole[role];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: lit ? _color : _borderByRole[role],
          width: 1.2,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

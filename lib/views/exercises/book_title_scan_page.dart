import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';
import '../../widgets/exercise_settings_sheet.dart';

enum _Phase { intro, antreman, quizIntro, quizSearch, quizAnswer }

class _CountChallenge {
  final String target;
  final int correctCount;
  const _CountChallenge(this.target, this.correctCount);
}

/// Klasör 4'ün dokuzuncu etkinliği: kitaptaki Etkinlik 5 — 2 sütunlu kitap
/// adları listesi. Önce hepsi antreman olarak sırayla yanıp sönerek
/// gösteriliyor (gözün yatay görüş alanını genişletmek, içten
/// seslendirmeyi önlemek için), sonra bir kitap adının sayfada kaç kere
/// geçtiğini bulduğumuz bir soru bölümü var.
class BookTitleScanPage extends StatefulWidget {
  const BookTitleScanPage({super.key});

  @override
  State<BookTitleScanPage> createState() => _BookTitleScanPageState();
}

class _BookTitleScanPageState extends State<BookTitleScanPage> {
  Color _color = const Color(0xFF0D9488);

  static const List<Color> _colorPalette = [
    Color(0xFF0D9488),
    Color(0xFFEC4899),
    Color(0xFFEA580C),
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFFB45309),
  ];
  static const List<String> _speedLabels = [
    'Yavaş',
    'Orta',
    'Hızlı',
    'Çok Hızlı',
  ];
  static const List<int> _stepMsBySpeed = [800, 600, 450, 320];
  static const int _cols = 2;
  // Kutucuklar normal (okunaklı) boyutta kalsın diye 26 satırın tamamı tek
  // ekrana küçültülerek sığdırılmıyor — bunun yerine sayfalara bölünüyor.
  static const int _rowsPerPage = 7;

  // Kitaptaki Etkinlik 5, 1. ve 2. sayfa birleştirilmiş — 2 sütun, soldan
  // sağa okunuyor.
  static const List<String> _col1 = [
    'Dede Korkut Hikâyeleri',
    'Yalnız Efe',
    'En Bilge Kankam',
    'Vatan Toprağı',
    'Benim Küçük Dostlarım',
    'İyi ki Varsın',
    "Aşk Yolcusu Yunus Emre'm",
    'Bir Küçük Osmancık Vardı',
    'Yürekdede ile Padişah',
    'İnsan Ne ile Yaşar',
    'Keloğlan Masalları',
    'Define Adası',
    'Barbaros Hayrettin Geliyor',
    'Üç Minik Serçem',
    'Türk Bilmecelerinden Seçmeler',
    'Vatan Toprağı',
    'En Bilge Kankam',
    "Aşk Yolcusu Yunus Emre'm",
    'İyi ki Varsın',
    'Yankılı Kayalar',
    "Aşk Yolcusu Yunus Emre'm",
    'Tiryaki Sözler',
    'Nasreddin Hoca Fıkraları',
    'İyi ki Varsın',
    'Kırk Derste Fuat Sezgin',
    'İstiklal Marşı',
  ];

  static const List<String> _col2 = [
    'Karagöz ile Hacivat',
    'İyi ki Varsın',
    'İnsan Sevgi ile Yaşar',
    'Mesneviden Öyküler',
    'İstiklal Marşı',
    'Yer Altında Bir Şehir',
    "Arif Nihat Asya'dan Şiirler",
    'Aritmetik İyi Kuşlar Pekiyi',
    'Kırk Derste Fuat Sezgin',
    'Aldı Sözü Anadolu',
    "Mehmet Akif Ersoy'dan Seçmeler",
    'Kırk Derste Fuat Sezgin',
    'Öğrenciler İçin Hızlı Okuma',
    'Keloğlan Masalları',
    'Türk Atasözlerinden Seçmeler',
    'İstiklal Marşı',
    'İyi ki Varsın',
    'Öğrenciler İçin Hızlı Okuma',
    'Beklenen Sensin',
    'Çanakkale Geçilmez',
    'Dede Korkut Hikâyeleri',
    'Vatan yahut Silistre',
    'Anadolu Masalları',
    'Osmancık',
    "Sait Faik'ten Seçme Hikâyeler",
    'Evvel Zaman İçinde',
  ];

  static const List<_CountChallenge> _challenges = [
    _CountChallenge('İstiklal Marşı', 3),
    _CountChallenge('Dede Korkut Hikâyeleri', 2),
    _CountChallenge('Vatan Toprağı', 2),
    _CountChallenge("Aşk Yolcusu Yunus Emre'm", 3),
    _CountChallenge('Çanakkale Geçilmez', 1),
  ];

  _Phase _phase = _Phase.intro;
  bool _hasCompletedOnce = false;
  bool _isPaused = false;
  int _speedLevel = 1;

  int _activeIndex = 0;
  Timer? _sweepTimer;
  int _bookPageIndex = 0;

  int _challengeIndex = 0;
  int _quizSelected = 0;
  bool _quizAnswered = false;

  int get _rows => max(_col1.length, _col2.length);
  int get _totalBookPages => (_rows / _rowsPerPage).ceil();

  String? _cellText(int row, int col) {
    final list = col == 0 ? _col1 : _col2;
    if (row >= list.length) return null;
    return list[row];
  }

  @override
  void dispose() {
    _sweepTimer?.cancel();
    super.dispose();
  }

  void _startAntreman() {
    setState(() {
      _phase = _Phase.antreman;
      _activeIndex = 0;
      _bookPageIndex = 0;
    });
    _scheduleStep();
  }

  int get _totalCells => _col1.length + _col2.length;

  void _scheduleStep() {
    _sweepTimer?.cancel();
    _sweepTimer = Timer(
      Duration(milliseconds: _stepMsBySpeed[_speedLevel]),
      () {
        if (!mounted) return;
        SoundManager.playTick();
        if (_activeIndex >= _totalCells - 1) {
          setState(() => _phase = _Phase.quizIntro);
        } else {
          setState(() {
            _activeIndex++;
            _bookPageIndex = (_activeIndex ~/ _cols) ~/ _rowsPerPage;
          });
          _scheduleStep();
        }
      },
    );
  }

  void _changeSpeed(int level) {
    setState(() => _speedLevel = level);
    if (_phase == _Phase.antreman) {
      _sweepTimer?.cancel();
      _scheduleStep();
    }
  }

  void _pauseGame() {
    _sweepTimer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resumeGame() {
    setState(() => _isPaused = false);
    _scheduleStep();
  }

  void _startQuiz() {
    setState(() {
      _phase = _Phase.quizSearch;
      _challengeIndex = 0;
      _bookPageIndex = 0;
    });
  }

  void _goToBookPage(int page) {
    setState(() => _bookPageIndex = page.clamp(0, _totalBookPages - 1));
  }

  void _goToAnswer() {
    setState(() {
      _phase = _Phase.quizAnswer;
      _quizAnswered = false;
      _quizSelected = 0;
    });
  }

  void _submitAnswer(int selected) {
    if (_quizAnswered) return;
    final correct = _challenges[_challengeIndex].correctCount;
    setState(() {
      _quizSelected = selected;
      _quizAnswered = true;
    });
    if (selected == correct) {
      SoundManager.playCorrect();
    } else {
      SoundManager.playGentleTap();
    }
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_challengeIndex >= _challenges.length - 1) {
        _finishAll();
      } else {
        setState(() {
          _challengeIndex++;
          _phase = _Phase.quizSearch;
          _bookPageIndex = 0;
        });
      }
    });
  }

  void _finishAll() {
    _hasCompletedOnce = true;

    const percent = 100;
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Kitap Adları Taraması',
      result: 'Antreman + ${_challenges.length} soru tamamlandı',
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
              'Tüm kitap adlarını taradık ve ${_challenges.length} tekrar '
              'sorusunu cevapladık!',
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
              setState(() => _phase = _Phase.intro);
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
          title: const Text('📚 Kitap Adları Taraması'),
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
                  _Phase.antreman => _buildAntreman(),
                  _Phase.quizIntro => _buildQuizIntro(),
                  _Phase.quizSearch => _buildQuizSearch(),
                  _Phase.quizAnswer => _buildQuizAnswer(),
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
                    'Etkinlik 9 · Kitap Adları Taraması',
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
                      child: Text('📚', style: TextStyle(fontSize: 72)),
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
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(fontSize: 13, color: _color),
                          children: const [
                            TextSpan(
                              text: 'Amaç: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  'Gözün yatay görüş alanını artırabilmek '
                                  've içten seslendirmeyi önlemek.\n',
                            ),
                            TextSpan(
                              text: 'Yöntem: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  'Kutunun ortasına odaklanarak her '
                                  'kutudaki kitap adını tek bakışta '
                                  'algıla. Önce hepsi sırayla yanıp '
                                  'sönerek gösterilecek, sonra bir kitap '
                                  'adının sayfada kaç kere geçtiğini '
                                  'bulacağız!',
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
                      onPressed: _startAntreman,
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

  Widget _buildAntreman() {
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
                child: Text(
                  '🎓 Antreman · Kitap Adlarını Tara',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold, color: _color),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _badge('Sayfa ${_bookPageIndex + 1}/$_totalBookPages'),
            const SizedBox(width: 8),
            buildPauseButton(color: _color, onPressed: _pauseGame),
          ],
        ),
        const SizedBox(height: 8),
        _speedChipRow(),
        const SizedBox(height: 12),
        Expanded(child: _grid(blinkEnabled: true)),
      ],
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: _color,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildQuizIntro() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: Text('🔎', style: TextStyle(fontSize: 64))),
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
                    'Antremanı tamamladık! Şimdi sayfaları gezip bir kitap '
                    'adının kaç kere geçtiğini bulacaksın — ok '
                    'butonlarıyla sayfalar arasında gidip gelebilirsin. '
                    '${_challenges.length} soru var!',
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
                    onPressed: _startQuiz,
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

  Widget _buildQuizSearch() {
    final challenge = _challenges[_challengeIndex];
    return Column(
      key: ValueKey('search-$_challengeIndex'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Soru ${_challengeIndex + 1}/${_challenges.length} · '
            '"${challenge.target}" kaç kere geçiyor?',
            maxLines: 2,
            style: TextStyle(fontWeight: FontWeight.bold, color: _color),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(child: _grid(blinkEnabled: false)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              onPressed: _bookPageIndex > 0
                  ? () => _goToBookPage(_bookPageIndex - 1)
                  : null,
              icon: const Icon(Icons.chevron_left_rounded),
              label: const Text('Önceki'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _color,
                side: BorderSide(color: _color),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            _badge('Sayfa ${_bookPageIndex + 1}/$_totalBookPages'),
            OutlinedButton.icon(
              onPressed: _bookPageIndex < _totalBookPages - 1
                  ? () => _goToBookPage(_bookPageIndex + 1)
                  : null,
              icon: const Icon(Icons.chevron_right_rounded),
              label: const Text('Sonraki'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _color,
                side: BorderSide(color: _color),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _goToAnswer,
            icon: const Icon(Icons.check),
            label: const Text(
              'SAYDIM, CEVAPLA',
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

  Widget _buildQuizAnswer() {
    final challenge = _challenges[_challengeIndex];
    final options = <int>{challenge.correctCount};
    var probe = challenge.correctCount + challenge.target.length;
    while (options.length < 4) {
      probe += 5;
      final candidate = (challenge.correctCount - 2 + (probe % 5)).clamp(1, 6);
      options.add(candidate);
    }
    final sortedOptions = options.toList()..sort();
    return LayoutBuilder(
      key: ValueKey('answer-$_challengeIndex'),
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(
                    'Soru ${_challengeIndex + 1}/${_challenges.length}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '"${challenge.target}"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _color,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'kaç kere geçti?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (_quizAnswered) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      _quizSelected == challenge.correctCount
                          ? '🎉 Harikasın, doğru!'
                          : '📖 Doğrusu: ${challenge.correctCount}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _quizSelected == challenge.correctCount
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFE11D48),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final option in sortedOptions)
                      _answerButton(option, challenge.correctCount),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _answerButton(int option, int correctCount) {
    final answered = _quizAnswered;
    final isSelected = _quizSelected == option && answered;
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
        onPressed: answered ? null : () => _submitAnswer(option),
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
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: fg,
          ),
        ),
      ),
    );
  }

  // Kaydırma yok — kutucuklar normal/okunaklı boyutta kalır, bir sayfaya
  // sığan kadar satır gösterilir; geri kalanı _bookPageIndex ile sayfa
  // sayfa (antremanda otomatik, soru bölümünde elle) gezilir.
  Widget _grid({required bool blinkEnabled}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final startRow = _bookPageIndex * _rowsPerPage;
        final endRow = (startRow + _rowsPerPage).clamp(0, _rows);
        final pageRowCount = endRow - startRow;
        final cellWidth =
            (constraints.maxWidth - spacing * (_cols - 1)) / _cols;
        final cellHeight =
            ((constraints.maxHeight - spacing * (pageRowCount - 1)) /
                    pageRowCount)
                .clamp(64.0, 100.0);

        Widget cellAt(int localR, int c) {
          final r = startRow + localR;
          final text = _cellText(r, c);
          if (text == null) return SizedBox(width: cellWidth);
          final index = r * _cols + c;
          final isActive = blinkEnabled && index == _activeIndex;
          final lit = isActive;
          return SizedBox(
            width: cellWidth,
            height: cellHeight,
            child: _cell(text, lit: lit),
          );
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (int localR = 0; localR < pageRowCount; localR++)
              Row(
                children: [
                  for (int c = 0; c < _cols; c++) ...[
                    if (c > 0) const SizedBox(width: spacing),
                    cellAt(localR, c),
                  ],
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _cell(String text, {required bool lit}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: lit ? _color : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: lit ? _color : Colors.grey.shade400,
          width: 1.4,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: lit ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/settings_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/reading_theme_picker.dart';
import '../../widgets/exercise_settings_sheet.dart';
import '../../widgets/confetti_overlay.dart';

enum _Phase { intro, warmup, ready, playing }

class _SentenceWord {
  final String label; // düğümde görünen hâli
  final String sentenceForm; // altta kurulan cümledeki hâli
  final String? caption; // düğümün altındaki küçük not (ör. yazar adı)
  const _SentenceWord(this.label, this.sentenceForm, {this.caption});
}

class _SentencePuzzle {
  final List<_SentenceWord> words; // doğru sıradaki kelimeler; ilk kelime
  // (index 0) her zaman ortada gösterilir, öğrenciye başlangıç noktasını
  // kolaylaştırmak için.
  const _SentencePuzzle({required this.words});
}

/// Klasör 4'ün beşinci etkinliği: "Cümle Kur". Kitaptaki örnek gibi bir
/// merkez kelime ve etrafında dağınık, çizgiyle bağlı kelime kutucukları
/// var. Öğrenci doğru cümle sırasına göre kutucuklara dokunuyor; yanlış
/// kutucuğa dokununca o kutucuk kırmızı yanıp sönüyor, doğru dokununca
/// altta kurulan cümleye ekleniyor.
class SentenceBuilderPage extends StatefulWidget {
  const SentenceBuilderPage({super.key});

  @override
  State<SentenceBuilderPage> createState() => _SentenceBuilderPageState();
}

class _SentenceBuilderPageState extends State<SentenceBuilderPage> {
  Color _color = const Color(0xFF0D9488);

  static const List<Color> _colorPalette = [
    Color(0xFF0D9488),
    Color(0xFFEC4899),
    Color(0xFFEA580C),
    Color(0xFF0D9488),
    Color(0xFF7C3AED),
    Color(0xFF2563EB),
  ];

  static const List<_SentencePuzzle> _puzzles = [
    _SentencePuzzle(
      words: [
        _SentenceWord('Her', 'Her'),
        _SentenceWord('İnsan', 'insan'),
        _SentenceWord('Kendi', 'kendi'),
        _SentenceWord('Başarısının', 'başarısının'),
        _SentenceWord('Hem', 'hem'),
        _SentenceWord('İşçisi', 'işçisi'),
        _SentenceWord('Hem de', 'hem de'),
        _SentenceWord(
          'Baş mimarıdır',
          'baş mimarıdır.',
          caption: '(Cumali Sever)',
        ),
      ],
    ),
    _SentencePuzzle(
      words: [
        _SentenceWord('Düşünmek', 'Düşünmek'),
        _SentenceWord('Ve', 've'),
        _SentenceWord('Söylemek', 'söylemek'),
        _SentenceWord('Kolay;', 'kolay,'),
        _SentenceWord('Fakat yaşamak,', 'fakat yaşamak,'),
        _SentenceWord('Hele başarı ile', 'hele başarı ile'),
        _SentenceWord('Sonuçlandırmak', 'sonuçlandırmak'),
        _SentenceWord('Çok zordur.', 'çok zordur.', caption: '(Z. Gökalp)'),
      ],
    ),
    _SentencePuzzle(
      words: [
        _SentenceWord('Güçlü', 'Güçlü'),
        _SentenceWord('Bir karakter', 'bir karakter'),
        _SentenceWord('Güzel', 'güzel'),
        _SentenceWord('Bir düşünceyle', 'bir düşünceyle'),
        _SentenceWord('Birleşince', 'birleşince'),
        _SentenceWord('Ortaya', 'ortaya'),
        _SentenceWord('Harikalar', 'harikalar'),
        _SentenceWord('Çıkar.', 'çıkar.', caption: '(Goethe)'),
      ],
    ),
    _SentencePuzzle(
      words: [
        _SentenceWord('Bir', 'Bir'),
        _SentenceWord('Ülkenin', 'ülkenin'),
        _SentenceWord('Geleceği', 'geleceği'),
        _SentenceWord('O', 'o'),
        _SentenceWord('Ülke', 'ülke'),
        _SentenceWord('İnsanlarının', 'insanlarının'),
        _SentenceWord('Göreceği', 'göreceği'),
        _SentenceWord('Eğitime', 'eğitime'),
        _SentenceWord('Bağlıdır.', 'bağlıdır.', caption: '(Einstein)'),
      ],
    ),
    _SentencePuzzle(
      words: [
        _SentenceWord('Sahipsiz', 'Sahipsiz'),
        _SentenceWord('Olan', 'olan', caption: '(M. Akif)'),
        _SentenceWord('Memleketin', 'memleketin'),
        _SentenceWord('Batması', 'batması'),
        _SentenceWord('Haktır.', 'haktır,'),
        _SentenceWord('Sen', 'sen'),
        _SentenceWord('Sahip', 'sahip'),
        _SentenceWord('Olursan', 'olursan'),
        _SentenceWord('Bu vatan', 'bu vatan'),
        _SentenceWord('Batmayacaktır.', 'batmayacaktır.'),
      ],
    ),
    _SentencePuzzle(
      words: [
        _SentenceWord('Dünün', 'Dünün'),
        _SentenceWord('Yarını', 'yarını,'),
        _SentenceWord('Bugün de', 'bugün de'),
        _SentenceWord('Değil midir', 'değil midir?', caption: '(Ö. Hayyam)'),
        _SentenceWord('Bir işi', 'Bir işi'),
        _SentenceWord('Yapmak için', 'yapmak için'),
        _SentenceWord('Neden', 'neden'),
        _SentenceWord('Yarını', 'yarını'),
        _SentenceWord('Bekliyorsun', 'bekliyorsun?'),
      ],
    ),
  ];

  _Phase _phase = _Phase.intro;
  bool _hasCompletedOnce = false;

  int _puzzleIndex = 0;
  int _nextIndex = 0;
  List<int> _shuffledSurroundingIndices = [];

  int? _wrongFlashIndex;
  bool _wrongFlashOn = false;
  Timer? _flashTimer;

  int _puzzleElapsedSec = 0;
  Timer? _puzzleTicker;
  int _hintsUsed = 0;
  int _totalScore = 0;
  int? _hintGlowIndex;

  Timer? _warmupTimer;
  int _warmupWordIndex = -1;

  Timer? _celebrateTimer;
  int _celebrateWordIndex = -1;

  @override
  void dispose() {
    _flashTimer?.cancel();
    _puzzleTicker?.cancel();
    _warmupTimer?.cancel();
    _celebrateTimer?.cancel();
    super.dispose();
  }

  // İlk cümle antreman olarak kullanılır (uygulama kendi gösterir); asıl
  // etkinlik geri kalan cümlelerle oynanır.
  _SentencePuzzle get _warmupPuzzle => _puzzles.first;
  List<_SentencePuzzle> get _playablePuzzles => _puzzles.sublist(1);
  _SentencePuzzle get _puzzle => _playablePuzzles[_puzzleIndex];

  void _startWarmup() {
    setState(() {
      _phase = _Phase.warmup;
      _warmupWordIndex = -1;
    });
    _warmupTimer?.cancel();
    int i = -1;
    final total = _warmupPuzzle.words.length;
    _warmupTimer = Timer.periodic(const Duration(milliseconds: 850), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      i++;
      if (i >= total) {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) setState(() => _phase = _Phase.ready);
        });
        return;
      }
      setState(() => _warmupWordIndex = i);
    });
  }

  void _startGame() {
    setState(() {
      _phase = _Phase.playing;
      _puzzleIndex = 0;
      _totalScore = 0;
    });
    _startPuzzle();
  }

  void _startPuzzle() {
    final puzzle = _puzzle;
    final indices = [for (int i = 1; i < puzzle.words.length; i++) i]
      ..shuffle(Random(_puzzleIndex * 97 + 13));
    _flashTimer?.cancel();
    _puzzleTicker?.cancel();
    setState(() {
      _nextIndex = 0;
      _wrongFlashIndex = null;
      _wrongFlashOn = false;
      _shuffledSurroundingIndices = indices;
      _puzzleElapsedSec = 0;
      _hintsUsed = 0;
      _hintGlowIndex = null;
    });
    _puzzleTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _puzzleElapsedSec++);
    });
  }

  int get _puzzlePoints =>
      (100 - _puzzleElapsedSec * 4 - _hintsUsed * 15).clamp(20, 100);

  void _onTapWord(int wordIndex) {
    if (wordIndex < _nextIndex) return; // zaten bulunmuş
    if (wordIndex == _nextIndex) {
      SoundManager.playCorrect();
      setState(() {
        _nextIndex++;
        _hintGlowIndex = null;
      });
      if (_nextIndex == _puzzle.words.length) {
        _puzzleTicker?.cancel();
        _totalScore += _puzzlePoints;
        _celebrateAndAdvance();
      }
    } else {
      SoundManager.playGentleTap();
      _flashWrong(wordIndex);
    }
  }

  // Cümle tamamlanınca konfeti patlatır ve kurulan cümlenin kelimelerini
  // sırayla bir kez yanıp söndürür, sonra bir sonraki cümleye geçer.
  void _celebrateAndAdvance() {
    showConfetti(context);
    _celebrateTimer?.cancel();
    int i = -1;
    final total = _puzzle.words.length;
    _celebrateTimer = Timer.periodic(const Duration(milliseconds: 260), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      i++;
      if (i >= total) {
        timer.cancel();
        setState(() => _celebrateWordIndex = -1);
        _advancePuzzle();
        return;
      }
      setState(() => _celebrateWordIndex = i);
    });
  }

  void _useHint() {
    if (_nextIndex >= _puzzle.words.length) return;
    SoundManager.playTick();
    setState(() {
      _hintsUsed++;
      _hintGlowIndex = _nextIndex;
    });
  }

  void _flashWrong(int wordIndex) {
    _flashTimer?.cancel();
    int ticks = 0;
    setState(() {
      _wrongFlashIndex = wordIndex;
      _wrongFlashOn = true;
    });
    _flashTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _wrongFlashOn = !_wrongFlashOn);
      ticks++;
      if (ticks >= 6) {
        timer.cancel();
        setState(() {
          _wrongFlashOn = false;
          _wrongFlashIndex = null;
        });
      }
    });
  }

  void _advancePuzzle() {
    if (!mounted) return;
    if (_puzzleIndex < _playablePuzzles.length - 1) {
      setState(() => _puzzleIndex++);
      _startPuzzle();
    } else {
      _finishAll();
    }
  }

  void _finishAll() {
    _flashTimer?.cancel();
    _puzzleTicker?.cancel();
    _hasCompletedOnce = true;

    const percent = 100;
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Cümle Kur',
      result: '${_playablePuzzles.length} cümle kuruldu · $_totalScore puan',
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
              '${_playablePuzzles.length} cümlenin hepsini doğru sırayla kurduk!',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              'Toplam puan: $_totalScore',
              style: TextStyle(
                color: _color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
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
          title: const Text('🧩 Cümle Kur'),
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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: switch (_phase) {
              _Phase.intro => _buildIntro(),
              _Phase.warmup => _buildWarmup(),
              _Phase.ready => _buildReady(),
              _Phase.playing => _buildPlaying(
                key: ValueKey('puzzle-$_puzzleIndex'),
              ),
            },
          ),
        ),
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
                    'Etkinlik 5 · Cümle Kur',
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
                      child: Text('🧩', style: TextStyle(fontSize: 80)),
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
                          children: [
                            TextSpan(
                              text: 'Amaç: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  'Dağınık kelime kutucuklarını doğru '
                                  'sırayla birleştirerek anlamlı bir cümle '
                                  'kurmak. Cümlenin ilk kelimesi her zaman '
                                  'ortada olur.\n',
                            ),
                            TextSpan(
                              text: 'Yöntem: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  'Önce ilk cümleyi biz gösteririz: '
                                  'kelimeler sırayla yanıp söner, '
                                  'dikkatlice takip et. Sonra sıra sende — '
                                  'kutucuklara doğru sırayla dokunarak '
                                  'cümleyi baştan sona kur. Yanlış '
                                  'kutucuğa dokunursan kırmızı yanıp söner '
                                  '— doğrusunu bul ve devam et!',
                            ),
                          ],
                        ),
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
                      onPressed: _startWarmup,
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
                  child: Text(
                    'Antremanı tamamladık! Şimdi sıra sende — yapabilirsin! '
                    'Kutucuklara doğru sırayla dokunarak cümleyi baştan '
                    'sona kur.',
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
                    onPressed: _startGame,
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

  Widget _buildPlaying({required Key key}) {
    final puzzle = _puzzle;
    final accent = SettingsManager.readingAccentColor;
    return KeyedSubtree(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                    'Cümle ${_puzzleIndex + 1}/${_playablePuzzles.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _badge('⭐ $_totalScore', Colors.amber.shade800),
              const SizedBox(width: 6),
              _badge('⏱ ${_puzzleElapsedSec}sn', Colors.blueGrey),
              IconButton(
                onPressed: () =>
                    showReadingThemePicker(context, () => setState(() {})),
                icon: const Icon(Icons.palette_outlined),
                tooltip: 'Tema değiştir',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _radialStack(
            surroundingIndices: _shuffledSurroundingIndices,
            nodeBuilder: (wordIndex, isCenter) =>
                _node(puzzle, wordIndex, accent, isCenter: isCenter),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: _nextIndex == 0
                ? Text(
                    'Cümleyi kurmaya başla...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400,
                    ),
                  )
                : Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (int i = 0; i < _nextIndex; i++)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: _celebrateWordIndex == i ? 6 : 0,
                            vertical: 2,
                          ),
                          decoration: _celebrateWordIndex == i
                              ? BoxDecoration(
                                  color: accent,
                                  borderRadius: BorderRadius.circular(6),
                                )
                              : null,
                          child: Text(
                            puzzle.words[i].sentenceForm,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _celebrateWordIndex == i
                                  ? Colors.white
                                  : accent,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _useHint,
              icon: const Icon(Icons.lightbulb_outline, size: 18),
              label: const Text(
                'İpucu Al',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.amber.shade800,
                side: BorderSide(color: Colors.amber.shade400),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarmup() {
    final puzzle = _warmupPuzzle;
    final accent = SettingsManager.readingAccentColor;
    final surrounding = [for (int i = 1; i < puzzle.words.length; i++) i];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.visibility_rounded, color: _color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Antreman: Cümle kurallı bir şekilde yanıp sönecek, '
                  'takip et!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _color,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _radialStack(
          surroundingIndices: surrounding,
          nodeBuilder: (wordIndex, isCenter) => _warmupNode(
            puzzle,
            wordIndex,
            accent,
            isCenter: isCenter,
            isLit: wordIndex <= _warmupWordIndex,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.3)),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              for (
                int i = 0;
                i <= _warmupWordIndex && i < puzzle.words.length;
                i++
              )
                Text(
                  puzzle.words[i].sentenceForm,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _radialStack({
    required List<int> surroundingIndices,
    required Widget Function(int wordIndex, bool isCenter) nodeBuilder,
  }) {
    final accent = SettingsManager.readingAccentColor;
    final n = surroundingIndices.length;
    return SizedBox(
      height: 380,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const nodeW = 104.0;
          const nodeH = 46.0;
          final cx = constraints.maxWidth / 2;
          final cy = constraints.maxHeight / 2;
          final rx = (constraints.maxWidth / 2 - nodeW / 2 - 4).clamp(
            0.0,
            double.infinity,
          );
          final ry = (constraints.maxHeight / 2 - nodeH / 2 - 4).clamp(
            0.0,
            double.infinity,
          );
          Offset centerFor(int i) {
            final angle = -pi / 2 + i * (2 * pi / n);
            return Offset(cx + rx * cos(angle), cy + ry * sin(angle));
          }

          final centers = [for (int i = 0; i < n; i++) centerFor(i)];
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RadialLinesPainter(
                    center: Offset(cx, cy),
                    targets: centers,
                    boxHalfExtent: const Offset(nodeW / 2, nodeH / 2),
                    color: accent.withValues(alpha: 0.35),
                  ),
                ),
              ),
              Positioned(
                left: cx - nodeW / 2,
                top: cy - nodeH / 2,
                width: nodeW,
                height: nodeH,
                child: nodeBuilder(0, true),
              ),
              for (int i = 0; i < n; i++)
                Positioned(
                  left: centers[i].dx - nodeW / 2,
                  top: centers[i].dy - nodeH / 2,
                  width: nodeW,
                  height: nodeH,
                  child: nodeBuilder(surroundingIndices[i], false),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _node(
    _SentencePuzzle puzzle,
    int wordIndex,
    Color accent, {
    bool isCenter = false,
  }) {
    final word = puzzle.words[wordIndex];
    final isFound = wordIndex < _nextIndex;
    final isWrongFlash = _wrongFlashIndex == wordIndex && _wrongFlashOn;
    final isHinted = _hintGlowIndex == wordIndex;
    Color bg = isCenter
        ? accent.withValues(alpha: 0.15)
        : SettingsManager.readingBackgroundColor;
    Color border = isCenter ? accent : SettingsManager.readingBorderColor;
    Color fg = const Color(0xFF0F172A);
    if (isFound) {
      bg = accent;
      border = accent;
      fg = Colors.white;
    }
    if (isHinted) {
      bg = const Color(0xFFFEF3C7);
      border = const Color(0xFFD97706);
    }
    if (isWrongFlash) {
      bg = const Color(0xFFFCA5A5);
      border = const Color(0xFFDC2626);
      fg = const Color(0xFF7F1D1D);
    }
    return GestureDetector(
      onTap: () => _onTapWord(wordIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                word.label,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, color: fg),
              ),
              if (word.caption != null)
                Text(
                  word.caption!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontStyle: FontStyle.italic,
                    color: fg.withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Antreman düğümü: dokunma yok, sadece sırası gelince rengi yanıp söner.
  Widget _warmupNode(
    _SentencePuzzle puzzle,
    int wordIndex,
    Color accent, {
    required bool isCenter,
    required bool isLit,
  }) {
    final word = puzzle.words[wordIndex];
    Color bg = isCenter
        ? accent.withValues(alpha: 0.15)
        : SettingsManager.readingBackgroundColor;
    Color border = isCenter ? accent : SettingsManager.readingBorderColor;
    Color fg = const Color(0xFF0F172A);
    if (isLit) {
      bg = accent;
      border = accent;
      fg = Colors.white;
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              word.label,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: fg),
            ),
            if (word.caption != null)
              Text(
                word.caption!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                  color: fg.withValues(alpha: 0.8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RadialLinesPainter extends CustomPainter {
  final Offset center;
  final List<Offset> targets;
  final Offset boxHalfExtent; // tüm kutucukların yarı genişlik/yükseklik'i
  final Color color;
  const _RadialLinesPainter({
    required this.center,
    required this.targets,
    required this.boxHalfExtent,
    required this.color,
  });

  // Doğrunun, verilen yarı genişlik/yükseklikteki dikdörtgenin kenarını
  // kestiği noktayı bulur — çizgi kutunun İÇİNDEN değil, kenarından başlar.
  Offset _edgePoint(Offset origin, Offset direction) {
    final ux = direction.dx.abs() < 0.0001 ? 0.0001 : direction.dx;
    final uy = direction.dy.abs() < 0.0001 ? 0.0001 : direction.dy;
    final t = min(boxHalfExtent.dx / ux.abs(), boxHalfExtent.dy / uy.abs());
    return origin + direction * t;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2;
    final dotPaint = Paint()..color = color;
    for (final target in targets) {
      final direction = target - center;
      final length = direction.distance;
      if (length < 0.001) continue;
      final unit = direction / length;
      final start = _edgePoint(center, unit);
      final end = _edgePoint(target, -unit);
      canvas.drawLine(start, end, linePaint);
      canvas.drawCircle(start, 2.5, dotPaint);
      canvas.drawCircle(end, 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadialLinesPainter oldDelegate) =>
      oldDelegate.center != center ||
      oldDelegate.targets != targets ||
      oldDelegate.boxHalfExtent != boxHalfExtent ||
      oldDelegate.color != color;
}

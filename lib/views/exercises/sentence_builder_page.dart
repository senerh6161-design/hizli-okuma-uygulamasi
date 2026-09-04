import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/settings_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/reading_theme_picker.dart';

enum _Phase { intro, playing }

class _SentenceWord {
  final String label; // düğümde görünen hâli
  final String sentenceForm; // altta kurulan cümledeki hâli
  final String? caption; // düğümün altındaki küçük not (ör. yazar adı)
  const _SentenceWord(this.label, this.sentenceForm, {this.caption});
}

class _SentencePuzzle {
  final List<_SentenceWord> words; // doğru sıradaki kelimeler
  final int centerIndex; // ortada gösterilecek kelimenin index'i
  const _SentencePuzzle({required this.words, required this.centerIndex});
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
  static const Color _color = Color(0xFF0D9488);

  static const List<_SentencePuzzle> _puzzles = [
    _SentencePuzzle(
      centerIndex: 1,
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
      centerIndex: 0,
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
      centerIndex: 2,
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
      centerIndex: 0,
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
      centerIndex: 8,
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
      centerIndex: 6,
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

  @override
  void dispose() {
    _flashTimer?.cancel();
    _puzzleTicker?.cancel();
    super.dispose();
  }

  _SentencePuzzle get _puzzle => _puzzles[_puzzleIndex];

  void _startGame() {
    setState(() {
      _phase = _Phase.playing;
      _puzzleIndex = 0;
      _totalScore = 0;
    });
    _startPuzzle();
  }

  void _startPuzzle() {
    final puzzle = _puzzles[_puzzleIndex];
    final indices = [
      for (int i = 0; i < puzzle.words.length; i++)
        if (i != puzzle.centerIndex) i,
    ]..shuffle(Random(_puzzleIndex * 97 + 13));
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
        Future.delayed(const Duration(milliseconds: 1400), _advancePuzzle);
      }
    } else {
      SoundManager.playGentleTap();
      _flashWrong(wordIndex);
    }
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
    if (_puzzleIndex < _puzzles.length - 1) {
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
      result: '${_puzzles.length} cümle kuruldu · $_totalScore puan',
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
              '${_puzzles.length} cümlenin hepsini doğru sırayla kurduk!',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              'Toplam puan: $_totalScore',
              style: const TextStyle(
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
        appBar: AppBar(title: const Text('🧩 Cümle Kur')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _phase == _Phase.intro
                ? _buildIntro()
                : _buildPlaying(key: ValueKey('puzzle-$_puzzleIndex')),
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
                  child: const Text(
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
                      child: const Text.rich(
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
                                  'kurmak.\n',
                            ),
                            TextSpan(
                              text: 'Yöntem: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  'Kutucuklara doğru sırayla dokunarak '
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
    final built = [
      for (int i = 0; i < _nextIndex; i++) puzzle.words[i].sentenceForm,
    ].join(' ');
    final n = _shuffledSurroundingIndices.length;
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
                    'Cümle ${_puzzleIndex + 1}/${_puzzles.length}',
                    style: const TextStyle(
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
          SizedBox(
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
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ),
                    Positioned(
                      left: cx - nodeW / 2,
                      top: cy - nodeH / 2,
                      width: nodeW,
                      height: nodeH,
                      child: _node(
                        puzzle,
                        puzzle.centerIndex,
                        accent,
                        isCenter: true,
                      ),
                    ),
                    for (int i = 0; i < n; i++)
                      Positioned(
                        left: centers[i].dx - nodeW / 2,
                        top: centers[i].dy - nodeH / 2,
                        width: nodeW,
                        height: nodeH,
                        child: _node(
                          puzzle,
                          _shuffledSurroundingIndices[i],
                          accent,
                        ),
                      ),
                  ],
                );
              },
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
            child: Text(
              built.isEmpty ? 'Cümleyi kurmaya başla...' : built,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: built.isEmpty ? Colors.grey.shade400 : accent,
              ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                word.label,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, color: fg),
              ),
            ),
            if (word.caption != null)
              Text(
                word.caption!,
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
  final Color color;
  const _RadialLinesPainter({
    required this.center,
    required this.targets,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6;
    for (final target in targets) {
      canvas.drawLine(center, target, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadialLinesPainter oldDelegate) =>
      oldDelegate.center != center ||
      oldDelegate.targets != targets ||
      oldDelegate.color != color;
}

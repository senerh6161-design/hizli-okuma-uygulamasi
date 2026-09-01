import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';

enum _ColorName { kirmizi, sari, yesil, mavi }

const Map<_ColorName, Color> _colorNameToColor = {
  _ColorName.kirmizi: Color(0xFFFF0000),
  _ColorName.sari: Color(0xFFFFC400),
  _ColorName.yesil: Color(0xFF00B050),
  _ColorName.mavi: Color(0xFF0070C0),
};

const Map<_ColorName, String> _colorNameToLabel = {
  _ColorName.kirmizi: 'KIRMIZI',
  _ColorName.sari: 'SARI',
  _ColorName.yesil: 'YEŞİL',
  _ColorName.mavi: 'MAVİ',
};

// Varsayılan (renksiz bırakılmış) yazılar bu koyu gri tonuyla gösteriliyor
// — dört renkten hiçbiriyle eşleşmediği için her zaman "uyumsuz" sayılıyor.
const Color _defaultInk = Color(0xFF334155);

class _StroopItem {
  final _ColorName word;
  final Color? inkColor; // null = varsayılan/renksiz
  const _StroopItem(this.word, this.inkColor);

  bool get isMismatch => inkColor != _colorNameToColor[word];
  Color get displayColor => inkColor ?? _defaultInk;
}

enum _Phase { intro, clap, snap, bolum2Intro, round }

class _SnapPair {
  final _StroopItem left;
  final _StroopItem right;
  final bool correctIsRight;
  const _SnapPair(this.left, this.right, this.correctIsRight);
}

/// Klasör 3'ün altıncı etkinliği: "Renk Uyumu". Hocanın verdiği sunumdaki
/// Stroop tarzı renk-kelime bulmacasının karşılığı. 1. Bölüm çocukları
/// fiziksel olarak katmak için: 1. Tur'da tek kart gelip renk kelimeyle
/// uyumluysa alkışlanıyor, 2. Tur'da iki kart gelip hangisi uyumluysa o
/// elin parmakları şıklatılıyor. 2. Bölüm'de ise ekrandaki ızgarada
/// (kutucuk sayısı gittikçe artarak: 2 → 4 → 6 → 8) rengiyle uyuşmayan
/// kelimeler dokunularak bulunuyor.
class ColorWordMatchPage extends StatefulWidget {
  const ColorWordMatchPage({super.key});

  @override
  State<ColorWordMatchPage> createState() => _ColorWordMatchPageState();
}

class _ColorWordMatchPageState extends State<ColorWordMatchPage> {
  static const Color _color = Color(0xFFEA580C);

  // Her turdaki kutucuk sayısı gittikçe artıyor: önce 2, sonra 4, 6, en
  // son 8.
  static const List<int> _roundSizes = [
    2,
    2,
    2,
    2,
    2,
    4,
    4,
    4,
    4,
    6,
    6,
    6,
    8,
    8,
  ];

  // 1. Bölüm · 1. Tur: tek kart geliyor, renk kelimeyle uyumluysa
  // hep birlikte alkışlıyoruz.
  static const List<_StroopItem> _clapCards = [
    _StroopItem(_ColorName.kirmizi, Color(0xFFFF0000)),
    _StroopItem(_ColorName.sari, Color(0xFF0070C0)),
    _StroopItem(_ColorName.yesil, Color(0xFF00B050)),
    _StroopItem(_ColorName.mavi, Color(0xFFFF0000)),
    _StroopItem(_ColorName.sari, Color(0xFFFFC400)),
    _StroopItem(_ColorName.yesil, Color(0xFFFF0000)),
  ];

  // 1. Bölüm · 2. Tur: iki kart yan yana geliyor, hangisi uyumluysa o
  // elin parmaklarını şıklatıyoruz.
  static const List<_SnapPair> _snapPairs = [
    _SnapPair(
      _StroopItem(_ColorName.kirmizi, Color(0xFFFF0000)),
      _StroopItem(_ColorName.sari, Color(0xFF0070C0)),
      false,
    ),
    _SnapPair(
      _StroopItem(_ColorName.yesil, Color(0xFFFF0000)),
      _StroopItem(_ColorName.mavi, Color(0xFF0070C0)),
      true,
    ),
    _SnapPair(
      _StroopItem(_ColorName.sari, Color(0xFFFFC400)),
      _StroopItem(_ColorName.kirmizi, Color(0xFFFFC400)),
      false,
    ),
    _SnapPair(
      _StroopItem(_ColorName.mavi, Color(0xFFFF0000)),
      _StroopItem(_ColorName.yesil, Color(0xFF00B050)),
      true,
    ),
    _SnapPair(
      _StroopItem(_ColorName.kirmizi, Color(0xFF00B050)),
      _StroopItem(_ColorName.sari, Color(0xFFFFC400)),
      true,
    ),
    _SnapPair(
      _StroopItem(_ColorName.yesil, Color(0xFF00B050)),
      _StroopItem(_ColorName.mavi, Color(0xFFFFC400)),
      false,
    ),
  ];

  // Hocanın sunumundaki 15 SmartArt turu, kelime + gerçek mürekkep rengi
  // olarak buraya aktarıldı — tek bir havuzda birleştirilip _roundSizes'a
  // göre yeniden gruplanıyor.
  static const List<List<_StroopItem>> _rawRounds = [
    [
      _StroopItem(_ColorName.sari, Color(0xFFFF0000)),
      _StroopItem(_ColorName.yesil, Color(0xFFFFC400)),
      _StroopItem(_ColorName.kirmizi, null),
      _StroopItem(_ColorName.mavi, Color(0xFF0070C0)),
    ],
    [
      _StroopItem(_ColorName.sari, null),
      _StroopItem(_ColorName.yesil, Color(0xFF00B050)),
      _StroopItem(_ColorName.kirmizi, Color(0xFF0070C0)),
      _StroopItem(_ColorName.mavi, Color(0xFFFF0000)),
    ],
    [
      _StroopItem(_ColorName.sari, Color(0xFF00B050)),
      _StroopItem(_ColorName.yesil, Color(0xFF0070C0)),
      _StroopItem(_ColorName.kirmizi, Color(0xFFFF0000)),
      _StroopItem(_ColorName.mavi, null),
    ],
    [
      _StroopItem(_ColorName.sari, Color(0xFFFFC400)),
      _StroopItem(_ColorName.yesil, Color(0xFFFFC400)),
      _StroopItem(_ColorName.kirmizi, Color(0xFF0070C0)),
      _StroopItem(_ColorName.mavi, Color(0xFF00B050)),
    ],
    [
      _StroopItem(_ColorName.kirmizi, null),
      _StroopItem(_ColorName.sari, Color(0xFF00B050)),
      _StroopItem(_ColorName.kirmizi, Color(0xFFFF0000)),
      _StroopItem(_ColorName.mavi, Color(0xFFFF0000)),
    ],
    [
      _StroopItem(_ColorName.yesil, Color(0xFF00B050)),
      _StroopItem(_ColorName.yesil, Color(0xFFFFC400)),
      _StroopItem(_ColorName.kirmizi, null),
      _StroopItem(_ColorName.mavi, Color(0xFFFF0000)),
    ],
    [
      _StroopItem(_ColorName.mavi, Color(0xFF0070C0)),
      _StroopItem(_ColorName.yesil, Color(0xFFFF0000)),
      _StroopItem(_ColorName.sari, Color(0xFF00B050)),
      _StroopItem(_ColorName.kirmizi, null),
    ],
    [
      _StroopItem(_ColorName.sari, Color(0xFF00B050)),
      _StroopItem(_ColorName.yesil, Color(0xFFFF0000)),
      _StroopItem(_ColorName.kirmizi, Color(0xFFFFC400)),
      _StroopItem(_ColorName.mavi, Color(0xFF0070C0)),
    ],
    [
      _StroopItem(_ColorName.mavi, Color(0xFF0070C0)),
      _StroopItem(_ColorName.sari, null),
      _StroopItem(_ColorName.kirmizi, Color(0xFF00B050)),
      _StroopItem(_ColorName.yesil, Color(0xFFFFC400)),
    ],
    [
      _StroopItem(_ColorName.sari, Color(0xFFFF0000)),
      _StroopItem(_ColorName.yesil, Color(0xFF00B050)),
      _StroopItem(_ColorName.kirmizi, Color(0xFFFF0000)),
      _StroopItem(_ColorName.mavi, null),
    ],
    [
      _StroopItem(_ColorName.kirmizi, null),
      _StroopItem(_ColorName.sari, Color(0xFFFFC400)),
      _StroopItem(_ColorName.yesil, Color(0xFF00B050)),
      _StroopItem(_ColorName.mavi, Color(0xFFFF0000)),
    ],
    [
      _StroopItem(_ColorName.yesil, Color(0xFFFF0000)),
      _StroopItem(_ColorName.kirmizi, null),
      _StroopItem(_ColorName.sari, Color(0xFFFFC400)),
      _StroopItem(_ColorName.mavi, Color(0xFFFFC400)),
    ],
    [
      _StroopItem(_ColorName.mavi, Color(0xFF0070C0)),
      _StroopItem(_ColorName.yesil, Color(0xFFFFC400)),
      _StroopItem(_ColorName.sari, Color(0xFFFF0000)),
      _StroopItem(_ColorName.kirmizi, null),
    ],
    [
      _StroopItem(_ColorName.sari, Color(0xFFFF0000)),
      _StroopItem(_ColorName.mavi, Color(0xFF0070C0)),
      _StroopItem(_ColorName.kirmizi, Color(0xFFFFC400)),
      _StroopItem(_ColorName.yesil, null),
    ],
    [
      _StroopItem(_ColorName.kirmizi, Color(0xFFFF0000)),
      _StroopItem(_ColorName.yesil, Color(0xFFFF0000)),
      _StroopItem(_ColorName.mavi, Color(0xFF0070C0)),
      _StroopItem(_ColorName.mavi, null),
    ],
  ];

  static List<_StroopItem> get _allItems => [for (final r in _rawRounds) ...r];

  late final List<List<_StroopItem>> _rounds = _buildRounds();

  List<List<_StroopItem>> _buildRounds() {
    final items = _allItems;
    final result = <List<_StroopItem>>[];
    int i = 0;
    for (final size in _roundSizes) {
      result.add(items.sublist(i, i + size));
      i += size;
    }
    return result;
  }

  _Phase _phase = _Phase.intro;
  bool _hasCompletedOnce = false;
  bool _isPaused = false;

  int _clapCardIndex = 0;
  int _snapPairIndex = 0;

  int _roundIndex = 0;
  final Set<int> _foundIndices = {};
  int? _wrongFlashIndex;
  Timer? _wrongFlashTimer;
  int _totalMistakes = 0;
  int _elapsedSec = 0;
  Timer? _elapsedTimer;

  @override
  void dispose() {
    _wrongFlashTimer?.cancel();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  int get _mismatchCountInRound =>
      _rounds[_roundIndex].where((it) => it.isMismatch).length;

  void _startBolum1() {
    setState(() {
      _phase = _Phase.clap;
      _clapCardIndex = 0;
    });
  }

  void _nextClapCard() {
    if (_clapCardIndex < _clapCards.length - 1) {
      setState(() => _clapCardIndex++);
    } else {
      setState(() {
        _phase = _Phase.snap;
        _snapPairIndex = 0;
      });
    }
  }

  void _nextSnapPair() {
    if (_snapPairIndex < _snapPairs.length - 1) {
      setState(() => _snapPairIndex++);
    } else {
      setState(() => _phase = _Phase.bolum2Intro);
    }
  }

  void _startGame() {
    setState(() {
      _phase = _Phase.round;
      _roundIndex = 0;
      _totalMistakes = 0;
      _foundIndices.clear();
      _wrongFlashIndex = null;
      _elapsedSec = 0;
    });
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSec++);
    });
  }

  void _pauseGame() {
    _elapsedTimer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resumeGame() {
    setState(() => _isPaused = false);
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSec++);
    });
  }

  void _tapItem(int index) {
    if (_foundIndices.contains(index)) return;
    final item = _rounds[_roundIndex][index];
    if (item.isMismatch) {
      SoundManager.playCorrect();
      setState(() => _foundIndices.add(index));
      if (_foundIndices.length == _mismatchCountInRound) {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          _advanceRound();
        });
      }
    } else {
      SoundManager.playGentleTap();
      _totalMistakes++;
      _wrongFlashTimer?.cancel();
      setState(() => _wrongFlashIndex = index);
      _wrongFlashTimer = Timer(const Duration(milliseconds: 320), () {
        if (!mounted) return;
        setState(() => _wrongFlashIndex = null);
      });
    }
  }

  void _advanceRound() {
    if (_roundIndex < _rounds.length - 1) {
      setState(() {
        _roundIndex++;
        _foundIndices.clear();
        _wrongFlashIndex = null;
      });
    } else {
      _finishAll();
    }
  }

  void _finishAll() {
    _elapsedTimer?.cancel();
    _hasCompletedOnce = true;

    const percent = 100;
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Renk Uyumu',
      result: '$_elapsedSec sn · $_totalMistakes hata',
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
              '${_rounds.length} turun hepsini tamamladık!',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text('Süre: $_elapsedSec sn'),
            Text('Toplam hata: $_totalMistakes'),
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
        appBar: AppBar(title: const Text('🎨 Renk Uyumu')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: switch (_phase) {
                  _Phase.intro => _buildIntro(),
                  _Phase.clap => _buildClapRound(
                    key: ValueKey('clap-$_clapCardIndex'),
                  ),
                  _Phase.snap => _buildSnapRound(
                    key: ValueKey('snap-$_snapPairIndex'),
                  ),
                  _Phase.bolum2Intro => _buildBolum2Intro(),
                  _Phase.round => _buildRound(
                    key: ValueKey('round-$_roundIndex'),
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
                    'Etkinlik 6 · Renk Uyumu',
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDD5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _color, width: 1.5),
                      ),
                      child: const Text(
                        'Amaç: Gözümüzün ve dikkatimizin hızını '
                        'artırmak.\n\nYöntem: Önce 1. Bölüm\'de kartların '
                        'renginin kelimeyle uyumlu olup olmadığını '
                        'alkışlayarak ve parmak şıklatarak göstereceğiz. '
                        'Sonra 2. Bölüm\'de rengiyle uyumlu olmayan '
                        'kelimeleri ekrana dokunarak bulacağız!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF7C2D12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildExampleBox(),
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
                      child: const Text(
                        '1. Bölüm\'de alkış ve parmak şıklatma turları, '
                        '2. Bölüm\'de dokunarak bulma turları var!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: _color,
                          fontWeight: FontWeight.w600,
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
                      onPressed: _startBolum1,
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

  Widget _buildExampleBox() {
    const exampleItem = _StroopItem(_ColorName.sari, Color(0xFFFF0000));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'ÖRNEK',
              style: TextStyle(
                color: Colors.amber.shade900,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              _colorNameToLabel[exampleItem.word]!,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: exampleItem.displayColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              children: const [
                TextSpan(text: '"SARI" yazıyor ama rengi '),
                TextSpan(
                  text: 'kırmızı',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDC2626),
                  ),
                ),
                TextSpan(text: ' — bu ikisi uyumsuz, buna dokunmalıyız!'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. Bölüm · 1. Tur: tek kart — renk kelimeyle uyumluysa hep birlikte
  // alkışlıyoruz. Öğretmen kontrolünde "Sonraki Kart" ile ilerliyor.
  Widget _buildClapRound({required Key key}) {
    final card = _clapCards[_clapCardIndex];
    return KeyedSubtree(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '1. Bölüm · 1. Tur · Kart ${_clapCardIndex + 1}/'
              '${_clapCards.length}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: _color,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDD5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _color, width: 1.5),
            ),
            child: const Text(
              '👏 Renk, kelimeyle UYUMLUYSA hep birlikte alkışlayalım!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7C2D12),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _colorNameToLabel[card.word]!,
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: card.displayColor,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _nextClapCard,
              icon: const Icon(Icons.arrow_forward),
              label: const Text(
                'SONRAKİ KART',
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
      ),
    );
  }

  // 1. Bölüm · 2. Tur: iki kart yan yana — hangisi uyumluysa o elin
  // parmaklarını şıklatıyoruz.
  Widget _buildSnapRound({required Key key}) {
    final pair = _snapPairs[_snapPairIndex];
    return KeyedSubtree(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '1. Bölüm · 2. Tur · Kart ${_snapPairIndex + 1}/'
              '${_snapPairs.length}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: _color,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDD5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _color, width: 1.5),
            ),
            child: const Text(
              '🤟 Hangi kart uyumluysa o elimizin parmaklarını '
              'şıklatalım! Sol uyumluysa sol el, sağ uyumluysa sağ el.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7C2D12),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _snapCard('SOL', pair.left)),
                const SizedBox(width: 16),
                Expanded(child: _snapCard('SAĞ', pair.right)),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _nextSnapPair,
              icon: const Icon(Icons.arrow_forward),
              label: const Text(
                'SONRAKİ KART',
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
      ),
    );
  }

  Widget _snapCard(String label, _StroopItem item) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _colorNameToLabel[item.word]!,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: item.displayColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 1. Bölüm bitince, ekrana dokunarak oynanacak 2. Bölüm'e geçiş ekranı.
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
                const Center(child: Text('👆', style: TextStyle(fontSize: 64))),
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
                    '1. Bölümü tamamladık! Şimdi 2. Bölüm\'de rengiyle '
                    'uyumlu olmayan kelimeleri ekrana dokunarak '
                    'bulacağız — ${_rounds.length} tur var, hazır '
                    'olduğunda başlayalım!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
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

  Widget _buildRound({required Key key}) {
    final round = _rounds[_roundIndex];
    return KeyedSubtree(
      key: key,
      child: Column(
        children: [
          Row(
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
                  '2. Bölüm · Tur ${_roundIndex + 1}/${_rounds.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _color,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Text(
                      '⏱ $_elapsedSec sn',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                  buildPauseButton(color: _color, onPressed: _pauseGame),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Rengiyle uyumlu OLMAYAN kelimelere dokun!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: round.length,
              itemBuilder: (context, index) {
                final item = round[index];
                final found = _foundIndices.contains(index);
                final wrongFlash = _wrongFlashIndex == index;
                Color bg = Colors.white;
                Color border = Colors.grey.shade300;
                if (found) {
                  bg = const Color(0xFF16A34A).withValues(alpha: 0.1);
                  border = const Color(0xFF16A34A);
                } else if (wrongFlash) {
                  bg = const Color(0xFFE11D48).withValues(alpha: 0.1);
                  border = const Color(0xFFE11D48);
                }
                return GestureDetector(
                  onTap: () => _tapItem(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: bg,
                      border: Border.all(color: border, width: 2.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      alignment: Alignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _colorNameToLabel[item.word]!,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: found
                                  ? item.displayColor.withValues(alpha: 0.35)
                                  : item.displayColor,
                            ),
                          ),
                        ),
                        if (found)
                          const Positioned(
                            top: 6,
                            right: 6,
                            child: Icon(
                              Icons.check_circle,
                              color: Color(0xFF16A34A),
                              size: 22,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

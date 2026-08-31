import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';

enum _Phase { intro, bolum2Intro, flash, grid }

/// Klasör 2'nin onuncu etkinliği: "Nerede Gördüm?". Sabit bir 3×3 kelime
/// karesi var; her turda bu 9 kelimeden biri tek başına 1 saniye
/// gösterilip kayboluyor, sonra kare tekrar beliriyor — öğrenci o
/// kelimenin karede NEREDE olduğunu hızlıca bulup dokunmalı. 20 tur.
class WordRecallGridPage extends StatefulWidget {
  const WordRecallGridPage({super.key});

  @override
  State<WordRecallGridPage> createState() => _WordRecallGridPageState();
}

class _WordRecallGridPageState extends State<WordRecallGridPage> {
  static const Color _color = Color(0xFFDC2626);
  static const int _roundCount = 20;
  // Bölüm 2 (sayılar) 20 turu ikiye bölünüyor: ilk 10 tur 1-9 arası,
  // sonraki 10 tur 11-19 arası — her ikisi de tam 9 sayı, 3x3 kareye
  // birebir oturuyor.
  static const int _numberSwitchRound = 10;
  static const List<String> _speedLabels = ['Yavaş', 'Orta', 'Hızlı'];
  static const List<int> _flashMsBySpeed = [1500, 1000, 600];
  static const List<int> _answerTimeMsBySpeed = [7000, 5000, 3500];

  // 1. Bölüm'ün sabit karesi — hoca 3. ve 4. Bölüm için farklı kelime
  // setleri paylaştıkça buraya eklenecek.
  static const List<String> _words = [
    'şiir',
    'haber',
    'kültür',
    'bilim',
    'kitap',
    'kardeş',
    'huzur',
    'okul',
    'kalem',
  ];

  // 2. Bölüm: aynı mekanik, kelimeler yerine sayılar — ilk 10 tur bu
  // havuzdan, sonraki 10 tur ikinci havuzdan.
  static const List<String> _numbersLow = [
    '1', '2', '3', '4', '5', '6', '7', '8', '9', //
  ];
  static const List<String> _numbersHigh = [
    '11', '12', '13', '14', '15', '16', '17', '18', '19', //
  ];

  final Random _random = Random();
  _Phase _phase = _Phase.intro;
  bool _hasCompletedOnce = false;
  bool _isPaused = false;
  bool _isDemoRound = false;
  int _currentBolum = 1;
  int _speedLevel = 1;

  List<String> _gridWords = []; // her turda o turun havuzundan yeniden dizilir
  String? _lastTargetWord; // aynı kelime/sayı art arda sorulmasın diye
  int _roundIndex = 0;
  int _totalScore = 0;
  int _correctCount = 0;
  int _targetIndex = 0;
  int _elapsedMs = 0;
  Timer? _answerTimer;
  Timer? _tickTimer;
  Timer? _flashTimer;
  int? _selectedIndex;
  bool _answered = false;

  @override
  void dispose() {
    _answerTimer?.cancel();
    _tickTimer?.cancel();
    _flashTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _totalScore = 0;
      _correctCount = 0;
    });
    _startBolum(1);
  }

  // Bölüm 1 ve 2 aynı mekaniği paylaşıyor, sadece içerik havuzu değişiyor.
  // Puan/doğru sayacı SIFIRLANMIYOR — iki bölümün toplamı olarak birikiyor.
  void _startBolum(int bolum) {
    setState(() {
      _currentBolum = bolum;
      _roundIndex = 0;
    });
    if (bolum == 1) {
      _startDemoRound();
    } else {
      _startRound();
    }
  }

  // O anki bölüme (ve Bölüm 2 içindeyse tur numarasına) göre hangi
  // havuzdan seçim yapılacağını belirler.
  List<String> _poolForCurrentRound() {
    if (_currentBolum == 1) return _words;
    return _roundIndex < _numberSwitchRound ? _numbersLow : _numbersHigh;
  }

  void _startRound() {
    _answerTimer?.cancel();
    _tickTimer?.cancel();
    _flashTimer?.cancel();
    final pool = _poolForCurrentRound();
    _gridWords = [...pool]..shuffle(_random);
    // Aynı kelime/sayı art arda iki kez sorulmasın diye, birden fazla
    // seçenek varsa bir önceki turun hedefiyle aynı olan seçim tekrar
    // denenir.
    int target;
    do {
      target = _random.nextInt(_gridWords.length);
    } while (_gridWords.length > 1 && _gridWords[target] == _lastTargetWord);
    _lastTargetWord = _gridWords[target];
    setState(() {
      _phase = _Phase.flash;
      _targetIndex = target;
      _selectedIndex = null;
      _answered = false;
    });
    _flashTimer = Timer(
      Duration(milliseconds: _flashMsBySpeed[_speedLevel]),
      () {
        if (!mounted) return;
        _startAnswerWindow();
      },
    );
  }

  // Gerçek turlar başlamadan önce puansız bir "antreman" turu: öğrenci
  // önce mekaniği görüp deneyimlesin diye — "önce bir kelime göstereceğiz,
  // şimdi sıra sende" akışının canlı bir örneği.
  void _startDemoRound() {
    _isDemoRound = true;
    _startRound();
  }

  void _skipDemo() {
    _answerTimer?.cancel();
    _tickTimer?.cancel();
    _flashTimer?.cancel();
    _isDemoRound = false;
    _startRound();
  }

  void _startAnswerWindow() {
    setState(() {
      _phase = _Phase.grid;
      _elapsedMs = 0;
    });
    final answerTimeMs = _answerTimeMsBySpeed[_speedLevel];
    _tickTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) return;
      setState(() => _elapsedMs = (_elapsedMs + 80).clamp(0, answerTimeMs));
    });
    _answerTimer = Timer(Duration(milliseconds: answerTimeMs), () {
      if (!mounted) return;
      _answerRound(null);
    });
  }

  void _pauseGame() {
    _answerTimer?.cancel();
    _tickTimer?.cancel();
    _flashTimer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resumeGame() {
    setState(() => _isPaused = false);
    if (_phase == _Phase.flash) {
      _flashTimer = Timer(
        Duration(milliseconds: _flashMsBySpeed[_speedLevel]),
        () {
          if (!mounted) return;
          _startAnswerWindow();
        },
      );
    } else if (_phase == _Phase.grid) {
      final answerTimeMs = _answerTimeMsBySpeed[_speedLevel];
      final remainingMs = (answerTimeMs - _elapsedMs).clamp(0, answerTimeMs);
      _tickTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
        if (!mounted) return;
        setState(() => _elapsedMs = (_elapsedMs + 80).clamp(0, answerTimeMs));
      });
      _answerTimer = Timer(Duration(milliseconds: remainingMs), () {
        if (!mounted) return;
        _answerRound(null);
      });
    }
  }

  void _answerRound(int? index) {
    if (_answered) return;
    _tickTimer?.cancel();
    _answerTimer?.cancel();
    final isCorrect = index != null && index == _targetIndex;
    setState(() {
      _selectedIndex = index;
      _answered = true;
    });
    if (isCorrect) {
      if (!_isDemoRound) {
        final remainingFraction =
            (1 - (_elapsedMs / _answerTimeMsBySpeed[_speedLevel])).clamp(
              0.0,
              1.0,
            );
        final points = (100 * remainingFraction).round().clamp(20, 100);
        _totalScore += points;
        _correctCount++;
      }
      SoundManager.playCorrect();
    } else {
      SoundManager.playGentleTap();
    }
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_isDemoRound) {
        _isDemoRound = false;
        _startRound();
      } else if (_roundIndex < _roundCount - 1) {
        setState(() => _roundIndex++);
        _startRound();
      } else if (_currentBolum == 1) {
        setState(() => _phase = _Phase.bolum2Intro);
      } else {
        _finishAll();
      }
    });
  }

  // 20 tur uzun gelebilir — öğrenci istediği an bir sonraki bölüme (ya da
  // son bölümdeyse doğrudan bitişe) atlayabilir.
  void _skipBolum() {
    _answerTimer?.cancel();
    _tickTimer?.cancel();
    _flashTimer?.cancel();
    if (_currentBolum == 1) {
      setState(() => _phase = _Phase.bolum2Intro);
    } else {
      _finishAll();
    }
  }

  void _finishAll() {
    _answerTimer?.cancel();
    _tickTimer?.cancel();
    _flashTimer?.cancel();
    _hasCompletedOnce = true;

    final totalRounds = _roundCount * 2;
    final percent = ((_correctCount / totalRounds) * 100).round();
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    SoundManager.playAchievement();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Nerede Gördüm?',
      result: '$_correctCount/$totalRounds doğru · $_totalScore puan',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('👏 Harikasın! Etkinlik Tamamlandı!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Doğru: $_correctCount / $totalRounds (%$percent)'),
            const SizedBox(height: 4),
            Text(
              'Toplam puan: $_totalScore 🎉',
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
        appBar: AppBar(title: const Text('🔍 Nerede Gördüm?')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: switch (_phase) {
                  _Phase.intro => _buildIntro(),
                  _Phase.bolum2Intro => _buildBolum2Intro(),
                  _Phase.flash || _Phase.grid => _buildRound(
                    key: ValueKey(
                      'round-$_currentBolum-$_roundIndex-$_isDemoRound-$_phase',
                    ),
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
    return _buildIntroScreen(
      badge: 'Etkinlik 10 · 1. Bölüm · Nerede Gördüm?',
      emoji: '🔍',
      instruction:
          'Önce bir kelime tek başına 1 saniye gösterilecek. Sonra 9 '
          'kelimelik kare belirecek — az önce gördüğün kelimenin karede '
          'NEREDE olduğunu hızlıca bulup dokun! Başlamadan önce sana '
          'puansız bir antreman turu göstereceğiz. Ardından 20 tur '
          'sürecek, ne kadar hızlı bulursan o kadar çok puan kazanırsın.',
      onStart: _startGame,
    );
  }

  Widget _buildBolum2Intro() {
    return _buildIntroScreen(
      badge: 'Etkinlik 10 · 2. Bölüm · Sayı Versiyonu',
      emoji: '🔢',
      instruction:
          'Aynı oyun, bu kez kelime yerine sayılarla! Bir sayı tek başına 1 '
          'saniye gösterilecek, sonra 9 sayılık kare belirecek — o sayının '
          'karede NEREDE olduğunu hızlıca bulup dokun! İlk 10 turda 1-9 '
          'arası, sonraki 10 turda 11-19 arası sayılarla oynayacaksın.',
      onStart: () => _startBolum(2),
    );
  }

  Widget _buildIntroScreen({
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
            onSelected: (_) => setState(() => _speedLevel = i),
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

  Widget _buildRound({required Key key}) {
    final remainingFraction = _phase == _Phase.grid
        ? (1 - (_elapsedMs / _answerTimeMsBySpeed[_speedLevel])).clamp(0.0, 1.0)
        : 1.0;
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
                  _isDemoRound
                      ? '🎓 Antreman Turu'
                      : '$_currentBolum. Bölüm · Tur ${_roundIndex + 1}/$_roundCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _color,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isDemoRound ? 'Puansız' : 'Puan: $_totalScore',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _color,
                    ),
                  ),
                  if (!_answered)
                    buildPauseButton(color: _color, onPressed: _pauseGame),
                ],
              ),
            ],
          ),
          if (_currentBolum == 2 && !_isDemoRound) ...[
            const SizedBox(height: 4),
            Text(
              _roundIndex < _numberSwitchRound
                  ? '1-9 arası sayılar'
                  : '11-19 arası sayılar',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
          if (_isDemoRound) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Text(
                _phase == _Phase.flash
                    ? 'Önce sana bir kelime göstereceğiz...'
                    : 'Şimdi sıra sende! Nerede olduğunu bul.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade900,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          _speedChipRow(),
          const SizedBox(height: 10),
          if (_phase == _Phase.grid)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: remainingFraction,
                minHeight: 8,
                backgroundColor: _color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(
                  remainingFraction <= 0.25 ? Colors.red : _color,
                ),
              ),
            )
          else
            const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: _phase == _Phase.flash
                  ? Text(
                      _gridWords[_targetIndex],
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: _color,
                      ),
                    )
                  : _buildGrid(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _isDemoRound ? _skipDemo : _skipBolum,
              icon: const Icon(Icons.skip_next_rounded),
              label: Text(
                _isDemoRound
                    ? 'ANTREMANI GEÇ'
                    : (_currentBolum == 1 ? 'SAYILARA GEÇ' : 'BİTİR'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _color,
                side: const BorderSide(color: _color),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return SizedBox(
      width: 320,
      height: 320,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _gridWords.length,
        itemBuilder: (context, index) {
          final isCorrectCell = index == _targetIndex;
          final isSelected = _selectedIndex == index;
          Color bg = _color.withValues(alpha: 0.08);
          Color border = _color.withValues(alpha: 0.3);
          Color fg = const Color(0xFF0F172A);
          if (_answered) {
            if (isCorrectCell) {
              bg = const Color(0xFF16A34A).withValues(alpha: 0.14);
              border = const Color(0xFF16A34A);
              fg = const Color(0xFF16A34A);
            } else if (isSelected) {
              bg = const Color(0xFFE11D48).withValues(alpha: 0.14);
              border = const Color(0xFFE11D48);
              fg = const Color(0xFFE11D48);
            }
          }
          return GestureDetector(
            onTap: _answered ? null : () => _answerRound(index),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border, width: 2),
              ),
              // Sayılar (2 hane) ve kelimeler (uzunluğu değişken) aynı hücreye
              // sığmalı — FittedBox büyük bir hedef punto ile başlayıp
              // gerekirse otomatik küçülterek her zaman kutuya sığdırıyor.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _gridWords[index],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

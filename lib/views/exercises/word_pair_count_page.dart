import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';

enum _Phase { intro, showing, answering }

class _Round {
  final List<String> grid;
  final String target;
  final int correctCount;
  const _Round(this.grid, this.target, this.correctCount);
}

/// Klasör 2'nin beşinci etkinliği: "İkili Kelime Grubu Say". Öğretmen
/// dokümanındaki tablo formatının uyarlaması: sayfada bir sürü ikili
/// kelime grubu (ör. "elma-armut") var, hedef gösterilen bir grup sayfada
/// kaç kere geçiyor — öğrenci hızlıca tarayıp sayıyor, süre dolunca (ya da
/// "CEVAPLA" ile erken) kaç kere gördüğünü seçiyor.
class WordPairCountPage extends StatefulWidget {
  const WordPairCountPage({super.key});

  @override
  State<WordPairCountPage> createState() => _WordPairCountPageState();
}

class _WordPairCountPageState extends State<WordPairCountPage> {
  static const Color _color = Color(0xFF0891B2);
  static const List<String> _speedLabels = ['Yavaş', 'Orta', 'Hızlı'];
  static const List<int> _roundTimeMsBySpeed = [15000, 10000, 6000];
  // Hızlı ayar daha zor olduğu için doğru cevap daha çok puan kazandırıyor.
  static const List<int> _pointsBySpeed = [50, 75, 100];
  // Eskiden 30 hücre + 5 tur vardı; 30 hücre ekrana sığmayıp kaydırma
  // gerektiriyordu. İkiye bölündü: 15 hücre (kaydırmadan sığıyor), tur
  // sayısı 10'a çıkarıldı — öğrenci toplamda daha fazla soru görüyor.
  static const int _roundCount = 10;
  static const int _gridCellCount = 15;

  // Not: "domates-domates" ve "fasulye-bezelye" gibi çok uzun çiftler
  // havuzdan bilerek çıkarıldı — grid hücresinde alt satıra kayıp çirkin
  // görünüyorlardı; kalanların hepsi tek satıra sığıyor.
  static const List<String> _pairPool = [
    'elma-armut',
    'kiraz-çilek',
    'patates-soğan',
    'karpuz-kavun',
    'havuç-turp',
    'muz-ananas',
    'nar-ayva',
    'üzüm-erik',
    'incir-dut',
    'marul-lahana',
  ];

  final Random _random = Random();
  _Phase _phase = _Phase.intro;
  bool _hasCompletedOnce = false;
  bool _isPaused = false;
  int _speedLevel = 1;

  int _roundIndex = 0;
  int _totalScore = 0;
  int _correctRoundCount = 0;
  late _Round _round;
  int _elapsedMs = 0;
  Timer? _roundTimer;
  Timer? _tickTimer;
  List<int> _answerOptions = const [];
  int? _selectedAnswer;
  bool _answered = false;
  // Aynı oturumda hedef kelime grubu tekrar etmesin diye (ör. üst üste
  // "domates-domates" çıkmasın) her tur farklı bir hedef seçiliyor.
  final Set<String> _usedTargets = {};

  @override
  void dispose() {
    _roundTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }

  _Round _generateRound() {
    final available = _pairPool
        .where((p) => !_usedTargets.contains(p))
        .toList();
    final pool = available.isNotEmpty ? available : _pairPool;
    final target = pool[_random.nextInt(pool.length)];
    _usedTargets.add(target);
    final targetCount = 2 + _random.nextInt(5); // 2..6
    final grid = <String>[];
    for (int i = 0; i < targetCount; i++) {
      grid.add(target);
    }
    // Kelimeler aynı ama sırası ters olan bir çeldirici ekleniyor (ör.
    // hedef "kiraz-çilek" ise "çilek-kiraz" da tuzak olarak geçebilir) —
    // öğrenci sadece kelimelere değil, sırasına da dikkat etmeli.
    final parts = target.split('-');
    if (parts.length == 2 && parts[0] != parts[1]) {
      final reversed = '${parts[1]}-${parts[0]}';
      final reversedCount = 1 + _random.nextInt(2); // 1-2 kere
      for (int i = 0; i < reversedCount; i++) {
        grid.add(reversed);
      }
    }
    final decoys = _pairPool.where((p) => p != target).toList();
    while (grid.length < _gridCellCount) {
      grid.add(decoys[_random.nextInt(decoys.length)]);
    }
    grid.shuffle(_random);
    return _Round(grid, target, targetCount);
  }

  void _startGame() {
    _usedTargets.clear();
    setState(() {
      _phase = _Phase.showing;
      _roundIndex = 0;
      _totalScore = 0;
      _correctRoundCount = 0;
    });
    _startRound();
  }

  void _startRound() {
    _roundTimer?.cancel();
    _tickTimer?.cancel();
    final round = _generateRound();
    setState(() {
      _phase = _Phase.showing;
      _round = round;
      _elapsedMs = 0;
      _selectedAnswer = null;
      _answered = false;
    });
    final totalMs = _roundTimeMsBySpeed[_speedLevel];
    _tickTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) return;
      setState(() => _elapsedMs = (_elapsedMs + 80).clamp(0, totalMs));
    });
    _roundTimer = Timer(Duration(milliseconds: totalMs), () {
      if (!mounted) return;
      _goToAnswerStep();
    });
  }

  void _pauseGame() {
    _roundTimer?.cancel();
    _tickTimer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resumeGame() {
    final totalMs = _roundTimeMsBySpeed[_speedLevel];
    final remainingMs = (totalMs - _elapsedMs).clamp(0, totalMs);
    setState(() => _isPaused = false);
    _tickTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) return;
      setState(() => _elapsedMs = (_elapsedMs + 80).clamp(0, totalMs));
    });
    _roundTimer = Timer(Duration(milliseconds: remainingMs), () {
      if (!mounted) return;
      _goToAnswerStep();
    });
  }

  void _goToAnswerStep() {
    _roundTimer?.cancel();
    _tickTimer?.cancel();
    final correctCount = _round.correctCount;
    // Rastgele deneme yerine olası tüm değerlerden karışık örnekleme —
    // doğru sayı sınıra yakınken sonsuz döngüye girme riski olmasın.
    const maxOption = 8;
    final otherValues = [
      for (int i = 0; i <= maxOption; i++)
        if (i != correctCount) i,
    ]..shuffle(_random);
    setState(() {
      _phase = _Phase.answering;
      _answerOptions = [correctCount, ...otherValues.take(3)]..shuffle(_random);
    });
  }

  void _answer(int selected) {
    if (_answered) return;
    final isCorrect = selected == _round.correctCount;
    setState(() => _selectedAnswer = selected);
    if (isCorrect) {
      SoundManager.playCorrect();
      _totalScore += _pointsBySpeed[_speedLevel];
      _correctRoundCount++;
    } else {
      SoundManager.playGentleTap();
    }
    setState(() => _answered = true);
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      if (_roundIndex < _roundCount - 1) {
        setState(() => _roundIndex++);
        _startRound();
      } else {
        _finishAll();
      }
    });
  }

  void _finishAll() {
    _roundTimer?.cancel();
    _tickTimer?.cancel();
    _hasCompletedOnce = true;

    final percent = ((_correctRoundCount / _roundCount) * 100).round();
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'İkili Kelime Grubu Say',
      result: '$_correctRoundCount/$_roundCount doğru (%$percent)',
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
            Text('Doğru: $_correctRoundCount / $_roundCount (%$percent)'),
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
        appBar: AppBar(title: const Text('🔎 İkili Kelime Grubu Say')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _phase == _Phase.intro
                    ? _buildIntro()
                    : _buildRound(key: ValueKey('round-$_roundIndex-$_phase')),
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
                    'Etkinlik 5 · İkili Kelime Grubu Say',
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
                    _buildAmacYontemBox(),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text('🔎', style: TextStyle(fontSize: 64)),
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
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: _color,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sayfada bir sürü ikili kelime grubu göreceksin. Üstte hangi grubu '
                              'arayacağın yazacak — süre dolmadan sayfada kaç kere geçtiğini say, '
                              'sonra doğru sayıyı seç!',
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

  // Kitaptaki sayfanın başındaki "Amaç / Yöntem" kutusu.
  Widget _buildAmacYontemBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFCFFAFE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _color, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text.rich(
            textAlign: TextAlign.center,
            TextSpan(
              style: const TextStyle(fontSize: 13, color: Color(0xFF164E63)),
              children: [
                const TextSpan(
                  text: 'Amaç: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(
                  text:
                      'Gözlerimizin odaklanma hızını artırmak, ikili kelime '
                      'gruplarını görebilmek.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text.rich(
            textAlign: TextAlign.center,
            TextSpan(
              style: const TextStyle(fontSize: 13, color: Color(0xFF164E63)),
              children: [
                const TextSpan(
                  text: 'Yöntem: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(
                  text:
                      'İkili kelime grubunu seçerek 10 saniye içinde sayfada '
                      'kaç kere kullanıldığını bulunuz.',
                ),
              ],
            ),
          ),
        ],
      ),
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
    final totalMs = _roundTimeMsBySpeed[_speedLevel];
    final remainingFraction = (1 - (_elapsedMs / totalMs)).clamp(0.0, 1.0);
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
                  'Tur ${_roundIndex + 1}/$_roundCount',
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
                    'Puan: $_totalScore',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _color,
                    ),
                  ),
                  if (_phase == _Phase.showing)
                    buildPauseButton(color: _color, onPressed: _pauseGame),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text(
                  'Ara: ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  _round.target,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (_phase == _Phase.showing)
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
            ),
          const SizedBox(height: 12),
          Expanded(
            child: _phase == _Phase.showing ? _buildGrid() : _buildAnswerStep(),
          ),
          if (_phase == _Phase.showing) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _goToAnswerStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'CEVAPLA',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Kelime grubu sayısı ekrana sığmayabilir — bu yüzden kart her zaman
  // kaydırılabilir, hiçbir zaman taşmaz.
  Widget _buildGrid() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SingleChildScrollView(
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.15,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: _round.grid.length,
          itemBuilder: (context, index) {
            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _round.grid[index],
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnswerStep() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '"${_round.target}"',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _color,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'sayfada kaç kere geçti?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                for (final option in _answerOptions) _answerButton(option),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _answerButton(int option) {
    final answered = _answered;
    final isSelected = _selectedAnswer == option;
    final isCorrectOption = option == _round.correctCount;
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
        onPressed: answered ? null : () => _answer(option),
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
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: fg,
          ),
        ),
      ),
    );
  }
}

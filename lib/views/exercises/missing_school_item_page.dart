import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';
import '../../widgets/exercise_settings_sheet.dart';

enum _Phase { intro, preview, playing }

class _Round {
  final List<String> shown;
  final String missing;
  const _Round(this.shown, this.missing);
}

/// Klasör 4'ün sekizinci etkinliği: "Eksik Kelimeyi Bul". missing_city_page
/// (Klasör 2 · Etkinlik 4, "Eksik Şehri Bul") ile birebir aynı mantık —
/// sadece şehir yerine okul eşyası kelimeleri: 6 sabit kelime var, her
/// satırda bunlardan SADECE 5'i görünüyor — öğrenci hangi kelimenin eksik
/// olduğunu bulup altındaki 6 buton arasından hızlıca seçmeli. Puan hem
/// doğruluğa hem hıza göre veriliyor.
class MissingSchoolItemPage extends StatefulWidget {
  const MissingSchoolItemPage({super.key});

  @override
  State<MissingSchoolItemPage> createState() => _MissingSchoolItemPageState();
}

class _MissingSchoolItemPageState extends State<MissingSchoolItemPage> {
  Color _color = const Color(0xFF0D9488);

  static const List<Color> _colorPalette = [
    Color(0xFF0D9488),
    Color(0xFFEC4899),
    Color(0xFFEA580C),
    Color(0xFF0D9488),
    Color(0xFF7C3AED),
    Color(0xFF2563EB),
  ];
  static const List<String> _speedLabels = ['Yavaş', 'Orta', 'Hızlı'];
  static const List<int> _roundTimeMsBySpeed = [8000, 5500, 3500];
  static const int _roundCount = 12;

  static const List<String> _items = [
    'Kalem',
    'Silgi',
    'Kitap',
    'Öğrenci',
    'Okul',
    'Bilgi',
  ];

  final Random _random = Random();
  _Phase _phase = _Phase.intro;
  bool _hasCompletedOnce = false;
  bool _isPaused = false;
  int _speedLevel = 1;

  static const int _previewSeconds = 10;
  int _previewElapsedSec = 0;
  Timer? _previewTimer;

  int _roundIndex = 0;
  int _totalScore = 0;
  int _correctCount = 0;
  late _Round _round;
  int _roundElapsedMs = 0;
  Timer? _roundTimer;
  Timer? _tickTimer;
  String? _selectedAnswer;
  bool _answered = false;
  int _lastPoints = 0;

  // Önizleme (6 kelimeyi ezberleme) ve oyun sırasında ekran dar (dikey)
  // kaldığında butonlar taşabiliyordu — bu iki aşamada artık yatay
  // çevirme zorunlu, "telefonunu çevir" ekranı gösterilir.
  bool get _needsLandscape =>
      _phase == _Phase.preview || _phase == _Phase.playing;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    _tickTimer?.cancel();
    _previewTimer?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  _Round _generateRound() {
    final shuffled = [..._items]..shuffle(_random);
    final missing = shuffled.removeLast();
    shuffled.shuffle(_random);
    return _Round(shuffled, missing);
  }

  void _startGame() {
    _previewTimer?.cancel();
    setState(() {
      _phase = _Phase.preview;
      _previewElapsedSec = 0;
    });
    _previewTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _previewElapsedSec++);
      if (_previewElapsedSec >= _previewSeconds) _finishPreview();
    });
  }

  void _finishPreview() {
    _previewTimer?.cancel();
    setState(() {
      _phase = _Phase.playing;
      _roundIndex = 0;
      _totalScore = 0;
      _correctCount = 0;
    });
    _startRound();
  }

  void _startRound() {
    _roundTimer?.cancel();
    _tickTimer?.cancel();
    final round = _generateRound();
    setState(() {
      _round = round;
      _roundElapsedMs = 0;
      _selectedAnswer = null;
      _answered = false;
      _lastPoints = 0;
    });
    final totalMs = _roundTimeMsBySpeed[_speedLevel];
    _tickTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) return;
      setState(
        () => _roundElapsedMs = (_roundElapsedMs + 80).clamp(0, totalMs),
      );
    });
    _roundTimer = Timer(Duration(milliseconds: totalMs), () {
      if (!mounted) return;
      _handleAnswer(null);
    });
  }

  void _pauseGame() {
    _roundTimer?.cancel();
    _tickTimer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resumeGame() {
    final totalMs = _roundTimeMsBySpeed[_speedLevel];
    final remainingMs = (totalMs - _roundElapsedMs).clamp(0, totalMs);
    setState(() => _isPaused = false);
    _tickTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) return;
      setState(
        () => _roundElapsedMs = (_roundElapsedMs + 80).clamp(0, totalMs),
      );
    });
    _roundTimer = Timer(Duration(milliseconds: remainingMs), () {
      if (!mounted) return;
      _handleAnswer(null);
    });
  }

  void _handleAnswer(String? selected) {
    if (_answered) return;
    _tickTimer?.cancel();
    _roundTimer?.cancel();
    final totalMs = _roundTimeMsBySpeed[_speedLevel];
    final isCorrect = selected != null && selected == _round.missing;
    int points = 0;
    if (isCorrect) {
      final remainingFraction = (1 - (_roundElapsedMs / totalMs)).clamp(
        0.0,
        1.0,
      );
      points = (100 * remainingFraction).round().clamp(20, 100);
      _correctCount++;
      _totalScore += points;
      SoundManager.playCorrect();
    } else {
      SoundManager.playGentleTap();
    }
    setState(() {
      _selectedAnswer = selected;
      _answered = true;
      _lastPoints = points;
    });
    Future.delayed(const Duration(milliseconds: 1100), () {
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

    final percent = ((_correctCount / _roundCount) * 100).round();
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Eksik Kelimeyi Bul',
      result: '$_correctCount/$_roundCount doğru · $_totalScore puan',
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
            Text('Doğru: $_correctCount / $_roundCount (%$percent)'),
            const SizedBox(height: 4),
            Text(
              'Toplam puan: $_totalScore',
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
        appBar: AppBar(
          title: const Text('🎒 Eksik Kelimeyi Bul'),
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
          child: OrientationBuilder(
            builder: (context, orientation) {
              if (_needsLandscape && orientation == Orientation.portrait) {
                return _buildRotatePrompt();
              }
              return Stack(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: switch (_phase) {
                      _Phase.intro => _buildIntro(),
                      _Phase.preview => _buildPreview(),
                      _Phase.playing => _buildPlaying(
                        key: ValueKey('round-$_roundIndex'),
                      ),
                    },
                  ),
                  if (_isPaused)
                    buildPauseOverlay(color: _color, onResume: _resumeGame),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRotatePrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            builder: (context, t, child) {
              return Transform.rotate(angle: t * 1.5708, child: child);
            },
            child: Icon(Icons.screen_rotation_rounded, size: 88, color: _color),
          ),
          const SizedBox(height: 20),
          const Text(
            'Telefonunu yan çevir',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu etkinlik yatay ekranda daha rahat oynanır.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Oyun başlamadan önce 6 kelime 10 saniye boyunca gösterilir — öğrenci
  // hepsini ezberleyip turlara öyle başlar.
  Widget _buildPreview() {
    final remaining = (_previewSeconds - _previewElapsedSec).clamp(
      0,
      _previewSeconds,
    );
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Önizleme · Kelimeleri Ezberle',
                style: TextStyle(fontWeight: FontWeight.bold, color: _color),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$remaining sn',
                style: TextStyle(
                  color: Colors.amber.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: _color, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '6 kelimeye dikkatlice odaklan! Az sonra her satırda '
                  'bunlardan sadece 5\'i görünecek.',
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
        Expanded(
          child: Center(
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              alignment: WrapAlignment.center,
              children: [
                for (final item in _items)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: _color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _color, width: 2),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: _color,
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
                    'Etkinlik 8 · Eksik Kelimeyi Bul',
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
                      child: Text('🎒', style: TextStyle(fontSize: 64)),
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
                          Icon(
                            Icons.info_outline_rounded,
                            color: _color,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '6 kelime var: Kalem, Silgi, Kitap, Öğrenci, Okul, Bilgi. '
                              'Her satırda bunlardan SADECE 5\'i görünecek — eksik olan '
                              'kelimeyi bulup hızlıca butona bas. Ne kadar hızlı bulursan '
                              'o kadar çok puan kazanırsın!',
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
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _color, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text.rich(
            textAlign: TextAlign.center,
            TextSpan(
              style: const TextStyle(fontSize: 13, color: Color(0xFF78350F)),
              children: [
                const TextSpan(
                  text: 'Amaç: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(
                  text: 'Dikkati artırmak ve okuma hızını geliştirmek.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text.rich(
            textAlign: TextAlign.center,
            TextSpan(
              style: const TextStyle(fontSize: 13, color: Color(0xFF78350F)),
              children: [
                const TextSpan(
                  text: 'Yöntem: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(
                  text:
                      'a) Soldan sağa hızlıca gözlerle fotoğraf çeker gibi okuyunuz. '
                      'b) "kalem, silgi, kitap, öğrenci, okul, bilgi" kelimelerinden '
                      'her satırda biri eksik yazılmıştır. Eksik olanı hızlıca '
                      'bulunuz.',
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

  Widget _buildPlaying({required Key key}) {
    final totalMs = _roundTimeMsBySpeed[_speedLevel];
    final remainingFraction = (1 - (_roundElapsedMs / totalMs)).clamp(0.0, 1.0);
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
                  'Satır ${_roundIndex + 1}/$_roundCount',
                  style: TextStyle(fontWeight: FontWeight.bold, color: _color),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Puan: $_totalScore',
                    style: TextStyle(
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
          const SizedBox(height: 10),
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
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Hangi kelime eksik?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        // Gösterilen kelimeler ile aşağıdaki cevap
                        // butonları kolay ayırt edilsin diye farklı
                        // (nötr gri) renkte.
                        for (final item in _round.shown)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Text(
                              item,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    if (_answered)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _selectedAnswer == _round.missing
                              ? '✅ Doğru! +$_lastPoints puan'
                              : '❌ Doğrusu: ${_round.missing}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _selectedAnswer == _round.missing
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFE11D48),
                          ),
                        ),
                      ),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [for (final item in _items) _itemButton(item)],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemButton(String item) {
    final isMissing = item == _round.missing;
    final isSelected = _selectedAnswer == item;
    Color bg = _color.withValues(alpha: 0.08);
    Color border = _color.withValues(alpha: 0.3);
    Color fg = _color;
    if (_answered) {
      if (isMissing) {
        bg = const Color(0xFF16A34A).withValues(alpha: 0.14);
        border = const Color(0xFF16A34A);
        fg = const Color(0xFF16A34A);
      } else if (isSelected) {
        bg = const Color(0xFFE11D48).withValues(alpha: 0.14);
        border = const Color(0xFFE11D48);
        fg = const Color(0xFFE11D48);
      }
    }
    return SizedBox(
      width: 150,
      height: 48,
      child: OutlinedButton(
        onPressed: _answered ? null : () => _handleAnswer(item),
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          side: BorderSide(color: border, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          item,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: fg,
          ),
        ),
      ),
    );
  }
}

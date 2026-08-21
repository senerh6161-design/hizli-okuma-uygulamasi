import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';

class _HidePuzzle {
  final String given;
  final String answer;
  final String hint1; // ilk/son harf
  final String hint2; // kategori ipucu
  final String hint3; // ilk üç harf
  const _HidePuzzle(this.given, this.answer, this.hint1, this.hint2, this.hint3);
}

String _normalize(String s) => s
    .trim()
    .replaceAll(RegExp(r'\s+'), '')
    .replaceAll('İ', 'I')
    .replaceAll('ı', 'i')
    .toUpperCase();

/// Mobil uygulama dokümanındaki "Kelimelerle Saklambaç" etkinliği: verilen
/// kelimenin TÜM harflerini kullanarak, ek almamış YENİ bir kelime bulman
/// gerekiyor (örn: KALEM = EMLAK). 30 saniyede bir yeni ipucu açılır, puan
/// ipucu açıldıkça biraz düşer.
class WordHideSeekPage extends StatefulWidget {
  const WordHideSeekPage({super.key});

  @override
  State<WordHideSeekPage> createState() => _WordHideSeekPageState();
}

class _WordHideSeekPageState extends State<WordHideSeekPage> {
  static const List<_HidePuzzle> _puzzles = [
    _HidePuzzle('AKSARAY', 'SAKARYA', 'İlk harfi S, son harfi A',
        'İstanbul\'a yakın bir şehir', 'Sak..'),
    _HidePuzzle('BİSULTAN', 'İSTANBUL', 'İlk harfi İ, son harfi L',
        'Şehirlerin en güzeli', 'İst..'),
    _HidePuzzle('KANKA EL AÇ', 'ÇANAKKALE', 'İlk harfi Ç, son harfi E',
        'Destan yazılan bir şehir', 'Çan..'),
  ];

  static const int _stageSeconds = 30;

  bool _showIntro = true;
  bool _hasCompletedOnce = false;
  int _index = 0;
  int _totalScore = 0;
  int _stage = 0;
  int _elapsedSeconds = 0;
  Timer? _timer;
  final TextEditingController _controller = TextEditingController();
  String? _feedback;
  bool _isWrongFlash = false;

  void _startPuzzles() {
    setState(() => _showIntro = false);
    _startTimerForCurrent();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTimerForCurrent() {
    _timer?.cancel();
    _stage = 0;
    _elapsedSeconds = 0;
    _feedback = null;
    _controller.clear();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
        if (_elapsedSeconds >= _stageSeconds * 3 && _stage < 3) {
          _stage = 3;
        } else if (_elapsedSeconds >= _stageSeconds * 2 && _stage < 2) {
          _stage = 2;
        } else if (_elapsedSeconds >= _stageSeconds && _stage < 1) {
          _stage = 1;
        }
        if (_elapsedSeconds >= _stageSeconds * 4) {
          _submit(force: true);
        }
      });
    });
  }

  // Öğrenci beklemeden manuel ipucu isteyebilsin diye — otomatik 30 sn'lik
  // ipucu zamanlayıcısıyla çakışmaz, çünkü zamanlayıcı sadece _stage GERİDE
  // kaldıysa ileri alır (_stage < X kontrolü), az önce elle ilerletilmiş bir
  // aşamayı asla geri almaz.
  void _requestHint() {
    if (_stage >= 3) return;
    SoundManager.playGentleTap();
    setState(() => _stage++);
  }

  int get _currentPointValue {
    switch (_stage) {
      case 0:
        return 100;
      case 1:
        return 90;
      case 2:
        return 80;
      default:
        return 70;
    }
  }

  void _submit({bool force = false}) {
    final puzzle = _puzzles[_index];
    final userAnswer = _normalize(_controller.text);
    final isSameAsGiven = userAnswer == _normalize(puzzle.given);
    final isCorrect = userAnswer == _normalize(puzzle.answer);

    if (isCorrect) {
      SoundManager.playCorrect();
      _timer?.cancel();
      _totalScore += _currentPointValue;
      setState(() => _feedback = '✅ Doğru! +$_currentPointValue puan');
      Future.delayed(const Duration(milliseconds: 900), _nextPuzzle);
    } else if (force) {
      SoundManager.playGentleTap();
      _timer?.cancel();
      setState(() => _feedback = '⏱️ Süre doldu. Cevap: ${puzzle.answer}');
      Future.delayed(const Duration(milliseconds: 1400), _nextPuzzle);
    } else {
      SoundManager.playGentleTap();
      setState(() {
        _isWrongFlash = true;
        _feedback = isSameAsGiven ? '✍️ Yeni bir kelime bulmalısın, aynısını yazma!' : null;
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _isWrongFlash = false);
      });
    }
  }

  void _nextPuzzle() {
    if (!mounted) return;
    if (_index < _puzzles.length - 1) {
      setState(() => _index++);
      _startTimerForCurrent();
    } else {
      _finish();
    }
  }

  void _finish() {
    _hasCompletedOnce = true;
    final maxScore = _puzzles.length * 100;
    ProgressManager.recordAttentionScore((_totalScore / maxScore * 100).round());

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Kelimelerle Saklambaç',
      result: '$_totalScore/$maxScore puan',
    );
    if (unlocked.isNotEmpty) SoundManager.playAchievement();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🎉 Saklambaç Bitti!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Toplam Puan: $_totalScore / $maxScore',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (unlocked.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('🎉 Yeni Başarım Kazandın!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: unlocked.map((a) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                        Text(a.title,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900)),
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
              Navigator.pop(context); // dialogu kapat
              Navigator.pop(context, true); // Klasör 1'e dön, tamamlandı olarak işaretle
            },
            child: const Text('Bitir'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _index = 0;
                _totalScore = 0;
              });
              _startTimerForCurrent();
            },
            child: const Text('Tekrar Dene'),
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
      appBar: AppBar(title: const Text('🙈 Kelimelerle Saklambaç')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _showIntro ? _buildIntro() : _buildPuzzle(),
      ),
      ),
    );
  }

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nasıl Oynanır?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(
          'Sana verilen harflerin TÜMÜNÜ kullanarak YENİ bir kelime bulacaksın. '
          'Bulduğun kelime, verilen kelimenin aynısı olamaz ve ek almamış olmalı.',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
          child: Text('ÖRNEK',
              style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.pink, width: 2),
            ),
            child: const Text('KALEM', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_downward, color: Colors.green.shade600),
              const SizedBox(width: 8),
              Text('EMLAK', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'KALEM\'in harfleri (K, A, L, E, M) kullanılarak EMLAK kelimesi bulunmuş — '
          'aynı harfler, yeni bir kelime!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: Colors.amber.shade800, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '30 saniye içinde cevap veremezsen ipucu kendiliğinden gelir. Beklemek '
                  'istemiyorsan "İPUCU AL" butonuna basıp hemen bir ipucu alabilirsin!',
                  style: TextStyle(fontSize: 13, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _startPuzzles,
            icon: const Icon(Icons.play_arrow),
            label: const Text('ANLADIM, BAŞLA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPuzzle() {
    final puzzle = _puzzles[_index];
    final remaining = (_stageSeconds - (_elapsedSeconds % _stageSeconds)) % _stageSeconds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Soru ${_index + 1}/${_puzzles.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Şu an: $_currentPointValue puan',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Verilen tüm harfleri kullanarak YENİ bir kelime bul. Bulduğun kelime ek almamış olmalı.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _isWrongFlash ? Colors.red : Colors.pink,
                    width: 2,
                  ),
                ),
                child: Text(
                  puzzle.given,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_stage >= 1)
              _hintChip('💡 İpucu 1: ${puzzle.hint1}'),
            if (_stage >= 2)
              _hintChip('💡 İpucu 2: ${puzzle.hint2}'),
            if (_stage >= 3)
              _hintChip('💡 İpucu 3: İlk üç harf "${puzzle.hint3}"'),
            if (_stage < 3)
              Center(
                child: OutlinedButton.icon(
                  onPressed: _requestHint,
                  icon: const Icon(Icons.lightbulb_outline_rounded),
                  label: const Text('İPUCU AL', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber.shade800,
                    side: BorderSide(color: Colors.amber.shade400),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            const Spacer(),
            if (_feedback != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _feedback!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.pink),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Yeni kelimeni yaz...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _submit(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Icon(Icons.check),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: (remaining <= 10 && _stage < 3)
                  ? Text(
                      'Sonraki ipucuna: $remaining sn',
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const SizedBox(height: 16),
            ),
          ],
        );
  }

  Widget _hintChip(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Text(text, style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.w600)),
    );
  }
}

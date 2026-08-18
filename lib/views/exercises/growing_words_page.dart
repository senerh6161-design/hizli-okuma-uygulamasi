import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';

class _WordRow {
  final String root;
  final String mid;
  final String long;
  const _WordRow(this.root, this.mid, this.long);
}

/// "7. Madde" dokümanındaki etkinlik: her satırda kök bir kelimeden başlayıp
/// giderek uzayan üç biçim var (Başar -> Başarılı -> Başarılıyım). Satırlar 3
/// tur boyunca gösterilir, her turda gösterim hızı otomatik olarak artar.
/// Sonunda hangi uzamış kelimelerin gösterildiğini hatırlama testi yapılır.
class GrowingWordsPage extends StatefulWidget {
  const GrowingWordsPage({super.key});

  @override
  State<GrowingWordsPage> createState() => _GrowingWordsPageState();
}

class _GrowingWordsPageState extends State<GrowingWordsPage> {
  static const List<_WordRow> _allRows = [
    _WordRow('Başar', 'Başarılı', 'Başarılıyım'),
    _WordRow('Düş', 'Düşünce', 'Düşünceli'),
    _WordRow('Bil', 'Bilge', 'Bilgelerden'),
    _WordRow('Var', 'Varlık', 'Varlıklıdır'),
    _WordRow('Giz', 'Gizem', 'Gizemlidir'),
    _WordRow('Bit', 'Bitki', 'Bitkilerimiz'),
    _WordRow('Bas', 'Baskı', 'Basınçlı'),
    _WordRow('Gün', 'Gündüz', 'Günlükler'),
    _WordRow('Öğren', 'Öğrenci', 'Öğrencilerimiz'),
    _WordRow('Sev', 'Sevgi', 'Sevgisizlik'),
    _WordRow('Say', 'Saygın', 'Saygınlık'),
    _WordRow('Kitap', 'Kitapçı', 'Kitapevleri'),
    _WordRow('Gör', 'Görgü', 'Görenek'),
    _WordRow('Gel', 'Gelin', 'Gelinlikçiler'),
    _WordRow('Vatan', 'Vatandaş', 'Vatanseverlik'),
    _WordRow('İş', 'İşçi', 'İşçilerimizden'),
    _WordRow('Bayrak', 'Bayraktar', 'Bayraklaşmak'),
    _WordRow('Yıldız', 'Yıldızlı', 'Yıldızlaşmak'),
    _WordRow('Çare', 'Çaresiz', 'Çare "siz"siniz'),
  ];

  static const int _rowsPerSession = 6;
  static const int _totalPasses = 3;
  static const List<int> _passStepMs = [1300, 900, 600];

  final Random _random = Random();
  late List<_WordRow> _sessionRows;
  late List<String> _recallOptions;
  final Set<String> _selectedOptions = {};

  bool _isReading = false;
  bool _showRecall = false;
  bool _hasCompletedOnce = false;
  int _pass = 0;
  int _flatIndex = 0; // sessionRows.length * 3 içindeki konum
  late List<String> _flatSequence;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _prepareSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _prepareSession() {
    final shuffled = List<_WordRow>.from(_allRows)..shuffle(_random);
    _sessionRows = shuffled.take(_rowsPerSession).toList();
    _flatSequence = _sessionRows.expand((r) => [r.root, r.mid, r.long]).toList();

    final otherLongs = _allRows
        .where((r) => !_sessionRows.contains(r))
        .map((r) => r.long)
        .toList()
      ..shuffle(_random);
    final options = <String>{..._sessionRows.map((r) => r.long)};
    options.addAll(otherLongs.take(4));
    _recallOptions = options.toList()..shuffle(_random);
    _selectedOptions.clear();
  }

  void _startReading() {
    _timer?.cancel();
    setState(() {
      _isReading = true;
      _showRecall = false;
      _pass = 0;
      _flatIndex = 0;
    });
    _scheduleNext();
  }

  void _stopReading() {
    _timer?.cancel();
    setState(() {
      _isReading = false;
      _showRecall = true;
    });
  }

  void _scheduleNext() {
    final stepMs = _passStepMs[_pass.clamp(0, _passStepMs.length - 1)];
    _timer = Timer(Duration(milliseconds: stepMs), () {
      if (!mounted) return;
      if (_flatIndex >= _flatSequence.length - 1) {
        if (_pass >= _totalPasses - 1) {
          setState(() {
            _isReading = false;
            _showRecall = true;
          });
          return;
        }
        setState(() {
          _pass++;
          _flatIndex = 0;
        });
      } else {
        setState(() => _flatIndex++);
      }
      _scheduleNext();
    });
  }

  void _toggleOption(String word) {
    setState(() {
      if (_selectedOptions.contains(word)) {
        _selectedOptions.remove(word);
      } else {
        _selectedOptions.add(word);
      }
    });
  }

  void _submitRecall() {
    _hasCompletedOnce = true;
    final correctSet = _sessionRows.map((r) => r.long).toSet();
    final correctPicks = _selectedOptions.intersection(correctSet).length;
    final wrongPicks = _selectedOptions.difference(correctSet).length;
    final score = ((correctPicks - wrongPicks) / correctSet.length * 100).round().clamp(0, 100);
    ProgressManager.recordAttentionScore(score);
    final isGood = score >= 60;

    if (isGood) {
      SoundManager.playSuccess();
    } else {
      SoundManager.playGentleTap();
    }

    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Uzayan Kelimeler',
      result: '$correctPicks/${correctSet.length} doğru · %$score',
    );
    if (unlocked.isNotEmpty) SoundManager.playAchievement();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(isGood ? '🎉 Harika Hafıza!' : '📖 Tekrar Deneyelim'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Doğru hatırlanan: $correctPicks / ${correctSet.length}'),
            Text('Puan: %$score'),
            const SizedBox(height: 10),
            const Text('Gösterilen kelimeler:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('• ${correctSet.join("\n• ")}'),
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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _prepareSession());
            },
            child: const Text('Yeni Kelimelerle Tekrar'),
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
      appBar: AppBar(title: const Text('📏 Uzayan Kelimeler')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _showRecall ? _buildRecallView() : _buildReadingView(),
      ),
      ),
    );
  }

  Widget _buildReadingView() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _isReading ? 'Tur: ${_pass + 1}/$_totalPasses' : 'Hazır',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
              ),
            ),
            Text(
              '$_rowsPerSession satır, giderek hızlanır',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Kelimeler kökten uzayarak görünecek. Sonunda hangi uzun kelimeleri gördüğün sorulacak, dikkatli oku!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
        ),
        const SizedBox(height: 40),
        Expanded(
          child: Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 120),
                child: Text(
                  _isReading ? _flatSequence[_flatIndex] : 'BAŞLAT\'a bas',
                  key: ValueKey('$_pass-$_flatIndex-$_isReading'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            if (_isReading) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _stopReading,
                  icon: const Icon(Icons.stop),
                  label: const Text('DURDUR', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isReading ? null : _startReading,
                icon: const Icon(Icons.play_arrow),
                label: const Text('BAŞLAT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecallView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Az önce hangi kelimeleri gördün? Doğrularını seç:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            itemCount: _recallOptions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.4,
            ),
            itemBuilder: (context, index) {
              final word = _recallOptions[index];
              final isSelected = _selectedOptions.contains(word);
              return InkWell(
                onTap: () => _toggleOption(word),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    word,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _selectedOptions.isEmpty ? null : _submitRecall,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
            ),
            child: const Text('KONTROL ET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}

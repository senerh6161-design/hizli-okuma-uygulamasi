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
    _WordRow('Oku', 'Okul', 'Okullarımız'),
    _WordRow('Yaz', 'Yazar', 'Yazarlarımız'),
    _WordRow('Konuş', 'Konuşma', 'Konuşmacılar'),
    _WordRow('Anla', 'Anlam', 'Anlamlıdır'),
    _WordRow('Sor', 'Soru', 'Sorumluluk'),
    _WordRow('Kal', 'Kalem', 'Kalemlikler'),
    _WordRow('Renk', 'Renkli', 'Renklendirmek'),
    _WordRow('Resim', 'Resimli', 'Resimlendirmek'),
    _WordRow('Şarkı', 'Şarkıcı', 'Şarkıcılarımız'),
    _WordRow('Oyun', 'Oyuncu', 'Oyuncularımız'),
    _WordRow('Spor', 'Sporcu', 'Sporcularımız'),
    _WordRow('Deniz', 'Denizci', 'Denizcilerimiz'),
    _WordRow('Orman', 'Ormancı', 'Ormancılıkta'),
    _WordRow('Toprak', 'Topraklı', 'Topraklarımız'),
    _WordRow('Güven', 'Güvenli', 'Güvenlikçiler'),
    _WordRow('Temiz', 'Temizlik', 'Temizlikçiler'),
  ];

  static const int _rowsPerSession = 6;
  static const int _totalPasses = 3;
  static const List<int> _passStepMs = [1300, 900, 600];

  final Random _random = Random();
  late List<_WordRow> _sessionRows;
  late List<String> _recallOptions;
  final Set<String> _selectedOptions = {};

  bool _isReading = false;
  bool _isPaused = false; // DURDUR'a basılıp henüz teste geçilmemiş durum
  bool _showRecall = false;
  bool _hasCompletedOnce = false;
  int _pass = 0;
  int _rowInPass = 0; // sessionRows içindeki hangi satırdayız
  int _stage = 0; // 0=kök, 1=kök+orta, 2=kök+orta+uzun (hepsi yan yana görünür)
  // Test sadece GERÇEKTEN gösterilmiş satırları sorsun diye (erken durunca
  // henüz görülmemiş kelimeler haksız yere sorulmasın).
  final Set<int> _seenRowIndices = {};
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
    _seenRowIndices.clear();
    _selectedOptions.clear();
  }

  // Test SADECE gerçekten gösterilmiş satırlardan hazırlanır — Durdur'a
  // erken basılırsa henüz görülmemiş kelimeler soru olarak çıkmaz.
  void _prepareRecallOptions() {
    final seenLongs = _seenRowIndices.map((i) => _sessionRows[i].long).toSet();
    final otherLongs = _allRows
        .where((r) => !seenLongs.contains(r.long))
        .map((r) => r.long)
        .toList()
      ..shuffle(_random);
    final options = <String>{...seenLongs};
    options.addAll(otherLongs.take(4));
    _recallOptions = options.toList()..shuffle(_random);
  }

  void _startReading() {
    _timer?.cancel();
    setState(() {
      _isReading = true;
      _isPaused = false;
      _showRecall = false;
      _pass = 0;
      _rowInPass = 0;
      _stage = 0;
      _seenRowIndices.clear();
    });
    _scheduleNext();
  }

  // DURDUR artık testi başlatmıyor — sadece o anki kelime ailesinde
  // dondurup ekler üzerine bakabilmesi için duraklatıyor. Devam etmek ya
  // da erken teste geçmek ayrı, bilinçli bir seçim.
  void _pauseReading() {
    _timer?.cancel();
    setState(() {
      _isReading = false;
      _isPaused = true;
    });
  }

  void _resumeReading() {
    setState(() {
      _isReading = true;
      _isPaused = false;
    });
    _scheduleNext();
  }

  void _goToRecallNow() {
    _timer?.cancel();
    _prepareRecallOptions();
    setState(() {
      _isReading = false;
      _isPaused = false;
      _showRecall = true;
    });
  }

  void _scheduleNext() {
    final baseStep = _passStepMs[_pass.clamp(0, _passStepMs.length - 1)];
    // Üçü de (kök+orta+uzun) yan yana göründüğünde, karşılaştırıp okumaya
    // vakit versin diye bir sonraki kelimeye geçiş biraz daha yavaş.
    final stepMs = _stage >= 2 ? (baseStep * 1.6).round() : baseStep;
    _timer = Timer(Duration(milliseconds: stepMs), () {
      if (!mounted) return;
      if (_stage < 2) {
        setState(() => _stage++);
      } else {
        _seenRowIndices.add(_rowInPass);
        if (_rowInPass < _sessionRows.length - 1) {
          setState(() {
            _rowInPass++;
            _stage = 0;
          });
        } else if (_pass < _totalPasses - 1) {
          setState(() {
            _pass++;
            _rowInPass = 0;
            _stage = 0;
          });
        } else {
          _prepareRecallOptions();
          setState(() {
            _isReading = false;
            _showRecall = true;
          });
          return;
        }
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
    final correctSet = _seenRowIndices.map((i) => _sessionRows[i].long).toSet();
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
        // DURDUR'a basınca (ya da okuma bitince) hatırlama testine anlık
        // bir kesmeyle değil, yumuşak bir geçişle geçilsin.
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: _showRecall
              ? _buildRecallView(key: const ValueKey('recall'))
              : _buildReadingView(key: const ValueKey('reading')),
        ),
      ),
      ),
    );
  }

  Widget _buildReadingView({Key? key}) {
    return Column(
      key: key,
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
                _isReading
                    ? 'Tur: ${_pass + 1}/$_totalPasses'
                    : (_isPaused ? 'Duraklatıldı' : 'Hazır'),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
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
          _isPaused
              ? 'Duraklatıldı — kelimenin eklerine bakabilirsin. Devam et ya da testi başlat!'
              : 'Kelime kökten başlayıp yan yana büyüyecek. Sonunda hangi uzun kelimeleri gördüğün sorulacak, dikkatli oku!',
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
              child: (_isReading || _isPaused)
                  ? _buildFamilyDisplay()
                  : const Text(
                      'BAŞLAT\'a bas',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (_isPaused)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _seenRowIndices.isEmpty ? null : _goToRecallNow,
                  icon: const Icon(Icons.quiz_outlined),
                  label: const Text('ŞİMDİ TEST ET', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFF2563EB)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _resumeReading,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('DEVAM ET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              if (_isReading) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pauseReading,
                    icon: const Icon(Icons.pause),
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
                    backgroundColor: const Color(0xFF2563EB),
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

  // Kök -> orta -> uzun biçim, tek tek birbirinin yerine geçmek yerine SOLDAN
  // SAĞA birikerek yan yana görünür: önce sadece kök, sonra yanına orta biçim
  // eklenir, sonra da uzun biçim — böylece kökten nasıl türediği bir arada
  // görülebiliyor.
  Widget _buildFamilyDisplay() {
    final row = _sessionRows[_rowInPass];
    final stages = [row.root, row.mid, row.long];
    final visibleCount = _stage + 1;

    final children = <Widget>[];
    for (int i = 0; i < visibleCount; i++) {
      if (i > 0) {
        children.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.arrow_forward_rounded, color: Color(0xFF94A3B8), size: 20),
        ));
      }
      children.add(
        TweenAnimationBuilder<double>(
          key: ValueKey('$_pass-$_rowInPass-$i'),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 250),
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.scale(scale: 0.85 + 0.15 * value, child: child),
          ),
          child: _wordChip(stages[i]),
        ),
      );
    }

    // FittedBox: hepsi TEK satırda kalsın diye (alt satıra kaymasın), uzun
    // kelimelerde satır gerekirse tamamı orantılı küçültülür.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _wordChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2563EB), width: 2),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildRecallView({Key? key}) {
    return Column(
      key: key,
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
                    color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300,
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
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('KONTROL ET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}

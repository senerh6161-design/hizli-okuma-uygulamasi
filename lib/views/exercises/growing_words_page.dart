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

class _RecallQuestion {
  final List<String> options;
  final String notSeenWord;
  const _RecallQuestion(this.options, this.notSeenWord);
}

/// "7. Madde" dokümanındaki etkinlik: her satırda kök bir kelimeden başlayıp
/// giderek uzayan üç biçim var (Başar -> Başarılı -> Başarılıyım). Satırlar 3
/// tur boyunca gösterilir, hızı öğrenci kendi seçer ve istediği an bir üst
/// hıza geçebilir — herkes aynı seviyede okumadığı için hız sabitlenmez.
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
  // Hız artık turla otomatik artmıyor — öğrenci bu 3 seviyeden istediğini
  // istediği an seçer (herkes aynı seviyede okumadığı için).
  static const List<int> _speedStepsMs = [1300, 900, 600];
  static const List<String> _speedLabels = ['Yavaş', 'Orta', 'Hızlı'];

  static const int _recallQuestionCount = 5;

  final Random _random = Random();
  late List<_WordRow> _sessionRows;
  List<_RecallQuestion> _recallQuestions = [];

  bool _isReading = false;
  bool _isPaused = false; // DURDUR'a basılıp henüz teste geçilmemiş durum
  bool _showRecall = false;
  bool _hasCompletedOnce = false;
  int _pass = 0;
  int _rowInPass = 0; // sessionRows içindeki hangi satırdayız
  int _stage = 0; // 0=kök, 1=kök+orta, 2=kök+orta+uzun (hepsi yan yana görünür)
  int _speedLevel = 0; // öğrencinin seçtiği hız seviyesi (0=yavaş..2=hızlı)
  // Test sadece GERÇEKTEN gösterilmiş satırları sorsun diye (erken durunca
  // henüz görülmemiş kelimeler haksız yere sorulmasın).
  final Set<int> _seenRowIndices = {};
  Timer? _timer;
  // Kelime uzayıp kart genişleyince en yeni (en uzun) biçim kart görünür
  // alanın dışında kalıp kesik görünüyordu — her yeni aşamada bu kaydırıcı
  // otomatik olarak en sona kayar, kelime her zaman tam görünür.
  final ScrollController _familyScrollController = ScrollController();

  int _recallIndex = 0;
  int _recallCorrectCount = 0;
  int? _recallSelectedIndex;
  Set<String> _recallShownWords = {};

  @override
  void initState() {
    super.initState();
    _prepareSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _familyScrollController.dispose();
    super.dispose();
  }

  void _scrollFamilyToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_familyScrollController.hasClients) return;
      _familyScrollController.animateTo(
        _familyScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _prepareSession() {
    final shuffled = List<_WordRow>.from(_allRows)..shuffle(_random);
    _sessionRows = shuffled.take(_rowsPerSession).toList();
    _seenRowIndices.clear();
    _showRecall = false;
    _recallIndex = 0;
    _recallCorrectCount = 0;
    _recallSelectedIndex = null;
  }

  // "Hangisini görmedin?" testi: her soruda gösterilmiş 3 kelime + hiç
  // gösterilmemiş 1 kelime karışık sırayla sunulur, öğrenci görmediğini
  // bulmaya çalışır. Test SADECE gerçekten gösterilmiş satırlardan
  // hazırlanır — Durdur'a erken basılırsa henüz görülmemiş kelimeler
  // "gösterilmiş" seçenek olarak çıkmaz.
  void _prepareRecallQuestions() {
    final seenLongs = _seenRowIndices.map((i) => _sessionRows[i].long).toList()
      ..shuffle(_random);
    _recallShownWords = seenLongs.toSet();
    if (seenLongs.isEmpty) {
      _recallQuestions = [];
      return;
    }
    final notSeenPool =
        _allRows
            .where((r) => !seenLongs.contains(r.long))
            .map((r) => r.long)
            .toList()
          ..shuffle(_random);

    final realSlotsPerQuestion = min(3, seenLongs.length);
    final questions = <_RecallQuestion>[];
    for (int i = 0; i < _recallQuestionCount; i++) {
      final notSeen = notSeenPool[i % notSeenPool.length];
      final reals = [
        for (int j = 0; j < realSlotsPerQuestion; j++)
          seenLongs[(i + j) % seenLongs.length],
      ];
      final options = [notSeen, ...reals]..shuffle(_random);
      questions.add(_RecallQuestion(options, notSeen));
    }
    _recallQuestions = questions;
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
    _prepareRecallQuestions();
    setState(() {
      _isReading = false;
      _isPaused = false;
      _showRecall = true;
      _recallIndex = 0;
      _recallCorrectCount = 0;
      _recallSelectedIndex = null;
    });
  }

  void _scheduleNext() {
    final baseStep = _speedStepsMs[_speedLevel];
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
          _prepareRecallQuestions();
          setState(() {
            _isReading = false;
            _showRecall = true;
            _recallIndex = 0;
            _recallCorrectCount = 0;
            _recallSelectedIndex = null;
          });
          return;
        }
      }
      _scrollFamilyToEnd();
      _scheduleNext();
    });
  }

  void _answerRecallQuestion(int optionIndex) {
    if (_recallSelectedIndex != null) return;
    final q = _recallQuestions[_recallIndex];
    final isCorrect = q.options[optionIndex] == q.notSeenWord;
    if (isCorrect) {
      _recallCorrectCount++;
      SoundManager.playCorrect();
    } else {
      SoundManager.playGentleTap();
    }
    setState(() => _recallSelectedIndex = optionIndex);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_recallIndex < _recallQuestions.length - 1) {
        setState(() {
          _recallIndex++;
          _recallSelectedIndex = null;
        });
      } else {
        _finishAll();
      }
    });
  }

  void _finishAll() {
    _hasCompletedOnce = true;
    final overallScore = (_recallCorrectCount / _recallQuestions.length * 100)
        .round();
    ProgressManager.recordAttentionScore(overallScore);
    final isGood = overallScore >= 60;

    if (isGood) {
      SoundManager.playSuccess();
    } else {
      SoundManager.playGentleTap();
    }

    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Uzayan Kelimeler',
      result:
          '$_recallCorrectCount/${_recallQuestions.length} doğru · %$overallScore',
    );
    if (unlocked.isNotEmpty) SoundManager.playAchievement();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(isGood ? '🎉 Harika!' : '📖 Tekrar Deneyelim'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hafıza testi: $_recallCorrectCount / ${_recallQuestions.length} doğru',
            ),
            Text('Puan: %$overallScore'),
            const SizedBox(height: 10),
            const Text(
              'Gösterilen kelimeler:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('• ${_recallShownWords.join("\n• ")}'),
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
              Navigator.pop(context); // dialogu kapat
              Navigator.pop(
                context,
                true,
              ); // Klasör 1'e dön, tamamlandı olarak işaretle
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
            Text(
              '$_rowsPerSession satır',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Text(
              'Hız: ',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(width: 6),
            for (int i = 0; i < _speedLabels.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _speedChip(i),
            ],
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                _isPaused
                    ? Icons.pause_circle_outline_rounded
                    : Icons.info_outline_rounded,
                color: const Color(0xFF2563EB),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isPaused
                      ? 'Duraklatıldı — kelimenin eklerine bakabilirsin. Devam et ya da testi başlat!'
                      : 'Kelime kökten başlayıp yan yana büyüyecek. İstediğin an hızını değiştirebilirsin. '
                            'Sonunda hangi uzun kelimeleri gördüğün sorulacak, dikkatli oku!',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
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
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: (_isReading || _isPaused)
                  ? _buildFamilyDisplay()
                  : const Text(
                      'BAŞLAT\'a bas',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
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
                  label: const Text(
                    'ŞİMDİ TEST ET',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFF2563EB)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _resumeReading,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text(
                    'DEVAM ET',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                    label: const Text(
                      'DURDUR',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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
                  label: const Text(
                    'BAŞLAT',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
        children.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ),
        );
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

    // Uzun kelime eklendiğinde yazı küçülmesin diye FittedBox kullanılmıyor;
    // gerekirse yatay kaydırılır, tüm biçimler her zaman aynı punto kalır.
    // _scrollFamilyToEnd her yeni aşamada bu kaydırıcıyı sona götürür, en
    // yeni (en uzun) biçim asla kesik kalmaz.
    return SingleChildScrollView(
      controller: _familyScrollController,
      scrollDirection: Axis.horizontal,
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  static const List<IconData> _speedIcons = [
    Icons.hourglass_bottom_rounded,
    Icons.directions_walk_rounded,
    Icons.bolt_rounded,
  ];

  Widget _speedChip(int level) {
    final selected = _speedLevel == level;
    return ChoiceChip(
      avatar: Icon(
        _speedIcons[level],
        size: 18,
        color: selected ? Colors.white : const Color(0xFF2563EB),
      ),
      label: Text(_speedLabels[level]),
      labelStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: selected ? Colors.white : const Color(0xFF2563EB),
      ),
      selected: selected,
      onSelected: (_) => setState(() => _speedLevel = level),
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.08),
      side: BorderSide(
        color: const Color(0xFF2563EB).withValues(alpha: selected ? 1 : 0.3),
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
    final q = _recallQuestions[_recallIndex];
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Soru: ${_recallIndex + 1}/${_recallQuestions.length}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Aşağıdakilerden hangisini GÖRMEDİN?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            itemCount: q.options.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.4,
            ),
            itemBuilder: (context, index) {
              final word = q.options[index];
              final isNotSeen = word == q.notSeenWord;
              final isSelected = _recallSelectedIndex == index;
              final answered = _recallSelectedIndex != null;

              Color bg = Colors.white;
              Color border = Colors.grey.shade300;
              Color textColor = Colors.black87;
              if (answered && isNotSeen) {
                bg = Colors.green.shade50;
                border = Colors.green.shade400;
                textColor = Colors.green.shade800;
              } else if (answered && isSelected) {
                bg = Colors.red.shade50;
                border = Colors.red.shade400;
                textColor = Colors.red.shade800;
              }

              return InkWell(
                onTap: answered ? null : () => _answerRecallQuestion(index),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border, width: 2),
                  ),
                  child: Text(
                    word,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: textColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

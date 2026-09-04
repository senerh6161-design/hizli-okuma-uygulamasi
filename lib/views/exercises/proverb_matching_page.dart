import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';

class _ProverbPair {
  final String left;
  final String right;
  const _ProverbPair(this.left, this.right);
}

enum _Phase { intro, warmup, ready, matching, bolum2Intro }

/// Klasör 3'ün beşinci etkinliği: "Atasözü Eşleştirme". Hocanın verdiği
/// sunumdaki atasözü yarım-birleştirme sayfalarının karşılığı — önce bir
/// antreman ekranında mekaniğin nasıl çalıştığı 3 kez otomatik olarak
/// gösteriliyor, sonra 1. Bölüm'de 5 sette (her sette 9 atasözü) öğrenci
/// sol yarıya dokunup doğru sağ yarıyı bularak atasözünü tamamlıyor.
/// 2. Bölüm'de aynı 5 set taraflar yer değiştirmiş halde tekrar geliyor
/// (tamamlayan yarılar solda, başlangıçlar sağda) — bkz. [_bolumIndex].
class ProverbMatchingPage extends StatefulWidget {
  const ProverbMatchingPage({super.key});

  @override
  State<ProverbMatchingPage> createState() => _ProverbMatchingPageState();
}

class _ProverbMatchingPageState extends State<ProverbMatchingPage> {
  static const Color _color = Color(0xFFDB2777);

  // Kutu içindeki yazı boyutu — en büyük seçenekte bile taşmasın diye
  // FittedBox ile birlikte kullanılıyor.
  static const List<String> _textSizeLabels = ['Küçük', 'Orta', 'Büyük'];
  static const List<double> _textSizeValues = [12, 14, 17];
  int _textSizeLevel = 1;

  // Antreman, egzersizdeki 5 setten İLK 3'ünü otomatik olarak gösterir —
  // her tekrarda gerçek bir set (9 atasözünün TAMAMI), egzersizle aynı
  // yoğunlukta ekranı doldursun diye. Sol sütun sırayla, sağ sütun ise
  // gerçek egzersizdeki gibi karışık (bkz. _startWarmup/_advanceWarmup).
  static const int _warmupRepeats = 3;
  static const List<String> _speedLabels = ['Yavaş', 'Orta', 'Hızlı'];
  static const List<int> _warmupStepMsBySpeed = [1300, 850, 500];
  int _speedLevel = 1;

  // Hocanın sunumundaki 5 set, her biri 9 atasözü (iki yarısı ayrı ayrı
  // sütunlarda karışık verilmiş) — buraya çözülmüş haliyle aktarıldı.
  static const List<List<_ProverbPair>> _sets = [
    [
      _ProverbPair('Görünen köy', 'kılavuz istemez'),
      _ProverbPair('Her güzelin', 'bir kusuru vardır'),
      _ProverbPair('Her kuşun', 'eti yenmez'),
      _ProverbPair('İş bilenin', 'kılıç kuşananın'),
      _ProverbPair('Körle yatan', 'şaşı kalkar'),
      _ProverbPair('Kimsenin ahı', 'kimsede kalmaz'),
      _ProverbPair('İşleyen demir', 'pas tutmaz'),
      _ProverbPair('Düşüne düşüne', 'görmeli işi'),
      _ProverbPair('Gayret bekler', 'olmamalı kişi'),
    ],
    [
      _ProverbPair('Minareyi çalan', 'kılıfını hazırlar'),
      _ProverbPair('Mum dibine', 'ışık vermez'),
      _ProverbPair('Kara gün', 'kararıp kalmaz'),
      _ProverbPair('Kara haber', 'tez duyulur'),
      _ProverbPair('Öfkeyle kalkan', 'zararla oturur'),
      _ProverbPair('Parayı veren', 'düdüğü çalar'),
      _ProverbPair('Sabır acıdır', 'meyvesi tatlıdır'),
      _ProverbPair('Yatan aslandan', 'gezen tilki iyidir'),
      _ProverbPair('Taşıma su ile', 'değirmen dönmez'),
    ],
    [
      _ProverbPair('Tek kanatla', 'kuş uçmaz'),
      _ProverbPair('Zararın neresinden', 'dönülse kardır'),
      _ProverbPair('Ağır kazan', 'geç kaynar'),
      _ProverbPair('Abanın kadri', 'yağmurda bilinir'),
      _ProverbPair('Adam arkadaşından', 'belli olur'),
      _ProverbPair('Ak akçe', 'kara gün içindir'),
      _ProverbPair('Akan su', 'yosun tutmaz'),
      _ProverbPair('Ağacın kurdu', 'içinde olur'),
      _ProverbPair('Ağaç yaprağıyla', 'gürler'),
    ],
    [
      _ProverbPair('Bal bal demekle', 'ağız tatlanmaz'),
      _ProverbPair('Bin kaygı', 'bir borç ödemez'),
      _ProverbPair('Bir elin nesi var', 'iki elin sesi var'),
      _ProverbPair('Ateş olmayan yerden', 'duman çıkmaz'),
      _ProverbPair('Çiftçinin ambarı', 'sabanın ucundadır'),
      _ProverbPair('Bir musibet, bin', 'nasihatten iyidir'),
      _ProverbPair('Denize düşen', 'yılana sarılır'),
      _ProverbPair('Boş çuval', 'dik durmaz'),
      _ProverbPair('Büyük lokma ye', 'büyük söz söyleme'),
    ],
    [
      _ProverbPair('Dost kara günde', 'belli olur'),
      _ProverbPair('El yarası geçer', 'dil yarası geçmez'),
      _ProverbPair('Al malın iyisini', 'çekme kaygısını'),
      _ProverbPair('Akıl yiğide', 'sermayedir'),
      _ProverbPair('Ateş olmayan', 'yerden duman çıkmaz'),
      _ProverbPair('Göz görmeyince', 'gönül katlanır'),
      _ProverbPair('Vakitsiz açılan gül', 'çabuk solar'),
      _ProverbPair('Yalnız taş', 'duvar olmaz'),
      _ProverbPair('Sabrın sonu', 'selamettir'),
    ],
  ];

  final Random _random = Random();
  _Phase _phase = _Phase.intro;
  bool _hasCompletedOnce = false;
  bool _isPaused = false;

  // Antreman
  int _warmupPairIndex = 0;
  int _warmupSubStep = 0; // 0 = sol vurgulu, 1 = sağ da vurgulu + eşleşti
  int _warmupRepeatIndex = 0;
  List<int> _warmupRightOrder = const [];
  Timer? _warmupTimer;

  int _setIndex = 0;
  // 0 = 1. Bölüm (sol=başlangıç, sağ=tamamlayan yarı), 1 = 2. Bölüm
  // (aynı 5 set ama sağ-sol yer değiştirmiş — soldakiler sağa, sağdakiler
  // sola alınmış).
  int _bolumIndex = 0;
  List<int> _leftOrder = const [];
  List<int> _rightOrder = const [];
  final Set<int> _solvedPairIndices = {};
  int? _selectedLeftIndex;
  int? _wrongLeftFlash;
  int? _wrongRightFlash;
  int _mistakeCount = 0;
  int _elapsedSec = 0;
  Timer? _elapsedTimer;

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _warmupTimer?.cancel();
    super.dispose();
  }

  void _startWarmup() {
    setState(() {
      _phase = _Phase.warmup;
      _warmupPairIndex = 0;
      _warmupSubStep = 0;
      _warmupRepeatIndex = 0;
      _warmupRightOrder = _shuffledOrder(_sets[0].length);
    });
    _scheduleWarmupStep();
  }

  List<int> _shuffledOrder(int length) =>
      (List<int>.generate(length, (i) => i)..shuffle(_random));

  void _scheduleWarmupStep() {
    _warmupTimer?.cancel();
    _warmupTimer = Timer(
      Duration(milliseconds: _warmupStepMsBySpeed[_speedLevel]),
      _advanceWarmup,
    );
  }

  void _advanceWarmup() {
    if (!mounted) return;
    if (_warmupSubStep == 0) {
      SoundManager.playCorrect();
      setState(() => _warmupSubStep = 1);
      _scheduleWarmupStep();
      return;
    }
    if (_warmupPairIndex < _sets[_warmupRepeatIndex].length - 1) {
      setState(() {
        _warmupPairIndex++;
        _warmupSubStep = 0;
      });
      _scheduleWarmupStep();
      return;
    }
    if (_warmupRepeatIndex < _warmupRepeats - 1) {
      setState(() {
        _warmupRepeatIndex++;
        _warmupPairIndex = 0;
        _warmupSubStep = 0;
        _warmupRightOrder = _shuffledOrder(_sets[_warmupRepeatIndex].length);
      });
      _scheduleWarmupStep();
    } else {
      _warmupTimer?.cancel();
      setState(() => _phase = _Phase.ready);
    }
  }

  void _changeWarmupSpeed(int level) {
    setState(() => _speedLevel = level);
    _scheduleWarmupStep();
  }

  void _startGame() {
    _setIndex = 0;
    _mistakeCount = 0;
    setState(() => _phase = _Phase.matching);
    _loadPairs();
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSec++);
    });
  }

  // O anki setin çift sırasını karıştırıp ekranı sıfırlıyor.
  void _loadPairs() {
    final pairs = _sets[_setIndex];
    final leftOrder = List<int>.generate(pairs.length, (i) => i)
      ..shuffle(_random);
    final rightOrder = List<int>.generate(pairs.length, (i) => i)
      ..shuffle(_random);
    setState(() {
      _leftOrder = leftOrder;
      _rightOrder = rightOrder;
      _solvedPairIndices.clear();
      _selectedLeftIndex = null;
      _wrongLeftFlash = null;
      _wrongRightFlash = null;
      _elapsedSec = 0;
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

  void _tapLeft(int pairIndex) {
    if (_solvedPairIndices.contains(pairIndex)) return;
    setState(() => _selectedLeftIndex = pairIndex);
  }

  void _tapRight(int pairIndex) {
    if (_solvedPairIndices.contains(pairIndex)) return;
    final selected = _selectedLeftIndex;
    if (selected == null) return;
    if (selected == pairIndex) {
      SoundManager.playCorrect();
      setState(() {
        _solvedPairIndices.add(pairIndex);
        _selectedLeftIndex = null;
      });
      if (_solvedPairIndices.length == _sets[_setIndex].length) {
        _elapsedTimer?.cancel();
        Future.delayed(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          _advanceSet();
        });
      }
    } else {
      SoundManager.playGentleTap();
      _mistakeCount++;
      setState(() {
        _wrongLeftFlash = selected;
        _wrongRightFlash = pairIndex;
      });
      Future.delayed(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        setState(() {
          _wrongLeftFlash = null;
          _wrongRightFlash = null;
          _selectedLeftIndex = null;
        });
      });
    }
  }

  void _advanceSet() {
    if (_setIndex < _sets.length - 1) {
      _setIndex++;
      _loadPairs();
      _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _elapsedSec++);
      });
    } else if (_bolumIndex == 0) {
      _elapsedTimer?.cancel();
      setState(() => _phase = _Phase.bolum2Intro);
    } else {
      _finishAll();
    }
  }

  // 2. Bölüm: aynı 5 set tekrar geliyor ama sağ-sol yer değiştiriyor —
  // soldaki atasözü başlangıçları sağa, sağdaki tamamlayan yarılar sola
  // alınıyor (bkz. _buildMatching'in swapped dalı).
  void _startBolum2() {
    _bolumIndex = 1;
    _setIndex = 0;
    setState(() => _phase = _Phase.matching);
    _loadPairs();
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSec++);
    });
  }

  void _finishAll() {
    _elapsedTimer?.cancel();
    _hasCompletedOnce = true;

    const percent = 100;
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Atasözü Eşleştirme',
      result: '2 bölüm · ${_sets.length} set · $_mistakeCount hata',
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
              '2 bölümde de ${_sets.length} sette tüm atasözlerini eşleştirdik!',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              'Toplam hata: $_mistakeCount',
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
              setState(() {
                _phase = _Phase.intro;
                _bolumIndex = 0;
              });
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
        appBar: AppBar(title: const Text('📖 Atasözü Eşleştirme')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildBody(),
              ),
              if (_isPaused)
                buildPauseOverlay(color: _color, onResume: _resumeGame),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _Phase.intro:
        return _buildIntro();
      case _Phase.warmup:
        return _buildWarmup();
      case _Phase.ready:
        return _buildReady();
      case _Phase.matching:
        return _buildMatching(key: ValueKey('set-$_bolumIndex-$_setIndex'));
      case _Phase.bolum2Intro:
        return _buildBolum2Intro();
    }
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
                    'Etkinlik 5 · Atasözü Eşleştirme',
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
                        color: const Color(0xFFFCE7F3),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _color, width: 1.5),
                      ),
                      child: const Text(
                        'Amaç: Gözümüzün tarama hızını artırmak ve '
                        'atasözlerimizi pekiştirmek.\n\nYöntem: Sol '
                        'taraftaki atasözü başlangıcına dokunup doğru '
                        'tamamlayan yarıyı sağdan bulacağız.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF831843),
                        ),
                      ),
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
                              'Önce küçük bir antremanla mekaniği 3 kez '
                              'izleyeceğiz, sonra 5 set atasözümüz var, '
                              'her sette 9 atasözü eşleştireceğiz!',
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
            onSelected: (_) {
              if (_phase == _Phase.warmup) {
                _changeWarmupSpeed(i);
              } else {
                setState(() => _speedLevel = i);
              }
            },
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

  // Antreman: mekaniği 3 kez otomatik gösteriyor — sol taraf sırayla
  // vurgulanıyor, sonra doğru sağ yarı bulunup ikisi de yeşile dönüyor.
  Widget _buildWarmup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '🎓 Antreman · Tekrar ${_warmupRepeatIndex + 1}/$_warmupRepeats',
            style: const TextStyle(fontWeight: FontWeight.bold, color: _color),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sol taraftaki başlangıca dokunacağız, sonra doğru tamamlayan '
          'yarıyı sağdan bulacağız — izle!',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        _speedChipRow(),
        const SizedBox(height: 16),
        Expanded(
          child: Builder(
            builder: (context) {
              final roundPairs = _sets[_warmupRepeatIndex];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        for (int r = 0; r < roundPairs.length; r++)
                          Expanded(
                            child: _proverbChip(
                              text: roundPairs[r].left,
                              solved:
                                  r < _warmupPairIndex ||
                                  (r == _warmupPairIndex &&
                                      _warmupSubStep == 1),
                              selected:
                                  r == _warmupPairIndex && _warmupSubStep == 0,
                              wrongFlash: false,
                              onTap: () {},
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      children: [
                        for (final r
                            in _warmupRightOrder.isEmpty
                                ? List<int>.generate(
                                    roundPairs.length,
                                    (i) => i,
                                  )
                                : _warmupRightOrder)
                          Expanded(
                            child: _proverbChip(
                              text: roundPairs[r].right,
                              solved:
                                  r < _warmupPairIndex ||
                                  (r == _warmupPairIndex &&
                                      _warmupSubStep == 1),
                              selected: false,
                              wrongFlash: false,
                              onTap: () {},
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // Antreman bitince doğrudan zamanlı gerçek sete atlamadan önce
  // gösterilen "artık sıra sende" yönerge ekranı.
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
                  child: const Text(
                    'Şimdi sıra sende! Az önce izlediğin gibi, sol '
                    'taraftaki atasözü başlangıcına dokunup doğru '
                    'tamamlayan yarıyı sağdan bulacaksın — 5 set var, '
                    'hazır olduğunda başlayalım!',
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

  // 1. Bölüm bitince, sağ-sol yer değiştiren 2. Bölüm'e geçmeden önce
  // gösterilen yönerge ekranı.
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
                const Center(child: Text('🔄', style: TextStyle(fontSize: 64))),
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
                  child: const Text(
                    '1. Bölümü tamamladık! Şimdi aynı 5 set tekrar '
                    'gelecek ama bu sefer taraflar yer değiştiriyor — '
                    'atasözünü tamamlayan yarılar solda, başlangıçlar '
                    'sağda olacak. Yine soldan sağa doğru eşleştireceğiz!',
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
                    onPressed: _startBolum2,
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

  Widget _buildMatching({required Key key}) {
    final pairs = _sets[_setIndex];
    return KeyedSubtree(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  '${_bolumIndex + 1}. Bölüm · Set ${_setIndex + 1}/'
                  '${_sets.length} · ${_solvedPairIndices.length}/'
                  '${pairs.length}',
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
          const SizedBox(height: 8),
          _textSizeChipRow(),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      for (final i in _leftOrder)
                        Expanded(
                          child: _proverbChip(
                            text: _bolumIndex == 0
                                ? pairs[i].left
                                : pairs[i].right,
                            solved: _solvedPairIndices.contains(i),
                            selected: _selectedLeftIndex == i,
                            wrongFlash: _wrongLeftFlash == i,
                            onTap: () => _tapLeft(i),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: [
                      for (final i in _rightOrder)
                        Expanded(
                          child: _proverbChip(
                            text: _bolumIndex == 0
                                ? pairs[i].right
                                : pairs[i].left,
                            solved: _solvedPairIndices.contains(i),
                            selected: false,
                            wrongFlash: _wrongRightFlash == i,
                            onTap: () => _tapRight(i),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _textSizeChipRow() {
    return Row(
      children: [
        Text(
          'Yazı: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 6),
        for (int i = 0; i < _textSizeLabels.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          ChoiceChip(
            label: Text(_textSizeLabels[i]),
            selected: _textSizeLevel == i,
            onSelected: (_) => setState(() => _textSizeLevel = i),
            selectedColor: _color,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _textSizeLevel == i ? Colors.white : _color,
            ),
            backgroundColor: _color.withValues(alpha: 0.08),
            side: BorderSide(
              color: _color.withValues(alpha: _textSizeLevel == i ? 1 : 0.3),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ],
    );
  }

  Widget _proverbChip({
    required String text,
    required bool solved,
    required bool selected,
    required bool wrongFlash,
    required VoidCallback onTap,
  }) {
    Color bg = Colors.white;
    Color border = Colors.grey.shade300;
    Color fg = const Color(0xFF334155);
    double borderWidth = 1;
    if (solved) {
      bg = const Color(0xFF16A34A).withValues(alpha: 0.12);
      border = const Color(0xFF16A34A);
      fg = const Color(0xFF16A34A);
      borderWidth = 2;
    } else if (wrongFlash) {
      bg = const Color(0xFFE11D48).withValues(alpha: 0.12);
      border = const Color(0xFFE11D48);
      fg = const Color(0xFFE11D48);
      borderWidth = 2;
    } else if (selected) {
      bg = _color.withValues(alpha: 0.15);
      border = _color;
      fg = _color;
      borderWidth = 2;
    }
    return GestureDetector(
      onTap: solved ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: borderWidth),
          borderRadius: BorderRadius.circular(12),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: _textSizeValues[_textSizeLevel],
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

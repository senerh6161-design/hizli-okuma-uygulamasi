import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';

class _ObjectItem {
  final String name;
  final String emoji;
  const _ObjectItem(this.name, this.emoji);
}

/// 1. Bölüm'ün her turu: kendi hedef/çeldiricisi, kendi akışı ve kendi
/// sorusu olan bağımsız bir tur. 1. Bölüm bunlardan 3 tanesini sırayla
/// (duyuru → akış → soru) çalıştırır.
class _Stage1Round {
  final _ObjectItem target;
  final _ObjectItem decoy;
  final List<_ObjectItem> sequence;
  final int correctCount;
  int? answer;
  bool? wasCorrect;
  _Stage1Round({
    required this.target,
    required this.decoy,
    required this.sequence,
    required this.correctCount,
  });
}

/// 2. Bölüm'ün her turu: 1. Bölüm ile AYNI mantık (tek hedef duyur → akış →
/// soru), sadece akışın GÖRSEL TARZI farklı — nesneler birikmiyor, satır
/// satır akıp kayboluyor. Öğrenci her turda SADECE 1 nesneyi aklında tutar.
class _Stage2Round {
  final String targetName;
  final int correctCount;
  final List<List<_ObjectItem>> lines;
  int? answer;
  bool? wasCorrect;
  _Stage2Round({
    required this.targetName,
    required this.correctCount,
    required this.lines,
  });
}

/// Öğretmen dokümanındaki nesne akışı etkinliği: satır üstünde hareketli
/// nesneler akar, bazı nesneler defalarca tekrarlanır. İki bölümden oluşur:
/// 1. Bölüm'de nesneler tek tek birikerek akar, 2. Bölüm'de satır satır akıp
/// kaybolur — her ikisi de 3'er tur, her turda tek bir hedef nesne önceden
/// duyurulup sonunda "kaç kez gördün?" diye sorulur.
class ObjectFlowCountingPage extends StatefulWidget {
  const ObjectFlowCountingPage({super.key});

  @override
  State<ObjectFlowCountingPage> createState() => _ObjectFlowCountingPageState();
}

class _ObjectFlowCountingPageState extends State<ObjectFlowCountingPage> {
  // Hocanın dokümanındaki nesne listesi.
  static const List<_ObjectItem> _objectPool = [
    _ObjectItem('Kalem', '🖊️'),
    _ObjectItem('Silgi', '🧼'),
    _ObjectItem('Kitap', '📕'),
    _ObjectItem('Çanta', '🎒'),
    _ObjectItem('Kalemlik', '🧰'),
    _ObjectItem('Suluk', '🧴'),
    _ObjectItem('Tenis Topu', '🎾'),
    _ObjectItem('Basketbol Topu', '🏀'),
    _ObjectItem('Futbol Topu', '⚽'),
    _ObjectItem('Akıllı Tahta', '🖥️'),
    _ObjectItem('Kalemtıraş', '✂️'),
    _ObjectItem('Cep Telefonu', '📱'),
    _ObjectItem('Defter', '📓'),
    _ObjectItem('Beslenme Çantası', '🍱'),
    _ObjectItem('Ayraç', '🔖'),
    _ObjectItem('Fosforlu Kalem', '🖍️'),
    _ObjectItem('Tost', '🥪'),
    _ObjectItem('Dosya', '📁'),
    _ObjectItem('Cetvel', '📏'),
    _ObjectItem('Küre Dünya', '🌍'),
    _ObjectItem('Yangın Tüpü', '🧯'),
    _ObjectItem('Mikroskop', '🔬'),
    _ObjectItem('Sıra', '🪑'),
    _ObjectItem('Oyuncak Ayı', '🧸'),
    _ObjectItem('Duvar Saati', '🕐'),
    _ObjectItem('Ay Yıldız Bayrak', '🇹🇷'),
    _ObjectItem('Boya Paleti', '🎨'),
    _ObjectItem('Kulaklık', '🎧'),
    _ObjectItem('Ampul', '💡'),
    _ObjectItem('Anahtar', '🔑'),
    _ObjectItem('Gönye', '📐'),
    _ObjectItem('Pusula', '🧭'),
    _ObjectItem('Harita', '🗺️'),
    _ObjectItem('Mıknatıs', '🧲'),
    _ObjectItem('Deney Tüpü', '🧪'),
    _ObjectItem('Termometre', '🌡️'),
    _ObjectItem('Bisiklet', '🚲'),
    _ObjectItem('Balon', '🎈'),
    _ObjectItem('Uçurtma', '🪁'),
    _ObjectItem('Çorap', '🧦'),
    _ObjectItem('Şapka', '🧢'),
    _ObjectItem('Yapboz', '🧩'),
    _ObjectItem('Ataç', '🖇️'),
    _ObjectItem('Fırça', '🖌️'),
    _ObjectItem('Davul', '🥁'),
    _ObjectItem('Sarı Yeşil Elma', '🍏'),
    _ObjectItem('Sarı Limon', '🍋'),
    _ObjectItem('Kırmızı Elma', '🍎'),
    _ObjectItem('Domates', '🍅'),
    _ObjectItem('Portakal', '🍊'),
    _ObjectItem('Mango', '🥭'),
    _ObjectItem('Üzüm', '🍇'),
    _ObjectItem('Patlıcan', '🍆'),
    _ObjectItem('Muz', '🍌'),
    _ObjectItem('Mısır', '🌽'),
  ];

  // Hedef/çeldirici HER OTURUMDA değişsin diye birden fazla çift tanımlı —
  // hep limon çıkmasın, öğrenci "yine aynı emojiler dönüyor" demesin.
  // Renkler BİLEREK BİRBİRİNDEN FARKLI seçildi (ör. kırmızı elma/yeşil
  // elma, sarı limon/mor üzüm) — aynı renk tonundaki çiftler (ör. turuncu
  // portakal/turuncu mango) net ayırt edilemiyordu, ekran "hep aynı renk"
  // gibi görünüyordu.
  static const List<List<String>> _confusablePairNames = [
    ['Kırmızı Elma', 'Sarı Yeşil Elma'],
    ['Sarı Limon', 'Üzüm'],
    ['Domates', 'Mısır'],
    ['Portakal', 'Patlıcan'],
    ['Muz', 'Mango'],
  ];

  // Doğrudan doğrulanabilir bir örnek doküman değeri yok, doğrudan
  // dokümanın verdiği "kitap kaç kez gösterildi" örneğiyle uyumlu bir hedef
  // seti seçildi.
  static const Map<String, int> _targetCounts = {
    'Kitap': 14,
    'Kalem': 10,
    'Silgi': 7,
  };

  static const int _totalPasses = 2;
  static const int _lineIntervalMs = 1500;
  static const int _itemsPerLine = 10;
  static const int _fillerObjectCount = 18;

  final Random _random = Random();
  bool _hasCompletedOnce = false;

  // 1. BÖLÜM (ÖNCE çalışır): 3 AYRI tur — her turda tek bir hedef nesne
  // önceden duyurulur, nesneler TEK TEK yan yana birikerek akar, aralarına
  // kasıtlı bir çeldirici karışır, sonunda "kaç kez gördün?" diye o turun
  // sorusu sorulur.
  late List<_Stage1Round> _stage1Rounds; // her zaman 3 eleman
  int _stage1RoundIndex = 0;
  bool _stage1FlowRunning = false;
  bool _stage1ShowQuestion = false;
  int _stage1FlowIndex = 0; // aktif turun akışındaki konum
  Timer? _stage1Timer;

  _Stage1Round get _stage1Round => _stage1Rounds[_stage1RoundIndex];

  // 2. BÖLÜM (1. Bölüm bitince başlar): AYNI mantık (tek hedef duyur → akış
  // → soru) 3 tur, ama akış görsel olarak satır satır akıp kayboluyor
  // (1. Bölüm'deki gibi birikmiyor) — bkz. _oldFlowStarted.
  bool _oldFlowStarted = false;
  bool _showOldFlowIntro = false;
  late List<_Stage2Round> _stage2Rounds; // her zaman 3 eleman
  int _stage2RoundIndex = 0;
  bool _isRunning = false;
  bool _showQuestions = false;
  int _pass = 0;
  int _lineIndex = 0;
  Timer? _timer;

  _Stage2Round get _oldRound => _stage2Rounds[_stage2RoundIndex];

  @override
  void initState() {
    super.initState();
    _prepareSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stage1Timer?.cancel();
    super.dispose();
  }

  _ObjectItem _byName(String name) => _objectPool.firstWhere((o) => o.name == name);

  void _prepareSession() {
    _prepareStage1Rounds();
  }

  void _prepareStage1Rounds() {
    final pairPool = _confusablePairNames.toList()..shuffle(_random);
    final chosenPairs = pairPool.take(3).toList();

    _stage1Rounds = chosenPairs.map((pairNames) {
      final flipped = _random.nextBool();
      final target = _byName(flipped ? pairNames[1] : pairNames[0]);
      final decoy = _byName(flipped ? pairNames[0] : pairNames[1]);

      // "30 satır" dediğimiz, tek tek gelen nesnelerin TOPLAMDA sayfayı
      // doldurması gerekiyordu — 25-30 nesne yan yana birikince sayfanın
      // yarısı boş kalıyordu. Sayıyı büyüttük ki birikince gerçekten tüm
      // sayfayı kaplasın (oran aynı kaldı: hedef ~%20, çeldirici ~%15).
      // Hedef/çeldirici sayısı görünen satır sayısına (~12-14) yakın
      // tutuluyor ki dizinin tamamına eşit dağıtıldıklarında satır başına
      // gerçekten ~1 tane düşsün, birden fazla olmasın.
      final totalLength = 70 + _random.nextInt(21); // 70-90 nesne
      final targetCount = 10 + _random.nextInt(4); // 10-13 kez
      final decoyCount = 8 + _random.nextInt(3); // 8-10 kez

      final fillerPool = _objectPool
          .where((o) => o.name != target.name && o.name != decoy.name)
          .toList()
        ..shuffle(_random);

      final bag = <_ObjectItem>[
        ...List.filled(targetCount, target),
        ...List.filled(decoyCount, decoy),
      ];
      final remaining = totalLength - bag.length;
      for (int i = 0; i < remaining; i++) {
        bag.add(fillerPool[i % fillerPool.length]);
      }

      return _Stage1Round(
        target: target,
        decoy: decoy,
        sequence: _spreadOut(bag),
        correctCount: targetCount,
      );
    }).toList();

    _stage1RoundIndex = 0;
    _oldFlowStarted = false;
    _showOldFlowIntro = false;
    _stage1FlowRunning = false;
    _stage1ShowQuestion = false;
    _stage1FlowIndex = 0;
  }

  // ÖNEMLİ: eski algoritma her adımda "en çok kalan türü" seçiyordu — bu da
  // hedef/çeldirici gibi yüksek sayılı türlerin dizinin BAŞINDA art arda
  // tüketilip (ör. ilk 3 satır sadece mango/muz), az sayılı dolgu
  // nesnelerin sona itilmesine yol açıyordu. Bunun yerine her türü kendi
  // sayısına göre dizinin TAMAMINA eşit aralıklarla yerleştiriyoruz —
  // hedef/çeldirici artık ilk satırda değil, tüm akış boyunca dengeli
  // dağılıyor. Tek sayıda (1) geçen dolgular ise kalan boşluklara rastgele
  // serpiştirilir.
  List<_ObjectItem> _spreadOut(List<_ObjectItem> bag) {
    final n = bag.length;
    final Map<String, List<_ObjectItem>> groups = {};
    for (final item in bag) {
      groups.putIfAbsent(item.name, () => []).add(item);
    }
    final result = List<_ObjectItem?>.filled(n, null);

    int nearestEmptySlot(int idealPos) {
      if (result[idealPos] == null) return idealPos;
      for (int offset = 1; offset < n; offset++) {
        final right = idealPos + offset;
        final left = idealPos - offset;
        if (right < n && result[right] == null) return right;
        if (left >= 0 && result[left] == null) return left;
      }
      return result.indexWhere((e) => e == null); // güvenlik ağı
    }

    final namesByCountDesc = groups.keys.toList()
      ..sort((a, b) => groups[b]!.length.compareTo(groups[a]!.length));

    for (final name in namesByCountDesc) {
      final items = groups[name]!;
      final count = items.length;
      if (count <= 1) continue; // tekiller sona, rastgele boşluklara
      final interval = n / count;
      for (int i = 0; i < count; i++) {
        // Tam ortalama aralığa koymak ("her satırda tam 1 tane") çok
        // düzenli/robotik duruyordu. Aralığa rastgele bir sapma (jitter)
        // ekleyerek doğal, karışık bir dağılım elde ediyoruz — bazı
        // satırlarda hiç olmayabilir, bazılarında 2 olabilir, ama yine de
        // baştan sona genel olarak dengeli yayılmış olur.
        final basePos = (i + 0.5) * interval;
        final jitter = (_random.nextDouble() - 0.5) * interval * 1.4;
        final idealPos = (basePos + jitter).round().clamp(0, n - 1);
        result[nearestEmptySlot(idealPos)] = items[i];
      }
    }

    final emptySlots = [for (int i = 0; i < n; i++) if (result[i] == null) i]..shuffle(_random);
    var cursor = 0;
    for (final name in namesByCountDesc) {
      final items = groups[name]!;
      if (items.length != 1) continue;
      result[emptySlots[cursor]] = items[0];
      cursor++;
    }

    return result.map((e) => e!).toList();
  }

  void _startStage1Flow() {
    _stage1Timer?.cancel();
    setState(() {
      _stage1FlowRunning = true;
      _stage1FlowIndex = 0;
    });
    _scheduleStage1Next();
  }

  void _scheduleStage1Next() {
    _stage1Timer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      if (_stage1FlowIndex >= _stage1Round.sequence.length - 1) {
        setState(() {
          _stage1FlowRunning = false;
          _stage1ShowQuestion = true;
        });
        return;
      }
      setState(() => _stage1FlowIndex++);
      _scheduleStage1Next();
    });
  }

  void _answerStage1Question(int chosen) {
    final round = _stage1Round;
    if (round.answer != null) return;
    final isCorrect = chosen == round.correctCount;
    setState(() {
      round.answer = chosen;
      round.wasCorrect = isCorrect;
    });
    if (isCorrect) {
      SoundManager.playCorrect();
    } else {
      SoundManager.playGentleTap();
    }
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_stage1RoundIndex < _stage1Rounds.length - 1) {
        setState(() {
          _stage1RoundIndex++;
          _stage1FlowRunning = false;
          _stage1ShowQuestion = false;
          _stage1FlowIndex = 0;
        });
      } else {
        _goToOldFlow();
      }
    });
  }

  void _goToOldFlow() {
    _prepareStage2Rounds();
    setState(() => _oldFlowStarted = true);
  }

  void _prepareStage2Rounds() {
    final entries = _targetCounts.entries.toList()..shuffle(_random);

    _stage2Rounds = entries.map((entry) {
      final bag = <_ObjectItem>[];
      bag.addAll(List.filled(entry.value, _byName(entry.key)));

      final fillerPool = _objectPool.where((o) => o.name != entry.key).toList()..shuffle(_random);
      for (final item in fillerPool.take(_fillerObjectCount)) {
        final repeat = _random.nextBool() ? 3 : 5;
        bag.addAll(List.filled(repeat, item));
      }
      bag.shuffle(_random);

      final lines = <List<_ObjectItem>>[];
      for (int i = 0; i < bag.length; i += _itemsPerLine) {
        final end = min(i + _itemsPerLine, bag.length);
        final chunk = bag.sublist(i, end);
        if (chunk.length < _itemsPerLine && lines.isNotEmpty) {
          lines.last.addAll(chunk);
        } else {
          lines.add(chunk);
        }
      }

      return _Stage2Round(targetName: entry.key, correctCount: entry.value, lines: lines);
    }).toList();

    _stage2RoundIndex = 0;
    _showOldFlowIntro = true;
    _isRunning = false;
    _showQuestions = false;
    _pass = 0;
    _lineIndex = 0;
  }

  void _startOldFlowFromIntro() {
    setState(() => _showOldFlowIntro = false);
    _start();
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      _isRunning = true;
      _showQuestions = false;
      _pass = 0;
      _lineIndex = 0;
    });
    _timer = Timer.periodic(const Duration(milliseconds: _lineIntervalMs), (_) {
      if (!mounted) return;
      final lines = _oldRound.lines;
      if (_lineIndex >= lines.length - 1) {
        if (_pass >= _totalPasses - 1) {
          _timer?.cancel();
          setState(() {
            _isRunning = false;
            _showQuestions = true;
          });
          return;
        }
        setState(() {
          _pass++;
          _lineIndex = 0;
        });
      } else {
        setState(() => _lineIndex++);
      }
    });
  }

  List<int> _optionsFor(int correct) {
    final options = <int>{correct};
    while (options.length < 4) {
      final delta = (_random.nextInt(6) + 1) * (_random.nextBool() ? 1 : -1);
      final candidate = correct + delta;
      if (candidate > 0) options.add(candidate);
    }
    final list = options.toList()..shuffle(_random);
    return list;
  }

  void _answerOldQuestion(int chosen) {
    final round = _oldRound;
    if (round.answer != null) return;
    final isCorrect = chosen == round.correctCount;
    setState(() {
      round.answer = chosen;
      round.wasCorrect = isCorrect;
    });
    if (isCorrect) {
      SoundManager.playCorrect();
    } else {
      SoundManager.playGentleTap();
    }

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_stage2RoundIndex < _stage2Rounds.length - 1) {
        setState(() {
          _stage2RoundIndex++;
          _showOldFlowIntro = true;
          _isRunning = false;
          _showQuestions = false;
          _pass = 0;
          _lineIndex = 0;
        });
      } else {
        _finish();
      }
    });
  }

  void _finish() {
    _hasCompletedOnce = true;
    final stage1Correct = _stage1Rounds.where((r) => r.wasCorrect ?? false).length;
    final stage2Correct = _stage2Rounds.where((r) => r.wasCorrect ?? false).length;
    final total = _stage1Rounds.length + _stage2Rounds.length;
    final totalCorrect = stage1Correct + stage2Correct;
    final percent = (totalCorrect / total * 100).round();
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Nesne Akışı (Sayma)',
      result: '$totalCorrect/$total doğru · %$percent',
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
            Text('Doğru: $totalCorrect / $total (%$percent)',
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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _prepareSession());
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
      appBar: AppBar(title: const Text('📦 Nesne Akışı')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _buildBody(),
        ),
      ),
      ),
    );
  }

  Widget _buildBody() {
    if (!_oldFlowStarted) {
      if (_stage1ShowQuestion) {
        return KeyedSubtree(key: const ValueKey('new-question'), child: _buildStage1Question());
      }
      if (_stage1FlowRunning) {
        return KeyedSubtree(key: const ValueKey('new-flow'), child: _buildStage1Flow());
      }
      return KeyedSubtree(key: const ValueKey('new-intro'), child: _buildStage1Intro());
    }
    if (_showOldFlowIntro) {
      return KeyedSubtree(
        key: ValueKey('old-intro-$_stage2RoundIndex'),
        child: _buildOldFlowIntro(),
      );
    }
    return KeyedSubtree(
      key: ValueKey('old-flow-$_stage2RoundIndex'),
      child: _showQuestions ? _buildOldQuestionView() : _buildOldFlowView(),
    );
  }

  Widget _buildStage1Intro() {
    final round = _stage1Round;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Hedef: ${_stage1RoundIndex + 1}/${_stage1Rounds.length}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
          ),
        ),
        const Spacer(),
        Center(child: Text(round.target.emoji, style: const TextStyle(fontSize: 96))),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'TEK bir nesneye odaklan — ${round.target.name}! Akış boyunca kaç kez '
                  'göreceğini dikkatlice say.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600),
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
            onPressed: _startStage1Flow,
            icon: const Icon(Icons.play_arrow),
            label: const Text('BAŞLA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStage1Flow() {
    final round = _stage1Round;
    return Column(
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
                'Hedef ${_stage1RoundIndex + 1}/${_stage1Rounds.length} · ${_stage1FlowIndex + 1}/${round.sequence.length}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
              ),
            ),
            Row(
              children: [
                Text('${round.target.emoji} say', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10),
              ],
            ),
            child: SingleChildScrollView(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (int i = 0; i <= _stage1FlowIndex; i++)
                    TweenAnimationBuilder<double>(
                      key: ValueKey('s1-$_stage1RoundIndex-$i'),
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 220),
                      builder: (context, value, child) => Opacity(
                        opacity: value,
                        child: Transform.scale(scale: 0.8 + 0.2 * value, child: child),
                      ),
                      child: Text(round.sequence[i].emoji, style: const TextStyle(fontSize: 34)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStage1Question() {
    final round = _stage1Round;
    final options = _optionsFor(round.correctCount);
    final isLastRound = _stage1RoundIndex == _stage1Rounds.length - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isLastRound
              ? 'Son Soru (${_stage1RoundIndex + 1}/${_stage1Rounds.length})'
              : 'Soru ${_stage1RoundIndex + 1}/${_stage1Rounds.length}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 16),
        ),
        const SizedBox(height: 24),
        Center(child: Text(round.target.emoji, style: const TextStyle(fontSize: 52))),
        const SizedBox(height: 12),
        Text(
          '"${round.target.name}" nesnesini kaç kez gördün?',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 16),
        if (round.answer != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: (round.wasCorrect ?? false) ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              (round.wasCorrect ?? false)
                  ? '🎉 Aferin, çok dikkatlisin!'
                  : '📖 Tekrar dene, daha dikkatli sayalım!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: (round.wasCorrect ?? false) ? Colors.green.shade800 : Colors.orange.shade800,
              ),
            ),
          ),
        const SizedBox(height: 14),
        Expanded(
          child: GridView.builder(
            itemCount: options.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.6,
            ),
            itemBuilder: (context, index) {
              final value = options[index];
              final isSelected = round.answer == value;
              Color bg = Colors.white;
              Color textColor = Colors.black87;
              if (isSelected) {
                bg = (round.wasCorrect ?? false) ? Colors.green.shade500 : Colors.red.shade400;
                textColor = Colors.white;
              }
              return InkWell(
                onTap: () => _answerStage1Question(value),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: Text(
                    '$value',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: textColor),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOldFlowIntro() {
    final round = _oldRound;
    final emoji = _byName(round.targetName).emoji;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0D9488).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '2. Bölüm · Hedef: ${_stage2RoundIndex + 1}/${_stage2Rounds.length}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
          ),
        ),
        const Spacer(),
        Center(child: Text(emoji, style: const TextStyle(fontSize: 96))),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D9488).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.flag_rounded, color: Color(0xFF0D9488), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bu sefer nesneler satır satır akıp kaybolacak. TEK bir nesneyi '
                  'aklında tut — ${round.targetName}! Kaç kez göreceğini dikkatlice say.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF115E59), fontWeight: FontWeight.w600),
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
            onPressed: _startOldFlowFromIntro,
            icon: const Icon(Icons.play_arrow),
            label: const Text('BAŞLA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOldFlowView() {
    final round = _oldRound;
    final emoji = _byName(round.targetName).emoji;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _isRunning ? 'Tur: ${_pass + 1}/$_totalPasses' : 'Hazır',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
              ),
            ),
            const SizedBox(width: 10),
            Text('$emoji say', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
        const Spacer(),
        Container(
          width: double.infinity,
          height: 110,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: !_isRunning
                  ? const Text(
                      'BAŞLAT\'a bas',
                      key: ValueKey('idle'),
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey),
                    )
                  : SingleChildScrollView(
                      key: ValueKey('$_pass-$_lineIndex'),
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: round.lines[_lineIndex].map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(item.emoji, style: const TextStyle(fontSize: 44)),
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isRunning ? null : _start,
            icon: const Icon(Icons.play_arrow),
            label: const Text('BAŞLAT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOldQuestionView() {
    final round = _oldRound;
    final options = _optionsFor(round.correctCount);
    final emoji = _byName(round.targetName).emoji;
    final isLastRound = _stage2RoundIndex == _stage2Rounds.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isLastRound
              ? 'Son Soru (${_stage2RoundIndex + 1}/${_stage2Rounds.length})'
              : 'Soru ${_stage2RoundIndex + 1}/${_stage2Rounds.length}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D9488), fontSize: 16),
        ),
        const SizedBox(height: 24),
        Center(child: Text(emoji, style: const TextStyle(fontSize: 52))),
        const SizedBox(height: 12),
        Text(
          '"${round.targetName}" nesnesi kaç kez gösterildi?',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 16),
        if (round.answer != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: (round.wasCorrect ?? false) ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              (round.wasCorrect ?? false)
                  ? '🎉 Aferin, çok dikkatlisin!'
                  : '📖 Tekrar dene, daha dikkatli sayalım!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: (round.wasCorrect ?? false) ? Colors.green.shade800 : Colors.orange.shade800,
              ),
            ),
          ),
        const SizedBox(height: 14),
        Expanded(
          child: GridView.builder(
            itemCount: options.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.6,
            ),
            itemBuilder: (context, index) {
              final value = options[index];
              final isSelected = round.answer == value;
              Color bg = Colors.white;
              Color textColor = Colors.black87;
              if (isSelected) {
                bg = (round.wasCorrect ?? false) ? Colors.green.shade500 : Colors.red.shade400;
                textColor = Colors.white;
              }
              return InkWell(
                onTap: () => _answerOldQuestion(value),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: Text(
                    '$value',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: textColor),
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

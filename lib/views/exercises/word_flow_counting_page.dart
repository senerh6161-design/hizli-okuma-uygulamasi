import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';

/// 1. Bölüm'ün her turu: kendi hedef/çeldirici kelimesi, kendi akışı ve
/// kendi sorusu olan bağımsız bir tur. 1. Bölüm bunlardan 3 tanesini
/// sırayla (duyuru → akış → soru) çalıştırır.
class _WordRound {
  final String target;
  final String decoy;
  final List<String> sequence;
  final int correctCount;
  int? answer;
  bool? wasCorrect;
  _WordRound({
    required this.target,
    required this.decoy,
    required this.sequence,
    required this.correctCount,
  });
}

/// 2. Bölüm'ün her turu: 1. Bölüm ile AYNI mantık (tek hedef duyur → akış →
/// soru), sadece akışın GÖRSEL TARZI farklı — kelimeler birikmiyor, satır
/// satır akıp kayboluyor.
class _WordFlowRound {
  final String targetWord;
  final int correctCount;
  final List<List<String>> lines;
  int? answer;
  bool? wasCorrect;
  _WordFlowRound({
    required this.targetWord,
    required this.correctCount,
    required this.lines,
  });
}

/// Öğretmen dokümanındaki "Etkinlik 8'in kelime versiyonu": satır üstünde
/// akan kelimeler, bazı kelimeler etkinlik sonuna kadar belirli bir sayıda
/// tekrarlanır. Üç bölümden oluşur: 1. Bölüm'de kelimeler tek tek birikerek
/// akar, 2. Bölüm'de satır satır akıp kaybolur — her ikisi de 3'er tur, her
/// turda tek bir hedef kelime önceden duyurulup sonunda "kaç kez gördün?"
/// diye sorulur. 3. Bölüm'de ise soru yok, sadece takip var: kelimeler
/// satırın bir ucundan diğerine kayar, her kelimede yön değişir (soldan
/// sağa, sonra sağdan sola...), öğrenci başını oynatmadan gözleriyle takip
/// eder.
class WordFlowCountingPage extends StatefulWidget {
  const WordFlowCountingPage({super.key});

  @override
  State<WordFlowCountingPage> createState() => _WordFlowCountingPageState();
}

class _WordFlowCountingPageState extends State<WordFlowCountingPage> {
  // Hocanın verdiği kelime havuzu (23x7 tablo).
  static const List<String> _wordPool = [
    'Anlam', 'Kavram', 'Hikaye', 'Şiir', 'Efsane', 'Deyim', 'Betimleme',
    'Tema', 'Konu', 'Fiil', 'Çarpma', 'Oran', 'Olay', 'Biyografi',
    'Doğru', 'Bölme', 'Çember', 'Kesir', 'Paralel', 'Hacim', 'Molekül',
    'Üçgen', 'Kare', 'Atom', 'Karışım', 'Enerji', 'Kuvvet', 'Çözünürlük',
    'Elektrik', 'Devre', 'Çekim', 'İskelet', 'Kalıtım', 'Haber', 'Solunum',
    'Denge', 'Kültür', 'Devlet', 'Anayasa', 'İklim', 'Barış', 'Kimyasal',
    'Savaş', 'Türkiye', 'Kıta', 'Deniz', 'Kuzey', 'Şehir', 'Cumhuriyet',
    'Yaklaşım', 'Mera', 'Akarsu', 'Nehir', 'Kasaba', 'Tarih', 'Coğrafya',
    'Temsilci', 'Kapsam', 'Üslup', 'Eleştiri', 'Tezat', 'Abartı', 'Yarımada',
    'Özgün', 'Termal', 'Bağlam', 'İfade', 'Anlatım', 'Duygu', 'Yakınçağ',
    'Derinlik', 'Gözlem', 'İzlenim', 'Tartışma', 'İletişim', 'Söylem', 'Bağımsızlık',
    'Özdeyiş', 'Boylam', 'Önyargı', 'Mantık', 'Sonuç', 'Çelişki', 'Vatandaşlık',
    'Süreç', 'Aşama', 'Delta', 'Sezgi', 'Miras', 'Nitelik', 'Kurgulamak',
    'Nicelik', 'Belirgin', 'Direnç', 'Harita', 'Reklam', 'Sosyal', 'Farkındalık',
    'Tarım', 'Sulama', 'Toprak', 'Sağlık', 'Egzersiz', 'Sonuç', 'Karşılaştırma',
    'Medya', 'Gelişme', 'Deney', 'Öğrenci', 'Meclis', 'Kütle', 'Sorgulamak',
    'Spor', 'Müzik', 'Trafik', 'Protein', 'Kırsal', 'Mineral', 'Vurgulamak',
    'Giriş', 'Tekil', 'Soyut', 'Eklem', 'Tiyatro', 'Somut', 'Karakter',
    'İlim', 'Sinir', 'Sinema', 'Damar', 'Hasat', 'Atasözü', 'Sürükleyici',
    'Sanat', 'Tekrar', 'Tümleç', 'Zarf', 'Cümle', 'Kültür', 'Fotosentez',
    'Heyelan', 'Zamir', 'Görenek', 'Krater', 'Levha', 'Bütçe', 'Adaptasyon',
    'Vitamin', 'Çoğul', 'Sıfat', 'Uydu', 'Galaksi', 'Gelenek', 'Medeniyet',
    'Özne', 'Yıldız', 'Yankı', 'Frekans', 'Yansıma', 'Yüklem', 'Okyanus',
  ];

  // 1. Bölüm'de kullanılan hedef/çeldirici kelime çiftleri — HER OTURUMDA
  // değişsin diye birden fazla tanımlı. Aynı 3-4 harfli önekle başlayan,
  // biraz dikkatsiz okunduğunda birbirine karışabilecek gerçek kelime
  // çiftleri seçildi (ör. Tarih/Tarım, Deniz/Denge).
  static const List<List<String>> _confusablePairNames = [
    ['Tarih', 'Tarım'],
    ['Deniz', 'Denge'],
    ['Devre', 'Devlet'],
    ['Sinir', 'Sinema'],
    ['Zarf', 'Zamir'],
  ];

  // 2. Bölüm: hocanın örnekteki tekrar sayıları: "Galaksi 20, Öğrenci 12,
  // şiir 15, spor 9, yıldız 8, Türkiye 18..." + örnek olarak verilen
  // "Hikaye" 15.
  static const Map<String, int> _targetCounts = {
    'Hikaye': 15,
    'Galaksi': 20,
    'Öğrenci': 12,
    'Şiir': 15,
    'Spor': 9,
    'Yıldız': 8,
    'Türkiye': 18,
  };

  static const int _totalPasses = 3;
  static const int _lineIntervalMs = 1500;
  static const int _wordsPerLine = 7;
  static const int _fillerWordCount = 22;

  final Random _random = Random();
  bool _hasCompletedOnce = false;

  // 1. BÖLÜM (ÖNCE çalışır): 3 AYRI tur — her turda tek bir hedef kelime
  // önceden duyurulur, kelimeler TEK TEK yan yana birikerek akar, aralarına
  // kasıtlı bir çeldirici karışır, sonunda "kaç kez gördün?" diye o turun
  // sorusu sorulur.
  late List<_WordRound> _stage1Rounds; // her zaman 3 eleman
  int _stage1RoundIndex = 0;
  bool _stage1FlowRunning = false;
  bool _stage1ShowQuestion = false;
  int _stage1FlowIndex = 0;
  Timer? _stage1Timer;

  _WordRound get _stage1Round => _stage1Rounds[_stage1RoundIndex];

  // 2. BÖLÜM (1. Bölüm bitince başlar): AYNI mantık (tek hedef duyur → akış
  // → soru) 3 tur, ama akış görsel olarak satır satır akıp kayboluyor
  // (1. Bölüm'deki gibi birikmiyor).
  bool _oldFlowStarted = false;
  bool _showOldFlowIntro = false;
  late List<_WordFlowRound> _stage2Rounds; // her zaman 3 eleman
  int _stage2RoundIndex = 0;
  bool _isRunning = false;
  bool _showQuestions = false;
  int _pass = 0;
  int _lineIndex = 0;
  Timer? _timer;

  _WordFlowRound get _oldRound => _stage2Rounds[_stage2RoundIndex];

  // 3. BÖLÜM (2. Bölüm bitince başlar): soru yok, sadece takip. Kelimeler
  // tek tek satırın bir ucundan diğerine kayar, yön her kelimede değişir.
  static const int _slideWordCount = 14;
  static const int _slideDurationMs = 1800;
  bool _slideStageStarted = false;
  bool _showSlideIntro = false;
  late List<String> _slideWords;
  int _slideIndex = 0;

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

  void _prepareSession() {
    _prepareStage1Rounds();
  }

  void _prepareStage1Rounds() {
    final pairPool = _confusablePairNames.toList()..shuffle(_random);
    final chosenPairs = pairPool.take(3).toList();

    _stage1Rounds = chosenPairs.map((pairNames) {
      final flipped = _random.nextBool();
      final target = flipped ? pairNames[1] : pairNames[0];
      final decoy = flipped ? pairNames[0] : pairNames[1];

      // Nesne Akışı'nda da aynı sorun vardı: az sayıda kelime dizinin
      // yarısını boş bırakıyordu. Sayıyı büyüttük ki birikince sayfa
      // gerçekten dolsun (hedef/çeldirici oranı görünen satır sayısına
      // yakın tutuluyor ki satır başına ~1 tane düşsün).
      final totalLength = 70 + _random.nextInt(21); // 70-90 kelime
      final targetCount = 10 + _random.nextInt(4); // 10-13 kez
      final decoyCount = 8 + _random.nextInt(3); // 8-10 kez

      final fillerPool = _wordPool.where((w) => w != target && w != decoy).toList()
        ..shuffle(_random);

      final bag = <String>[
        ...List.filled(targetCount, target),
        ...List.filled(decoyCount, decoy),
      ];
      final remaining = totalLength - bag.length;
      for (int i = 0; i < remaining; i++) {
        bag.add(fillerPool[i % fillerPool.length]);
      }

      return _WordRound(
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
    _slideStageStarted = false;
    _showSlideIntro = false;
    _slideIndex = 0;
  }

  // Düz bir shuffle, hedef/çeldirici gibi yüksek sayılı kelimelerin ya
  // dizinin BAŞINDA kümelenmesine ya da (tam eşit aralık verilirse) her
  // satırda robotik biçimde tam 1 tane çıkmasına yol açıyordu. Bu yüzden
  // her kelimeyi kendi sayısına göre dizinin TAMAMINA, rastgele bir
  // sapmayla (jitter) yerleştiriyoruz — hem baştan sona dengeli dağılır
  // hem de doğal/karışık görünür (bazı satırlarda 0, bazılarında 2 olabilir).
  List<String> _spreadOut(List<String> bag) {
    final n = bag.length;
    final Map<String, List<String>> groups = {};
    for (final item in bag) {
      groups.putIfAbsent(item, () => []).add(item);
    }
    final result = List<String?>.filled(n, null);

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
    final chosen = entries.take(3).toList();

    _stage2Rounds = chosen.map((entry) {
      final bag = <String>[];
      bag.addAll(List.filled(entry.value, entry.key));

      final fillerPool = _wordPool.where((w) => w != entry.key).toList()..shuffle(_random);
      for (final word in fillerPool.take(_fillerWordCount)) {
        final repeat = _random.nextBool() ? 3 : 5;
        bag.addAll(List.filled(repeat, word));
      }
      bag.shuffle(_random);

      final lines = <List<String>>[];
      for (int i = 0; i < bag.length; i += _wordsPerLine) {
        final end = min(i + _wordsPerLine, bag.length);
        final chunk = bag.sublist(i, end);
        if (chunk.length < _wordsPerLine && lines.isNotEmpty) {
          lines.last.addAll(chunk);
        } else {
          lines.add(chunk);
        }
      }

      return _WordFlowRound(targetWord: entry.key, correctCount: entry.value, lines: lines);
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
        _goToSlideStage();
      }
    });
  }

  void _goToSlideStage() {
    final pool = List<String>.from(_wordPool)..shuffle(_random);
    setState(() {
      _slideWords = pool.take(_slideWordCount).toList();
      _slideIndex = 0;
      _slideStageStarted = true;
      _showSlideIntro = true;
    });
  }

  void _startSlideFromIntro() {
    setState(() => _showSlideIntro = false);
  }

  void _advanceSlideWord() {
    if (!mounted) return;
    if (_slideIndex >= _slideWords.length - 1) {
      _finish();
      return;
    }
    setState(() => _slideIndex++);
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
      type: 'Kelime Akışı (Sayma)',
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
      appBar: AppBar(title: const Text('🌊 Kelime Akışı')),
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
    if (_slideStageStarted) {
      if (_showSlideIntro) {
        return KeyedSubtree(key: const ValueKey('slide-intro'), child: _buildSlideIntro());
      }
      return KeyedSubtree(key: ValueKey('slide-flow-$_slideIndex'), child: _buildSlideFlow());
    }
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
        Center(
          child: Text(
            round.target,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
          ),
        ),
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
                  'TEK bir kelimeye odaklan — "${round.target}"! Akış boyunca kaç kez '
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
            Text('"${round.target}" say', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
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
                spacing: 14,
                runSpacing: 12,
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
                      child: Text(
                        round.sequence[i],
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
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
        Text(
          '"${round.target}" kelimesi kaç kez tekrarlandı?',
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
        Center(
          child: Text(
            round.targetWord,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
          ),
        ),
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
                  'Bu sefer kelimeler satır satır akıp kaybolacak. TEK bir kelimeyi '
                  'aklında tut — "${round.targetWord}"! Kaç kez göreceğini dikkatlice say.',
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
            Text('"${round.targetWord}" say', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 30),
        Expanded(
          child: Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.3, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Wrap(
                  key: ValueKey('$_pass-$_lineIndex-$_isRunning'),
                  alignment: WrapAlignment.center,
                  spacing: 14,
                  runSpacing: 10,
                  children: _isRunning
                      ? round.lines[_lineIndex]
                          .map((w) => Text(
                                w,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ))
                          .toList()
                      : [
                          const Text(
                            'BAŞLAT\'a bas',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
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
        Text(
          '"${round.targetWord}" kelimesi kaç kez tekrarlandı?',
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

  Widget _buildSlideIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE11D48).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            '3. Bölüm · Kelime Takibi',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE11D48)),
          ),
        ),
        const Spacer(),
        const Center(child: Text('↔️', style: TextStyle(fontSize: 72))),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE11D48).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(Icons.remove_red_eye_rounded, color: Color(0xFFE11D48), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bu sefer soru yok! Kelimeler satırın bir ucundan diğerine kayacak, '
                  'her kelimede yön değişecek. Başını oynatmadan, sadece gözlerinle takip et.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9F1239), fontWeight: FontWeight.w600),
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
            onPressed: _startSlideFromIntro,
            icon: const Icon(Icons.play_arrow),
            label: const Text('BAŞLA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlideFlow() {
    final word = _slideWords[_slideIndex];
    // Yön her kelimede değişir: çift index soldan sağa, tek index sağdan
    // sola kayar — gözler hem bir yöne hem diğerine takip alıştırması yapar.
    final leftToRight = _slideIndex.isEven;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE11D48).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '3. Bölüm · Kelime ${_slideIndex + 1}/${_slideWords.length}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE11D48)),
              ),
            ),
            Icon(
              leftToRight ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
              color: const Color(0xFFE11D48),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10),
              ],
            ),
            child: TweenAnimationBuilder<double>(
              key: ValueKey(_slideIndex),
              tween: Tween(begin: leftToRight ? 0.0 : 1.0, end: leftToRight ? 1.0 : 0.0),
              duration: const Duration(milliseconds: _slideDurationMs),
              curve: Curves.linear,
              onEnd: _advanceSlideWord,
              builder: (context, t, child) {
                return Align(
                  alignment: Alignment(-1 + 2 * t, 0),
                  child: Text(
                    word,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFE11D48)),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

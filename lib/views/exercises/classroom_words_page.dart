import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';

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

/// Klasör 2'nin sekizinci etkinliği: "Sınıf Eşyaları · Kelime". Eskiden
/// Etkinlik 3 ile birebir aynı Satır Akışı + quiz mekaniğini kullanıyordu —
/// bu yüzden Klasör 1'deki dokuzuncu etkinlik "Kelime Akışı"nın yapısına
/// (3 bölüm) taşındı, ama FARKLI kelimeler, farklı hedef/çeldirici
/// çiftleri, farklı tekrar sayıları ve farklı (daha hızlı) zamanlamayla:
/// 1. Bölüm'de kelimeler tek tek birikerek akar, 2. Bölüm'de satır satır
/// akıp kaybolur — her ikisi de 3'er tur, her turda tek bir hedef kelime
/// önceden duyurulup sonunda "kaç kez gördün?" diye sorulur. 3. Bölüm'de
/// ise soru yok, sadece takip var: kelimeler satırın bir ucundan diğerine
/// kayar, her kelimede yön değişir.
class ClassroomWordsPage extends StatefulWidget {
  const ClassroomWordsPage({super.key});

  @override
  State<ClassroomWordsPage> createState() => _ClassroomWordsPageState();
}

class _ClassroomWordsPageState extends State<ClassroomWordsPage> {
  // Hocanın Sınıf Eşyaları kelime havuzu — Klasör 1 · Etkinlik 9'dakinden
  // tamamen farklı bir kelime seti.
  static const List<String> _wordPool = [
    'Bakteri',
    'Hijyen',
    'Güzel',
    'Zanaat',
    'Cenk',
    'Zafer',
    'Ekosistem',
    'Samimi',
    'Zeybek',
    'Hünkâr',
    'Türkmen',
    'Kalpak',
    'Sindirim',
    'Dingin',
    'Hançer',
    'Meslek',
    'Kervan',
    'Güven',
    'Metabolizma',
    'Ahilik',
    'Sancak',
    'Şefkat',
    'Değer',
    'Bağlılık',
    'Bağışıklık',
    'Ferah',
    'Yemin',
    'Tüccar',
    'Töre',
    'Aşiret',
    'Hastalık',
    'Kaftan',
    'Yiğit',
    'Korkut',
    'Ödev',
    'Mikroskop',
    'Destan',
    'Barış',
    'Hüzün',
    'Sıcaklık',
    'Element',
    'Dostluk',
    'Proje',
    'Saat',
    'Konu',
    'Çizim',
    'Test',
    'Malazgirt',
    'Sınav',
    'Harita',
    'Fırça',
    'Desen',
    'Nota',
    'Melodi',
    'Mutluluk',
    'Takvim',
    'Çeviri',
    'Odak',
    'Uzantı',
    'Ulusal',
    'Varsayım',
    'Organizma',
    'Tuval',
    'Öngörü',
    'Gelgit',
    'Yükümlü',
    'Özenti',
    'Yavan',
    'Nezaket',
    'Metot',
    'Kalıcı',
    'Özdeş',
    'Maksat',
    'Yargı',
    'Sağduyu',
    'Yapıtaşı',
    'Kuşku',
    'İmge',
    'Dipnot',
    'İrade',
    'Lirik',
    'Alternatif',
    'Yapaylık',
    'Drama',
    'Boyut',
    'Deneyim',
    'Coşkun',
    'Kaynak',
    'Perspektif',
    'Yenilik',
    'Kanaat',
    'Mahlas',
    'Ayrıntı',
    'Kaygı',
    'Anlatım',
    'Kompozisyon',
    'Yinele',
    'Kalıp',
    'Özlü',
    'Sanal',
    'Kitle',
    'Klişe',
    'Enstrüman',
    'Trajedi',
    'Rastgele',
    'Çalışma',
    'Simge',
    'Sentez',
    'Biçim',
    'Jimnastik',
    'Otorite',
    'Sulh',
    'Taslak',
    'Analiz',
    'Yalın',
    'Antrenman',
    'Özveri',
    'Garp',
    'İrdele',
    'Ocak',
    'Özerk',
    'Peygamber',
    'Koşul',
    'Çehre',
    'Alaca',
    'Sığ',
    'Hicret',
    'Üstünkörü',
    'Katmerli',
    'İvedi',
    'Hoşgörü',
    'Çelişki',
    'Bulgu',
    'İleti',
    'Terennüm',
    'İzlenim',
    'Örtük',
    'Seçkin',
    'Çevik',
    'İkilem',
    'Refleks',
    'Tökezlemek',
    'İrkilmek',
    'Faktör',
    'Arşiv',
    'Karşıt',
    'Motif',
    'Özlem',
    'Örselenmek',
  ];

  // 1. Bölüm'de kullanılan hedef/çeldirici kelime çiftleri — HER OTURUMDA
  // değişsin diye birden fazla tanımlı. Klasör 1 · Etkinlik 9'dakinden
  // tamamen farklı çiftler.
  static const List<List<String>> _confusablePairNames = [
    ['Sınav', 'Sınıf'],
    ['Kalem', 'Kalıp'],
    ['Ödev', 'Ödül'],
    ['Kitap', 'Kitle'],
    ['Defter', 'Destan'],
  ];

  // 2. Bölüm: farklı hedef kelimeler ve farklı tekrar sayıları.
  static const Map<String, int> _targetCounts = {
    'Sevgi': 16,
    'Huzur': 11,
    'Kardeş': 14,
    'Umut': 19,
    'Neşe': 8,
    'Gülümse': 22,
    'Tatlı': 13,
  };

  static const int _totalPasses = 3;
  static const int _wordsPerLine = 7;
  static const int _fillerWordCount = 22;

  // Öğrenci hızını kendi seçebilsin diye 1. ve 2. Bölüm'ün akış hızı
  // sabit değil, seçilebilir bir aralıkta.
  static const List<String> _speedLabels = ['Yavaş', 'Orta', 'Hızlı'];
  static const List<int> _stage1RevealMsBySpeed = [550, 380, 230];
  static const List<int> _lineIntervalMsBySpeed = [1700, 1200, 800];
  int _speedLevel = 1;

  final Random _random = Random();
  bool _hasCompletedOnce = false;
  bool _isPaused = false;

  // ANTREMAN (en başta çalışır, ısınma turu): Klasör 1 · Kelime Akışı'ndaki
  // ile AYNI mekanik — kelimeler en üstten, soldan sağa doğru tek tek
  // birikerek gelir, TEK SAYFA, döngü yok. Süresiz/puansız, öğrenci hazır
  // olunca DEVAM ET'e basar.
  static const Color _warmupColor = Color(0xFF0284C7);
  static const int _warmupWordsPerPage = 30;
  bool _warmupDone = false;
  bool _warmupRunning = false;
  late List<String> _warmupWords;
  int _warmupWordIndex = 0;
  Timer? _warmupTimer;
  int _warmupElapsedSeconds = 0;
  Timer? _warmupElapsedTimer;

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
  int _stage1ElapsedSec = 0;
  Timer? _stage1ElapsedTimer;

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
  int _stage2ElapsedSec = 0;
  Timer? _stage2ElapsedTimer;

  _WordFlowRound get _oldRound => _stage2Rounds[_stage2RoundIndex];

  // 3. BÖLÜM (2. Bölüm bitince başlar): soru yok, sadece takip. Kelimeler
  // tek tek satırın bir ucundan diğerine kayar, yön her kelimede değişir.
  static const int _slideWordCount = 14;
  static const int _slideDurationMs = 1400;
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
    _stage1ElapsedTimer?.cancel();
    _stage2ElapsedTimer?.cancel();
    _warmupTimer?.cancel();
    _warmupElapsedTimer?.cancel();
    super.dispose();
  }

  void _prepareSession() {
    _prepareWarmup();
    _prepareStage1Rounds();
  }

  void _prepareWarmup() {
    final pool = List<String>.from(_wordPool)..shuffle(_random);
    _warmupWords = pool.take(_warmupWordsPerPage).toList();
    _warmupWordIndex = 0;
    _warmupRunning = false;
    _warmupDone = false;
  }

  void _startWarmup() {
    _warmupTimer?.cancel();
    _warmupElapsedTimer?.cancel();
    setState(() {
      _warmupRunning = true;
      _warmupWordIndex = 1; // ilk kelime hemen görünsün
      _warmupElapsedSeconds = 0;
    });
    _scheduleWarmupWord();
    _warmupElapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _warmupElapsedSeconds++);
    });
  }

  // Öğrenci baştan izlemek isterse AYNI sayfayı sıfırdan tekrar birikmeye
  // başlatır — "DEVAM ET"e basmadan istediği kadar tekrar izleyebilir.
  void _replayWarmup() {
    _startWarmup();
  }

  void _finishWarmup() {
    _warmupTimer?.cancel();
    _warmupElapsedTimer?.cancel();
    setState(() {
      _warmupRunning = false;
      _warmupDone = true;
    });
  }

  // Tek sayfalık antreman — tüm kelimeler bir kez birikip biter, döngü
  // yok (gerçek akış zaten 1. Bölüm'de baştan sona gösterilecek).
  void _scheduleWarmupWord() {
    if (_warmupWordIndex >= _warmupWords.length) return;
    _warmupTimer = Timer(
      Duration(milliseconds: _stage1RevealMsBySpeed[_speedLevel]),
      () {
        if (!mounted || !_warmupRunning) return;
        setState(() => _warmupWordIndex++);
        _scheduleWarmupWord();
      },
    );
  }

  void _prepareStage1Rounds() {
    final pairPool = _confusablePairNames.toList()..shuffle(_random);
    final chosenPairs = pairPool.take(3).toList();

    _stage1Rounds = chosenPairs.map((pairNames) {
      final flipped = _random.nextBool();
      final target = flipped ? pairNames[1] : pairNames[0];
      final decoy = flipped ? pairNames[0] : pairNames[1];

      final totalLength = 70 + _random.nextInt(21); // 70-90 kelime
      final targetCount = 10 + _random.nextInt(4); // 10-13 kez
      final decoyCount = 8 + _random.nextInt(3); // 8-10 kez

      final fillerPool =
          _wordPool.where((w) => w != target && w != decoy).toList()
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

    final emptySlots = [
      for (int i = 0; i < n; i++)
        if (result[i] == null) i,
    ]..shuffle(_random);
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
    _stage1ElapsedTimer?.cancel();
    setState(() {
      _stage1FlowRunning = true;
      _stage1FlowIndex = 0;
      _stage1ElapsedSec = 0;
    });
    _stage1ElapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _stage1ElapsedSec++);
    });
    _scheduleStage1Next();
  }

  void _scheduleStage1Next() {
    _stage1Timer = Timer(
      Duration(milliseconds: _stage1RevealMsBySpeed[_speedLevel]),
      () {
        if (!mounted) return;
        if (_stage1FlowIndex >= _stage1Round.sequence.length - 1) {
          _stage1ElapsedTimer?.cancel();
          setState(() {
            _stage1FlowRunning = false;
            _stage1ShowQuestion = true;
          });
          return;
        }
        setState(() => _stage1FlowIndex++);
        _scheduleStage1Next();
      },
    );
  }

  void _pauseGame() {
    _warmupTimer?.cancel();
    _warmupElapsedTimer?.cancel();
    _stage1Timer?.cancel();
    _stage1ElapsedTimer?.cancel();
    _timer?.cancel();
    _stage2ElapsedTimer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resumeGame() {
    setState(() => _isPaused = false);
    if (_warmupRunning) {
      _scheduleWarmupWord();
      _warmupElapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _warmupElapsedSeconds++);
      });
    } else if (_stage1FlowRunning) {
      _stage1ElapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _stage1ElapsedSec++);
      });
      _scheduleStage1Next();
    } else if (_isRunning) {
      _stage2ElapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _stage2ElapsedSec++);
      });
      _timer = Timer.periodic(
        Duration(milliseconds: _lineIntervalMsBySpeed[_speedLevel]),
        (_) {
          if (!mounted) return;
          final lines = _oldRound.lines;
          if (_lineIndex >= lines.length - 1) {
            if (_pass >= _totalPasses - 1) {
              _timer?.cancel();
              _stage2ElapsedTimer?.cancel();
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
        },
      );
    }
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

      final fillerPool = _wordPool.where((w) => w != entry.key).toList()
        ..shuffle(_random);
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

      return _WordFlowRound(
        targetWord: entry.key,
        correctCount: entry.value,
        lines: lines,
      );
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
    _stage2ElapsedTimer?.cancel();
    setState(() {
      _isRunning = true;
      _showQuestions = false;
      _pass = 0;
      _lineIndex = 0;
      _stage2ElapsedSec = 0;
    });
    _stage2ElapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _stage2ElapsedSec++);
    });
    _timer = Timer.periodic(
      Duration(milliseconds: _lineIntervalMsBySpeed[_speedLevel]),
      (_) {
        if (!mounted) return;
        final lines = _oldRound.lines;
        if (_lineIndex >= lines.length - 1) {
          if (_pass >= _totalPasses - 1) {
            _timer?.cancel();
            _stage2ElapsedTimer?.cancel();
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
      },
    );
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
    final stage1Correct = _stage1Rounds
        .where((r) => r.wasCorrect ?? false)
        .length;
    final stage2Correct = _stage2Rounds
        .where((r) => r.wasCorrect ?? false)
        .length;
    final total = _stage1Rounds.length + _stage2Rounds.length;
    final totalCorrect = stage1Correct + stage2Correct;
    final percent = (totalCorrect / total * 100).round();
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Sınıf Eşyaları · Kelime',
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
            Text(
              'Doğru: $totalCorrect / $total (%$percent)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
              setState(() => _prepareSession());
            },
            child: const Text('Yeniden Başlat'),
          ),
        ],
      ),
    );
  }

  Widget _elapsedBadge(int seconds) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Text(
        '⏱ $seconds sn',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.amber.shade800,
        ),
      ),
    );
  }

  Widget _speedChipRow(Color color) {
    return Row(
      children: [
        Text(
          'Hız:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 8),
        Wrap(
          spacing: 6,
          children: [
            for (int i = 0; i < _speedLabels.length; i++)
              ChoiceChip(
                label: Text(_speedLabels[i]),
                selected: _speedLevel == i,
                onSelected: (_) => setState(() => _speedLevel = i),
                selectedColor: color,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _speedLevel == i ? Colors.white : Colors.black87,
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompletionPopScope(
      isCompleted: () => _hasCompletedOnce,
      child: Scaffold(
        appBar: AppBar(title: const Text('📝 Sınıf Eşyaları · Kelime')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildBody(),
              ),
              if (_isPaused)
                buildPauseOverlay(
                  color: const Color(0xFF0284C7),
                  onResume: _resumeGame,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!_warmupDone) {
      if (_warmupRunning) {
        return KeyedSubtree(
          key: const ValueKey('warmup-flow'),
          child: _buildWarmupFlow(),
        );
      }
      return KeyedSubtree(
        key: const ValueKey('warmup-intro'),
        child: _buildWarmupIntro(),
      );
    }
    if (_slideStageStarted) {
      if (_showSlideIntro) {
        return KeyedSubtree(
          key: const ValueKey('slide-intro'),
          child: _buildSlideIntro(),
        );
      }
      return KeyedSubtree(
        key: ValueKey('slide-flow-$_slideIndex'),
        child: _buildSlideFlow(),
      );
    }
    if (!_oldFlowStarted) {
      if (_stage1ShowQuestion) {
        return KeyedSubtree(
          key: const ValueKey('new-question'),
          child: _buildStage1Question(),
        );
      }
      if (_stage1FlowRunning) {
        return KeyedSubtree(
          key: const ValueKey('new-flow'),
          child: _buildStage1Flow(),
        );
      }
      return KeyedSubtree(
        key: const ValueKey('new-intro'),
        child: _buildStage1Intro(),
      );
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

  Widget _buildWarmupIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _warmupColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Antreman · Odaklanma',
            style: TextStyle(fontWeight: FontWeight.bold, color: _warmupColor),
          ),
        ),
        const Spacer(),
        const Center(child: Text('📝', style: TextStyle(fontSize: 96))),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _warmupColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: _warmupColor, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Önce gözümüzü ısındıracağız! Kelimeler kutunun en '
                  'üstünden, soldan sağa doğru tek tek birikerek gelecek — '
                  'biz de her birini birlikte takip edeceğiz. Hazır '
                  'olduğunda sıra sende, BAŞLA\'ya basalım!',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF075985),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _speedChipRow(_warmupColor),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _startWarmup,
            icon: const Icon(Icons.play_arrow),
            label: const Text(
              'BAŞLA',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _warmupColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWarmupFlow() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _warmupColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Antreman · Odaklanma',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _warmupColor,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '⏱ $_warmupElapsedSeconds sn',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                      fontSize: 12,
                    ),
                  ),
                ),
                buildPauseButton(color: _warmupColor, onPressed: _pauseGame),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        _speedChipRow(_warmupColor),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                ),
              ],
            ),
            // Klasör 1 · Kelime Akışı'ndaki gibi: kelimeler en üstten,
            // soldan sağa doğru tek tek birikerek geliyor, kutu/kayma yok.
            child: Align(
              alignment: Alignment.topLeft,
              child: SingleChildScrollView(
                child: Wrap(
                  alignment: WrapAlignment.start,
                  spacing: 14,
                  runSpacing: 12,
                  children: [
                    for (int i = 0; i < _warmupWordIndex; i++)
                      TweenAnimationBuilder<double>(
                        key: ValueKey('warmup-word-$i'),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 220),
                        builder: (context, value, child) => Opacity(
                          opacity: value,
                          child: Transform.scale(
                            scale: 0.8 + 0.2 * value,
                            child: child,
                          ),
                        ),
                        child: Text(
                          _warmupWords[i],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _replayWarmup,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text(
                    'TEKRAR İZLE',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _warmupColor,
                    side: const BorderSide(color: _warmupColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _finishWarmup,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text(
                    'DEVAM ET',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _warmupColor,
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
      ],
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
            color: const Color(0xFF0284C7).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '1. Bölüm · Hedef: ${_stage1RoundIndex + 1}/${_stage1Rounds.length}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF0284C7),
            ),
          ),
        ),
        const Spacer(),
        Center(
          child: Text(
            round.target,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0284C7),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0284C7).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF0284C7),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '"${round.target}" kelimesine odaklanacağız! Akış boyunca '
                  'kaç kez göreceğimizi dikkatlice sayacağız.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF075985),
                    fontWeight: FontWeight.w600,
                  ),
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
            label: const Text(
              'BAŞLA',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
                color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Hedef ${_stage1RoundIndex + 1}/${_stage1Rounds.length} · ${_stage1FlowIndex + 1}/${round.sequence.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0284C7),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _elapsedBadge(_stage1ElapsedSec),
                buildPauseButton(
                  color: const Color(0xFF0284C7),
                  onPressed: _pauseGame,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '"${round.target}" sayıyoruz',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 8),
        _speedChipRow(const Color(0xFF0284C7)),
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
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  alignment: WrapAlignment.start,
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
                          child: Transform.scale(
                            scale: 0.8 + 0.2 * value,
                            child: child,
                          ),
                        ),
                        child: Text(
                          round.sequence[i],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                  ],
                ),
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0284C7),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '"${round.target}" kelimesi kaç kez tekrarlandı?',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),
        if (round.answer != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: (round.wasCorrect ?? false)
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              (round.wasCorrect ?? false)
                  ? '🎉 Aferin, çok dikkatlisin!'
                  : '📖 Tekrar dene, daha dikkatli sayalım!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: (round.wasCorrect ?? false)
                    ? Colors.green.shade800
                    : Colors.orange.shade800,
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
                bg = (round.wasCorrect ?? false)
                    ? Colors.green.shade500
                    : Colors.red.shade400;
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
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
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D9488),
            ),
          ),
        ),
        const Spacer(),
        Center(
          child: Text(
            round.targetWord,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D9488),
            ),
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
              const Icon(
                Icons.flag_rounded,
                color: Color(0xFF0D9488),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bu sefer kelimeler satır satır akıp kaybolacak. '
                  '"${round.targetWord}" kelimesini aklımızda tutacağız! '
                  'Kaç kez göreceğimizi dikkatlice sayacağız.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF115E59),
                    fontWeight: FontWeight.w600,
                  ),
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
            label: const Text(
              'BAŞLA',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D9488),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isRunning) _elapsedBadge(_stage2ElapsedSec),
                if (_isRunning)
                  buildPauseButton(
                    color: const Color(0xFF0D9488),
                    onPressed: _pauseGame,
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '"${round.targetWord}" sayıyoruz',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 8),
        _speedChipRow(const Color(0xFF0D9488)),
        const SizedBox(height: 14),
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
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                  ),
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
                child: Align(
                  key: ValueKey('$_pass-$_lineIndex-$_isRunning'),
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    alignment: WrapAlignment.start,
                    spacing: 14,
                    runSpacing: 10,
                    children: _isRunning
                        ? round.lines[_lineIndex]
                              .map(
                                (w) => Text(
                                  w,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              )
                              .toList()
                        : [
                            const Text(
                              'BAŞLAT\'a bas',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                  ),
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
            label: const Text(
              'BAŞLAT',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D9488),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '"${round.targetWord}" kelimesi kaç kez tekrarlandı?',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),
        if (round.answer != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: (round.wasCorrect ?? false)
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              (round.wasCorrect ?? false)
                  ? '🎉 Aferin, çok dikkatlisin!'
                  : '📖 Tekrar dene, daha dikkatli sayalım!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: (round.wasCorrect ?? false)
                    ? Colors.green.shade800
                    : Colors.orange.shade800,
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
                bg = (round.wasCorrect ?? false)
                    ? Colors.green.shade500
                    : Colors.red.shade400;
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFE11D48),
            ),
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
              Icon(
                Icons.remove_red_eye_rounded,
                color: Color(0xFFE11D48),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bu sefer soru yok! Kelimeler satırın bir ucundan diğerine kayacak, '
                  'her kelimede yön değişecek. Başımızı oynatmadan, sadece '
                  'gözlerimizle takip edeceğiz.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9F1239),
                    fontWeight: FontWeight.w600,
                  ),
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
            label: const Text(
              'BAŞLA',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE11D48),
                ),
              ),
            ),
            Icon(
              leftToRight
                  ? Icons.arrow_forward_rounded
                  : Icons.arrow_back_rounded,
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
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                ),
              ],
            ),
            child: TweenAnimationBuilder<double>(
              key: ValueKey(_slideIndex),
              tween: Tween(
                begin: leftToRight ? 0.0 : 1.0,
                end: leftToRight ? 1.0 : 0.0,
              ),
              duration: const Duration(milliseconds: _slideDurationMs),
              curve: Curves.linear,
              onEnd: _advanceSlideWord,
              builder: (context, t, child) {
                return Align(
                  alignment: Alignment(-1 + 2 * t, 0),
                  child: Text(
                    word,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE11D48),
                    ),
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

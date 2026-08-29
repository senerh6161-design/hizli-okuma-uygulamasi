import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';

class _ObjectItem {
  final String name;
  final String emoji;
  const _ObjectItem(this.name, this.emoji);
}

/// 1. Bölüm'ün her turu: kendi hedef/çeldiricisi, kendi akışı ve kendi
/// sorusu olan bağımsız bir tur. 1. Bölüm bunlardan 3 tanesini sırayla
/// (duyuru → akış → soru) çalıştırır. Akışta aktif satırdaki nesneler TEK
/// TEK belirir, satır dolunca hepsi birden kaybolup yeni satır gelir — tüm
/// sayfayı aynı anda emojiyle doldurmaz.
class _Stage1Round {
  final _ObjectItem target;
  final _ObjectItem decoy;
  final List<List<_ObjectItem>> lines;
  final int correctCount;
  int? answer;
  bool? wasCorrect;
  _Stage1Round({
    required this.target,
    required this.decoy,
    required this.lines,
    required this.correctCount,
  });
}

/// Eşleştirme oyunundaki tek bir kart: arkası kapalıyken sadece '?' görünür,
/// çevrilince (ya da eşleşince) emojisi gösterilir.
class _MatchCard {
  final _ObjectItem item;
  bool isFlipped = false;
  bool isMatched = false;
  _MatchCard(this.item);
}

/// Öğretmen dokümanındaki nesne akışı etkinliği: satır üstünde hareketli
/// nesneler akar, bazı nesneler defalarca tekrarlanır. Üç bölümden oluşur:
/// 1. Bölüm bir ISINMA turu — nesneler TEK SATIRDA durur, aktif olan
/// KENDİLİĞİNDEN sırayla döner (süresi yok, öğrenci DEVAM ET'e basana
/// kadar sürer), öğrenci sadece izler ve her nesneye anlık odaklanır
/// (soru/puan yok). 2. Bölüm'de her satırdaki nesneler TEK TEK
/// belirip satır dolunca hepsi birden kaybolur, yeni satır gelir — 3 tur,
/// her turda tek bir hedef nesne önceden duyurulup sonunda "kaç kez
/// gördün?" diye sorulur. 3. Bölüm'de ise kartların arkası kapalı halde
/// emoji eşleştirme oyunu oynanır.
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

  // Türk bayrağı her oturumda KESİNLİKLE sorulan nesnelerden biri olsun diye
  // ayrı tutuluyor — _prepareStage1Rounds bu çifti rastgele seçime bırakmadan
  // her zaman 3 turdan birine dahil eder.
  static const List<String> _flagPair = ['Ay Yıldız Bayrak', 'Balon'];

  static const int _itemsPerLine = 6;
  static const int _rowsPerRound = 30;
  // Akış ilerledikçe nesneler giderek hızlı belirir — ilk satırlarda
  // rahat say, sonlara doğru dikkat gerektirecek şekilde hızlanır.
  static const int _startItemMs = 450;
  static const int _endItemMs = 180;
  static const int _rowPauseMs =
      500; // satır tamamlanınca kaybolmadan önceki bekleme
  // Eşleştirme oyunu 3 turda kolaydan zora gider: az emojiden çok emojiye.
  static const List<int> _matchPairCountsByStage = [4, 6, 8];

  static const int _warmupObjectCount = 6;
  static const int _warmupStepMs = 550;

  final Random _random = Random();
  bool _hasCompletedOnce = false;
  bool _isPaused = false;

  // 1. BÖLÜM (en başta çalışır, ısınma turu): nesneler TEK SATIRDA durur,
  // aktif olan KENDİLİĞİNDEN sırayla döner — süresi yok, öğrenci hazır
  // olduğunda kendisi DEVAM ET'e basana kadar sürer. Öğrenci sadece izler,
  // her nesneye "fotoğrafını çeker gibi" anlık odaklanır. Soru/puan yok.
  bool _warmupDone = false;
  bool _warmupRunning = false;
  late List<_ObjectItem> _warmupObjects;
  int _warmupActiveIndex = 0;
  Timer? _warmupTimer;
  // Süresi yok ama öğrenci ne kadar zaman geçirdiğini görsün diye ayrı bir
  // saniye sayacı.
  int _warmupElapsedSeconds = 0;
  Timer? _warmupElapsedTimer;

  // 2. BÖLÜM: 3 AYRI tur — her turda tek bir hedef nesne önceden duyurulur,
  // aktif satırdaki nesneler TEK TEK belirir, satır dolunca hepsi birden
  // kaybolur ve yeni satır gelir; aralarına kasıtlı bir çeldirici karışır,
  // sonunda "kaç kez gördün?" diye o turun sorusu sorulur.
  late List<_Stage1Round> _stage1Rounds; // her zaman 3 eleman
  int _stage1RoundIndex = 0;
  bool _stage1FlowRunning = false;
  bool _stage1ShowQuestion = false;
  int _stage1LineIndex = 0; // aktif turun akışındaki satır
  int _stage1ItemIndex =
      0; // aktif satırda kaç nesne belirdi (0 = henüz hiçbiri)
  Timer? _stage1Timer;
  // Akış boyunca geçen süreyi gösteren ayrı bir saniye sayacı.
  int _stage1ElapsedSeconds = 0;
  Timer? _stage1ElapsedTimer;

  _Stage1Round get _stage1Round => _stage1Rounds[_stage1RoundIndex];

  // 2. BÖLÜM (1. Bölüm bitince başlar): kartların arkası kapalı, öğrenci
  // ikişer ikişer çevirip aynı emojiyi eşleştirmeye çalışır. 3 tur var,
  // her turda çift sayısı artar (kolaydan zora).
  bool _matchingStageStarted = false;
  bool _showMatchingIntro = false;
  int _matchStageIndex = 0; // 0..2
  late List<_MatchCard> _matchCards;
  int? _firstFlippedIndex;
  bool _matchInputLocked = false;
  int _matchMoves = 0; // 3 tur boyunca toplam hamle
  int _matchedPairs = 0; // aktif turda eşleşen çift sayısı

  @override
  void initState() {
    super.initState();
    _prepareSession();
  }

  @override
  void dispose() {
    _stage1Timer?.cancel();
    _stage1ElapsedTimer?.cancel();
    _warmupTimer?.cancel();
    _warmupElapsedTimer?.cancel();
    super.dispose();
  }

  _ObjectItem _byName(String name) =>
      _objectPool.firstWhere((o) => o.name == name);

  void _prepareSession() {
    _prepareWarmup();
    _prepareStage1Rounds();
  }

  void _prepareWarmup() {
    final pool = List<_ObjectItem>.from(_objectPool)..shuffle(_random);
    _warmupObjects = pool.take(_warmupObjectCount).toList();
    _warmupActiveIndex = 0;
    _warmupRunning = false;
    _warmupDone = false;
  }

  void _startWarmup() {
    _warmupTimer?.cancel();
    _warmupElapsedTimer?.cancel();
    setState(() {
      _warmupRunning = true;
      _warmupActiveIndex = 0;
      _warmupElapsedSeconds = 0;
    });
    _scheduleWarmupStep();
    _warmupElapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _warmupElapsedSeconds++);
    });
  }

  // Öğrenci baştan izlemek isterse sayacı ve döngüyü sıfırdan başlatır —
  // "DEVAM ET"e basmadan istediği kadar tekrar izleyebilir.
  void _replayWarmup() {
    _startWarmup();
  }

  // Süresi yok — öğrenci "DEVAM ET"e basana kadar sürekli döner.
  void _finishWarmup() {
    _warmupTimer?.cancel();
    _warmupElapsedTimer?.cancel();
    setState(() {
      _warmupRunning = false;
      _warmupDone = true;
    });
  }

  void _scheduleWarmupStep() {
    _warmupTimer = Timer(const Duration(milliseconds: _warmupStepMs), () {
      if (!mounted) return;
      setState(() {
        final next = _warmupActiveIndex + 1;
        if (next >= _warmupObjects.length) {
          // Bir tur tamamlandı — hep aynı nesneler dönmesin diye yeni
          // rastgele bir set seçiliyor.
          final pool = List<_ObjectItem>.from(_objectPool)..shuffle(_random);
          _warmupObjects = pool.take(_warmupObjectCount).toList();
          _warmupActiveIndex = 0;
        } else {
          _warmupActiveIndex = next;
        }
      });
      _scheduleWarmupStep();
    });
  }

  void _prepareStage1Rounds() {
    // Bayrak çifti HER OTURUMDA garanti edilsin diye ayrı tutulup rastgele
    // seçilen diğer 2 çiftle birleştiriliyor, sonra tur sırası karıştırılıyor.
    final otherPairs =
        _confusablePairNames.where((p) => p != _flagPair).toList()
          ..shuffle(_random);
    final chosenPairs = [_flagPair, ...otherPairs.take(2)]..shuffle(_random);

    _stage1Rounds = chosenPairs.map((pairNames) {
      final flipped = _random.nextBool();
      final target = _byName(flipped ? pairNames[1] : pairNames[0]);
      final decoy = _byName(flipped ? pairNames[0] : pairNames[1]);

      // 30 satır, her satırda TAM OLARAK en fazla 1 hedef ve en fazla 1
      // çeldirici olacak şekilde satır bazında üretiliyor — böylece "aynı
      // satırda 2 hedef" ihtimali baştan imkansız (eski akış-sonra-böl
      // yönteminde jitter yüzünden bazen 2 tane aynı satıra düşebiliyordu).
      final targetCount = 10 + _random.nextInt(4); // 10-13 kez
      final decoyCount = 8 + _random.nextInt(3); // 8-10 kez

      final fillerPool =
          _objectPool
              .where((o) => o.name != target.name && o.name != decoy.name)
              .toList()
            ..shuffle(_random);

      final targetRows = (List.generate(
        _rowsPerRound,
        (i) => i,
      )..shuffle(_random)).take(targetCount).toSet();
      final decoyRows = (List.generate(
        _rowsPerRound,
        (i) => i,
      )..shuffle(_random)).take(decoyCount).toSet();

      final lines = <List<_ObjectItem>>[];
      for (int r = 0; r < _rowsPerRound; r++) {
        final slots = List<_ObjectItem?>.filled(_itemsPerLine, null);
        final positions = List.generate(_itemsPerLine, (i) => i)
          ..shuffle(_random);
        int cursor = 0;
        if (targetRows.contains(r)) {
          slots[positions[cursor]] = target;
          cursor++;
        }
        if (decoyRows.contains(r)) {
          slots[positions[cursor]] = decoy;
          cursor++;
        }
        // Aynı satırda dolgu nesnelerden de asla tekrar olmasın diye her
        // satır için ayrı karıştırılmış bir havuzdan SIRAYLA farklı öğeler
        // alınıyor (rastgele indeksle tekrar çekmek yerine).
        final rowFillers = List<_ObjectItem>.from(fillerPool)..shuffle(_random);
        int fillerCursor = 0;
        for (int i = 0; i < _itemsPerLine; i++) {
          if (slots[i] == null) {
            slots[i] = rowFillers[fillerCursor];
            fillerCursor++;
          }
        }
        lines.add(slots.map((e) => e!).toList());
      }

      return _Stage1Round(
        target: target,
        decoy: decoy,
        lines: lines,
        correctCount: targetCount,
      );
    }).toList();

    _stage1RoundIndex = 0;
    _stage1FlowRunning = false;
    _stage1ShowQuestion = false;
    _stage1LineIndex = 0;
    _stage1ItemIndex = 0;
    _matchingStageStarted = false;
    _showMatchingIntro = false;
  }

  void _startStage1Flow() {
    _stage1Timer?.cancel();
    _stage1ElapsedTimer?.cancel();
    setState(() {
      _stage1FlowRunning = true;
      _stage1LineIndex = 0;
      _stage1ItemIndex = 1; // ilk nesne hemen belirsin
      _stage1ElapsedSeconds = 0;
    });
    _scheduleStage1ItemReveal();
    _stage1ElapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _stage1ElapsedSeconds++);
    });
  }

  // Akış ilerledikçe (satırdan satıra) nesnelerin belirme hızı _startItemMs'
  // den _endItemMs'e doğru kademeli olarak artar — ilk satırlar rahat, son
  // satırlar dikkat gerektirecek kadar hızlıdır.
  int _currentItemRevealMs() {
    final totalLines = _stage1Round.lines.length;
    final progress = totalLines <= 1
        ? 0.0
        : _stage1LineIndex / (totalLines - 1);
    return (_startItemMs - (_startItemMs - _endItemMs) * progress).round();
  }

  // Aktif satırdaki nesneler TEK TEK belirir (ör. mısır, sonra elma, sonra
  // mısır...); satır tamamen dolunca kısa bir süre öylece durup öğrenciye
  // sayma fırsatı verir, sonra hepsi birden kaybolup yeni satır aynı şekilde
  // tek tek belirmeye başlar.
  void _scheduleStage1ItemReveal() {
    final lines = _stage1Round.lines;
    final currentLine = lines[_stage1LineIndex];
    final rowComplete = _stage1ItemIndex >= currentLine.length;
    final delay = rowComplete ? _rowPauseMs : _currentItemRevealMs();
    _stage1Timer = Timer(Duration(milliseconds: delay), () {
      if (!mounted) return;
      if (rowComplete) {
        if (_stage1LineIndex >= lines.length - 1) {
          _stage1ElapsedTimer?.cancel();
          setState(() {
            _stage1FlowRunning = false;
            _stage1ShowQuestion = true;
          });
          return;
        }
        setState(() {
          _stage1LineIndex++;
          _stage1ItemIndex = 1;
        });
      } else {
        setState(() => _stage1ItemIndex++);
      }
      _scheduleStage1ItemReveal();
    });
  }

  void _pauseGame() {
    _warmupTimer?.cancel();
    _warmupElapsedTimer?.cancel();
    _stage1Timer?.cancel();
    _stage1ElapsedTimer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resumeGame() {
    setState(() => _isPaused = false);
    if (_warmupRunning) {
      _scheduleWarmupStep();
      _warmupElapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _warmupElapsedSeconds++);
      });
    } else if (_stage1FlowRunning) {
      _scheduleStage1ItemReveal();
      _stage1ElapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _stage1ElapsedSeconds++);
      });
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
    // Otomatik geçiş çok hızlı olup öğrencinin parmağı ekrandayken bir
    // sonraki ekrana yanlışlıkla dokunmasına yol açıyordu — artık öğrenci
    // "DEVAM ET" butonuna basana kadar bekleniyor.
  }

  void _advanceFromStage1Question() {
    if (_stage1RoundIndex < _stage1Rounds.length - 1) {
      setState(() {
        _stage1RoundIndex++;
        _stage1FlowRunning = false;
        _stage1ShowQuestion = false;
        _stage1LineIndex = 0;
      });
    } else {
      _goToMatchingGame();
    }
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

  void _goToMatchingGame() {
    _matchStageIndex = 0;
    _matchMoves = 0;
    _matchingStageStarted = true;
    _prepareMatchStage();
  }

  void _prepareMatchStage() {
    final pairCount = _matchPairCountsByStage[_matchStageIndex];
    final chosen = (List<_ObjectItem>.from(
      _objectPool,
    )..shuffle(_random)).take(pairCount).toList();
    final cards = [
      ...chosen,
      ...chosen,
    ].map((item) => _MatchCard(item)).toList()..shuffle(_random);
    setState(() {
      _matchCards = cards;
      _firstFlippedIndex = null;
      _matchInputLocked = false;
      _matchedPairs = 0;
      _showMatchingIntro = true;
    });
  }

  void _startMatchingFromIntro() {
    setState(() => _showMatchingIntro = false);
  }

  void _flipCard(int index) {
    if (_matchInputLocked) return;
    final card = _matchCards[index];
    if (card.isMatched || card.isFlipped) return;

    if (_firstFlippedIndex == null) {
      setState(() {
        card.isFlipped = true;
        _firstFlippedIndex = index;
      });
      return;
    }

    setState(() {
      card.isFlipped = true;
      _matchMoves++;
    });

    final first = _matchCards[_firstFlippedIndex!];
    final second = _matchCards[index];
    if (first.item.name == second.item.name) {
      SoundManager.playCorrect();
      setState(() {
        first.isMatched = true;
        second.isMatched = true;
        _matchedPairs++;
        _firstFlippedIndex = null;
      });
      if (_matchedPairs == _matchPairCountsByStage[_matchStageIndex]) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          if (_matchStageIndex < _matchPairCountsByStage.length - 1) {
            _matchStageIndex++;
            _prepareMatchStage();
          } else {
            _finish();
          }
        });
      }
    } else {
      SoundManager.playGentleTap();
      _matchInputLocked = true;
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() {
          first.isFlipped = false;
          second.isFlipped = false;
          _firstFlippedIndex = null;
          _matchInputLocked = false;
        });
      });
    }
  }

  void _finish() {
    _hasCompletedOnce = true;
    final stage1Correct = _stage1Rounds
        .where((r) => r.wasCorrect ?? false)
        .length;
    final total = _stage1Rounds.length;
    final countingPercent = (stage1Correct / total * 100).round();
    // Eşleştirme oyunu ayrı bir beceriyi (görsel hafıza) ölçtüğü için sayma
    // doğruluğuyla ortalanır — en verimli sonuç 3 turun toplam çift sayısı
    // kadar hamlede bitirmek olduğundan oran buna göre hesaplanır.
    final totalMatchPairs = _matchPairCountsByStage.reduce((a, b) => a + b);
    final matchPercent =
        (totalMatchPairs / _matchMoves.clamp(totalMatchPairs, 999) * 100)
            .round();
    final percent = ((countingPercent + matchPercent) / 2).round();
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Nesne Akışı (Sayma)',
      result:
          '$stage1Correct/$total doğru · $_matchMoves hamlede eşleşti · %$percent',
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
            Text('Sayma testi: $stage1Correct / $total doğru'),
            Text('Eşleştirme: $_matchMoves hamlede tamamlandı'),
            Text(
              'Puan: %$percent',
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
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildBody(),
              ),
              if (_isPaused)
                buildPauseOverlay(
                  color: const Color(0xFF2563EB),
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
    if (_matchingStageStarted) {
      if (_showMatchingIntro) {
        return KeyedSubtree(
          key: ValueKey('match-intro-$_matchStageIndex'),
          child: _buildMatchingIntro(),
        );
      }
      return KeyedSubtree(
        key: ValueKey('match-game-$_matchStageIndex'),
        child: _buildMatchingGame(),
      );
    }
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
            '2. Bölüm · Hedef: ${_stage1RoundIndex + 1}/${_stage1Rounds.length}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),
        ),
        const Spacer(),
        Center(
          child: Text(round.target.emoji, style: const TextStyle(fontSize: 96)),
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
              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF2563EB),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "'${round.target.name}' nesnesine odaklan! Akış boyunca kaç kez "
                  'göreceğini dikkatlice say.',
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
              backgroundColor: const Color(0xFF2563EB),
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
        // Etiket uzun ("2. Bölüm · Hedef X/Y · Satır A/B") + sağdaki grup
        // (say + süre + duraklat) tek satırda taşıyordu — iki satıra bölündü.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '2. Bölüm · Hedef ${_stage1RoundIndex + 1}/${_stage1Rounds.length} · '
                  'Satır ${_stage1LineIndex + 1}/${round.lines.length}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ),
            buildPauseButton(
              color: const Color(0xFF2563EB),
              onPressed: _pauseGame,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '${round.target.emoji} say',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '⏱ $_stage1ElapsedSeconds sn',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                  fontSize: 12,
                ),
              ),
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
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                ),
              ],
            ),
            // Row (Wrap DEĞİL): satır TEK satır kalmalı, alt satıra kaymamalı
            // — kaç nesne olursa olsun (en fazla _itemsPerLine kadar) yan
            // yana sığar, dolunca hepsi birden kaybolur. Bilerek Center
            // DEĞİL, sola yaslı: ortalanmış olsaydı her yeni nesne
            // eklendiğinde satırın tamamı yeniden ortalanıp nesneler
            // "ortadan çıkıyormuş" gibi kayardı.
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (
                    int i = 0;
                    i < _stage1ItemIndex &&
                        i < round.lines[_stage1LineIndex].length;
                    i++
                  )
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(
                          's1-$_stage1RoundIndex-$_stage1LineIndex-$i',
                        ),
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
                          round.lines[_stage1LineIndex][i].emoji,
                          style: const TextStyle(fontSize: 34),
                        ),
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
              ? '2. Bölüm · Son Soru (${_stage1RoundIndex + 1}/${_stage1Rounds.length})'
              : '2. Bölüm · Soru ${_stage1RoundIndex + 1}/${_stage1Rounds.length}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2563EB),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(round.target.emoji, style: const TextStyle(fontSize: 52)),
        ),
        const SizedBox(height: 12),
        Text(
          '"${round.target.name}" nesnesini kaç kez gördün?',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 20),
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
        if (round.answer != null) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _advanceFromStage1Question,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text(
                'DEVAM ET',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMatchingIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF059669).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '3. Bölüm · Tur ${_matchStageIndex + 1}/${_matchPairCountsByStage.length}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF059669),
            ),
          ),
        ),
        const Spacer(),
        const Center(child: Text('🧩', style: TextStyle(fontSize: 96))),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF059669).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.grid_view_rounded,
                color: Color(0xFF059669),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kartların arkası kapalı! İkişer ikişer çevirip aynı emojiyi bulmaya çalış — '
                  'bu turda ${_matchPairCountsByStage[_matchStageIndex]} çift var. '
                  'Eşleşmezlerse tekrar kapanırlar, eşleşirlerse açık kalırlar.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF065F46),
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
            onPressed: _startMatchingFromIntro,
            icon: const Icon(Icons.play_arrow),
            label: const Text(
              'BAŞLA',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
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

  Widget _buildMatchingGame() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Tur ${_matchStageIndex + 1}/${_matchPairCountsByStage.length} · '
                'Eşleşen: $_matchedPairs/${_matchPairCountsByStage[_matchStageIndex]}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF059669),
                ),
              ),
            ),
            Text(
              'Hamle: $_matchMoves',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            itemCount: _matchCards.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              final card = _matchCards[index];
              final revealed = card.isFlipped || card.isMatched;
              return GestureDetector(
                onTap: () => _flipCard(index),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Container(
                    key: ValueKey('$index-$revealed'),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: card.isMatched
                          ? Colors.green.shade50
                          : (revealed ? Colors.white : const Color(0xFF059669)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: card.isMatched
                            ? Colors.green.shade400
                            : const Color(0xFF059669),
                        width: 2,
                      ),
                    ),
                    child: revealed
                        ? Text(
                            card.item.emoji,
                            style: const TextStyle(fontSize: 30),
                          )
                        : const Icon(
                            Icons.help_outline_rounded,
                            color: Colors.white,
                            size: 26,
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

  Widget _buildWarmupIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            '1. Bölüm · Odaklanma',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),
        ),
        const Spacer(),
        const Center(child: Text('📸', style: TextStyle(fontSize: 96))),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF2563EB),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nesneler daire üzerinde kendiliğinden dönecek. Her nesneye sırayla, sanki '
                  'fotoğrafını çekiyormuş gibi anlık odaklan — sen sadece izle!',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1E3A8A),
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
            onPressed: _startWarmup,
            icon: const Icon(Icons.play_arrow),
            label: const Text(
              'BAŞLA',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
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
    final n = _warmupObjects.length;
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
              child: const Text(
                '1. Bölüm · Odaklanma',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
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
                buildPauseButton(
                  color: const Color(0xFF2563EB),
                  onPressed: _pauseGame,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Center(
            // Dairesel DEĞİL, Wrap DEĞİL: nesneler TEK satırda kalmalı,
            // alt satıra kaymamalı — aktif olan kendiliğinden soldan sağa
            // sırayla döner, süresi yoktur. Dar ekranlarda satır genişliği
            // taşabildiği için (sağdan overflow hatası) yatay kaydırılabilir
            // yapıldı.
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < n; i++)
                    Builder(
                      builder: (_) {
                        final isActive = i == _warmupActiveIndex;
                        final nodeSize = isActive ? 64.0 : 48.0;
                        // Bilerek animasyonsuz (Container, AnimatedContainer
                        // DEĞİL) — anlık geçiş, "gölge kalması" sorununu
                        // kökten çözen köklü desen.
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Container(
                            width: nodeSize,
                            height: nodeSize,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive
                                  ? const Color(0xFF2563EB)
                                  : Colors.white,
                              border: Border.all(
                                color: const Color(0xFF2563EB),
                                width: isActive ? 3 : 2,
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF2563EB,
                                        ).withValues(alpha: 0.4),
                                        blurRadius: 14,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Text(
                              _warmupObjects[i].emoji,
                              style: TextStyle(fontSize: isActive ? 32 : 22),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
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
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFF2563EB)),
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
                    backgroundColor: const Color(0xFF2563EB),
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
}

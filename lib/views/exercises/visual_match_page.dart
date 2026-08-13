import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/progress_manager.dart';
import '../../models/achievement.dart';

enum _Difficulty { easy, medium, hard }

extension on _Difficulty {
  int get pairCount {
    switch (this) {
      case _Difficulty.easy:
        return 4;
      case _Difficulty.medium:
        return 6;
      case _Difficulty.hard:
        return 8;
    }
  }

  String get label {
    switch (this) {
      case _Difficulty.easy:
        return 'Kolay';
      case _Difficulty.medium:
        return 'Orta';
      case _Difficulty.hard:
        return 'Zor';
    }
  }

  String get storageKey => 'visual_match_best_$pairCount';
}

class VisualMatchPage extends StatefulWidget {
  const VisualMatchPage({super.key});

  @override
  State<VisualMatchPage> createState() => _VisualMatchPageState();
}

class _VisualMatchPageState extends State<VisualMatchPage> {
  // Eşleştirilecek İkon Havuzu (en zor mod 8 çift kullandığı için en az 8 ikon gerekli)
  final List<IconData> availableIcons = const [
    Icons.card_giftcard,
    Icons.laptop,
    Icons.menu_book,
    Icons.beach_access,
    Icons.directions_car,
    Icons.watch,
    Icons.headphones,
    Icons.camera_alt,
  ];

  _Difficulty difficulty = _Difficulty.easy;

  late List<IconData> gameBoard;
  List<bool> revealed = [];
  int? firstSelectedIndex;
  int pairsLeft = 0;
  int elapsedSeconds = 0;
  int moves = 0;
  Timer? timer;
  bool isBusy = false;

  SharedPreferences? _prefs;
  int? bestTime;
  List<Achievement> _lastUnlocked = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      bestTime = _prefs?.getInt(difficulty.storageKey);
    });
    _startNewGame();
  }

  Future<void> _maybeSaveBestTime() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final current = prefs.getInt(difficulty.storageKey);
    if (current == null || elapsedSeconds < current) {
      await prefs.setInt(difficulty.storageKey, elapsedSeconds);
      if (mounted) setState(() => bestTime = elapsedSeconds);
    }
  }

  void _changeDifficulty(_Difficulty newDifficulty) {
    timer?.cancel();
    setState(() {
      difficulty = newDifficulty;
      bestTime = _prefs?.getInt(difficulty.storageKey);
    });
    _startNewGame();
  }

  void _startNewGame() {
    timer?.cancel();
    final pairCount = difficulty.pairCount;
    List<IconData> selectedIcons = List.from(availableIcons)..shuffle();
    List<IconData> pairs = selectedIcons.take(pairCount).toList();

    gameBoard = [...pairs, ...pairs]..shuffle();
    revealed = List.filled(gameBoard.length, false);
    pairsLeft = pairCount;
    firstSelectedIndex = null;
    elapsedSeconds = 0;
    moves = 0;
    isBusy = false;

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => elapsedSeconds++);
    });

    setState(() {});
  }

  void _onCardTap(int index) {
    if (isBusy || revealed[index] || firstSelectedIndex == index) return;

    setState(() {
      revealed[index] = true;
    });

    if (firstSelectedIndex == null) {
      // İlk kart seçildi
      firstSelectedIndex = index;
    } else {
      // İkinci kart seçildi, kontrol et
      isBusy = true;
      final firstIndex = firstSelectedIndex!;
      setState(() => moves++);

      if (gameBoard[firstIndex] == gameBoard[index]) {
        // EŞLEŞTİ!
        setState(() {
          pairsLeft--;
          firstSelectedIndex = null;
          isBusy = false;
        });

        if (pairsLeft == 0) {
          timer?.cancel();
          final unlocked = ProgressManager.addCompletedExercise(
            type: 'Görsel Eşleştirme (${difficulty.label})',
            result: '$elapsedSeconds sn · $moves hamle',
          );
          _lastUnlocked = unlocked;
          _maybeSaveBestTime().then((_) => _showWinDialog());
        }
      } else {
        // EŞLEŞMEDİ! 0.8 saniye gösterip kapat
        Timer(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              revealed[firstIndex] = false;
              revealed[index] = false;
              firstSelectedIndex = null;
              isBusy = false;
            });
          }
        });
      }
    }
  }

  void _showWinDialog() {
    final isNewRecord = bestTime == elapsedSeconds;
    final canLevelUp = difficulty != _Difficulty.hard;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🎉 Muhteşem Görsel Algı!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tüm eşleri $elapsedSeconds saniyede, $moves hamlede buldunuz.'),
            if (isNewRecord) ...[
              const SizedBox(height: 8),
              const Text(
                '🏆 YENİ REKOR!',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ],
            if (_lastUnlocked.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                '🎉 Yeni Başarım Kazandın!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _lastUnlocked.map((a) {
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
              _startNewGame();
            },
            child: const Text('Tekrar Oyna'),
          ),
          if (canLevelUp)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _changeDifficulty(
                  difficulty == _Difficulty.easy ? _Difficulty.medium : _Difficulty.hard,
                );
              },
              child: const Text('Sıradaki Zorluk'),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧩 Görsel Çift Eşleştirme'),
      ),
      body: Column(
        children: [
          // ZORLUK SEÇİCİ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: _Difficulty.values.map((d) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${d.label} (${d.pairCount} çift)'),
                    selected: difficulty == d,
                    onSelected: (selected) {
                      if (selected) _changeDifficulty(d);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // ÜST İSTATİSTİK BARI
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kalan: $pairsLeft',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                ),
                Text(
                  'Hamle: $moves',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                Text(
                  'Süre: $elapsedSeconds sn',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ],
            ),
          ),

          // REKOR ROZETİ
          if (bestTime != null)
            Container(
              width: double.infinity,
              color: Colors.green.shade50,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                '🏆 Rekor (${difficulty.label}): $bestTime sn',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),

          const SizedBox(height: 10),

          // KART MATRIX ALANI
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                itemCount: gameBoard.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: difficulty == _Difficulty.medium ? 3 : 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final isRevealed = revealed[index];

                  return InkWell(
                    onTap: () => _onCardTap(index),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: isRevealed ? Colors.white : const Color(0xFF4F46E5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isRevealed ? const Color(0xFF4F46E5) : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                          )
                        ],
                      ),
                      child: Center(
                        child: isRevealed
                            ? Icon(
                                gameBoard[index],
                                size: 34,
                                color: const Color(0xFF4F46E5),
                              )
                            : const Icon(
                                Icons.help_outline_rounded,
                                size: 30,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // YENİDEN BAŞLAT BUTONU
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _startNewGame,
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'OYUNU SIFIRLA',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
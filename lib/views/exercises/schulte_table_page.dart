import 'dart:async';
import 'package:flutter/material.dart';

enum SchulteMode { numbers, letters }

class SchulteTablePage extends StatefulWidget {
  const SchulteTablePage({super.key});

  @override
  State<SchulteTablePage> createState() => _SchulteTablePageState();
}

class _SchulteTablePageState extends State<SchulteTablePage> {
  int gridSize = 5; // Varsayılan 5x5
  SchulteMode currentMode = SchulteMode.numbers;

  List<String> items = [];
  int currentTargetIndex = 0;
  int elapsedSeconds = 0;
  int? bestTime;
  Timer? timer;
  bool isRunning = false;

  final List<String> turkishAlphabet = [
    'A',
    'B',
    'C',
    'Ç',
    'D',
    'E',
    'F',
    'G',
    'Ğ',
    'H',
    'I',
    'İ',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'Ö',
    'P',
    'R',
    'S',
    'Ş',
    'T',
    'U',
    'Ü',
    'V',
    'Y',
    'Z',
  ];

  @override
  void initState() {
    super.initState();
    _initGrid();
  }

  void _initGrid() {
    int totalItems = gridSize * gridSize;

    if (currentMode == SchulteMode.numbers) {
      items = List.generate(totalItems, (i) => '${i + 1}');
    } else {
      // Harf modunda alfabeden grid boyutuna göre eleman çekilir
      items = turkishAlphabet.take(totalItems).toList();
    }

    items.shuffle(); // Her açılışta karıştır
  }

  void startTable() {
    setState(() {
      _initGrid();
      currentTargetIndex = 0;
      elapsedSeconds = 0;
      isRunning = true;
    });

    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() => elapsedSeconds++);
      }
    });
  }

  String get currentTargetLabel {
    int totalItems = gridSize * gridSize;
    if (currentTargetIndex >= totalItems) return 'Tamamlandı';

    if (currentMode == SchulteMode.numbers) {
      return '${currentTargetIndex + 1}';
    } else {
      return turkishAlphabet[currentTargetIndex];
    }
  }

  void onItemClick(String value) {
    if (!isRunning) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen önce aşağıdaki "BAŞLA" butonuna basın!'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    if (value == currentTargetLabel) {
      int totalItems = gridSize * gridSize;
      if (currentTargetIndex == totalItems - 1) {
        // Oyun Bitti
        timer?.cancel();
        setState(() {
          isRunning = false;
          if (bestTime == null || elapsedSeconds < bestTime!) {
            bestTime = elapsedSeconds;
          }
        });
        _showSuccessDialog();
      } else {
        setState(() => currentTargetIndex++);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🎉 Muhteşem Odak!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mod: $gridSize x $gridSize (${currentMode == SchulteMode.numbers ? "Sayı" : "Harf"})',
            ),
            const SizedBox(height: 6),
            Text('Süreniz: $elapsedSeconds saniye'),
            if (bestTime == elapsedSeconds) ...[
              const SizedBox(height: 8),
              const Text(
                '🏆 YENİ REKOR!',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              startTable();
            },
            child: const Text('Tekrar Başlat'),
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
      appBar: AppBar(title: const Text('Schulte Tablosu')),
      body: Column(
        children: [
          // MOD VE BOYUT SEÇİM ALANI
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Grid Boyutu Seçici
                    Row(
                      children: [3, 4, 5, 6].map((size) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text('${size}x$size'),
                            selected: gridSize == size,
                            onSelected: (selected) {
                              if (selected) {
                                timer?.cancel();
                                setState(() {
                                  gridSize = size;
                                  isRunning = false;
                                  _initGrid();
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Sayı / Harf Modu Seçici
                    SegmentedButton<SchulteMode>(
                      segments: const [
                        ButtonSegment(
                          value: SchulteMode.numbers,
                          label: Text('1-25 Sayı'),
                        ),
                        ButtonSegment(
                          value: SchulteMode.letters,
                          label: Text('A-Z Harf'),
                        ),
                      ],
                      selected: {currentMode},
                      onSelectionChanged: (Set<SchulteMode> newSelection) {
                        timer?.cancel();
                        setState(() {
                          currentMode = newSelection.first;
                          isRunning = false;
                          _initGrid();
                        });
                      },
                    ),
                    if (bestTime != null)
                      Text(
                        '🏆 Rekor: $bestTime sn',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // SÜRE VE HEDEF BİLGİSİ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hedef: $currentTargetLabel',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
                Text(
                  'Süre: $elapsedSeconds sn',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // SCHULTE GRID
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                itemCount: gridSize * gridSize,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridSize,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemBuilder: (context, index) {
                  final itemValue = items[index];

                  // Geçilen elemanları bulma hesabı
                  int itemIndex;
                  if (currentMode == SchulteMode.numbers) {
                    itemIndex = int.tryParse(itemValue) != null
                        ? int.parse(itemValue) - 1
                        : -1;
                  } else {
                    itemIndex = turkishAlphabet.indexOf(itemValue);
                  }

                  final isPassed = itemIndex < currentTargetIndex;

                  return Material(
                    color: isPassed
                        ? Colors.green.shade600
                        : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => onItemClick(itemValue),
                      child: Container(
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            itemValue,
                            style: TextStyle(
                              fontSize: gridSize >= 5 ? 18 : 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // BAŞLA BUTONU
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: startTable,
                icon: Icon(isRunning ? Icons.refresh : Icons.play_arrow),
                label: Text(
                  isRunning ? 'YENİDEN BAŞLAT' : 'BAŞLA',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

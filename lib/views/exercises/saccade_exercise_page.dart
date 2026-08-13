import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/word_data.dart';

class SaccadeExercisePage extends StatefulWidget {
  const SaccadeExercisePage({super.key});

  @override
  State<SaccadeExercisePage> createState() => _SaccadeExercisePageState();
}

class _SaccadeExercisePageState extends State<SaccadeExercisePage> {
  final Random random = Random();

  Timer? timer;
  bool isRunning = false;
  int wordIndex = 0;
  int speedMs = 1000; // Varsayılan hız: 1 saniye

  // Ekranın 4 köşesi ve merkezi için hizalama koordinatları
  final List<Alignment> positions = const [
    Alignment(-0.7, -0.6), // Sol Üst
    Alignment(0.7, -0.6),  // Sağ Üst
    Alignment(-0.7, 0.6),  // Sol Alt
    Alignment(0.7, 0.6),   // Sağ Alt
    Alignment(0.0, 0.0),   // Merkez
  ];

  Alignment currentAlignment = Alignment.center;

  void startExercise() {
    if (isRunning) return;

    setState(() {
      isRunning = true;
      wordIndex = 0;
    });

    timer = Timer.periodic(Duration(milliseconds: speedMs), (_) {
      if (!mounted) return;
      setState(() {
        wordIndex++;
        // Rastgele farklı bir konuma zıpla
        currentAlignment = positions[random.nextInt(positions.length)];
      });
    });
  }

  void stopExercise() {
    timer?.cancel();
    if (mounted) {
      setState(() {
        isRunning = false;
        currentAlignment = Alignment.center;
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentWord = WordData.singleWords[wordIndex % WordData.singleWords.length];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Göz Sıçratma (Saccade)'),
      ),
      body: Column(
        children: [
          // ÜST BİLGİLENDİRME
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: Column(
              children: [
                const Text(
                  'Başınızı sabit tutun! Yalnızca göz bebeklerinizle kelimeyi takip edin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Hız: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    ChoiceChip(
                      label: const Text('1.0 sn'),
                      selected: speedMs == 1000,
                      onSelected: (selected) {
                        if (selected) {
                          stopExercise();
                          setState(() => speedMs = 1000);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('0.7 sn'),
                      selected: speedMs == 700,
                      onSelected: (selected) {
                        if (selected) {
                          stopExercise();
                          setState(() => speedMs = 700);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('0.5 sn'),
                      selected: speedMs == 500,
                      onSelected: (selected) {
                        if (selected) {
                          stopExercise();
                          setState(() => speedMs = 500);
                        }
                      },
                    ),
                  ],
                )
              ],
            ),
          ),

          // ZILAMA ALANI (ANIMATED ALIGNMENT)
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 150), // Yumuşak zıplama efekti
                curve: Curves.easeInOut,
                alignment: currentAlignment,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF4F46E5), width: 1.5),
                  ),
                  child: Text(
                    isRunning ? currentWord : 'HAZIR',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // BAŞLAT / DURDUR BUTONU
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
                onPressed: isRunning ? stopExercise : startExercise,
                icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
                label: Text(
                  isRunning ? 'DURAKLAT' : 'EGZERSİZİ BAŞLAT',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
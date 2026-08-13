import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/word_data.dart';

class MemoryExercisePage extends StatefulWidget {
  const MemoryExercisePage({super.key});

  @override
  State<MemoryExercisePage> createState() => _MemoryExercisePageState();
}

class _MemoryExercisePageState extends State<MemoryExercisePage> {
  final Random random = Random();

  int currentLevel = 1;
  int totalScore = 0;

  List<String> targetWords = [];
  List<String> testOptions = [];
  Set<String> selectedWords = {};

  bool showItems = true;
  int countdown = 4;
  Timer? countdownTimer;

  // Seviyeye göre kaç kelime hatırlanması gerektiği
  int get wordCount {
    if (currentLevel == 1) return 3;
    if (currentLevel == 2) return 4;
    return 5; // Seviye 3 ve üzeri
  }

  // Seviyeye göre ekranda kalma süresi (saniye)
  int get displayDuration {
    if (currentLevel == 1) return 4;
    if (currentLevel == 2) return 3;
    return 2; // Seviye 3 ve üzeri hızlanır
  }

  @override
  void initState() {
    super.initState();
    startNewRound();
  }

  void startNewRound() {
    countdownTimer?.cancel();
    setState(() {
      showItems = true;
      countdown = displayDuration;
      selectedWords.clear();

      // Seviyeye göre kelime havuzunu belirle (İleri seviyede ikili öbekler gelsin)
      List<String> sourceWords = currentLevel >= 3 
          ? WordData.pairs 
          : WordData.singleWords;

      List<String> shuffled = List.from(sourceWords)..shuffle();
      
      // Hedef kelimeleri seç
      targetWords = shuffled.sublist(0, wordCount);

      // Yanıltıcı seçeneklerle birlikte test havuzu oluştur
      List<String> distractors = shuffled.sublist(wordCount, wordCount + wordCount);
      testOptions = [...targetWords, ...distractors]..shuffle();
    });

    // Zamanlayıcı
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (countdown > 1) {
        setState(() => countdown--);
      } else {
        timer.cancel();
        setState(() => showItems = false);
      }
    });
  }

  void toggleWordSelection(String word) {
    setState(() {
      if (selectedWords.contains(word)) {
        selectedWords.remove(word);
      } else {
        selectedWords.add(word);
      }
    });
  }

  void checkAnswers() {
    bool isFullSuccess = selectedWords.length == targetWords.length &&
        selectedWords.containsAll(targetWords);

    if (isFullSuccess) {
      setState(() {
        totalScore += currentLevel * 10; // Yüksek seviye daha çok puan verir
        currentLevel++; // Bir sonraki seviyeye geç
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(isFullSuccess ? '🎉 Seviye Atladın!' : '❌ Hatalı Hatırlama'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isFullSuccess
                  ? 'Harika! Şimdi Seviye $currentLevel seviyesine geçiyorsun.'
                  : 'Doğru kelimeler şunlardı:\n• ${targetWords.join("\n• ")}',
            ),
            const SizedBox(height: 10),
            Text(
              'Sonraki Seviye Süresi: ${displayDuration} sn | Kelime Sayısı: $wordCount',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo),
            )
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              startNewRound();
            },
            child: Text(isFullSuccess ? 'Sonraki Seviyeye Geç' : 'Tekrar Denet'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 Görsel Hafıza'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // SEVİYE VE SKOR BİLGİSİ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Seviye: $currentLevel',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                  ),
                ),
                Text(
                  'Puan: $totalScore',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
                if (showItems)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Süre: $countdown sn',
                      style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // KELİME GÖSTERİM AŞAMASI
            if (showItems) ...[
              Text(
                'Aşağıdaki $wordCount kelimeyi $displayDuration saniye içinde aklınızda tutun:',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: targetWords.map((item) {
                  return Chip(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                    label: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ]
            // TEST AŞAMASI
            else ...[
              Text(
                'Az önce gördüğünüz $wordCount kelimeyi seçin:',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  itemCount: testOptions.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: currentLevel >= 3 ? 1.8 : 2.2,
                  ),
                  itemBuilder: (context, index) {
                    final word = testOptions[index];
                    final isSelected = selectedWords.contains(word);

                    return InkWell(
                      onTap: () => toggleWordSelection(word),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          word,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: currentLevel >= 3 ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: selectedWords.isEmpty ? null : checkAnswers,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('KONTROL ET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
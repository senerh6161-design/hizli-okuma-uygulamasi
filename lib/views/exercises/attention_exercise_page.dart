import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/word_data.dart';

class AttentionExercisePage extends StatefulWidget {
  const AttentionExercisePage({super.key});

  @override
  State<AttentionExercisePage> createState() => _AttentionExercisePageState();
}

class _AttentionExercisePageState extends State<AttentionExercisePage> {
  final Random random = Random();

  String target = '';
  List<String> displayedWords = [];
  int score = 0;

  @override
  void initState() {
    super.initState();
    _generateWords();
  }

  void _generateWords() {
    // 1. Dev havuzdan tamamen RASTGELE ve BENZERSİZ 12 kelime çek
    displayedWords = WordData.getRandomSingleWords(12);

    // 2. Bu 12 kelimeden tam olarak 1 tanesini HEDEF KELİME seç
    target = displayedWords[random.nextInt(12)];

    setState(() {});
  }

  void _selectWord(String word) {
    if (word == target) {
      setState(() {
        score++;
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doğru! 🎯'),
          duration: Duration(milliseconds: 400),
          backgroundColor: Colors.green,
        ),
      );
      // Yeni turda dev havuzdan BATIŞIK/YENİ kelimeler gelsin
      _generateWords();
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yanlış kelime, hedefe tekrar bak! ❌'),
          duration: Duration(milliseconds: 400),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎯 Dikkat Egzersizi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'HEDEF KELİME',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              target,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bulunan: $score',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                itemCount: displayedWords.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () => _selectWord(displayedWords[index]),
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 5,
                          )
                        ],
                      ),
                      child: Text(
                        displayedWords[index],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
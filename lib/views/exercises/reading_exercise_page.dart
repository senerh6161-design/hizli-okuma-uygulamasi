import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/word_data.dart';
import 'attention_exercise_page.dart';

class ReadingExercisePage extends StatefulWidget {
  final int level;

  const ReadingExercisePage({
    super.key,
    required this.level,
  });

  @override
  State<ReadingExercisePage> createState() => _ReadingExercisePageState();
}

class _ReadingExercisePageState extends State<ReadingExercisePage> {
  final Random random = Random();

  Timer? timer;
  Timer? countdownTimer;

  bool running = false;
  bool showRedDot = true;

  int wordIndex = 0;
  int remainingSeconds = 60;
  int wordsRead = 0;

  late int displayMilliseconds;

  @override
  void initState() {
    super.initState();
    displayMilliseconds = _getDisplayTime();
  }

  int _getDisplayTime() {
    switch (widget.level) {
      case 1:
        return 2000;
      case 2:
        return 1500;
      case 3:
        return 1000;
      case 4:
        return 750;
      case 5:
        return 500;
      default:
        return 2000;
    }
  }

  String _currentContent() {
    if (widget.level <= 2) {
      return WordData.singleWords[wordIndex % WordData.singleWords.length];
    }

    if (widget.level <= 4) {
      return WordData.pairs[wordIndex % WordData.pairs.length];
    }

    if (random.nextBool()) {
      return WordData.singleWords[wordIndex % WordData.singleWords.length];
    }

    return WordData.pairs[wordIndex % WordData.pairs.length];
  }

  void startExercise() {
    if (running) return;

    setState(() {
      running = true;
      remainingSeconds = 60;
      wordsRead = 0;
      wordIndex = 0;
    });

    timer = Timer.periodic(
      Duration(milliseconds: displayMilliseconds),
      (_) {
        if (!mounted) return;
        setState(() {
          wordIndex++;
          wordsRead++;
        });
      },
    );

    countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;
        if (remainingSeconds > 1) {
          setState(() {
            remainingSeconds--;
          });
        } else {
          stopExercise();
          _showResult();
        }
      },
    );
  }

  void stopExercise() {
    timer?.cancel();
    countdownTimer?.cancel();
    if (mounted) {
      setState(() {
        running = false;
      });
    }
  }

  void resetExercise() {
    stopExercise();
    setState(() {
      remainingSeconds = 60;
      wordsRead = 0;
      wordIndex = 0;
    });
  }

  void _showResult() {
    int wpm = wordsRead;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text('🎉 Egzersiz Tamamlandı!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _resultRow(Icons.speed, 'Okuma Hızı', '$wpm WPM'),
              _resultRow(Icons.timer, 'Süre', '60 saniye'),
              _resultRow(Icons.emoji_events, 'Seviye', '${widget.level}'),
              const SizedBox(height: 15),
              const Text(
                'Bir sonraki egzersizde dikkat ve hafıza çalışması yapabilirsin.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AttentionExercisePage(),
                  ),
                );
              },
              child: const Text('Dikkat Egzersizine Geç'),
            ),
          ],
        );
      },
    );
  }

  Widget _resultRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo),
          const SizedBox(width: 10),
          Text(title),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seviye ${widget.level} - Hızlı Okuma'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                showRedDot = !showRedDot;
              });
            },
            icon: Icon(
              showRedDot ? Icons.center_focus_strong : Icons.center_focus_weak,
              color: showRedDot ? Colors.red : Colors.grey,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: Column(
              children: [
                Text(
                  'Başınızı ve dudaklarınızı oynatmadan, yalnızca gözlerinizle takip ediniz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kelime gösterim süresi: ${_displayText()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .05),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  if (showRedDot)
                    const Center(
                      child: SizedBox(
                        width: 9,
                        height: 9,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 80),
                      child: Text(
                        running ? _currentContent() : 'BAŞLAT',
                        key: ValueKey(wordIndex),
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 15,
                    left: 15,
                    right: 15,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Seviye ${widget.level}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$remainingSeconds sn',
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 15,
                    left: 15,
                    right: 15,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Okunan: $wordsRead',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'WPM: $wordsRead',
                          style: const TextStyle(
                            color: Colors.indigo,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: running ? stopExercise : startExercise,
                    icon: Icon(running ? Icons.pause : Icons.play_arrow),
                    label: Text(running ? 'DURAKLAT' : 'BAŞLAT'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: resetExercise,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _displayText() {
    if (displayMilliseconds == 2000) return '2 saniye';
    if (displayMilliseconds == 1500) return '1.5 saniye';
    if (displayMilliseconds == 1000) return '1 saniye';
    if (displayMilliseconds == 750) return '0.75 saniye';
    return '0.5 saniye';
  }
}
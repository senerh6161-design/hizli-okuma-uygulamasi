import 'package:flutter/material.dart';
import '../../models/comprehension_data_folder3.dart';
import 'comprehension_page.dart';

/// Klasör 3 oturumuna girince gösterilen ön metin adımı — Klasör 1/2'deki
/// ön metin seviye seçimiyle aynı desen. Çocuk seviyesini seçiyor, o
/// seviyenin gerçek antreman metni ([Folder3ReadingData]) okunuyor ve
/// ardından D/Y sorularıyla anlama kontrol ediliyor.
class Folder3LevelSelectionPage extends StatelessWidget {
  const Folder3LevelSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📖 Seviyeni Seç')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Antreman metnini seviyene uygun bir uyarlamayla okuyacaksın.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.15,
                children: [
                  for (final level in Folder3ReadingData.levels)
                    _LevelCard(
                      emoji: level.emoji,
                      title: level.title,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ComprehensionPage(
                              passage: Folder3ReadingData.passageForLevel(
                                level.id,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final String emoji;
  final String title;
  final VoidCallback onTap;

  const _LevelCard({
    required this.emoji,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../widgets/home_widgets.dart';
import '../../models/progress_manager.dart';
import '../../models/achievement.dart';
import '../levels/school_level_selection_page.dart';
import '../levels/wpm_test_page.dart';
import '../exercises/eye_coordination_page.dart';
import '../exercises/topic_selection_page.dart';
import '../leaderboard/leaderboard_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isEyeCoordinationDone = false;
  bool isReadingDone = false;
  bool isComprehensionDone = false;

  void _showAchievementSnackBar(List<Achievement> unlocked) {
    final names = unlocked.map((a) => a.title).join(', ');
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🏆 Yeni başarım: $names'),
        backgroundColor: Colors.amber.shade800,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hızlı Okuma Lab',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WelcomeCard(),
            const SizedBox(height: 20),

            const Text(
              'Bugünkü Durum',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // DİNAMİK SERVİSTEN ÇEKİLEN KARTLAR
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'WPM',
                    value: '${ProgressManager.wpm}',
                    icon: Icons.speed,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Anlama',
                    value: '%${ProgressManager.comprehensionRate}',
                    icon: Icons.menu_book,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Seviye',
                    value: '${ProgressManager.currentLevel}',
                    icon: Icons.emoji_events,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Tamamlanan',
                    value: '${ProgressManager.completedExercises}',
                    icon: Icons.check_circle_outline,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // LİDERLİK TABLOSU GİRİŞİ
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LeaderboardPage()),
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bugün en çok kim okudu? Liderlik tablosuna bak! 🏆',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            const Text(
              'Bugünkü Çalışma',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // GÖREVLER
            InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EyeCoordinationPage()),
                );
                final unlocked = ProgressManager.addCompletedExercise(
                  type: 'Göz Koordinasyonu',
                  result: 'Isınma turu',
                );
                setState(() => isEyeCoordinationDone = true);
                if (unlocked.isNotEmpty && mounted) {
                  _showAchievementSnackBar(unlocked);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: DailyTaskTile(
                icon: Icons.visibility_outlined,
                title: 'Göz Koordinasyonu',
                subtitle: 'Kelimelere geçmeden önce gözleri ısıt',
                completed: isEyeCoordinationDone,
              ),
            ),

            InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WpmTestPage()),
                );
                setState(() {});
              },
              borderRadius: BorderRadius.circular(16),
              child: DailyTaskTile(
                icon: Icons.speed_rounded,
                title: 'Seviyeni Ölç',
                subtitle: ProgressManager.personalWpmBaseline != null
                    ? 'Kişisel hızın: ~${ProgressManager.personalWpmBaseline} WPM · Tekrar ölç'
                    : 'Gerçek okuma hızını ölç, seviyeler sana göre ayarlansın',
                completed: ProgressManager.personalWpmBaseline != null,
              ),
            ),

            InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SchoolLevelSelectionPage()),
                );
                setState(() => isReadingDone = true);
              },
              borderRadius: BorderRadius.circular(16),
              child: DailyTaskTile(
                icon: Icons.menu_book,
                title: 'Hızlı Okuma',
                subtitle: '5 dakika antrenman',
                completed: isReadingDone,
              ),
            ),

            InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TopicSelectionPage()),
                );
                // ComprehensionPage artık kendi gerçek sonucunu (% doğru ve
                // hız çarpanı etkisiyle birlikte) ProgressManager'a kaydediyor.
                // Burada tekrar sahte "Tamamlandı" kaydı EKLEMİYORUZ, yoksa
                // tek bir test iki kez sayılır.
                setState(() {
                  isComprehensionDone = true;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: DailyTaskTile(
                icon: Icons.quiz,
                title: 'Anlama Testi',
                subtitle: 'İlgi alanına göre konu seç, okuduğunu kavrama ölçümü',
                completed: isComprehensionDone,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

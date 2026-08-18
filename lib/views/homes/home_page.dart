import 'package:flutter/material.dart';
import '../../widgets/home_widgets.dart';
import '../../models/progress_manager.dart';
import '../leaderboard/leaderboard_page.dart';

class HomePage extends StatefulWidget {
  // Egzersizler sekmesine geçiş için MainNavigation'dan verilen callback.
  final VoidCallback? onNavigateToExercises;

  const HomePage({super.key, this.onNavigateToExercises});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _blue = Color(0xFF2563EB);
  static const _teal = Color(0xFF0D9488);
  static const _emerald = Color(0xFF059669);
  static const _rose = Color(0xFFE11D48);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Hızlı Okuma Lab',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF8FAFC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WelcomeCard(streak: ProgressManager.currentStreak),
            const SizedBox(height: 24),

            _SectionHeader(icon: Icons.insights_rounded, title: 'Bugünkü Durum', color: _blue),
            const SizedBox(height: 12),

            // DİNAMİK SERVİSTEN ÇEKİLEN KARTLAR
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'WPM',
                    value: '${ProgressManager.wpm}',
                    icon: Icons.speed_rounded,
                    color: _blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Anlama',
                    value: '%${ProgressManager.comprehensionRate}',
                    icon: Icons.menu_book_rounded,
                    color: _teal,
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
                    icon: Icons.emoji_events_rounded,
                    color: _rose,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Tamamlanan',
                    value: '${ProgressManager.completedExercises}',
                    icon: Icons.check_circle_rounded,
                    color: _emerald,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // SEVİYE İLERLEME ÇUBUĞU
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Seviye ${ProgressManager.currentLevel}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                      Text('%${(ProgressManager.levelProgress * 100).round()}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _blue)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: ProgressManager.levelProgress.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: _blue.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation(_blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // LİDERLİK TABLOSU GİRİŞİ
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LeaderboardPage()),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE11D48), Color(0xFFFB7185)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE11D48).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.emoji_events_rounded, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bugün en çok kim okudu? Liderlik tablosuna bak! 🏆',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            _SectionHeader(icon: Icons.local_fire_department_rounded, title: 'Bugünkü Çalışma', color: _teal),
            const SizedBox(height: 12),

            InkWell(
              onTap: widget.onNavigateToExercises,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0369A1), Color(0xFF0D9488)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0369A1).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.psychology_rounded, color: Colors.white, size: 32),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Klasör 1\'e Git',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Göz koordinasyonundan kelimelerle saklambaça, tüm etkinlikler burada',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
      ],
    );
  }
}

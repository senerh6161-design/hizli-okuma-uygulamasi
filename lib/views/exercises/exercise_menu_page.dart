import 'package:flutter/material.dart';
import '../levels/school_level_selection_page.dart';
import 'attention_exercise_page.dart';
import 'memory_exercise_page.dart';
import 'topic_selection_page.dart';
import 'schulte_table_page.dart';
import 'visual_match_page.dart';

class ExerciseMenuPage extends StatelessWidget {
  const ExerciseMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Egzersiz Laboratuvarı',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ÜST BİLGİ KARTI
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.amber, size: 36),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Günlük Antrenman',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Odak ve okuma hızını artırmak için farklı modları deneyin.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Okuma & Algı Modları',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),

            // EGZERSİZ GRID LİSTESİ
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.85,
              children: [
                _buildGridCard(
                  context,
                  title: 'Hızlı Okuma',
                  subtitle: 'Eğitim Seviyeli',
                  badge: 'İlkokul-Lise',
                  badgeColor: Colors.indigo,
                  icon: Icons.speed,
                  color: const Color(0xFF4F46E5),
                  page: const SchoolLevelSelectionPage(), // İLKOKUL/LİSE SEÇİM EKRANI
                ),
                _buildGridCard(
                  context,
                  title: 'Dikkat Avcısı',
                  subtitle: 'Kelime Matrisi',
                  badge: 'Odak',
                  badgeColor: Colors.orange,
                  icon: Icons.remove_red_eye,
                  color: Colors.orange,
                  page: const AttentionExercisePage(),
                ),
                _buildGridCard(
                  context,
                  title: 'Schulte Grid',
                  subtitle: '5x5 Odak Tablosu',
                  badge: 'Popüler',
                  badgeColor: Colors.teal,
                  icon: Icons.grid_on,
                  color: Colors.teal,
                  page: const SchulteTablePage(),
                ),
                _buildGridCard(
                  context,
                  title: 'Görsel Hafıza',
                  subtitle: 'Anlık Hatırlama',
                  badge: 'Hafıza',
                  badgeColor: Colors.purple,
                  icon: Icons.psychology,
                  color: Colors.purple,
                  page: const MemoryExercisePage(),
                ),
                _buildGridCard(
                  context,
                  title: 'Anlama Testi',
                  subtitle: 'Konu Seç & Kavra',
                  badge: 'Test',
                  badgeColor: Colors.green,
                  icon: Icons.quiz,
                  color: Colors.green,
                  page: const TopicSelectionPage(),
                ),
                _buildGridCard(
                 context,
                 title: 'Görsel Eşleştirme',
                 subtitle: 'Çift Bulma Oyunu',
                 badge: 'Çocuk & Genç',
                 badgeColor: Colors.pink,
                 icon: Icons.extension,
                 color: Colors.pink,
                page: const VisualMatchPage(),
             ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required Color color,
    required Widget page,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Row(
                children: const [
                  Text(
                    'Başla',
                    style: TextStyle(
                      color: Color(0xFF4F46E5),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF4F46E5)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

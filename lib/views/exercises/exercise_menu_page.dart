import 'package:flutter/material.dart';
import '../../models/school_level.dart';
import '../levels/level_page.dart';
import 'topic_selection_page.dart';
import 'schulte_table_page.dart';
import 'eye_coordination_page.dart';
import 'circular_sequence_page.dart';
import 'arrow_word_cycle_page.dart';
import 'growing_words_page.dart';
import 'attention_questions_page.dart';
import 'city_anagram_test_page.dart';
import 'word_hide_seek_page.dart';
import 'object_flow_counting_page.dart';
import 'word_flow_counting_page.dart';
import 'folder1_session_page.dart';

class ExerciseMenuPage extends StatelessWidget {
  const ExerciseMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Klasör 1',
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
                  colors: [Color(0xFF2563EB), Color(0xFF0D9488)],
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
            const SizedBox(height: 16),

            // TAM OTURUM: ÖN METİN -> 8 ETKİNLİK -> SON METİN -> D/Y -> SONUÇ
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Folder1SessionPage()),
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.play_circle_fill, color: Colors.white, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Oturumu Başlat',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Ön metin → 10 etkinlik → son metin → D/Y → hız + dikkat puanı',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Etkinlikler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Öğretmenin belirlediği sırayla, Etkinlik 1\'den başla',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 12),

            // ÖĞRETMENİN SIRALADIĞI ETKİNLİKLER
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
                  title: 'Göz Koordinasyonu',
                  subtitle: 'Yön Takip Isınması',
                  badge: 'Etkinlik 1',
                  badgeColor: Color(0xFF2563EB),
                  icon: Icons.visibility_outlined,
                  color: Color(0xFF2563EB),
                  page: const EyeCoordinationPage(),
                ),
                _buildGridCard(
                  context,
                  title: 'Hızlı Okuma',
                  subtitle: 'Eğitim Seviyeli',
                  badge: 'Etkinlik 2',
                  badgeColor: Color(0xFF2563EB),
                  icon: Icons.speed,
                  color: const Color(0xFF2563EB),
                  page: LevelPage(schoolLevel: SchoolLevelConfig.levels[1]),
                ),
                _buildGridCard(
                  context,
                  title: 'Dairesel Sıralama',
                  subtitle: 'Sayılar (1-12, 1-20)',
                  badge: 'Etkinlik 3',
                  badgeColor: Colors.deepPurple,
                  icon: Icons.donut_large,
                  color: Colors.deepPurple,
                  page: const CircularSequencePage(
                    availableModes: [CircularMode.numbers12, CircularMode.numbers20],
                    appBarTitle: '🔄 Dairesel Sıralama (Sayılar)',
                  ),
                ),
                _buildGridCard(
                  context,
                  title: 'Dairesel Gün/Ay',
                  subtitle: 'Sıralama',
                  badge: 'Etkinlik 4',
                  badgeColor: Colors.deepPurple,
                  icon: Icons.calendar_month,
                  color: Colors.deepPurple,
                  page: const CircularSequencePage(
                    availableModes: [CircularMode.days, CircularMode.months],
                    appBarTitle: '🔄 Dairesel Gün/Ay Sıralama',
                  ),
                ),
                _buildGridCard(
                  context,
                  title: 'Kelime Döngüsü',
                  subtitle: 'Ok Yönünde Oku',
                  badge: 'Etkinlik 5',
                  badgeColor: Colors.blue,
                  icon: Icons.sync,
                  color: Colors.blue,
                  page: const ArrowWordCyclePage(),
                ),
                _buildGridCard(
                  context,
                  title: 'Uzayan Kelimeler',
                  subtitle: 'Hızlanan Okuma',
                  badge: 'Etkinlik 6',
                  badgeColor: Colors.cyan,
                  icon: Icons.expand,
                  color: Colors.cyan,
                  page: const GrowingWordsPage(),
                ),
                _buildGridCard(
                  context,
                  title: 'Dikkat Soruları',
                  subtitle: 'Harf Bulmacaları',
                  badge: 'Etkinlik 7',
                  badgeColor: Colors.orange,
                  icon: Icons.help_center,
                  color: Colors.orange,
                  page: const AttentionQuestionsPage(),
                ),
                _buildGridCard(
                  context,
                  title: 'Nesne Akışı',
                  subtitle: 'Kaç Kez Geçti?',
                  badge: 'Etkinlik 8',
                  badgeColor: Colors.brown,
                  icon: Icons.category,
                  color: Colors.brown,
                  page: const ObjectFlowCountingPage(),
                ),
                _buildGridCard(
                  context,
                  title: 'Kelime Akışı',
                  subtitle: 'Kaç Kez Geçti?',
                  badge: 'Etkinlik 9',
                  badgeColor: Colors.lightBlue,
                  icon: Icons.waves,
                  color: Colors.lightBlue,
                  page: const WordFlowCountingPage(),
                ),
                _buildGridCard(
                  context,
                  title: 'Kelimelerle Saklambaç',
                  subtitle: 'Yeni Kelime Bul',
                  badge: 'Etkinlik 10',
                  badgeColor: Colors.pink,
                  icon: Icons.extension,
                  color: Colors.pink,
                  page: const WordHideSeekPage(),
                ),
              ],
            ),
            const SizedBox(height: 28),

            const Text(
              'Ekstra & Ölçüm',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Numaralı 10 etkinliğin dışında, istersen ek pratik',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 12),

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
                  title: 'Şehir Anagramı',
                  subtitle: 'Dikkat Testi',
                  badge: 'Bonus',
                  badgeColor: Colors.redAccent,
                  icon: Icons.location_city,
                  color: Colors.redAccent,
                  page: const CityAnagramTestPage(),
                ),
                _buildGridCard(
                  context,
                  title: 'Anlama Testi',
                  subtitle: 'Konu Seç & D/Y Yanıtla',
                  badge: 'D/Y Test',
                  badgeColor: Colors.green,
                  icon: Icons.quiz,
                  color: Colors.green,
                  page: const TopicSelectionPage(),
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
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF2563EB)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

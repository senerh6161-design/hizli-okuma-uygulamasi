import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/achievement.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📈 İlerlemem'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GÜNLÜK SERİ KARTI
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ProgressManager.currentStreak > 0
                              ? '${ProgressManager.currentStreak} günlük seri'
                              : 'Seriye henüz başlamadın',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'En uzun serin: ${ProgressManager.longestStreak} gün',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            const Text(
              'Genel Performans',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // DİNAMİK VERİ KARTLARI
            _progressCard('Ortalama WPM', '${ProgressManager.wpm}', Icons.speed, Colors.indigo),
            _progressCard('Anlama Oranı', '%${ProgressManager.comprehensionRate}', Icons.menu_book, Colors.green),
            _progressCard('Dikkat Başarısı', '%${ProgressManager.attentionSuccess}', Icons.visibility, Colors.orange),
            _progressCard('Tamamlanan Egzersiz', '${ProgressManager.completedExercises}', Icons.check_circle, Colors.purple),

            const SizedBox(height: 25),
            const Text(
              'Seviye İlerlemesi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // CANLI İLERLEME ÇUBUĞU
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Seviye ${ProgressManager.currentLevel}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('%${(ProgressManager.levelProgress * 100).round()}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: ProgressManager.levelProgress > 1.0 ? 1.0 : ProgressManager.levelProgress,
                    minHeight: 10,
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Bir sonraki seviyeye ulaşmak için ${((1.0 - ProgressManager.levelProgress) * 10).round()} egzersiz daha tamamla.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Başarımlar',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${ProgressManager.unlockedAchievementIds.length}/${Achievement.all.length}',
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // BAŞARIM ROZETLERİ IZGARASI
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: Achievement.all.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final achievement = Achievement.all[index];
                final isUnlocked = ProgressManager.unlockedAchievementIds.contains(achievement.id);

                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isUnlocked ? Colors.amber.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isUnlocked ? Colors.amber.shade300 : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        achievement.icon,
                        size: 26,
                        color: isUnlocked ? Colors.amber.shade800 : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        achievement.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? Colors.amber.shade900 : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 25),
            const Text(
              'Son Çalışmalar',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // DİNAMİK GEÇMİŞ LİSTESİ
            ...ProgressManager.history.map((item) {
              return _historyItem(item['title']!, item['result']!, item['date']!);
            }),
          ],
        ),
      ),
    );
  }

  Widget _progressCard(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: .12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
    );
  }

  Widget _historyItem(String title, String result, String isoDate) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(_relativeLabel(isoDate), style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(
            result,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
        ],
      ),
    );
  }

  // Kayıt anında gerçek bir ISO zaman damgası saklanıyor (bkz.
  // ProgressManager); burada, o an geçerli olan aradan ne kadar süre
  // geçtiğine göre okunabilir bir etiket üretilir — "Şimdi" artık her
  // kayıtta sabit değil, gerçekten yeni olanlarda gösterilir.
  String _relativeLabel(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate; // eski/tanınmayan biçim, olduğu gibi göster
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return 'Şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} sa önce';
    if (diff.inDays == 1) return 'Dün';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
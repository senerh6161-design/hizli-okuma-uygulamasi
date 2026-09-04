import 'package:flutter/material.dart';
import 'attention_question2_page.dart';
import 'book_title_scan_page.dart';
import 'exam_word_group_scan_page.dart';
import 'hidden_words_page.dart';
import 'missing_school_item_page.dart';
import 'number_recall_grid_page.dart';
import 'sentence_builder_page.dart';
import 'teacher_manifesto_scan_page.dart';
import 'word_pattern_scan_page.dart';

class _Folder4Activity {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color color;
  final Widget Function()? build; // null ise henüz hazır değil
  const _Folder4Activity({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.color,
    this.build,
  });
}

/// Klasör 4'ün oturum ekranı. Klasör 3 başlangıçta böyleydi: hoca kitaptan
/// yeni sayfalar paylaştıkça etkinlikler tek tek eklenir. Henüz gerçek Ön
/// Metin/Son Metin içeriği olmadığından basit bir etkinlik listesi —
/// yeterince içerik biriktiğinde Klasör 1/2/3'teki gibi tam oturum akışına
/// (Ön Metin → etkinlikler → Antreman → Son Metin → Sonuç) geçirilecek.
class Folder4SessionPage extends StatelessWidget {
  const Folder4SessionPage({super.key});

  static final List<_Folder4Activity> _activities = [
    _Folder4Activity(
      title: 'Kelime Kalıpları Tarama',
      subtitle: '1. Bölüm: 5 sayfa 4 yön tarama · 2. Bölüm: dikey odak okuma',
      badge: 'Etkinlik 1',
      icon: Icons.grid_view_rounded,
      color: const Color(0xFF0369A1),
      build: () => const WordPatternScanPage(),
    ),
    _Folder4Activity(
      title: 'Saklı Kelimeler',
      subtitle: 'İç içe geçmiş gizli kelimeleri bul, işaretle, puan topla',
      badge: 'Etkinlik 2',
      icon: Icons.search_rounded,
      color: const Color(0xFFDB2777),
      build: () => const HiddenWordsPage(),
    ),
    _Folder4Activity(
      title: 'Dikkat Sorusu',
      subtitle: '1. Bölüm: yazılabilir mi? · 2. Bölüm: karışık harfler',
      badge: 'Etkinlik 3',
      icon: Icons.psychology_alt_rounded,
      color: const Color(0xFF16A34A),
      build: () => const AttentionQuestion2Page(),
    ),
    _Folder4Activity(
      title: 'Sınav Kelimeleri',
      subtitle: '8 sayfa 4 yön tara, sonra kaç kere geçti sorularını çöz',
      badge: 'Etkinlik 4',
      icon: Icons.menu_book_rounded,
      color: const Color(0xFF9333EA),
      build: () => const ExamWordGroupScanPage(),
    ),
    _Folder4Activity(
      title: 'Cümle Kur',
      subtitle: 'Dağınık kelime kutucuklarına doğru sırayla dokun',
      badge: 'Etkinlik 5',
      icon: Icons.hub_rounded,
      color: const Color(0xFF0D9488),
      build: () => const SentenceBuilderPage(),
    ),
    _Folder4Activity(
      title: 'Nerede Gördüm? (Sayılar)',
      subtitle: '3 basamaklı sayı karesinde gördüğün yeri hızlıca bul',
      badge: 'Etkinlik 6',
      icon: Icons.grid_view_rounded,
      color: const Color(0xFFDC2626),
      build: () => const NumberRecallGridPage(),
    ),
    _Folder4Activity(
      title: 'Ben Bir Öğretmenim',
      subtitle: '5 sayfa, 4 yönde bölünmüş metni tara',
      badge: 'Etkinlik 7',
      icon: Icons.menu_book_rounded,
      color: const Color(0xFF15803D),
      build: () => const TeacherManifestoScanPage(),
    ),
    _Folder4Activity(
      title: 'Eksik Kelimeyi Bul',
      subtitle: '6 kelimeyi ezberle, her satırda eksik olanı hızlıca bul',
      badge: 'Etkinlik 8',
      icon: Icons.search_off_rounded,
      color: const Color(0xFF0D9488),
      build: () => const MissingSchoolItemPage(),
    ),
    _Folder4Activity(
      title: 'Kitap Adları Taraması',
      subtitle: 'Antreman sonra bir kitabın kaç kere geçtiğini bul',
      badge: 'Etkinlik 9',
      icon: Icons.library_books_rounded,
      color: const Color(0xFFB45309),
      build: () => const BookTitleScanPage(),
    ),
    const _Folder4Activity(
      title: 'Yakında',
      subtitle: 'Hoca yeni sayfayı paylaşınca eklenecek',
      badge: 'Etkinlik 10',
      icon: Icons.lock_outline,
      color: Colors.grey,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final readyCount = _activities.where((a) => a.build != null).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Klasör 4')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0369A1), Color(0xFF0D9488)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                '$readyCount/${_activities.length} egzersiz hazır',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                itemCount: _activities.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _ActivityCard(activity: _activities[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final _Folder4Activity activity;
  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final ready = activity.build != null;
    return Card(
      elevation: ready ? 2 : 0,
      color: ready ? Colors.white : Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: ready ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: ready
            ? () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => activity.build!()),
              )
            : () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bu etkinlik yakında eklenecek 🔒'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: activity.color.withValues(
                  alpha: ready ? 0.12 : 0.08,
                ),
                child: Icon(
                  activity.icon,
                  color: ready ? activity.color : Colors.grey,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.badge,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: ready ? activity.color : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activity.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: ready
                            ? const Color(0xFF0F172A)
                            : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activity.subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                ready ? Icons.arrow_forward_rounded : Icons.lock_outline,
                color: ready ? activity.color : Colors.grey,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

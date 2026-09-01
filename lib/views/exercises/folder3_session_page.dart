import 'package:flutter/material.dart';
import 'color_word_match_page.dart';
import 'column_reading_page.dart';
import 'focus_box_page.dart';
import 'four_direction_scan_page.dart';
import 'number_hunt_page.dart';
import 'folder3_level_selection_page.dart';
import 'proverb_matching_page.dart';
import 'scrambled_letters_page.dart';
import 'synonym_antonym_page.dart';
import 'word_pair_scan_page.dart';

class _Folder3Activity {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color color;
  final Widget Function()? build; // null = henüz hazır değil
  const _Folder3Activity({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.color,
    this.build,
  });
}

/// Klasör 3'ün etkinlik listesi. Klasör 1/2'deki gibi tam bir ön
/// metin/etkinlikler/son metin oturumu DEĞİL — hoca henüz Klasör 3 için
/// sabit bir ön/son metin paylaşmadı, o yüzden etkinlikler tek tek
/// açılıyor. Ama Klasör 1/2'deki gibi: oturuma girilince önce bir giriş
/// ekranı, ardından Klasör 1/2'deki ön metin seviye seçimiyle aynı desen
/// ([Folder3LevelSelectionPage] — seviye seç, o seviyenin gerçek antreman
/// metnini oku) gösteriliyor; ardından etkinlik listesine geçiliyor.
class Folder3SessionPage extends StatefulWidget {
  const Folder3SessionPage({super.key});

  @override
  State<Folder3SessionPage> createState() => _Folder3SessionPageState();
}

class _Folder3SessionPageState extends State<Folder3SessionPage> {
  static final List<_Folder3Activity> _activities = [
    _Folder3Activity(
      title: 'Eş ve Zıt Anlamlı Kelimeler',
      subtitle: 'Kelime kutucuklarını hızlı tara',
      badge: 'Etkinlik 1',
      icon: Icons.compare_arrows_rounded,
      color: const Color(0xFF15803D),
      build: () => const SynonymAntonymPage(),
    ),
    _Folder3Activity(
      title: 'Sayı Avı',
      subtitle: '1\'den 30\'a kadar sayıları bul',
      badge: 'Etkinlik 2',
      icon: Icons.pin_rounded,
      color: const Color(0xFF1D4ED8),
      build: () => const NumberHuntPage(),
    ),
    _Folder3Activity(
      title: 'Dört Yönlü Kelime Taraması',
      subtitle: 'Soldan sağa, sağdan sola, aşağı, yukarı tara',
      badge: 'Etkinlik 3',
      icon: Icons.explore_rounded,
      color: const Color(0xFF7C3AED),
      build: () => const FourDirectionScanPage(),
    ),
    _Folder3Activity(
      title: 'Karışık Harfler',
      subtitle: '9 harfi birleştir, kelimeyi bul',
      badge: 'Etkinlik 4',
      icon: Icons.spellcheck_rounded,
      color: const Color(0xFF0D9488),
      build: () => const ScrambledLettersPage(),
    ),
    _Folder3Activity(
      title: 'Atasözü Eşleştirme',
      subtitle: 'Atasözünün doğru yarısını bul',
      badge: 'Etkinlik 5',
      icon: Icons.menu_book_rounded,
      color: const Color(0xFFDB2777),
      build: () => const ProverbMatchingPage(),
    ),
    _Folder3Activity(
      title: 'Renk Uyumu',
      subtitle: 'Rengiyle uyuşmayan kelimeyi hızlıca bul',
      badge: 'Etkinlik 6',
      icon: Icons.palette_rounded,
      color: const Color(0xFFEA580C),
      build: () => const ColorWordMatchPage(),
    ),
    _Folder3Activity(
      title: 'Sütun Takibi',
      subtitle: 'Metni sütun sütun, yukarıdan aşağıya oku',
      badge: 'Etkinlik 7',
      icon: Icons.view_column_rounded,
      color: const Color(0xFF4338CA),
      build: () => const ColumnReadingPage(),
    ),
    _Folder3Activity(
      title: 'Odaklanma Kutucukları',
      subtitle: 'Yanıp sönen kutucuğu soldan sağa takip et',
      badge: 'Etkinlik 8',
      icon: Icons.center_focus_strong_rounded,
      color: const Color(0xFFB91C1C),
      build: () => const FocusBoxPage(),
    ),
    _Folder3Activity(
      title: 'Kelime Çiftleri Tarama',
      subtitle: '3 sayfa, 4 yönde kelime çifti tara',
      badge: 'Etkinlik 9',
      icon: Icons.grid_view_rounded,
      color: const Color(0xFF65A30D),
      build: () => const WordPairScanPage(),
    ),
    const _Folder3Activity(
      title: 'Yakında Eklenecek',
      subtitle: 'Hoca yeni etkinlik paylaşınca hazır olacak',
      badge: 'Etkinlik 10',
      icon: Icons.lock_outline,
      color: Colors.grey,
    ),
  ];

  final Set<int> _activityDone = {};
  bool _started = false;

  Future<void> _openActivity(int index) async {
    final activity = _activities[index];
    if (activity.build == null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${activity.title} 🔒'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => activity.build!()),
    );
    if (!mounted) return;
    if (completed == true) {
      setState(() => _activityDone.add(index));
    }
  }

  Future<void> _goToLevelPick() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const Folder3LevelSelectionPage()),
    );
    if (!mounted) return;
    setState(() => _started = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Klasör 3')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _started ? _buildActivityList() : _buildIntro(),
      ),
    );
  }

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0369A1), Color(0xFF15803D)],
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.folder_open,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Klasör 3 Oturumu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Önce seviyene uygun bir antreman metni okuyacaksın,\n'
                'sonra 10 etkinliğe geçeceğiz.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _goToLevelPick,
            icon: const Icon(Icons.play_arrow),
            label: const Text(
              'BAŞLA',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0369A1),
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: const Color(0xFF0369A1).withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '10 Etkinlik',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_activityDone.length}/${_activities.length} tamamlandı',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: _activities.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _activityCard(index),
          ),
        ),
      ],
    );
  }

  Widget _activityCard(int index) {
    final activity = _activities[index];
    final locked = activity.build == null;
    final done = _activityDone.contains(index);
    final color = done
        ? const Color(0xFF16A34A)
        : (locked ? Colors.grey : activity.color);
    return Card(
      elevation: locked ? 0 : 2,
      color: locked ? Colors.grey.shade100 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: locked
            ? BorderSide(color: Colors.grey.shade300)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openActivity(index),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(
                  done ? Icons.check_circle : activity.icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            activity.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: locked
                                  ? Colors.grey.shade500
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            activity.badge,
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
              const SizedBox(width: 10),
              if (locked)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Yakında',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      done ? 'Tamamlandı' : 'Aç',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (!done) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: color),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

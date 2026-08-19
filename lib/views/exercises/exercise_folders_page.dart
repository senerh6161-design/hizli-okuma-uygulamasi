import 'package:flutter/material.dart';
import 'folder1_session_page.dart';

class _FolderInfo {
  final int number;
  final String title;
  final bool isUnlocked;
  final int readyCount;
  final int totalCount;

  const _FolderInfo({
    required this.number,
    required this.title,
    required this.isUnlocked,
    required this.readyCount,
    required this.totalCount,
  });
}

/// Egzersizler sekmesinin giriş ekranı: toplamda 10 klasör (her biri 10
/// egzersiz, toplam 100 egzersiz) planlanıyor. Şu an yalnızca Klasör 1
/// içeriği hazır; diğerleri hoca yeni etkinlikleri paylaştıkça açılacak.
class ExerciseFoldersPage extends StatelessWidget {
  const ExerciseFoldersPage({super.key});

  static const List<_FolderInfo> _folders = [
    _FolderInfo(number: 1, title: 'Klasör 1', isUnlocked: true, readyCount: 10, totalCount: 10),
    _FolderInfo(number: 2, title: 'Klasör 2', isUnlocked: false, readyCount: 0, totalCount: 10),
    _FolderInfo(number: 3, title: 'Klasör 3', isUnlocked: false, readyCount: 0, totalCount: 10),
    _FolderInfo(number: 4, title: 'Klasör 4', isUnlocked: false, readyCount: 0, totalCount: 10),
    _FolderInfo(number: 5, title: 'Klasör 5', isUnlocked: false, readyCount: 0, totalCount: 10),
    _FolderInfo(number: 6, title: 'Klasör 6', isUnlocked: false, readyCount: 0, totalCount: 10),
    _FolderInfo(number: 7, title: 'Klasör 7', isUnlocked: false, readyCount: 0, totalCount: 10),
    _FolderInfo(number: 8, title: 'Klasör 8', isUnlocked: false, readyCount: 0, totalCount: 10),
    _FolderInfo(number: 9, title: 'Klasör 9', isUnlocked: false, readyCount: 0, totalCount: 10),
    _FolderInfo(number: 10, title: 'Klasör 10', isUnlocked: false, readyCount: 0, totalCount: 10),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Egzersizler', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  Icon(Icons.folder_special, color: Colors.amber, size: 36),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '10 Klasör, 100 Egzersiz',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Her klasörde 10 egzersiz olacak. Şimdilik Klasör 1 açık.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: _folders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _FolderCard(folder: _folders[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final _FolderInfo folder;
  const _FolderCard({required this.folder});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: folder.isUnlocked ? 2 : 0,
      color: folder.isUnlocked ? Colors.white : Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: folder.isUnlocked
            ? BorderSide.none
            : BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (folder.isUnlocked) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Folder1SessionPage()),
            );
          } else {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${folder.title} yakında eklenecek 🔒'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: (folder.isUnlocked ? const Color(0xFF2563EB) : Colors.grey)
                    .withValues(alpha: 0.12),
                child: Icon(
                  folder.isUnlocked ? Icons.folder_open : Icons.lock_outline,
                  color: folder.isUnlocked ? const Color(0xFF2563EB) : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: folder.isUnlocked ? const Color(0xFF0F172A) : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      folder.isUnlocked
                          ? '${folder.readyCount}/${folder.totalCount} egzersiz hazır'
                          : '${folder.totalCount} egzersiz',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (folder.isUnlocked)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Aç',
                      style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF2563EB)),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Yakında',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

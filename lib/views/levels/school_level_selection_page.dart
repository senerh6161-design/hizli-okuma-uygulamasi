import 'package:flutter/material.dart';
import '../../models/school_level.dart';
import 'level_page.dart';

class SchoolLevelSelectionPage extends StatelessWidget {
  const SchoolLevelSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final levels = SchoolLevelConfig.levels;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eğitim Seviyesi Seçin'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: levels.length,
        itemBuilder: (context, index) {
          final level = levels[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 3,
            child: ListTile(
              contentPadding: const EdgeInsets.all(18),
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.12),
                child: Icon(
                  index == 0
                      ? Icons.child_care
                      : index == 1
                          ? Icons.school
                          : index == 2
                              ? Icons.cast_for_education
                              : Icons.psychology,
                  color: const Color(0xFF2563EB),
                ),
              ),
              title: Text(
                level.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(level.description),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LevelPage(schoolLevel: level),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
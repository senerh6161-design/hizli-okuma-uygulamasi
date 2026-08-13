enum EducationLevel { ilkokul, ortaokul, lise, yetiskin }

class SchoolLevelConfig {
  final EducationLevel level;
  final String title;
  final String description;
  final int defaultWpm;
  final double fontSize;

  const SchoolLevelConfig({
    required this.level,
    required this.title,
    required this.description,
    required this.defaultWpm,
    required this.fontSize,
  });

  static List<SchoolLevelConfig> get levels => const [
        SchoolLevelConfig(
          level: EducationLevel.ilkokul,
          title: 'İlkokul (1-4. Sınıf)',
          description: 'Büyük yazı boyutu, temel kelimeler ve yavaş tempo (100-200 WPM)',
          defaultWpm: 150,
          fontSize: 44,
        ),
        SchoolLevelConfig(
          level: EducationLevel.ortaokul,
          title: 'Ortaokul (5-8. Sınıf)',
          description: 'Orta boy kelimeler, ikili öbekler (200-350 WPM)',
          defaultWpm: 250,
          fontSize: 38,
        ),
        SchoolLevelConfig(
          level: EducationLevel.lise,
          title: 'Lise & LGS/YKS',
          description: 'Uzun metinler, hızlı takistoskop (350-500 WPM)',
          defaultWpm: 380,
          fontSize: 32,
        ),
        SchoolLevelConfig(
          level: EducationLevel.yetiskin,
          title: 'Yetişkin / İleri',
          description: 'Maksimum odaklanma ve yüksek WPM antrenmanları (500+ WPM)',
          defaultWpm: 500,
          fontSize: 30,
        ),
      ];
}
import 'package:flutter/material.dart';
import 'progress_manager.dart';

/// Tek bir başarım (rozet) tanımı. isUnlocked, ProgressManager'ın GÜNCEL
/// durumuna bakarak açık olup olmadığını anlık hesaplar — ayrı bir "kayıtlı
/// durum" tutmuyor, ProgressManager.unlockedAchievementIds o işi yapıyor.
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool Function() isUnlocked;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
  });

  static List<Achievement> get all => [
        Achievement(
          id: 'first_step',
          title: 'İlk Adım',
          description: 'İlk egzersizini tamamladın',
          icon: Icons.flag_rounded,
          isUnlocked: () => ProgressManager.completedExercises >= 1,
        ),
        Achievement(
          id: 'five_exercises',
          title: 'Isınıyorsun',
          description: '5 egzersiz tamamladın',
          icon: Icons.local_fire_department_rounded,
          isUnlocked: () => ProgressManager.completedExercises >= 5,
        ),
        Achievement(
          id: 'twenty_exercises',
          title: 'Azimli',
          description: '20 egzersiz tamamladın',
          icon: Icons.military_tech_rounded,
          isUnlocked: () => ProgressManager.completedExercises >= 20,
        ),
        Achievement(
          id: 'fifty_exercises',
          title: 'Efsane',
          description: '50 egzersiz tamamladın',
          icon: Icons.workspace_premium_rounded,
          isUnlocked: () => ProgressManager.completedExercises >= 50,
        ),
        Achievement(
          id: 'streak_3',
          title: '3 Gün Seri',
          description: '3 gün üst üste çalıştın',
          icon: Icons.whatshot_rounded,
          isUnlocked: () => ProgressManager.currentStreak >= 3,
        ),
        Achievement(
          id: 'streak_7',
          title: 'Bir Hafta Seri',
          description: '7 gün üst üste çalıştın',
          icon: Icons.whatshot_rounded,
          isUnlocked: () => ProgressManager.currentStreak >= 7,
        ),
        Achievement(
          id: 'streak_30',
          title: 'Aylık Şampiyon',
          description: '30 gün üst üste çalıştın',
          icon: Icons.emoji_events_rounded,
          isUnlocked: () => ProgressManager.currentStreak >= 30,
        ),
        Achievement(
          id: 'wpm_200',
          title: '200 WPM',
          description: '200 kelime/dakika hıza ulaştın',
          icon: Icons.speed_rounded,
          isUnlocked: () => ProgressManager.wpm >= 200,
        ),
        Achievement(
          id: 'wpm_400',
          title: '400 WPM',
          description: '400 kelime/dakika hıza ulaştın',
          icon: Icons.speed_rounded,
          isUnlocked: () => ProgressManager.wpm >= 400,
        ),
        Achievement(
          id: 'wpm_600',
          title: 'Hız Canavarı',
          description: '600 kelime/dakika hıza ulaştın',
          icon: Icons.rocket_launch_rounded,
          isUnlocked: () => ProgressManager.wpm >= 600,
        ),
        Achievement(
          id: 'comprehension_90',
          title: 'Anlama Ustası',
          description: 'Anlama testinde %90 ve üzeri başarı elde ettin',
          icon: Icons.psychology_alt_rounded,
          isUnlocked: () => ProgressManager.comprehensionRate >= 90,
        ),
        Achievement(
          id: 'speed_boost',
          title: 'Tempo Arttı',
          description: 'Anlama başarınla hızlı okuma temponu artırdın',
          icon: Icons.trending_up_rounded,
          isUnlocked: () => ProgressManager.speedAdjustment > 1.0,
        ),
        Achievement(
          id: 'level_5',
          title: 'Seviye 5',
          description: 'Genel seviyende 5. seviyeye ulaştın',
          icon: Icons.star_rounded,
          isUnlocked: () => ProgressManager.currentLevel >= 5,
        ),
      ];
}
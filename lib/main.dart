import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'views/homes/home_page.dart';
import 'views/exercises/exercise_folders_page.dart';
import 'views/progress/progress_page.dart';
import 'views/settings/settings_page.dart';
import 'models/progress_manager.dart';
import 'models/settings_manager.dart';

Future<void> main() async {
  // SharedPreferences'a ve Firebase'e erişmeden önce Flutter binding'in
  // hazır olması gerekir.
  WidgetsFlutterBinding.ensureInitialized();

  // Uygulamanın geneli dikey tasarlandı — Klasör 2'deki "Hızlı Odaklanma"
  // gibi yatay isteyen sayfalar bunu kendi içinde geçici olarak açar.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Firebase'i başlat (Authentication + Firestore için gerekli).
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Kayıtlı ilerleme ve ayarları diskten yükle. runApp'ten önce bittiği için
  // ekranlar ilk çizildiğinde zaten doğru (kalıcı) değerlerle açılıyor.
  await ProgressManager.init();
  await SettingsManager.init();

  runApp(const SpeedReadingApp());
}

class SpeedReadingApp extends StatelessWidget {
  const SpeedReadingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hızlı Okuma Lab',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  void _goToTab(int index) {
    setState(() => currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onNavigateToExercises: () => _goToTab(1)),
      const ExerciseFoldersPage(),
      const ProgressPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology),
            label: 'Egzersiz',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'İlerleme',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}

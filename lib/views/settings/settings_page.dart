import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/settings_manager.dart';
import '../../models/audio_manager.dart';
import '../../services/auth_service.dart';
import '../auth/auth_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Ekran açılırken SettingsManager'daki (cihazda kayıtlı) son değerlerle
  // başlatılır. Her değişiklikte hem bu local state hem de SettingsManager
  // güncellenip diske yazılır.
  late bool isFocusRed = SettingsManager.isFocusRed;
  late bool isSoundOn = SettingsManager.isSoundOn;
  late bool isReminderOn = SettingsManager.isReminderOn;
  late bool isBackgroundMusicOn = SettingsManager.isBackgroundMusicOn;
  late TimeOfDay reminderTime = SettingsManager.reminderTime;
  late String readingTheme = SettingsManager.readingTheme;

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: reminderTime,
    );
    if (picked != null && picked != reminderTime) {
      setState(() {
        reminderTime = picked;
        SettingsManager.reminderTime = picked;
      });
      SettingsManager.save();
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İlerlemeyi Sıfırla'),
        content: const Text(
          'Tüm egzersiz geçmişiniz, seviyeniz ve istatistikleriniz sıfırlanacak. Emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              setState(() {
                ProgressManager.resetProgress();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tüm ilerleme başarıyla sıfırlandı! 🔄'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            child: const Text('Sıfırla', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _goToAuthPage() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthPage()));
    if (!mounted) return;
    setState(() {}); // Giriş yapılmış olabilir, ekranı tazele.
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await AuthService.signOut();
              if (!mounted) return;
              Navigator.pop(dialogContext);
              setState(() {});
            },
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _setReadingTheme(String value) {
    setState(() {
      readingTheme = value;
      SettingsManager.readingTheme = value;
    });
    SettingsManager.save();
  }

  Widget _themeOption({
    required String value,
    required String label,
    required Color previewColor,
    required IconData icon,
  }) {
    final selected = readingTheme == value;
    return SizedBox(
      width: 104,
      child: GestureDetector(
        onTap: () => _setReadingTheme(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: previewColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFF4F46E5) : Colors.grey.shade300,
              width: selected ? 2.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? const Color(0xFF4F46E5) : Colors.black45),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: selected ? const Color(0xFF4F46E5) : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = AuthService.isLoggedIn;
    final user = AuthService.currentUser;
    final displayName = (user?.displayName?.trim().isNotEmpty ?? false) ? user!.displayName! : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Ayarlar & Profil'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF4F46E5),
                    child: Icon(
                      loggedIn ? Icons.emoji_people : Icons.person,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loggedIn ? (displayName ?? user?.email ?? 'Kullanıcı') : 'Misafir Kullanıcı',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          loggedIn
                              ? (user?.email ?? 'Hesabınla giriş yaptın.')
                              : 'Giriş yaparsan ilerlemen her cihazda seninle gelir ve liderlik tablosunda görünürsün.',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: loggedIn ? _showLogoutDialog : _goToAuthPage,
                    style: loggedIn
                        ? ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black87)
                        : null,
                    child: Text(loggedIn ? 'Çıkış Yap' : 'Giriş Yap'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Okuma Teması',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Anlama Testi\'ndeki metin arka planı için dinlendirici bir renk seç.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _themeOption(
                value: 'default',
                label: 'Varsayılan',
                previewColor: Colors.white,
                icon: Icons.wb_sunny_outlined,
              ),
              _themeOption(
                value: 'blue',
                label: 'Mavi 🔵',
                previewColor: const Color(0xFFEFF6FF),
                icon: Icons.water_drop_outlined,
              ),
              _themeOption(
                value: 'green',
                label: 'Yeşil 🟢',
                previewColor: const Color(0xFFECFDF5),
                icon: Icons.eco_outlined,
              ),
              _themeOption(
                value: 'lavender',
                label: 'Lavanta 🟣',
                previewColor: const Color(0xFFF5F3FF),
                icon: Icons.spa_outlined,
              ),
              _themeOption(
                value: 'cream',
                label: 'Krem 🟡',
                previewColor: const Color(0xFFFFFBEB),
                icon: Icons.wb_incandescent_outlined,
              ),
              _themeOption(
                value: 'gray',
                label: 'Gri ⚪',
                previewColor: const Color(0xFFF8FAFC),
                icon: Icons.cloud_outlined,
              ),
            ],
          ),

          const Divider(height: 30),

          const Text(
            'Egzersiz Tercihleri',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 16),
          ),
          const SizedBox(height: 8),

          SwitchListTile(
            title: const Text('Varsayılan Odak Noktası'),
            subtitle: const Text('Kırmızı nokta egzersiz başlarken açık gelsin.'),
            value: isFocusRed,
            onChanged: (val) {
              setState(() {
                isFocusRed = val;
                SettingsManager.isFocusRed = val;
              });
              SettingsManager.save();
            },
          ),
          SwitchListTile(
            title: const Text('Ses Efektleri'),
            subtitle: const Text('Doğru cevap ve başarımlarda tatmin edici ses/titreşim geri bildirimi.'),
            value: isSoundOn,
            onChanged: (val) {
              setState(() {
                isSoundOn = val;
                SettingsManager.isSoundOn = val;
              });
              SettingsManager.save();
            },
          ),
          SwitchListTile(
            title: const Text('Arka Plan Müziği'),
            subtitle: const Text('Okuma sırasında sakin, dinlendirici bir fon sesi çalar.'),
            value: isBackgroundMusicOn,
            onChanged: (val) {
              setState(() {
                isBackgroundMusicOn = val;
                SettingsManager.isBackgroundMusicOn = val;
              });
              SettingsManager.save();
              if (!val) AudioManager.stopAmbient();
            },
          ),

          const Divider(height: 30),

          const Text(
            'Uygulama Ayarları',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 16),
          ),
          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(Icons.notifications_active, color: Colors.indigo),
            title: const Text('Günlük Çalışma Hatırlatıcısı'),
            subtitle: Text(
              isReminderOn
                  ? 'Her gün saat ${reminderTime.format(context)}\'de bildirim gönder.'
                  : 'Hatırlatıcı kapalı.',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isReminderOn)
                  IconButton(
                    icon: const Icon(Icons.access_time, color: Colors.indigo),
                    onPressed: () => _selectTime(context),
                  ),
                Switch(
                  value: isReminderOn,
                  onChanged: (val) {
                    setState(() {
                      isReminderOn = val;
                      SettingsManager.isReminderOn = val;
                    });
                    SettingsManager.save();
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 30),

          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.redAccent),
            title: const Text(
              'İlerlemeyi Sıfırla',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
            onTap: _showResetDialog,
          ),
        ],
      ),
    );
  }
}

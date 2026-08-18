import 'package:flutter/material.dart';
import '../models/settings_manager.dart';

/// Okuma ekranlarında (Anlama Testi, Klasör 1 Oturumu) metnin arka plan
/// rengini anında değiştirmek için kullanılan küçük alt panel. Seçim
/// SettingsManager.readingTheme'e yazılır, böylece uygulamanın her yerinde
/// aynı tema kullanılmaya devam eder.
Future<void> showReadingThemePicker(BuildContext context, VoidCallback onChanged) {
  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Metin Rengi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _ThemeDot(value: 'default', bg: Colors.white, border: const Color(0xFF4F46E5), onChanged: onChanged),
              _ThemeDot(value: 'blue', bg: const Color(0xFFEFF6FF), border: const Color(0xFF2563EB), onChanged: onChanged),
              _ThemeDot(value: 'green', bg: const Color(0xFFECFDF5), border: const Color(0xFF059669), onChanged: onChanged),
              _ThemeDot(value: 'lavender', bg: const Color(0xFFF5F3FF), border: const Color(0xFF7C3AED), onChanged: onChanged),
              _ThemeDot(value: 'cream', bg: const Color(0xFFFFFBEB), border: const Color(0xFFB45309), onChanged: onChanged),
              _ThemeDot(value: 'gray', bg: const Color(0xFFF8FAFC), border: const Color(0xFF475569), onChanged: onChanged),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ThemeDot extends StatelessWidget {
  final String value;
  final Color bg;
  final Color border;
  final VoidCallback onChanged;

  const _ThemeDot({
    required this.value,
    required this.bg,
    required this.border,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = SettingsManager.readingTheme == value;
    return InkWell(
      onTap: () {
        SettingsManager.readingTheme = value;
        SettingsManager.save();
        onChanged();
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: border, width: isSelected ? 3 : 1.5),
        ),
        child: isSelected ? Icon(Icons.check, color: border, size: 20) : null,
      ),
    );
  }
}

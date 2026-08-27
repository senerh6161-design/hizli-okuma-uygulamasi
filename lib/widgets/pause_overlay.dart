import 'package:flutter/material.dart';

/// Etkinlik ekranlarının üst çubuğuna eklenen "Durdur" (duraklat) ikon
/// butonu.
Widget buildPauseButton({
  required Color color,
  required VoidCallback onPressed,
}) {
  return IconButton(
    onPressed: onPressed,
    icon: Icon(Icons.pause_circle_outline_rounded, color: color),
    tooltip: 'Duraklat',
    visualDensity: VisualDensity.compact,
  );
}

/// Ekranı tamamen kaplayan, "Duraklatıldı" yazılı ve "Devam Et" butonlu
/// overlay. Etkinliğin aktif (oynanan) fazının en dış widget'ı bir
/// [Stack]'e alınıp bu overlay [Positioned.fill] ile üstüne eklenir.
Widget buildPauseOverlay({
  required Color color,
  required VoidCallback onResume,
}) {
  return Positioned.fill(
    child: Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.pause_circle_filled_rounded,
              color: Colors.white,
              size: 72,
            ),
            const SizedBox(height: 16),
            const Text(
              'Duraklatıldı',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onResume,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text(
                'DEVAM ET',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

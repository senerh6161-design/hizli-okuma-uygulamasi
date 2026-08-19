import 'package:flutter/material.dart';
import '../models/audio_manager.dart';
import '../models/settings_manager.dart';

/// Okuma metnine başlamadan önce (veya Ayarlar'da) gösterilen kompakt fon
/// müziği kontrolü: aç/kapat anahtarı + parça seçim çipleri.
class BackgroundMusicPicker extends StatefulWidget {
  const BackgroundMusicPicker({super.key});

  @override
  State<BackgroundMusicPicker> createState() => _BackgroundMusicPickerState();
}

class _BackgroundMusicPickerState extends State<BackgroundMusicPicker> {
  @override
  Widget build(BuildContext context) {
    final isOn = SettingsManager.isBackgroundMusicOn;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D9488).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.music_note_rounded, color: Color(0xFF0D9488), size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Fon Müziği',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0D9488)),
                ),
              ),
              Switch(
                value: isOn,
                activeThumbColor: const Color(0xFF0D9488),
                onChanged: (val) async {
                  setState(() => SettingsManager.isBackgroundMusicOn = val);
                  await SettingsManager.save();
                  if (val) {
                    await AudioManager.startAmbient();
                  } else {
                    await AudioManager.stopAmbient();
                  }
                },
              ),
            ],
          ),
          if (isOn) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kBackgroundTracks.map((track) {
                final selected = SettingsManager.backgroundMusicTrack == track.id;
                return ChoiceChip(
                  label: Text(track.label),
                  selected: selected,
                  onSelected: (sel) async {
                    if (!sel) return;
                    setState(() => SettingsManager.backgroundMusicTrack = track.id);
                    await SettingsManager.save();
                    await AudioManager.switchTrackIfPlaying();
                  },
                  selectedColor: const Color(0xFF0D9488).withValues(alpha: 0.18),
                  labelStyle: TextStyle(
                    color: selected ? const Color(0xFF0D9488) : const Color(0xFF475569),
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  side: BorderSide(color: selected ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0)),
                  backgroundColor: Colors.white,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

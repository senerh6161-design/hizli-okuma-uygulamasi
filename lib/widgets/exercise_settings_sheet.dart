import 'package:flutter/material.dart';
import 'background_music_picker.dart';

/// Etkinlik ekranlarındaki "⋮" menüsü — tema rengi, yazı boyutu ve fon
/// müziği tek bir yerde toplanıyor (ayrı ayrı ikonlar ekranda çok yer
/// kaplıyordu). Her etkinlik kendi renk paletini [colorOptions] ile,
/// isterse yazı boyutu seçeneklerini [fontSizeLabels]/[onFontSizeChanged]
/// ile sağlıyor — biri null bırakılırsa o bölüm gizlenir.
void showExerciseSettingsSheet(
  BuildContext context, {
  required Color currentColor,
  required List<Color> colorOptions,
  required ValueChanged<Color> onColorChanged,
  List<String>? fontSizeLabels,
  int? fontSizeLevel,
  ValueChanged<int>? onFontSizeChanged,
}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ayarlar',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.palette_outlined, color: currentColor),
                    const SizedBox(width: 8),
                    const Text(
                      'Tema Rengi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final option in colorOptions)
                      InkWell(
                        onTap: () {
                          onColorChanged(option);
                          setSheetState(() {});
                        },
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: option,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: currentColor == option ? 3 : 0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: option.withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: currentColor == option
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
                if (fontSizeLabels != null && onFontSizeChanged != null) ...[
                  const Divider(height: 28),
                  Row(
                    children: [
                      Icon(Icons.format_size_rounded, color: currentColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Yazı Boyutu',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (int i = 0; i < fontSizeLabels.length; i++)
                        ChoiceChip(
                          label: Text(fontSizeLabels[i]),
                          selected: fontSizeLevel == i,
                          onSelected: (_) {
                            onFontSizeChanged(i);
                            setSheetState(() {});
                          },
                          selectedColor: currentColor,
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: fontSizeLevel == i
                                ? Colors.white
                                : currentColor,
                          ),
                          backgroundColor: currentColor.withValues(alpha: 0.08),
                          side: BorderSide(
                            color: currentColor.withValues(
                              alpha: fontSizeLevel == i ? 1 : 0.3,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const Divider(height: 28),
                const BackgroundMusicPicker(),
              ],
            ),
          );
        },
      );
    },
  );
}

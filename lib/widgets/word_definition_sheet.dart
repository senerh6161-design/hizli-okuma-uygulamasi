import 'package:flutter/material.dart';
import '../models/word_dictionary.dart';
import '../services/tdk_service.dart';

/// Bir kelimeye dokunulduğunda, önce TDK'nin (Türk Dil Kurumu) gerçek,
/// resmî sözlüğünden tanımı çekmeye çalışır (yükleniyor animasyonuyla).
/// İnternet yoksa ya da TDK'de kelime bulunamazsa, cihazdaki küçük yerel
/// sözlüğe düşer.
void showWordDefinition(
  BuildContext context,
  String rawToken, {
  Color? accentColor,
}) {
  final cleanWord = WordDictionary.cleanWord(rawToken);
  if (cleanWord.isEmpty) return;

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _WordDefinitionSheet(
      word: cleanWord,
      accentColor: accentColor ?? const Color(0xFF4F46E5),
    ),
  );
}

/// Bir metni tek tek dokunulabilir kelimeler hâlinde çizer. Bir kelimeye
/// dokunulduğunda [showWordDefinition] açılır. Metindeki boş satırlar
/// (\n\n) paragraf sınırı sayılır — her paragraf kendi satırında ayrı
/// başlar; böylece madde başlıkları/paragraflar tek bir akışa karışmaz
/// (bkz. hoca geri bildirimi: "paragraf düzenine dikkat"). Kelimeler bir
/// Text.rich içinde WidgetSpan olarak dizilir ve TextAlign.justify
/// kullanılır — böylece metin sola değil, kitaptaki gibi HER İKİ YANA da
/// yaslı görünür (satır sonundaki kelime boşlukları esner).
Widget buildInteractiveText(
  BuildContext context,
  String content, {
  Color? accentColor,
  TextStyle? style,
}) {
  final color = accentColor ?? const Color(0xFF4F46E5);
  final effectiveStyle =
      style ??
      const TextStyle(fontSize: 17, height: 1.6, color: Colors.black87);
  final paragraphs = content
      .split(RegExp(r'\n\s*\n'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();

  Widget paragraphText(String paragraph) {
    final tokens = paragraph
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    final spans = <InlineSpan>[];
    for (int i = 0; i < tokens.length; i++) {
      if (i > 0) spans.add(const TextSpan(text: ' '));
      final token = tokens[i];
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: () => showWordDefinition(context, token, accentColor: color),
            child: Text(
              token,
              style: effectiveStyle.copyWith(
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dotted,
                decorationColor: color.withValues(alpha: 0.35),
              ),
            ),
          ),
        ),
      );
    }
    return Text.rich(TextSpan(children: spans), textAlign: TextAlign.justify);
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (int i = 0; i < paragraphs.length; i++) ...[
        if (i > 0) const SizedBox(height: 14),
        paragraphText(paragraphs[i]),
      ],
    ],
  );
}

class _WordDefinitionSheet extends StatefulWidget {
  final String word;
  final Color accentColor;
  const _WordDefinitionSheet({required this.word, required this.accentColor});

  @override
  State<_WordDefinitionSheet> createState() => _WordDefinitionSheetState();
}

class _WordDefinitionSheetState extends State<_WordDefinitionSheet> {
  List<String>? _tdkDefinitions;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await TdkService.lookup(widget.word);
    if (!mounted) return;
    setState(() {
      _tdkDefinitions = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFromTdk = _tdkDefinitions != null && _tdkDefinitions!.isNotEmpty;
    final localDefinition = WordDictionary.define(widget.word);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, color: widget.accentColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.word,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (isFromTdk)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'TDK',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (_loading)
            Text(
              'Türk Dil Kurumu sözlüğünden aranıyor…',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            )
          else if (isFromTdk)
            ..._tdkDefinitions!.take(3).toList().asMap().entries.map((e) {
              final showNumber = _tdkDefinitions!.length > 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  showNumber ? '${e.key + 1}. ${e.value}' : e.value,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              );
            })
          else
            Text(
              localDefinition ??
                  'Bu kelimenin tanımını bulamadık, ama harika bir kelime! Öğretmenine ya da ailene sorabilirsin. 😊',
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
        ],
      ),
    );
  }
}

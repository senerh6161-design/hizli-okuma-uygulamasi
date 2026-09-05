import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/confetti_overlay.dart';
import '../../widgets/exercise_settings_sheet.dart';

class _WordLine {
  final String text;
  final List<String> words;
  const _WordLine(this.text, this.words);
}

/// Klasör 4'ün ikinci etkinliği: "Saklı Kelimeler". Kitaptaki Etkinlik 9'un
/// karşılığı — her satırda boşluksuz, iç içe geçmiş gerçek kelimeler
/// gizlenmiş. Öğrenci harflere sırayla dokunarak ardışık bir aralık seçer;
/// seçim bir hedef kelimeye denk gelince o kelime bulunmuş sayılır, kendi
/// rengiyle işaretlenir ve puan kazanılır. Sayfaya sığmadığı için 2 sayfaya
/// bölündü.
class HiddenWordsPage extends StatefulWidget {
  const HiddenWordsPage({super.key});

  @override
  State<HiddenWordsPage> createState() => _HiddenWordsPageState();
}

class _HiddenWordsPageState extends State<HiddenWordsPage> {
  Color _color = const Color(0xFFDB2777);

  static const List<Color> _colorPalette = [
    Color(0xFFDB2777),
    Color(0xFFEC4899),
    Color(0xFFEA580C),
    Color(0xFF0D9488),
    Color(0xFF7C3AED),
    Color(0xFF2563EB),
  ];
  static const int _pointsPerWord = 10;
  static const int _linesPerPage = 8;

  static const List<_WordLine> _lines = [
    _WordLine('Senezaketçaprazrakamyoncamii', [
      'çapraz',
      'rakam',
      'kamyon',
      'cami',
    ]),
    _WordLine('Karabayramazankaramakaskırık', [
      'bayram',
      'ramazan',
      'kara',
      'makas',
      'kırık',
    ]),
    _WordLine('Kitapınakitfaiyeminaresimdatkı', [
      'kitap',
      'yemin',
      'minare',
      'resim',
    ]),
    _WordLine('Nemlakvaryumurtalimandalinat', ['emlak', 'yumurta', 'liman']),
    _WordLine('Gümüşterimzalimkanatlaspirinç', [
      'gümüş',
      'terim',
      'zalim',
      'kanat',
      'aspirin',
      'pirinç',
    ]),
    _WordLine('Namazeretkinliklimarketiketiki', [
      'namaz',
      'etkinlik',
      'market',
      'etiket',
      'iki',
    ]),
    _WordLine('Kalitevazurnasihatırahmetrenk', [
      'kalite',
      'zurna',
      'nasihat',
      'hatıra',
      'rahmet',
      'renk',
    ]),
    _WordLine('Makinefestivalidemirmiktarlasa', [
      'makine',
      'festival',
      'demir',
      'miktar',
    ]),
    _WordLine('Galaksinemakarnafakatmersinat', [
      'galaksi',
      'makarna',
      'fakat',
      'mersin',
    ]),
    _WordLine('Nadirendişemsiyelpazeytincirit', [
      'nadir',
      'yel',
      'zeytin',
      'cirit',
    ]),
    _WordLine('Yelkenetlenmektepsikolojiletek', [
      'yelken',
      'mektep',
      'psikoloji',
    ]),
    _WordLine('Mehterfikireçeldivendişekilginç', [
      'mehter',
      'fikir',
      'şekil',
      'ilginç',
    ]),
    _WordLine('Dikkatmersinsanayirmikramatör', [
      'dikkat',
      'mersin',
      'sanayi',
      'amatör',
    ]),
    _WordLine('Hedefterbiyeteneklemlaktaralık', [
      'hedef',
      'terbiye',
      'yetenek',
      'emlak',
      'aralık',
    ]),
    _WordLine('Bayrakrabartmaketçaprazimzaman', [
      'bayrak',
      'maket',
      'çapraz',
      'imza',
      'zaman',
    ]),
    _WordLine('Ezannefesleğengelgitariftarihlas', [
      'ezan',
      'nefes',
      'engel',
      'gitar',
      'tarif',
      'tarih',
    ]),
  ];

  static const List<Color> _palette = [
    Color(0xFFDC2626),
    Color(0xFFEA580C),
    Color(0xFFD97706),
    Color(0xFF65A30D),
    Color(0xFF059669),
    Color(0xFF0891B2),
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFFC026D3),
    Color(0xFFDB2777),
    Color(0xFF4338CA),
    Color(0xFF0D9488),
  ];

  // Satır başına seçilmiş "hedef" kelimelerin dışında, öğrenci metinde
  // gerçekten geçen başka geçerli bir kelimeyi de bulabilsin diye ekstra
  // puan veren yaygın kelime havuzu.
  static const Set<String> _bonusWords = {
    'sen',
    'ben',
    'biz',
    'siz',
    'ana',
    'ata',
    'dede',
    'nine',
    'kuzu',
    'kedi',
    'köpek',
    'kuş',
    'ama',
    'evet',
    'okul',
    'kalem',
    'defter',
    'masa',
    'sıra',
    'kapı',
    'duvar',
    'oda',
    'bahçe',
    'sokak',
    'şehir',
    'köy',
    'deniz',
    'göl',
    'dağ',
    'orman',
    'çiçek',
    'ağaç',
    'yaprak',
    'dal',
    'elma',
    'ekmek',
    'süt',
    'çay',
    'şeker',
    'tuz',
    'yağ',
    'un',
    'et',
    'tavuk',
    'balık',
    'koyun',
    'inek',
    'eşek',
    'arı',
    'karınca',
    'yılan',
    'baş',
    'göz',
    'kulak',
    'burun',
    'ağız',
    'diş',
    'dil',
    'saç',
    'kol',
    'bacak',
    'ayak',
    'parmak',
    'kalp',
    'kan',
    'kemik',
    'deri',
    'boy',
    'kilo',
    'mavi',
    'yeşil',
    'sarı',
    'siyah',
    'beyaz',
    'mor',
    'pembe',
    'gri',
    'para',
    'yol',
    'top',
    'kap',
    'tas',
    'kova',
    'ip',
    'taş',
    'kar',
    'kır',
    'kız',
    'oğul',
    'anne',
    'baba',
    'yaz',
    'kış',
    'gül',
    'iz',
    'usta',
    'aşık',
    'yıl',
    'gün',
    'saat',
    'an',
    'zaman',
    'işaret',
    'renk',
    'kitap',
    'kilim',
    'halı',
    'ketçap',
    'araba',
    'camii',
    'peynir',
    'reçel',
    'bal',
    'çorba',
    'pilav',
    'salata',
    'meyve',
    'sebze',
    'armut',
    'kiraz',
    'karpuz',
    'limon',
    'portakal',
    'muz',
    'çilek',
    'üzüm',
    'sene',
    'nezaket',
    'çap',
    'kara',
    'bayram',
    'pınar',
    'akit',
    'nem',
    'emlak',
    'akvaryum',
    'var',
    'gümüş',
    'ter',
    'terim',
    'namaz',
    'az',
    'kalite',
    'tevazu',
    'eva',
    'zurna',
    'makine',
    'kin',
    'mefes',
    'efes',
  };

  int get _pageCount => (_lines.length / _linesPerPage).ceil();
  int get _totalWordCount => _lines.fold(0, (sum, l) => sum + l.words.length);
  int get _foundCount => _foundColors.length;
  int get _score => _foundCount * _pointsPerWord;

  int _pageIndex = 0;
  int? _activeLineIndex;
  Set<int> _selected = {};
  final Map<String, Color> _foundColors = {};
  final Map<String, List<int>> _foundRanges = {};
  int _curatedFoundCount = 0;

  int _elapsedSec = 0;
  Timer? _timer;
  bool _hasCompletedOnce = false;
  bool _started = false;
  String? _checkMessage;
  Timer? _checkMessageTimer;

  void _startGame() {
    setState(() => _started = true);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSec++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _checkMessageTimer?.cancel();
    super.dispose();
  }

  String _trLower(String s) =>
      s.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();

  void _toggleLetter(int lineIndex, int charIndex) {
    setState(() {
      _checkMessage = null;
      if (_activeLineIndex != lineIndex) {
        _activeLineIndex = lineIndex;
        _selected = {charIndex};
      } else if (_selected.contains(charIndex)) {
        _selected.remove(charIndex);
      } else {
        _selected.add(charIndex);
      }
    });
  }

  void _checkSelection() {
    final lineIndex = _activeLineIndex;
    if (lineIndex == null || _selected.isEmpty) return;
    final sorted = _selected.toList()..sort();
    if (sorted.last - sorted.first + 1 != sorted.length) {
      _showCheckMessage('Ardışık harfleri seç 🤔');
      return;
    }
    final line = _lines[lineIndex];
    final candidate = _trLower(
      line.text.substring(sorted.first, sorted.last + 1),
    );
    final key = '$lineIndex:$candidate';
    if (_foundColors.containsKey(key)) {
      _showCheckMessage('Bu kelimeyi zaten buldun ✓');
      return;
    }
    final isCurated = line.words.any((w) => _trLower(w) == candidate);
    // Sadece satır başına seçtiğimiz "hedef" kelimeler değil — metinde
    // gerçekten geçen HERHANGİ bir Türkçe kelimeyi bulmak da ödüllendirilsin
    // diye geniş bir yaygın-kelime listesine de bakıyoruz.
    final isBonus =
        !isCurated && candidate.length >= 3 && _bonusWords.contains(candidate);
    if (isCurated || isBonus) {
      setState(() {
        _foundColors[key] = _palette[_foundColors.length % _palette.length];
        _foundRanges[key] = [sorted.first, sorted.last];
        if (isCurated) _curatedFoundCount++;
        _selected = {};
        _activeLineIndex = null;
        _checkMessage = null;
      });
      SoundManager.playCorrect();
      showConfetti(context);
      if (isBonus) _showCheckMessage('Ekstra kelime! +10 puan 🎉');
      return;
    }
    SoundManager.playGentleTap();
    _showCheckMessage('Bu bir kelime değil, tekrar dene 📖');
  }

  void _showCheckMessage(String message) {
    _checkMessageTimer?.cancel();
    setState(() => _checkMessage = message);
    _checkMessageTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _checkMessage = null);
    });
  }

  void _clearSelection() {
    _checkMessageTimer?.cancel();
    setState(() {
      _selected = {};
      _activeLineIndex = null;
      _checkMessage = null;
    });
  }

  // Harf aralıkları (ör. "sen" ile "nezaket") çakışabiliyor — sonradan
  // bulunan kelime öncekiyle ortak harfleri de kapsıyorsa, o harfler eski
  // rengiyle takılı kalmasın diye en SON bulunan kelimenin rengi kazanıyor
  // (bu yüzden döngü ilk eşleşmede DÖNMÜYOR, en son eşleşeni tutuyor).
  Color? _colorForIndex(int lineIndex, int i) {
    Color? result;
    for (final entry in _foundRanges.entries) {
      if (!entry.key.startsWith('$lineIndex:')) continue;
      final r = entry.value;
      if (i >= r[0] && i <= r[1]) result = _foundColors[entry.key];
    }
    return result;
  }

  void _nextPage() {
    if (_pageIndex < _pageCount - 1) {
      _checkMessageTimer?.cancel();
      setState(() {
        _pageIndex++;
        _selected = {};
        _activeLineIndex = null;
        _checkMessage = null;
      });
    } else {
      _finishAll();
    }
  }

  void _finishAll() {
    _timer?.cancel();
    _hasCompletedOnce = true;

    final percent = ((_curatedFoundCount / _totalWordCount) * 100).round();
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Saklı Kelimeler',
      result:
          '$_curatedFoundCount/$_totalWordCount hedef kelime · $_foundCount toplam · $_score puan · ${_elapsedSec}sn',
    );
    if (unlocked.isNotEmpty) SoundManager.playAchievement();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🎉 Etkinlik Tamamlandı!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_curatedFoundCount / $_totalWordCount hedef kelimeyi buldun! '
              '(Toplam $_foundCount kelime bulundu.)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              'Puan: $_score · Süre: $_elapsedSec sn',
              style: TextStyle(
                color: _color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            if (unlocked.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                '🎉 Yeni Başarım Kazandın!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: unlocked.map((a) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(a.icon, size: 14, color: Colors.amber.shade800),
                        const SizedBox(width: 4),
                        Text(
                          a.title,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('Bitir'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _restart();
            },
            child: const Text('Yeniden Başlat'),
          ),
        ],
      ),
    );
  }

  void _restart() {
    _checkMessageTimer?.cancel();
    setState(() {
      _pageIndex = 0;
      _selected = {};
      _activeLineIndex = null;
      _checkMessage = null;
      _foundColors.clear();
      _foundRanges.clear();
      _curatedFoundCount = 0;
      _elapsedSec = 0;
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return CompletionPopScope(
      isCompleted: () => _hasCompletedOnce,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🔍 Saklı Kelimeler'),
          actions: [
            IconButton(
              onPressed: () => showExerciseSettingsSheet(
                context,
                currentColor: _color,
                colorOptions: _colorPalette,
                onColorChanged: (c) => setState(() => _color = c),
              ),
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: 'Ayarlar',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: _started ? _buildGame() : _buildIntro(),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Etkinlik 2 · Saklı Kelimeler',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _color,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    const Center(
                      child: Text('🔍', style: TextStyle(fontSize: 72)),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE7F3),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _color, width: 1.2),
                      ),
                      child: const Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF831843),
                          ),
                          children: [
                            TextSpan(
                              text: 'Amaç: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  'Göz ve zihin odaklanmasını artırmak, iç '
                                  'içe geçmiş kelimeleri yakalayabilmek.\n',
                            ),
                            TextSpan(
                              text: 'Yöntem: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  'Her satırın harfleri boşluksuz — içinde '
                                  'gizli gerçek kelimeler var. Bulduğun '
                                  'kelimenin harflerine sırayla dokun, her '
                                  'kelime 10 puan!',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _startGame,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text(
                        'BAŞLA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGame() {
    final startLine = _pageIndex * _linesPerPage;
    final endLine = ((_pageIndex + 1) * _linesPerPage).clamp(0, _lines.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Sayfa ${_pageIndex + 1}/$_pageCount',
                  style: TextStyle(fontWeight: FontWeight.bold, color: _color),
                ),
              ),
            ),
            const SizedBox(width: 6),
            _badge('⭐ $_score puan', Colors.amber.shade800),
            const SizedBox(width: 6),
            _badge('⏱ ${_elapsedSec}sn', Colors.blueGrey),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (int li = startLine; li < endLine; li++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildLineRow(li),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_selected.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _color.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    'Seçili: ${_currentSelectionText()}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _clearSelection,
                child: const Text('Temizle'),
              ),
              const SizedBox(width: 4),
              ElevatedButton(
                onPressed: _checkSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Kontrol Et',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        if (_checkMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _checkMessage!,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB45309),
              ),
            ),
          ),
        _buildFoundList(),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _nextPage,
            icon: Icon(
              _pageIndex < _pageCount - 1
                  ? Icons.arrow_forward
                  : Icons.flag_rounded,
            ),
            label: Text(
              _pageIndex < _pageCount - 1 ? 'SONRAKİ SAYFA' : 'BİTİR',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _currentSelectionText() {
    if (_activeLineIndex == null || _selected.isEmpty) return '';
    final sorted = _selected.toList()..sort();
    final isContiguous = sorted.last - sorted.first + 1 == sorted.length;
    if (!isContiguous) return '(ardışık harf seç)';
    return _lines[_activeLineIndex!].text.substring(
      sorted.first,
      sorted.last + 1,
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildLineRow(int lineIndex) {
    final line = _lines[lineIndex];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < line.text.length; i++)
            GestureDetector(
              onTap: () => _toggleLetter(lineIndex, i),
              child: Container(
                width: 28,
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _bgForIndex(lineIndex, i),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300, width: 0.6),
                ),
                child: Text(
                  line.text[i],
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _fgForIndex(lineIndex, i),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _bgForIndex(int lineIndex, int i) {
    final found = _colorForIndex(lineIndex, i);
    if (found != null) return found;
    if (_activeLineIndex == lineIndex && _selected.contains(i)) {
      return _color.withValues(alpha: 0.25);
    }
    return Colors.white;
  }

  Color _fgForIndex(int lineIndex, int i) {
    final found = _colorForIndex(lineIndex, i);
    if (found != null) return Colors.white;
    return const Color(0xFF334155);
  }

  Widget _buildFoundList() {
    if (_foundColors.isEmpty) {
      return Text(
        'Henüz kelime bulunmadı — harflere sırayla dokunarak seç!',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      );
    }
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 92),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final entry in _foundColors.entries)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: entry.value,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '✓ ${entry.key.split(':')[1]}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

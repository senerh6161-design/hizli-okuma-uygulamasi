import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';
import '../../widgets/exercise_settings_sheet.dart';

enum _Direction { leftToRight, rightToLeft, bottomToTop, topToBottom }

enum _Phase {
  intro,
  warmup,
  ready,
  exercise,
  bolum2Intro,
  bolum2Search,
  bolum2Answer,
}

class _CountChallenge {
  final String target;
  final int correctCount;
  const _CountChallenge(this.target, this.correctCount);
}

/// Klasör 4'ün dördüncü etkinliği: "Sınav Kelimeleri". Kitaptaki
/// Etkinlik 7'nin karşılığı — kitapta her sayfada 3 sütun kelime grubu
/// var, telefon ekranına sığmadığı için 2 sütun olarak gösteriyoruz.
/// 1. Bölüm: word_pattern_scan_page ile aynı mantık — antreman, sonra
/// sıra sende, her sayfa 4 yönde taranıyor. 2. Bölüm: metinde belirli bir
/// kelime grubunun kaç kere geçtiğini soruyoruz (focus_box_page'in
/// "Odaklanma Kutucukları" 4. Turu ile aynı mantık: önce sayfayı serbestçe
/// tara, sonra cevapla).
class ExamWordGroupScanPage extends StatefulWidget {
  const ExamWordGroupScanPage({super.key});

  @override
  State<ExamWordGroupScanPage> createState() => _ExamWordGroupScanPageState();
}

class _ExamWordGroupScanPageState extends State<ExamWordGroupScanPage> {
  Color _color = const Color(0xFF9333EA);

  static const List<Color> _colorPalette = [
    Color(0xFF9333EA),
    Color(0xFFEC4899),
    Color(0xFFEA580C),
    Color(0xFF0D9488),
    Color(0xFF7C3AED),
    Color(0xFF2563EB),
  ];
  static const List<String> _speedLabels = [
    'Yavaş',
    'Orta',
    'Hızlı',
    'Çok Hızlı',
  ];
  static const List<int> _stepMsBySpeed = [1000, 700, 480, 320];
  static const List<_Direction> _directions = [
    _Direction.leftToRight,
    _Direction.rightToLeft,
    _Direction.bottomToTop,
    _Direction.topToBottom,
  ];
  static const List<String> _directionLabels = [
    'Soldan Sağa',
    'Sağdan Sola',
    'Aşağıdan Yukarı',
    'Yukarıdan Aşağı',
  ];
  static const int _cols = 2;

  // Kitaptaki 5 sayfa (162-166), her sayfada 3 sütun (yeşil/pembe/mavi).
  // Sırasıyla düz liste halinde: her sütun kendi başlığıyla birlikte.
  static const List<List<String>> _columns = [
    // Sayfa 162 - yeşil
    [
      'dergi, makale',
      'gayret bekler',
      'uluslararası',
      'tasarlandı',
      'görsel sanatlar',
      'yaşama açılan',
      'tahammül eden',
      'resim asmaya',
      'övgüye değer',
      'kağıt üzerine',
      'örgü ağını',
      'tarafından',
      'gül taşıyorum',
      'her sanat dalı',
      'cevap kâğıdı',
      'adım atanlar',
      'fotoğraf çekmeye',
      'ömür geçirmek',
    ],
    // Sayfa 162 - pembe
    [
      'suya yazı yazmak',
      'dergi çıkartmak',
      'imkânsız bir iş',
      'kitap eleştirisi',
      'genç okurların',
      'edebiyat ve şiir',
      'kalıcı olmak',
      'boş yere uğraşmak',
      'göğüs germek',
      'köklü bir geçmiş',
      'teşekkür ederim',
      'yanlışlık yapılmıştır',
      'tahammül edenler',
      'adım atanlar',
      'övgüye değer',
      'ömür geçirmek',
      'iletişime kapalı',
      'sanattan yoksun',
    ],
    // Sayfa 162 - mavi
    [
      'farklı açılardan',
      'her sahasında',
      'bilinçli kullanmak',
      'akıllı cihazlar',
      'elektronik emzik',
      'dikkat çekmek',
      'teknolojisiz bir gün',
      'sosyal sorumluluk',
      'ekran bağımlılığı',
      'sosyal medyayı',
      'kontrol etme',
      'bilgisayar başında',
      'teknoloji diyeti',
      'kitap okurum',
      'vakit geçiririm',
      'kullanılmamıştır',
      'yürüyüş yaparım',
      'resim çizerim',
    ],
    // Sayfa 163 - yeşil
    [
      'yeni yerler keşfet',
      'teşekkür ederim',
      'fark edebilirsiniz',
      'dil ve anlatımıyla',
      'hangisi yanlıştır',
      'asıl anlatılmak',
      'iyi değerlendir',
      'eylem cümlesi',
      'olumlu cümle',
      'kullanılmamıştır',
      'tarihî yapıların',
      'önemli bir kısmı',
      'orijinal çizimleri',
      'kesin olarak',
      'akışı bozulmaz',
      'kapsamlı çalışma',
      'toplu taşıma',
      'ideal zamanlar',
    ],
    // Sayfa 163 - pembe
    [
      'geri dönüşüm',
      'hikâye kitabıyla',
      'çevre bilinci',
      'somutlaştırıp',
      'hikâye serisi',
      'empati kurma',
      'yargıların hangisi',
      'kişilik gelişiminde',
      'sağlıklı iletişimin',
      'teknoloji diyeti',
      'ekonomiye katkısı',
      'çocuk eğitimi',
      'yol göstermek',
      'öğretim yapılan',
      'yazım yanlışı',
      'yapılmamıştır',
      'saygı sözleri',
      'yanlış yapılmıştır',
    ],
    // Sayfa 163 - mavi
    [
      'cevap kâğıdı',
      'çayların parasını',
      'samimi olduğu',
      'huzurlu hissettiği',
      'boşa çıkarırdı',
      'gencecik yaşında',
      'vatan uğruna',
      'bizim kasabada',
      'uygun yazılmıştır',
      'göz göze gelirdi',
      'ayrılığın acısı',
      'boynuna sarılmış',
      'teknoloji diyeti',
      'acımasızca eleştiri',
      'öz güven kaybı',
      'mükemmeliyetçi',
      'esnek olmamak',
      'öteki yüzünü',
    ],
    // Sayfa 164 - yeşil
    [
      'çıkarılabilecek',
      'temel nedeni',
      'iyi bir dinlenme',
      'ideal bir süreç',
      'olumsuz duygu',
      'düşünce ve tutum',
      'yol açar',
      'tehdit eder',
      'tedirgin etmek',
      'içine işlemek',
      'duygulandırmak',
      'gül taşıyorum',
      'teknoloji diyeti',
      'olması gerekir',
      'meydana gelir',
      'takdir ediyorum',
      'kullanılmamıştır',
      'iyi taktik',
    ],
    // Sayfa 164 - pembe
    [
      'sütten ağzı yandı',
      'arkadaş seçiminde',
      'daha dikkatli',
      'insan sarrafı',
      'ince eleyip',
      'yönlerini değiştir',
      'teknikleri kullan',
      'kullanılmamıştır',
      'bilim insanları',
      'kullanılmamıştır',
      'kaligrafi sanatı',
      'anlamlı şekiller',
      'çizgi tekniklerinin',
      'sık dokuduğundan',
      'yazı sistemi',
      'sonucuna varıyorlar',
      'bilgilere göre',
      'uygun yazılmıştır',
    ],
    // Sayfa 164 - mavi
    [
      'gül taşıyorum',
      'kesin yargılara',
      'kanıtlama amacı',
      'yazı türüdür',
      'farklı işlevleri',
      'müzik aleti',
      'kas hareketlerinin',
      'uyum hâlinde',
      'aktif çalışır',
      'toprak çanaklarda',
      'kanat çırpıyor',
      'cevap kâğıdı',
      'beni yüreklendir',
      'ayrılıp kavuşma',
      'yanlışlık yapılmıştır',
      'gül taşıyorum',
      'gençlik arkadaşı',
      'cevap kâğıdı',
    ],
    // Sayfa 165 - yeşil
    [
      'göz hastalığıdır',
      'reklam afişleri',
      'olumsuz tutumların',
      'meyvesiz ağaca',
      'insan büyüktür',
      'öğrenmenin sınırı',
      'köy köy dolaşmış',
      'gezgin olarak',
      'dile getiren kişi',
      'teknoloji diyeti',
      'lavanta kokulu',
      'teşekkür ederim',
      'güzel günlerin',
      'hayalini kuruyorum',
      'mecalsiz bir ihtiyar',
      'soframıza bereket',
      'bir tebessüm',
      'gül taşıyorum',
      'kullanılmamıştır',
      'yanlışlık yapılmıştır',
    ],
    // Sayfa 165 - pembe
    [
      'tırnak içindeki',
      'özel olarak',
      'cümle içerisinde',
      'bölüm başlıkları',
      'açıklamalara göre',
      'kullanımıyla ilgili',
      'yanlışlık yapılmıştır',
      'bilgi kuvvettir',
      'Kurtuluş Savaşı',
      'koca bir ömür',
      'tecrübeli insanlar',
      'nasihat etmekten',
      'sözün önemini',
      'birçok pişmanlık',
      'çok rastlanıyor',
      'feleğin çemberi',
      'teknoloji diyeti',
      'boş bırakılan',
      'teknolojisiz bir gün',
      'aşağıdaki tabloda',
    ],
    // Sayfa 165 - mavi
    [
      'büyüklerin sözü',
      'elinizdeki olanak',
      'kıymetini bilin',
      'teknoloji diyeti',
      'geleceğe odaklanın',
      'hayatta hep mutlu',
      'açıklamaya göre',
      'bazı şirketler',
      'masal gibi bir yerdi',
      'eserlerimdeki',
      'karakterlere',
      'yön verdi',
      'cevap vermek',
      'nasıl bir çocukluk',
      'nasıl etkiledi',
      'ne ölçüde',
      'toplumsal ilişkiler',
      'teknoloji diyeti',
      'teşekkür ederim',
    ],
    // Sayfa 166 - yeşil
    [
      'verilerini işleyip',
      'özel programlar',
      'araştırmaya göre',
      'tahmin edebiliyor',
      'beğendiğiniz içerik',
      'kültür seviyenizi',
      'ruh hâlinizi',
      'tespit edebiliyor',
      'internet şifrelerinin',
      'verimsiz kullanması',
      'haber ve yayınlara',
      'cevap kâğıdı',
      'ortaya çıkarabilir',
      'yanlışlık yapılmıştır',
      'değerlendiriyorsun',
      'kurtulmuştur',
      'kaybetmiştir',
      'gösteren grafik',
    ],
    // Sayfa 166 - pembe
    [
      'bazı açıklamalar',
      'resimle gösterilmesi',
      'bilgi verilmesi',
      'niteliklerinden',
      'örneklenmiştir',
      'bulunması beklenen',
      'örneklendirilmesi',
      'teşekkür ederim',
      'aşağıdaki tabloda',
      'aşağıdakilerden',
      'teknoloji diyeti',
      'trafik kurallarına',
      'sürücü belgesini',
      'kuralına uymak',
      'emniyet kemeri',
      'kural ihlalinde',
      'kimlik bilgilerini',
      'cevap kâğıdı',
    ],
    // Sayfa 166 - mavi
    [
      'kurşun kalemle',
      'çocukluk yıllarını',
      'yoksulluk içinde',
      'azim ve iradesi',
      'engeli aşmak',
      'ilim ve kültür',
      'iftihar ettiği',
      'bir ilim insanı',
      'numaralanmış',
      'gazetecilerle',
      'düşüncelerinizin',
      'şiddetli soğuktan',
      'toprağın altındaki',
      'bitki ve hayvanlar',
      'ilkbahara hazırlan',
      'karlar eridiğinde',
      'tüm canlılığıyla',
      'cevap verdi',
    ],
  ];

  static const List<Color> _bgByRole = [
    Color(0xFFDCF5C7),
    Color(0xFFF7D9E8),
    Color(0xFFCDEBF7),
  ];
  static const List<Color> _borderByRole = [
    Color(0xFF4D7C0F),
    Color(0xFFBE185D),
    Color(0xFF0369A1),
  ];

  // Ekrana 3 yerine 2 sütun sığdığı için sütunlar ikişer ikişer eşlenip
  // sayfalara bölündü (15 sütun -> 7 ikili + 1 tekli = 8 sayfa).
  late final List<List<int>> _pages = [
    for (int i = 0; i < _columns.length; i += 2)
      if (i + 1 < _columns.length) [i, i + 1] else [i],
  ];

  static const List<_CountChallenge> _challenges = [
    _CountChallenge('teknoloji diyeti', 9),
    _CountChallenge('cevap kâğıdı', 6),
    _CountChallenge('kullanılmamıştır', 6),
    _CountChallenge('gül taşıyorum', 5),
    _CountChallenge('yanlışlık yapılmıştır', 5),
    _CountChallenge('teşekkür ederim', 5),
  ];

  _Phase _phase = _Phase.intro;
  bool _hasCompletedOnce = false;
  bool _isPaused = false;
  int _speedLevel = 1;

  int _pageIndex = 0;
  int _directionIndex = 0;
  int _activeIndex = 0;
  Timer? _sweepTimer;
  bool _blinkOn = true;
  Timer? _blinkTimer;

  int _challengeIndex = 0;
  int _bolum2Selected = 0;
  bool _bolum2Answered = false;

  @override
  void dispose() {
    _sweepTimer?.cancel();
    _blinkTimer?.cancel();
    super.dispose();
  }

  List<int> get _currentColumns =>
      _phase == _Phase.warmup ? [0, 1] : _pages[_pageIndex];

  int get _currentRows {
    final cols = _currentColumns;
    int maxLen = 0;
    for (final c in cols) {
      final len = _phase == _Phase.warmup ? 8 : _columns[c].length;
      if (len > maxLen) maxLen = len;
    }
    return maxLen;
  }

  String? _cellText(int row, int col) {
    final cols = _currentColumns;
    if (col >= cols.length) return null;
    final lines = _columns[cols[col]];
    if (row >= (_phase == _Phase.warmup ? 8 : lines.length)) return null;
    return lines[row];
  }

  List<int> _sweepOrder(_Direction dir) {
    final rows = _currentRows;
    final order = <int>[];
    bool exists(int r, int c) => _cellText(r, c) != null;
    switch (dir) {
      case _Direction.leftToRight:
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < _cols; c++) {
            if (exists(r, c)) order.add(r * _cols + c);
          }
        }
      case _Direction.rightToLeft:
        for (int r = 0; r < rows; r++) {
          for (int c = _cols - 1; c >= 0; c--) {
            if (exists(r, c)) order.add(r * _cols + c);
          }
        }
      case _Direction.bottomToTop:
        for (int c = 0; c < _cols; c++) {
          for (int r = rows - 1; r >= 0; r--) {
            if (exists(r, c)) order.add(r * _cols + c);
          }
        }
      case _Direction.topToBottom:
        for (int c = 0; c < _cols; c++) {
          for (int r = 0; r < rows; r++) {
            if (exists(r, c)) order.add(r * _cols + c);
          }
        }
    }
    return order;
  }

  late List<int> _sweepIndices = [];

  void _startWarmup() {
    setState(() {
      _phase = _Phase.warmup;
      _directionIndex = 0;
    });
    _startDirection();
  }

  void _startExercise() {
    setState(() {
      _phase = _Phase.exercise;
      _pageIndex = 0;
      _directionIndex = 0;
    });
    _startDirection();
  }

  void _startDirection() {
    _sweepTimer?.cancel();
    _blinkTimer?.cancel();
    _sweepIndices = _sweepOrder(_directions[_directionIndex]);
    setState(() {
      _activeIndex = 0;
      _blinkOn = true;
    });
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 380), (_) {
      if (!mounted) return;
      setState(() => _blinkOn = !_blinkOn);
    });
    _scheduleStep();
  }

  void _scheduleStep() {
    _sweepTimer?.cancel();
    _sweepTimer = Timer(
      Duration(milliseconds: _stepMsBySpeed[_speedLevel]),
      () {
        if (!mounted) return;
        SoundManager.playTick();
        if (_activeIndex >= _sweepIndices.length - 1) {
          _onDirectionDone();
        } else {
          setState(() => _activeIndex++);
          _scheduleStep();
        }
      },
    );
  }

  void _onDirectionDone() {
    if (_directionIndex < _directions.length - 1) {
      setState(() => _directionIndex++);
      _startDirection();
      return;
    }
    if (_phase == _Phase.warmup) {
      _blinkTimer?.cancel();
      setState(() => _phase = _Phase.ready);
      return;
    }
    if (_pageIndex < _pages.length - 1) {
      setState(() {
        _pageIndex++;
        _directionIndex = 0;
      });
      _startDirection();
    } else {
      setState(() => _phase = _Phase.bolum2Intro);
    }
  }

  void _changeSpeed(int level) {
    setState(() {
      _speedLevel = level;
      _activeIndex = 0;
    });
    _sweepTimer?.cancel();
    _scheduleStep();
  }

  void _pauseGame() {
    _sweepTimer?.cancel();
    _blinkTimer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resumeGame() {
    setState(() => _isPaused = false);
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 380), (_) {
      if (!mounted) return;
      setState(() => _blinkOn = !_blinkOn);
    });
    _scheduleStep();
  }

  void _startBolum2() {
    setState(() {
      _phase = _Phase.bolum2Search;
      _challengeIndex = 0;
    });
  }

  void _goToAnswer() {
    setState(() {
      _phase = _Phase.bolum2Answer;
      _bolum2Answered = false;
      _bolum2Selected = 0;
    });
  }

  void _submitBolum2Answer(int selected) {
    if (_bolum2Answered) return;
    final correct = _challenges[_challengeIndex].correctCount;
    setState(() {
      _bolum2Selected = selected;
      _bolum2Answered = true;
    });
    if (selected == correct) {
      SoundManager.playCorrect();
    } else {
      SoundManager.playGentleTap();
    }
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_challengeIndex >= _challenges.length - 1) {
        _finishAll();
      } else {
        setState(() {
          _challengeIndex++;
          _phase = _Phase.bolum2Search;
        });
      }
    });
  }

  void _finishAll() {
    _hasCompletedOnce = true;

    const percent = 100;
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Sınav Kelimeleri',
      result: '${_pages.length} sayfa · 4 yön · ${_challenges.length} soru',
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
              '${_pages.length} sayfayı 4 yönden taradık, sonra '
              '${_challenges.length} tekrar sorusunu cevapladık!',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
              _startWarmup();
            },
            child: const Text('Yeniden Başlat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompletionPopScope(
      isCompleted: () => _hasCompletedOnce,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('📝 Sınav Kelimeleri'),
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
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: switch (_phase) {
                  _Phase.intro => _buildIntro(),
                  _Phase.warmup => _buildScan(
                    key: ValueKey('warmup-$_directionIndex'),
                  ),
                  _Phase.ready => _buildReady(),
                  _Phase.exercise => _buildScan(
                    key: ValueKey('ex-$_pageIndex-$_directionIndex'),
                  ),
                  _Phase.bolum2Intro => _buildBolum2Intro(),
                  _Phase.bolum2Search => _buildBolum2Search(),
                  _Phase.bolum2Answer => _buildBolum2Answer(),
                },
              ),
              if (_isPaused)
                buildPauseOverlay(color: _color, onResume: _resumeGame),
            ],
          ),
        ),
      ),
    );
  }

  Widget _speedChipRow() {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        Text(
          'Hız: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
        for (int i = 0; i < _speedLabels.length; i++)
          ChoiceChip(
            label: Text(_speedLabels[i]),
            selected: _speedLevel == i,
            onSelected: (_) => _changeSpeed(i),
            selectedColor: _color,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _speedLevel == i ? Colors.white : _color,
            ),
            backgroundColor: _color.withValues(alpha: 0.08),
            side: BorderSide(
              color: _color.withValues(alpha: _speedLevel == i ? 1 : 0.3),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }

  Widget _buildScan({required Key key}) {
    final isWarmup = _phase == _Phase.warmup;
    return KeyedSubtree(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    isWarmup
                        ? '🎓 Antreman · ${_directionLabels[_directionIndex]}'
                        : '1. Bölüm · Sayfa ${_pageIndex + 1}/${_pages.length} · '
                              '${_directionLabels[_directionIndex]}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              buildPauseButton(color: _color, onPressed: _pauseGame),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (int i = 0; i < _directions.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= _directionIndex
                        ? _color
                        : _color.withValues(alpha: 0.15),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          _speedChipRow(),
          const SizedBox(height: 12),
          Expanded(child: _grid()),
        ],
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
                    'Etkinlik 4 · Sınav Kelimeleri',
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
                      child: Text('📝', style: TextStyle(fontSize: 72)),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _color, width: 1.2),
                      ),
                      child: const Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF581C87),
                          ),
                          children: [
                            TextSpan(
                              text: 'Amaç: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  'Sınavda çıkan kelime gruplarıyla göze '
                                  'ritim kazandırmak.\n',
                            ),
                            TextSpan(
                              text: 'Yöntem: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  'Kelime gruplarının ortasına odaklanarak '
                                  'tek bakışta algılamaya çalış. Önce '
                                  'antremanı yapacağız, sonra sıra sende '
                                  '— 8 sayfayı da bu şekilde '
                                  'tarayacaksın!',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _speedChipRow(),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _startWarmup,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text(
                        'ANTREMANA GEÇ',
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

  Widget _buildReady() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: Text('📝', style: TextStyle(fontSize: 64))),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Antremanı tamamladık! Şimdi sıra sende — az önce '
                    'izlediğin gibi kutucuğu takip ederek 8 sayfayı da 4 '
                    'yönde tarayacaksın.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: _color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _startExercise,
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBolum2Intro() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: Text('🔁', style: TextStyle(fontSize: 64))),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '8 sayfayı tamamladık! Şimdi 2. Bölüm: metinde bazı '
                    'kelime grupları tekrar tekrar geçiyordu. Şimdi '
                    'sayfaları serbestçe tarayıp bir kelime grubunun kaç '
                    'kere geçtiğini bulacaksın — ${_challenges.length} soru '
                    'var!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: _color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _startBolum2,
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBolum2Search() {
    final challenge = _challenges[_challengeIndex];
    return Column(
      key: ValueKey('search-$_challengeIndex'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Soru ${_challengeIndex + 1}/${_challenges.length} · '
            '"${challenge.target}" kaç kere geçiyor?',
            style: TextStyle(fontWeight: FontWeight.bold, color: _color),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: _columns.length,
            itemBuilder: (context, colIndex) {
              final role = colIndex % 3;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _bgByRole[role],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderByRole[role], width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final line in _columns[colIndex])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          line,
                          style: TextStyle(
                            fontSize: 13,
                            color: _borderByRole[role],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _goToAnswer,
            icon: const Icon(Icons.check),
            label: const Text(
              'SAYDIM, CEVAPLA',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

  Widget _buildBolum2Answer() {
    final challenge = _challenges[_challengeIndex];
    final options = <int>{challenge.correctCount};
    final seed = challenge.correctCount + challenge.target.length;
    var probe = seed;
    while (options.length < 4) {
      probe += 3;
      final candidate = (challenge.correctCount - 2 + (probe % 5)).clamp(1, 14);
      options.add(candidate);
    }
    final sortedOptions = options.toList()..sort();
    return LayoutBuilder(
      key: ValueKey('answer-$_challengeIndex'),
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(
                    'Soru ${_challengeIndex + 1}/${_challenges.length}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '"${challenge.target}"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _color,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'kaç kere geçti?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (_bolum2Answered) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      _bolum2Selected == challenge.correctCount
                          ? '🎉 Harikasın, doğru!'
                          : '📖 Doğrusu: ${challenge.correctCount}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _bolum2Selected == challenge.correctCount
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFE11D48),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final option in sortedOptions)
                      _bolum2AnswerButton(option, challenge.correctCount),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _bolum2AnswerButton(int option, int correctCount) {
    final answered = _bolum2Answered;
    final isSelected = _bolum2Selected == option && answered;
    final isCorrectOption = option == correctCount;
    Color bg = _color.withValues(alpha: 0.08);
    Color border = _color.withValues(alpha: 0.3);
    Color fg = _color;
    if (answered && isCorrectOption) {
      bg = const Color(0xFF16A34A).withValues(alpha: 0.12);
      border = const Color(0xFF16A34A);
      fg = const Color(0xFF16A34A);
    } else if (answered && isSelected && !isCorrectOption) {
      bg = const Color(0xFFE11D48).withValues(alpha: 0.12);
      border = const Color(0xFFE11D48);
      fg = const Color(0xFFE11D48);
    }
    return SizedBox(
      width: 64,
      height: 64,
      child: OutlinedButton(
        onPressed: answered ? null : () => _submitBolum2Answer(option),
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          side: BorderSide(color: border, width: 2),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          '$option',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: fg,
          ),
        ),
      ),
    );
  }

  Widget _grid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final rows = _currentRows;
        final cols = _currentColumns;
        final cellWidth =
            (constraints.maxWidth - spacing * (_cols - 1)) / _cols;
        final rawCellHeight =
            (constraints.maxHeight - spacing * (rows - 1)) / rows;
        final cellHeight = rawCellHeight.clamp(34.0, 60.0);

        Widget cellAt(int r, int c) {
          final text = _cellText(r, c);
          if (text == null) return SizedBox(width: cellWidth);
          final index = r * _cols + c;
          final isActive =
              index ==
              (_sweepIndices.isEmpty ? -1 : _sweepIndices[_activeIndex]);
          final lit = isActive && _blinkOn;
          final role = c < cols.length ? cols[c] % 3 : 0;
          return SizedBox(
            width: cellWidth,
            height: cellHeight,
            child: _cell(text, lit: lit, role: role),
          );
        }

        final rowWidgets = <Widget>[
          for (int r = 0; r < rows; r++)
            Padding(
              padding: EdgeInsets.only(bottom: r < rows - 1 ? spacing : 0),
              child: Row(
                children: [
                  for (int c = 0; c < _cols; c++) ...[
                    if (c > 0) const SizedBox(width: spacing),
                    cellAt(r, c),
                  ],
                ],
              ),
            ),
        ];

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: rowWidgets,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cell(String text, {required bool lit, required int role}) {
    Color bg = lit ? _color : _bgByRole[role];
    Color fg = lit ? Colors.white : _borderByRole[role];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: lit ? _color : _borderByRole[role],
          width: 1.2,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

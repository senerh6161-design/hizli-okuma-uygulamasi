import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';

enum _Direction { leftToRight, rightToLeft, topToBottom, bottomToTop }

enum _Phase { intro, warmup, transition, exercise }

/// Klasör 3'ün üçüncü etkinliği: "Dört Yönlü Kelime Taraması". Sabit bir
/// ızgara (4 sütun) üzerinde vurgulanan kutucuk sırayla dört farklı yönde
/// geziniyor: önce soldan sağa, sayfa bitince sağdan sola, sonra yukarıdan
/// aşağıya, en son aşağıdan yukarıya. Önce gülen yüzlerle puansız bir
/// antreman yapılıyor, ardından hocanın verdiği kelime listesindeki TÜM
/// kelimeler sayfalara bölünerek aynı dört yönlü tarama ile gösteriliyor.
class FourDirectionScanPage extends StatefulWidget {
  const FourDirectionScanPage({super.key});

  @override
  State<FourDirectionScanPage> createState() => _FourDirectionScanPageState();
}

class _FourDirectionScanPageState extends State<FourDirectionScanPage> {
  static const Color _color = Color(0xFF7C3AED);
  static const List<String> _speedLabels = ['Yavaş', 'Orta', 'Hızlı'];
  static const List<int> _stepMsBySpeed = [700, 450, 260];
  static const List<String> _directionLabels = [
    'Soldan Sağa',
    'Sağdan Sola',
    'Yukarıdan Aşağıya',
    'Aşağıdan Yukarıya',
  ];
  static const List<_Direction> _directions = [
    _Direction.leftToRight,
    _Direction.rightToLeft,
    _Direction.topToBottom,
    _Direction.bottomToTop,
  ];

  static const int _warmupCols = 4;
  static const int _warmupRows = 5;
  static const String _warmupEmoji = '😊';

  static const int _exerciseCols = 4;
  static const int _exerciseRowsPerPage = 6; // sayfa başına 24 hücre

  // Hocanın paylaştığı kelime tablosundaki TÜM kelimeler — sırasıyla,
  // hiçbiri atlanmadan. Tablo A-G sütunları, satır satır okunarak buraya
  // aktarıldı.
  static const List<String> _wordPool = [
    'Anlam',
    'Kavram',
    'Hikaye',
    'Şiir',
    'Efsane',
    'Deyim',
    'Betimleme',
    'Tema',
    'Konu',
    'Fiil',
    'Çarpma',
    'Oran',
    'Olay',
    'Biyografi',
    'Doğru',
    'Bölme',
    'Çember',
    'Kesir',
    'Paralel',
    'Hacim',
    'Molekül',
    'Üçgen',
    'Kare',
    'Atom',
    'Karışım',
    'Enerji',
    'Kuvvet',
    'Çözünürlük',
    'Elektrik',
    'Devre',
    'Çekim',
    'İskelet',
    'Kalıtım',
    'Haber',
    'Solunum',
    'Denge',
    'Kültür',
    'Devlet',
    'Anayasa',
    'İklim',
    'Barış',
    'Kimyasal',
    'Savaş',
    'Tarım',
    'Kıta',
    'Deniz',
    'Kuzey',
    'Şehir',
    'Cumhuriyet',
    'Yaklaşım',
    'Mera',
    'Akarsu',
    'Nehir',
    'Kasaba',
    'Tarih',
    'Coğrafya',
    'Temsilci',
    'Kapsam',
    'Üslup',
    'Eleştiri',
    'Tezat',
    'Abartı',
    'Yarımada',
    'Özgün',
    'Termal',
    'Bağlam',
    'İfade',
    'Anlatım',
    'Duygu',
    'Yakınçağ',
    'Derinlik',
    'Gözlem',
    'İzlenim',
    'Tartışma',
    'İletişim',
    'Söylem',
    'Bağımsızlık',
    'Özdeyiş',
    'Boylam',
    'Önyargı',
    'Mantık',
    'Sonuç',
    'Çelişki',
    'Vatandaşlık',
    'Süreç',
    'Aşama',
    'Delta',
    'Sezgi',
    'Miras',
    'Nitelik',
    'Kurgulamak',
    'Nicelik',
    'Belirgin',
    'Direnç',
    'Harita',
    'Reklam',
    'Sosyal',
    'Farkındalık',
    'Tarım',
    'Sulama',
    'Toprak',
    'Sağlık',
    'Egzersiz',
    'Sonuç',
    'Karşılaştırma',
    'Medya',
    'Gelişme',
    'Deney',
    'Hipotez',
    'Meclis',
    'Kütle',
    'Sorgulamak',
    'Spor',
    'Müzik',
    'Trafik',
    'Protein',
    'Kırsal',
    'Mineral',
    'Vurgulamak',
    'Giriş',
    'Tekil',
    'Soyut',
    'Eklem',
    'Tiyatro',
    'Somut',
    'Karakter',
    'İlim',
    'Sinir',
    'Sinema',
    'Damar',
    'Hasat',
    'Atasözü',
    'Sürükleyici',
    'Sanat',
    'Tekrar',
    'Tümleç',
    'Zarf',
    'Cümle',
    'Kültür',
    'Fotosentez',
    'Heyelan',
    'Zamir',
    'Görenek',
    'Krater',
    'Levha',
    'Bütçe',
    'Adaptasyon',
    'Vitamin',
    'Çoğul',
    'Sıfat',
    'Uydu',
    'Galaksi',
    'Gelenek',
    'Medeniyet',
    'Özne',
    'Yıldız',
    'Yankı',
    'Frekans',
    'Yansıma',
    'Yüklem',
    'Okyanus',
    'Bakteri',
    'Hijyen',
    'Güzel',
    'Zanaat',
    'Cenk',
    'Zafer',
    'Ekosistem',
    'Samimi',
    'Tatlı',
    'Zeybek',
    'Hünkâr',
    'Türkmen',
    'Kalpak',
    'Sindirim',
    'Dingin',
    'Hançer',
    'Kardeş',
    'Meslek',
    'Kervan',
    'Güven',
    'Metabolizma',
    'Umut',
    'Ahilik',
    'Sancak',
    'Şefkat',
    'Değer',
    'Bağlılık',
    'Bağışıklık',
    'Ferah',
    'Yemin',
    'Tüccar',
    'Töre',
    'Umut',
    'Aşiret',
    'Hastalık',
    'Sevgi',
    'Kaftan',
    'Neşe',
    'Yiğit',
    'Korkut',
    'Ödev',
    'Mikroskop',
    'Destan',
    'Umut',
    'Sevgi',
    'Barış',
    'Huzur',
    'Sıcaklık',
    'Element',
    'Dostluk',
    'Proje',
    'Saat',
    'Konu',
    'Çizim',
    'Test',
    'Malazgirt',
    'Sınav',
    'Harita',
    'Fırça',
    'Desen',
    'Nota',
    'Melodi',
    'Mutluluk',
    'Takvim',
    'Çeviri',
    'Odak',
    'Uzantı',
    'Ulusal',
    'Varsayım',
    'Organizma',
    'Tuval',
    'Öngörü',
    'Gelgit',
    'Yükümlü',
    'Özenti',
    'Yavan',
    'Gülümse',
    'Nezaket',
    'Metot',
    'Kalıcı',
    'Özdeş',
    'Maksat',
    'Yargı',
    'Sağduyu',
    'Yapıtaşı',
    'Kuşku',
    'İmge',
    'Dipnot',
    'İrade',
    'Lirik',
    'Alternatif',
    'Yapaylık',
    'Drama',
    'Boyut',
    'Deneyim',
    'Coşkun',
    'Kaynak',
    'Perspektif',
    'Yenilik',
    'Kanaat',
    'Mahlas',
    'Ayrıntı',
    'Kaygı',
    'Anlatım',
    'Kompozisyon',
    'Yinele',
    'Kalıp',
    'Özlü',
    'Sanal',
    'Kitle',
    'Klişe',
    'Enstrüman',
    'Trajedi',
    'Rastgele',
    'Çalışma',
    'Simge',
    'Sentez',
    'Biçim',
    'Jimnastik',
    'Otorite',
    'Sulh',
    'Taslak',
    'Analiz',
    'Yalın',
    'Kalıcı',
    'Antrenman',
    'Özveri',
    'Garp',
    'İrdele',
    'İrade',
    'Ocak',
    'Özerk',
    'Peygamber',
    'Koşul',
    'Çehre',
    'Hüzün',
    'Alaca',
    'Sığ',
    'Hicret',
    'Üstünkörü',
    'Katmerli',
    'İvedi',
    'Hoşgörü',
    'Çelişki',
    'Bulgu',
    'İleti',
    'Terennüm',
    'İzlenim',
    'Örtük',
    'Seçkin',
    'Çevik',
    'İkilem',
    'Refleks',
    'Tökezlemek',
    'İrkilmek',
    'Faktör',
    'Arşiv',
    'Karşıt',
    'Motif',
    'Özlem',
    'Örselenmek',
  ];

  late final List<List<String>> _wordPages = _buildWordPages();

  _Phase _phase = _Phase.intro;
  bool _hasCompletedOnce = false;
  bool _isPaused = false;
  int _speedLevel = 1;

  List<String> _currentItems = const [];
  int _cols = _warmupCols;
  int _rows = _warmupRows;
  List<int> _sweepIndices = const [];
  int _sweepPos = 0;
  int _directionIndex = 0;
  int _pageIndex = 0;
  Timer? _sweepTimer;
  int _elapsedSec = 0;
  Timer? _elapsedTimer;

  @override
  void dispose() {
    _sweepTimer?.cancel();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  List<List<String>> _buildWordPages() {
    const perPage = _exerciseCols * _exerciseRowsPerPage;
    final pages = <List<String>>[];
    for (int i = 0; i < _wordPool.length; i += perPage) {
      final end = i + perPage > _wordPool.length
          ? _wordPool.length
          : i + perPage;
      pages.add(_wordPool.sublist(i, end));
    }
    return pages;
  }

  // Aktif ızgaranın tek bir yöndeki gezinme sırası — sadece o anda dolu
  // olan hücreleri (son sayfa eksik kalabilir) içerir.
  List<int> _sweepOrder(int cols, int rows, _Direction dir) {
    final order = <int>[];
    final cellCount = _currentItems.length;
    switch (dir) {
      case _Direction.leftToRight:
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            final i = r * cols + c;
            if (i < cellCount) order.add(i);
          }
        }
      case _Direction.rightToLeft:
        for (int r = 0; r < rows; r++) {
          for (int c = cols - 1; c >= 0; c--) {
            final i = r * cols + c;
            if (i < cellCount) order.add(i);
          }
        }
      case _Direction.topToBottom:
        for (int c = 0; c < cols; c++) {
          for (int r = 0; r < rows; r++) {
            final i = r * cols + c;
            if (i < cellCount) order.add(i);
          }
        }
      case _Direction.bottomToTop:
        for (int c = 0; c < cols; c++) {
          for (int r = rows - 1; r >= 0; r--) {
            final i = r * cols + c;
            if (i < cellCount) order.add(i);
          }
        }
    }
    return order;
  }

  void _startSweep() {
    _sweepTimer?.cancel();
    _sweepIndices = _sweepOrder(_cols, _rows, _directions[_directionIndex]);
    setState(() => _sweepPos = 0);
    SoundManager.playTick();
    _scheduleSweepStep();
  }

  void _scheduleSweepStep() {
    final stepMs = _stepMsBySpeed[_speedLevel];
    _sweepTimer = Timer(Duration(milliseconds: stepMs), () {
      if (!mounted) return;
      if (_sweepPos >= _sweepIndices.length - 1) {
        _onDirectionDone();
      } else {
        setState(() => _sweepPos++);
        SoundManager.playTick();
        _scheduleSweepStep();
      }
    });
  }

  void _onDirectionDone() {
    if (_directionIndex < _directions.length - 1) {
      setState(() => _directionIndex++);
      _startSweep();
    } else if (_phase == _Phase.warmup) {
      _finishWarmup();
    } else {
      _advanceExercisePage();
    }
  }

  // Hız değişince öğrenci taramanın başına dönsün diye mevcut yön en
  // baştan başlatılıyor.
  void _changeSpeed(int level) {
    _sweepTimer?.cancel();
    setState(() {
      _speedLevel = level;
      _sweepPos = 0;
    });
    _scheduleSweepStep();
  }

  void _pauseGame() {
    _sweepTimer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resumeGame() {
    setState(() => _isPaused = false);
    _scheduleSweepStep();
  }

  void _startWarmup() {
    setState(() {
      _phase = _Phase.warmup;
      _cols = _warmupCols;
      _rows = _warmupRows;
      _currentItems = List.filled(_warmupCols * _warmupRows, _warmupEmoji);
      _directionIndex = 0;
    });
    _startSweep();
  }

  void _finishWarmup() {
    _sweepTimer?.cancel();
    setState(() => _phase = _Phase.transition);
  }

  void _startExercise() {
    _elapsedTimer?.cancel();
    _elapsedSec = 0;
    _pageIndex = 0;
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSec++);
    });
    _loadExercisePage();
  }

  void _loadExercisePage() {
    final page = _wordPages[_pageIndex];
    setState(() {
      _phase = _Phase.exercise;
      _currentItems = page;
      _cols = _exerciseCols;
      _rows = (page.length / _exerciseCols).ceil();
      _directionIndex = 0;
    });
    _startSweep();
  }

  void _advanceExercisePage() {
    if (_pageIndex < _wordPages.length - 1) {
      _pageIndex++;
      _loadExercisePage();
    } else {
      _finishAll();
    }
  }

  void _finishAll() {
    _sweepTimer?.cancel();
    _elapsedTimer?.cancel();
    _hasCompletedOnce = true;

    const percent = 100;
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Dört Yönlü Kelime Taraması',
      result: '${_wordPages.length} sayfa · $_elapsedSec sn',
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
              'Toplam ${_wordPages.length} sayfa kelimeyi 4 yönde de taradık!',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              'Süre: $_elapsedSec sn',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
              setState(() => _phase = _Phase.intro);
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
        appBar: AppBar(title: const Text('🧭 Dört Yönlü Tarama')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildBody(),
              ),
              if (_isPaused)
                buildPauseOverlay(color: _color, onResume: _resumeGame),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _Phase.intro:
        return _buildIntro();
      case _Phase.transition:
        return _buildTransition();
      case _Phase.warmup:
        return _buildScanScreen(key: ValueKey('warmup-$_directionIndex'));
      case _Phase.exercise:
        return _buildScanScreen(
          key: ValueKey('exercise-$_pageIndex-$_directionIndex'),
        );
    }
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
                  child: const Text(
                    'Etkinlik 3 · Dört Yönlü Kelime Taraması',
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _color, width: 1.5),
                      ),
                      child: const Text(
                        'Amaç: Gözlerimizin farklı yönlerdeki tarama hızını '
                        'artırmak.\n\nYöntem: Önce gülen yüzlerle küçük bir '
                        'antreman yapacağız. Sonra aynı taramayı '
                        'kelimelerle yapacağız — her seferinde önce soldan '
                        'sağa, sonra sağdan sola, sonra yukarıdan aşağıya, '
                        'en son aşağıdan yukarıya tarayacağız.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4C1D95),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text('🧭', style: TextStyle(fontSize: 64)),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: _color,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Vurgulanan kutucuğu gözünle takip edeceğiz — '
                              'kutucuk hangi yöne gidiyorsa gözümüz de o '
                              'yöne gidecek. Hazır olduğunda antremanla '
                              'başlayalım!',
                              style: TextStyle(
                                fontSize: 13,
                                color: _color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildTransition() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: Text('✅', style: TextStyle(fontSize: 64))),
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
                    'Antremanı tamamladık! Şimdi aynı taramayı '
                    'kelimelerle yapacağız — toplam ${_wordPages.length} '
                    'sayfa kelime göreceğiz, hazır olduğunda devam edelim!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
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
                      'DEVAM ET',
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

  Widget _speedChipRow() {
    return Row(
      children: [
        Text(
          'Hız: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 6),
        for (int i = 0; i < _speedLabels.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          ChoiceChip(
            label: Text(_speedLabels[i]),
            selected: _speedLevel == i,
            onSelected: (_) {
              if (_phase == _Phase.intro || _phase == _Phase.transition) {
                setState(() => _speedLevel = i);
              } else {
                _changeSpeed(i);
              }
            },
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
      ],
    );
  }

  Widget _directionProgressDots() {
    return Row(
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
    );
  }

  Widget _buildScanScreen({required Key key}) {
    final isWarmup = _phase == _Phase.warmup;
    return KeyedSubtree(
      key: key,
      child: Column(
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
                    isWarmup
                        ? '🎓 Antreman · ${_directionLabels[_directionIndex]}'
                        : 'Sayfa ${_pageIndex + 1}/${_wordPages.length} · '
                              '${_directionLabels[_directionIndex]}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (!isWarmup)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Text(
                    '⏱ $_elapsedSec sn',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
              buildPauseButton(color: _color, onPressed: _pauseGame),
            ],
          ),
          const SizedBox(height: 10),
          _directionProgressDots(),
          const SizedBox(height: 10),
          _speedChipRow(),
          const SizedBox(height: 12),
          Expanded(child: _buildGrid()),
        ],
      ),
    );
  }

  // Kutucuklar küçük bir alana sıkışmasın, tüm ekranı kullansın diye
  // hücre boyutu ekrana göre hesaplanıyor. Sadece o an sırası gelen
  // hücre yanıp beliriyor; sırası geçince tamamen kayboluyor — diğer
  // hücreler sıra kendilerine gelene kadar hep boş.
  Widget _buildGrid() {
    final activeIndex = _sweepIndices.isEmpty ? -1 : _sweepIndices[_sweepPos];
    final isWarmup = _phase == _Phase.warmup;
    const spacing = 8.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth =
              (constraints.maxWidth - spacing * (_cols - 1)) / _cols;
          final cellHeight =
              (constraints.maxHeight - spacing * (_rows - 1)) / _rows;
          final aspectRatio = cellWidth / cellHeight;
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _cols,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
            ),
            itemCount: _currentItems.length,
            itemBuilder: (context, index) {
              final isActive = index == activeIndex;
              return AnimatedOpacity(
                duration: const Duration(milliseconds: 90),
                opacity: isActive ? 1 : 0,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 90),
                  scale: isActive ? 1 : 0.8,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _color.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _currentItems[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isWarmup ? 42 : 22,
                            fontWeight: FontWeight.bold,
                            color: _color,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';

class _Page {
  final List<String> left;
  final List<String> right;
  const _Page(this.left, this.right);
  int get totalLines => left.length + right.length;
}

enum _Phase { intro, warmup, transition, reading }

/// Klasör 3'ün yedinci etkinliği: "Sütun Takibi". Kitaptaki çok sütunlu,
/// yukarıdan aşağıya okunan metin sayfalarının karşılığı (kitapta
/// "Gökkuşağı Tadında Bir Hayat" gibi metinler bu düzende veriliyor) —
/// Eş/Zıt Anlamlı Kelimeler etkinliğindeki nokta/yanıp sönme mekaniğiyle
/// aynı mantık, ama kelime kutucukları yerine gerçek bir metin var: sol
/// sütun yukarıdan aşağıya, sonra sağ sütun yukarıdan aşağıya izleniyor.
/// Önce kısa bir antreman, sonra "Hızlı Okumanın Alışkanlık Haline
/// Gelmesi İçin Önemli On Madde" metninin tamamı bu şekilde okunuyor.
class ColumnReadingPage extends StatefulWidget {
  const ColumnReadingPage({super.key});

  @override
  State<ColumnReadingPage> createState() => _ColumnReadingPageState();
}

class _ColumnReadingPageState extends State<ColumnReadingPage> {
  static const Color _color = Color(0xFF4338CA);
  static const List<String> _speedLabels = ['Yavaş', 'Orta', 'Hızlı'];
  static const List<int> _stepMsBySpeed = [900, 600, 350];
  int _speedLevel = 1;

  static const int _wordsPerLine = 2;
  static const int _linesPerColumn = 10;
  static const int _warmupLineCount = 8;

  // Hocanın onayıyla kullanılan tam metin (folder1/folder2 antreman
  // metniyle aynı) — "Hızlı Okumanın Alışkanlık Haline Gelmesi İçin
  // Önemli On Madde".
  static const String _fullText =
      'HIZLI OKUMANIN ALIŞKANLIK HALİNE GELMESİ İÇİN ÖNEMLİ ON MADDE:\n\n'
      '1. İlk zamanlar sadece göz hızını artırınız.\n'
      'İlk zamanlar anlamaya odaklanmayınız. Yoksa hızınız istenilen '
      'düzeye çıkmayabilir. Eski alışkanlıkları yıkmak tabii ki çok zor. '
      'Dolayısıyla asla önyargılı olmayınız. Bir de başaracağınıza olan '
      'inanç çok yüksek olsun. Şunu da unutmayınız ki: "Ben '
      'başaramayacağım galiba." diye işe başlayanla "Ben bu işi '
      'başaracağım." diye başlayanın elde edecekleri sonuç asla aynı '
      'olmayacaktır. Zihnimizde şöyle bir düşünce baloncuğu '
      'oluşturalım: "Her şeye rağmen çalışacağım. Başarana kadar '
      'vazgeçmeyeceğim!" Emin olun ki insanların çoğu, kaybettikleri '
      'için başarısız olmazlar. İnsanların çoğunun başarısız olmasının '
      'nedeni, yaptıkları işi yarıda bırakıp pes etmeleri, o işi '
      'neticelendirmemeleridir. Bir işi yarıda bırakmak, onu hiç '
      'yapmamakla eş değer olduğu gibi insan için zaman, enerji ve '
      'özgüven kaybına da sebep olur.\n\n'
      '2. Egzersizleri her gün uygulayınız.\n'
      'Gözlerimiz ve beynimiz, hızlı görmeye ve odaklanmaya alışıncaya '
      'kadar, göz-beyin arasındaki uyum hızını en az iki katına '
      'çıkarana kadar, egzersizleri her gün, en az 3-4 hafta boyunca '
      'aralıksız yapmalı.\n\n'
      '3. Sözcükleri içten ve dıştan seslendirmeyiniz!\n'
      'İçten okumanın ya da dudakla okumanın sesli okumadan pek de '
      'farkı yoktur. İç sesi tamamen yok edemeyiz belki; ama en aza '
      'indirmemiz gerekir. Bu kazanım da, kitaptaki etkinlikleri '
      'verilen sayıda ve sürelerde yapmaya bağlı olarak zamanla '
      'oluşacaktır. Seslendirerek 1 dakikada okuyacağımız kelime '
      'sayısı sınırlıdır. Sesli olarak anlaşılabilir bir şekilde '
      'okuyacağımız sözcük sayısı 250-300 kelime arasındadır. Daha '
      'fazlası okunsa da anlaşılmaz; ama sessiz okumanın sınırı '
      'kişiden kişiye değişir. Örneğin hızlı okuma tekniğini öğrenmiş '
      'bir öğrenci dakikada 400-800 kelime okuyabilir.\n\n'
      '4. Sözcük hazinenizi her gün bir kelime de olsa geliştiriniz.\n'
      'Eğer bir öğrenci bir kitap kurduysa ve sözcük hazinesi çok '
      'zenginse bu okuma oranı gitgide artacaktır. Yeteneğine, almış '
      'olduğu eğitime, kitap okuma alışkanlığına ve kendini sürekli '
      'geliştirmesine bağlı olarak bu 1 dakikada okunan kelime sayısı, '
      'daha da yükselecektir. Yani sözcükleri içten seslendirme '
      'oranımızı ne kadar azaltırsak o kadar hızlı okumaya başlarız. '
      'Ne kadar çok sözcük bilirsek o kadar az seslendirme yaparız. '
      'Çünkü genelde seslendirdiğimiz kelimeler, ilk kez '
      'karşılaştığımız kelimelerdir. Şu bir gerçek ki beynimiz, bir '
      'salisede bilindik bir kelimeyi algılayabilmektedir. O zaman '
      'yapacağımız önemli işlerden biri de bilindik kelime sayısını '
      'artırmak olmalıdır. Bu muhteşem potansiyeli kullanabilmek, '
      'gözümüzün bu muhteşem hızından faydalanabilmek için sık sık '
      'kitap okumalı, ara ara sözlük taraması yaparak sözcük '
      'bilgimizi geliştirmeliyiz. Aslında hızlı okuma sürecinde '
      'günlük 20 kelimenin anlamını öğrensek bir ayda 600 kelime '
      'yapar ki, bu da müthiş bir sonuçtur.\n\n'
      '5. Sözcükleri gruplandırarak okuyunuz.\n'
      'Tek tek sözcüklere değil, sözcük gruplarına odaklanarak '
      'okumalı. Bunun alışkanlık haline gelmesi için egzersizleri '
      'yaparken ilk zamanlar anlama odaklanmamalı. Israrla '
      'egzersizleri yapmaya devam etmeli. Kelimeleri bir nesne, '
      'paragrafları da bir hediye kutusu varsayarsak şöyle bir örnek '
      'verebiliriz: Kutunun içindeki hediyeyi bir bütün olarak '
      'görürüz. Parçalara pek de takılmayız. O hediyeyi anlamlı kılan '
      'da zaten o bütünlüktür. Kelimeler de bir cümlenin, paragrafın '
      'hatta bir yazının anlamlı parçalarıdır. Bir kelimenin cümle '
      'içinde anlamı değişebilir. Dolayısıyla cümle içindeki bulunan '
      'kelimeleri ne kadar hızlı okursak anlam hediyesine o kadar '
      'çabuk ulaşırız. Bu konuyla ilgili örnekleri ve açıklamaları '
      'etkinlikler bölümünde bulabilirsiniz.\n\n'
      '6. Geriye dönük değil, ileriye dönük okuyunuz.\n'
      'Geriye dönüşleri azaltmalı ve sıfıra indirmeli. Bir kelimeyi, '
      'cümleyi sık sık geriye dönerek tekrar okumak, özgüven '
      'eksikliğini doğurur. Bunu aşmanın yolu, tüm dikkatimizi '
      'okuduğumuz yazıya vermektir. Okuduğumuz parçayla adeta '
      'iletişime geçmeli, bize ne anlatmaya çalıştığını kavramaya '
      'çalışmalıyız. Dikkatimizi parçada yoğunlaştırmak için yazıyı '
      'okumadan önce kendimize sorular sorarak dikkatimizi '
      'canlandırabiliriz. "Yazar bana ne anlatmaya çalışıyor?" "Bu '
      'metinden ne sonuç çıkarabilirim?" Hatta okuduğumuz paragraf '
      'sorularını sıkıcılıktan kurtarmak için paragrafa başlamadan '
      'önce "Hey dostum, senin derdin ne?" diyerek işi biraz da '
      'espriye vurarak dikkatimize uyandırabiliriz. Bu tip sorularla '
      'okumaya başladığımızda dikkatimiz, daha canlı olacak ve bir '
      'cümleyi, bir metni tekrar tekrar okumuş olmaktan ve zaman '
      'kaybından kurtulmuş olacağız. Şu bir gerçek ki, hedefine '
      'varmış, başarıya ulaşmış tüm insanların hayatlarını '
      'gözlemlediğimizde "Her ne iş yapıyorsan o işi, hayatın o işe '
      'bağlıymışçasına yap." ilkesini tüm çalışmalarında '
      'kullandıklarını görüyoruz.\n\n'
      '7. İlk zamanlar her satırı en fazla üç veya dört duruşta '
      'okuyunuz.\n'
      'Egzersizleri sabırla uygulayarak odaklanma hızımızı artırmalı '
      've bir satırdaki duruş sayımızı düşürmek için gayret etmeliyiz. '
      'Unutmayalım ki, her gün yapılan bir davranış daha kolay ve '
      'daha hızlı yapılarak alışkanlık haline gelir. Ve şunu da '
      'unutmayalım ki, biz koşmayı öğrenmeden önce yürümeyi öğrendik. '
      'Yıllarca tek tek kelimelerle okumaya alışmış olan gözümüzün bu '
      'alışkanlığını yıkmak, zaman alabilir. Biraz zamana, biraz '
      'sabırla çalışmaya ve daha çok kendimize inanmaya ihtiyacımız '
      'olacaktır.\n\n'
      '8. Dikkatinizi sadece ve sadece okuduğunuz parçaya odaklayınız.\n'
      'Dağınık dikkat, yapılan işte görünmesine rağmen zihnin '
      'yapılandan uzaklaşarak daldan dala konması, konudan konuya '
      'atlamasıdır. Eğer bu okunan bir kitap ise gözler ile '
      'düşüncenin aynı doğrultuda olmaması demektir. Bunun önüne '
      'geçmek için okurken belirli aralıklarla kendimize soru '
      'yöneltebiliriz. "Düşüncem ile okuduklarım aynı doğrultuda mı?" '
      'Cevabınız evet ise hızınızı hiç düşürmeden cümlenin, '
      'paragrafın ve metnin ana düşüncesine odaklanarak okumanızı '
      'sürdürün. Sözcüklere değil, anlama ve düşünceye yoğunlaşın.\n\n'
      '9. Kararlı ve istikrarlı çalışınız.\n'
      'Kayayı delen damlacıkların kuvveti değil sürekliliğidir. İlk '
      'zamanlar anlama oranı düşse de, kararlılıkla okumaya devam '
      'ederseniz okuma hızınız en az iki katına çıkacaktır. Kültür '
      'birikimi ve kitap okuma alışkanlığınıza göre de hızınız ve '
      'anlama oranınızın giderek arttığını gördükçe kendiniz bile '
      'ulaştığınız seviyeye şaşıracaksınız. İşte başarının altın '
      'kuralı: Tüm dikkatini, yaptığın işte topla. Okuyorsan sadece '
      've sadece okuduğunu düşünmelisin ve tüm dikkatini okuduğun '
      'yazıya vermelisin. Anlam hazinelerinin anahtarı budur.\n\n'
      '10. Yani hızlı okumak için kısaca üç şey gerekli:\n'
      '1. İnanarak ISRARLA çalışmak\n'
      '2. İnanarak ISRARLA çalışmak\n'
      '3. İnanarak ISRARLA çalışmak\n'
      'Hızlı okumak için olmazsa olmaz iki madde:\n'
      '1. Kendine inanmak ve güvenmek\n'
      '2. Daha iyisini yapabileceğini düşünmek ve çalışmak\n'
      'Daha iyisi için gayret ediniz ve daha iyisini gerçekleştirene '
      'kadar vazgeçmeyiniz, pes etmeyiniz, yılmayınız ve lütfen bir '
      'daha deneyiniz!';

  late final List<String> _allWords = _fullText
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();

  late final List<String> _allLines = _buildLines(_allWords, _wordsPerLine);

  static List<String> _buildLines(List<String> words, int perLine) {
    final lines = <String>[];
    for (int i = 0; i < words.length; i += perLine) {
      final end = i + perLine > words.length ? words.length : i + perLine;
      lines.add(words.sublist(i, end).join(' '));
    }
    return lines;
  }

  late final List<_Page> _pages = _buildPages(_allLines);

  // Okuma sırası satır satır (o satırın solu, sonra sağı) olduğu için
  // satırlar sayfa içinde de bu sıraya göre sol/sağ sütuna dağıtılıyor —
  // yoksa sağ sütun metnin çok ilerisinden bir parçayı gösterip sırayı
  // bozardı.
  List<_Page> _buildPages(List<String> lines) {
    final linesPerPage = _linesPerColumn * 2;
    final pages = <_Page>[];
    for (int i = 0; i < lines.length; i += linesPerPage) {
      final end = i + linesPerPage > lines.length
          ? lines.length
          : i + linesPerPage;
      final pageLines = lines.sublist(i, end);
      final left = <String>[];
      final right = <String>[];
      for (int j = 0; j < pageLines.length; j++) {
        if (j.isEven) {
          left.add(pageLines[j]);
        } else {
          right.add(pageLines[j]);
        }
      }
      pages.add(_Page(left, right));
    }
    return pages;
  }

  // Antreman da asıl egzersizle aynı sol/sağ sütun düzenini kullanıyor —
  // satırlar aynı sol-sağ-sol-sağ sırasıyla iki sütuna dağıtılıyor.
  late final _Page _warmupPage = _buildWarmupPage();

  _Page _buildWarmupPage() {
    final lines = _allLines.take(_warmupLineCount).toList();
    final left = <String>[];
    final right = <String>[];
    for (int j = 0; j < lines.length; j++) {
      if (j.isEven) {
        left.add(lines[j]);
      } else {
        right.add(lines[j]);
      }
    }
    return _Page(left, right);
  }

  _Phase _phase = _Phase.intro;
  bool _hasCompletedOnce = false;
  bool _isPaused = false;

  int _pageIndex = 0;
  int _activeStep = 0;
  Timer? _stepTimer;
  bool _blinkOn = true;
  Timer? _blinkTimer;
  int _elapsedSec = 0;
  Timer? _elapsedTimer;
  bool _warmupDone = false;

  _Page get _currentPage =>
      _phase == _Phase.warmup ? _warmupPage : _pages[_pageIndex];

  @override
  void dispose() {
    _stepTimer?.cancel();
    _blinkTimer?.cancel();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  void _startWarmup() {
    setState(() {
      _phase = _Phase.warmup;
      _activeStep = 0;
      _warmupDone = false;
    });
    _startStepping();
  }

  void _replayWarmup() {
    _stepTimer?.cancel();
    _blinkTimer?.cancel();
    setState(() {
      _activeStep = 0;
      _warmupDone = false;
    });
    _startStepping();
  }

  void _finishWarmup() {
    _stepTimer?.cancel();
    _blinkTimer?.cancel();
    setState(() => _phase = _Phase.transition);
  }

  void _startReading() {
    _pageIndex = 0;
    setState(() {
      _phase = _Phase.reading;
      _activeStep = 0;
      _elapsedSec = 0;
    });
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSec++);
    });
    _startStepping();
  }

  void _startStepping() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (!mounted) return;
      setState(() => _blinkOn = !_blinkOn);
    });
    _scheduleStep();
  }

  void _scheduleStep() {
    _stepTimer?.cancel();
    _stepTimer = Timer(Duration(milliseconds: _stepMsBySpeed[_speedLevel]), () {
      if (!mounted) return;
      final total = _currentPage.totalLines;
      if (_activeStep >= total - 1) {
        _onPageDone();
      } else {
        setState(() => _activeStep++);
        _scheduleStep();
      }
    });
  }

  void _onPageDone() {
    _stepTimer?.cancel();
    if (_phase == _Phase.warmup) {
      _blinkTimer?.cancel();
      setState(() => _warmupDone = true);
      return;
    }
    if (_pageIndex < _pages.length - 1) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() {
          _pageIndex++;
          _activeStep = 0;
        });
        _scheduleStep();
      });
    } else {
      _finishAll();
    }
  }

  void _changeSpeed(int level) {
    _stepTimer?.cancel();
    setState(() {
      _speedLevel = level;
      _activeStep = 0;
    });
    _scheduleStep();
  }

  void _pauseGame() {
    _stepTimer?.cancel();
    _blinkTimer?.cancel();
    _elapsedTimer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resumeGame() {
    setState(() => _isPaused = false);
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSec++);
    });
    _startStepping();
  }

  void _finishAll() {
    _stepTimer?.cancel();
    _blinkTimer?.cancel();
    _elapsedTimer?.cancel();
    _hasCompletedOnce = true;

    const percent = 100;
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Sütun Takibi',
      result: '${_pages.length} sayfa · $_elapsedSec sn',
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
              'Metnin tamamını (${_allWords.length} kelime) okuduk!',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text('Süre: $_elapsedSec sn'),
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
        appBar: AppBar(title: const Text('📖 Sütun Takibi')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: switch (_phase) {
                  _Phase.intro => _buildIntro(),
                  _Phase.warmup => _buildWarmup(),
                  _Phase.transition => _buildTransition(),
                  _Phase.reading => _buildReading(
                    key: ValueKey('page-$_pageIndex'),
                  ),
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
                    'Etkinlik 7 · Sütun Takibi',
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
                        color: const Color(0xFFE0E7FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _color, width: 1.5),
                      ),
                      child: const Text(
                        'Amaç: Dikey göz hareketlerini hızlandırmak ve '
                        'gözümüzü sütun sütun okumaya alıştırmak.\n\n'
                        'Yöntem: Metin, kitaptaki gibi sütunlara '
                        'bölünmüş. Önce sol sütunu yukarıdan aşağıya, '
                        'sonra sağ sütunu yukarıdan aşağıya, yanıp '
                        'sönen satırı takip ederek okuyacağız.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF312E81),
                        ),
                      ),
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
                      child: Text(
                        'Önce küçük bir antreman yapacağız, sonra '
                        '"Hızlı Okumanın 10 Maddesi" metnini '
                        '(${_allWords.length} kelime, ${_pages.length} '
                        'sayfa) bu şekilde okuyacağız!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _color,
                          fontWeight: FontWeight.w600,
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
              if (_phase == _Phase.warmup || _phase == _Phase.reading) {
                _changeSpeed(i);
              } else {
                setState(() => _speedLevel = i);
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

  Widget _buildWarmup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '🎓 Antreman',
                style: TextStyle(fontWeight: FontWeight.bold, color: _color),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          ],
        ),
        const SizedBox(height: 8),
        _speedChipRow(),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _columnBody(_warmupPage),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _replayWarmup,
                icon: const Icon(Icons.replay),
                label: const Text('TEKRAR İZLE'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _color,
                  side: const BorderSide(color: _color),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _warmupDone ? _finishWarmup : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'DEVAM ET',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
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
                    'Antremanı tamamladık! Şimdi aynı şekilde asıl '
                    'metni okuyacağız — ${_pages.length} sayfa var, '
                    'hazır olduğunda devam edelim!',
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
                    onPressed: _startReading,
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

  Widget _buildReading({required Key key}) {
    final page = _pages[_pageIndex];
    return KeyedSubtree(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                  'Sayfa ${_pageIndex + 1}/${_pages.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _color,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
            ],
          ),
          const SizedBox(height: 8),
          _speedChipRow(),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _columnBody(page),
            ),
          ),
        ],
      ),
    );
  }

  // Sol sütun yukarıdan aşağıya, sonra sağ sütun yukarıdan aşağıya —
  // eş/zıt anlamlı kelimeler etkinliğindeki gibi nokta sadece ilk
  // satırda, ondan sonra aktif satır yanıp sönerek belli oluyor.
  // Satır satır ilerliyor: önce o satırın solu, sonra sağı, sonra bir alt
  // satıra geçiyor — asla yukarı zıplamıyor (sol sütunu bitirip sağ
  // sütunun tepesine dönmek yerine).
  Widget _columnBody(_Page page, {double fontSize = 17}) {
    final maxRows = page.left.length > page.right.length
        ? page.left.length
        : page.right.length;
    final leftSteps = <int>[];
    final rightSteps = <int>[];
    int step = 0;
    for (int r = 0; r < maxRows; r++) {
      if (r < page.left.length) {
        leftSteps.add(step);
        step++;
      }
      if (r < page.right.length) {
        rightSteps.add(step);
        step++;
      }
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _columnLines(page.left, leftSteps, fontSize: fontSize)),
        if (page.right.isNotEmpty) ...[
          const SizedBox(width: 16),
          Expanded(
            child: _columnLines(page.right, rightSteps, fontSize: fontSize),
          ),
        ],
      ],
    );
  }

  Widget _columnLines(
    List<String> lines,
    List<int> steps, {
    required double fontSize,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < lines.length; i++)
          Expanded(child: _lineRow(lines[i], steps[i], fontSize)),
      ],
    );
  }

  Widget _lineRow(String text, int step, double fontSize) {
    final isActive = step == _activeStep;
    final showDot = isActive && _activeStep == 0;
    final lit = isActive && _blinkOn;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: fontSize * 0.8,
          child: showDot
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _color,
                  ),
                )
              : null,
        ),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? (lit ? _color : _color.withValues(alpha: 0.45))
                    : const Color(0xFF334155),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/progress_manager.dart';
import '../../models/settings_manager.dart';
import '../../models/sound_manager.dart';
import '../../widgets/completion_pop_scope.dart';
import '../../widgets/pause_overlay.dart';
import '../../widgets/reading_theme_picker.dart';

enum _Phase { intro, warmup, transition, reading }

/// Klasör 3'ün yedinci etkinliği: "Kelime Takibi". Antreman Metni'ndeki
/// (folder1/folder2/folder3 oturumlarındaki) gibi düz, doğal akan bir
/// metin — sütun kutucukları veya sıçrayan bir işaretçi YOK. Sayfadaki
/// TÜM kelimeler baştan itibaren görünür durumda; sadece o an sırası
/// gelen kelime büyüyüp renkleniyor, geri kalanı sönük gri duruyor. Önce
/// kısa bir antreman, sonra "Hızlı Okumanın Alışkanlık Haline Gelmesi
/// İçin Önemli On Madde" metninin tamamı sayfa sayfa bu şekilde okunuyor.
class ColumnReadingPage extends StatefulWidget {
  const ColumnReadingPage({super.key});

  @override
  State<ColumnReadingPage> createState() => _ColumnReadingPageState();
}

class _ColumnReadingPageState extends State<ColumnReadingPage> {
  static const Color _color = Color(0xFF4338CA);
  static const List<String> _speedLabels = ['Yavaş', 'Orta', 'Hızlı'];
  static const List<int> _stepMsBySpeed = [550, 350, 200];
  int _speedLevel = 1;

  static const int _wordsPerPage = 50;
  // 32 kelime metnin başından itibaren tam iki cümleyi kapsıyor (".Eski
  // alışkanlıkları yıkmak tabii ki çok zor." ile bitiyor) — cümle
  // ortasında kesilmesin diye özellikle bu sayı seçildi.
  static const int _warmupWordCount = 32;

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

  late final List<List<String>> _pages = _paginate(_allWords, _wordsPerPage);
  late final List<String> _warmupWords = _allWords
      .take(_warmupWordCount)
      .toList();

  // Sayfa hedef kelime sayısına ulaşınca hemen kesilmiyor — cümle
  // ortasında kalmasın diye o cümlenin sonuna (. ! ? :) kadar devam
  // ediyor. Çok uzun bir cümle varsa da sayfa aşırı büyümesin diye bir
  // üst sınırda yine de bölünüyor.
  static List<List<String>> _paginate(List<String> words, int targetPerPage) {
    final pages = <List<String>>[];
    var current = <String>[];
    final sentenceEnd = RegExp(r'[.!?:]$');
    for (final word in words) {
      current.add(word);
      final reachedTarget = current.length >= targetPerPage;
      final hardLimit = current.length >= (targetPerPage * 1.6).round();
      if (hardLimit || (reachedTarget && sentenceEnd.hasMatch(word))) {
        pages.add(current);
        current = [];
      }
    }
    if (current.isNotEmpty) pages.add(current);
    return pages;
  }

  _Phase _phase = _Phase.intro;
  bool _hasCompletedOnce = false;
  bool _isPaused = false;

  int _pageIndex = 0;
  int _activeStep = 0; // o an sırası gelen (büyüyüp renklenen) kelime
  Timer? _wordTimer;
  int _elapsedSec = 0;
  Timer? _elapsedTimer;
  bool _warmupDone = false;

  @override
  void dispose() {
    _wordTimer?.cancel();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  void _startWarmup() {
    setState(() {
      _phase = _Phase.warmup;
      _activeStep = 0;
      _warmupDone = false;
    });
    _scheduleWarmupWord();
  }

  void _replayWarmup() {
    _wordTimer?.cancel();
    setState(() {
      _activeStep = 0;
      _warmupDone = false;
    });
    _scheduleWarmupWord();
  }

  void _scheduleWarmupWord() {
    _wordTimer?.cancel();
    _wordTimer = Timer(Duration(milliseconds: _stepMsBySpeed[_speedLevel]), () {
      if (!mounted) return;
      if (_activeStep >= _warmupWords.length - 1) {
        setState(() => _warmupDone = true);
        return;
      }
      setState(() => _activeStep++);
      _scheduleWarmupWord();
    });
  }

  void _finishWarmup() {
    _wordTimer?.cancel();
    setState(() => _phase = _Phase.transition);
  }

  void _startReading() {
    setState(() {
      _phase = _Phase.reading;
      _pageIndex = 0;
      _activeStep = 0;
      _elapsedSec = 0;
    });
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSec++);
    });
    _scheduleReadingWord();
  }

  // Sayfadaki son kelimeye gelince kısa bir bekleme sonrası yeni bir
  // sayfa açılıp kaldığı yerden devam ediyor — son sayfa bitince metnin
  // tamamı okunmuş oluyor. Metin baştan beri TAMAMI görünür durumda,
  // sadece o an sırası gelen kelime büyüyüp renkleniyor.
  void _scheduleReadingWord() {
    _wordTimer?.cancel();
    final currentPage = _pages[_pageIndex];
    _wordTimer = Timer(Duration(milliseconds: _stepMsBySpeed[_speedLevel]), () {
      if (!mounted) return;
      if (_activeStep >= currentPage.length - 1) {
        if (_pageIndex >= _pages.length - 1) {
          _finishAll();
          return;
        }
        Future.delayed(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          setState(() {
            _pageIndex++;
            _activeStep = 0;
          });
          _scheduleReadingWord();
        });
        return;
      }
      setState(() => _activeStep++);
      _scheduleReadingWord();
    });
  }

  void _changeSpeed(int level) {
    _wordTimer?.cancel();
    setState(() => _speedLevel = level);
    if (_phase == _Phase.warmup) {
      _scheduleWarmupWord();
    } else if (_phase == _Phase.reading) {
      _scheduleReadingWord();
    }
  }

  void _pauseGame() {
    _wordTimer?.cancel();
    _elapsedTimer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resumeGame() {
    setState(() => _isPaused = false);
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSec++);
    });
    _scheduleReadingWord();
  }

  void _finishAll() {
    _wordTimer?.cancel();
    _elapsedTimer?.cancel();
    _hasCompletedOnce = true;

    const percent = 100;
    ProgressManager.recordAttentionScore(percent);

    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Kelime Takibi',
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
        appBar: AppBar(title: const Text('📖 Kelime Takibi')),
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
                    'Etkinlik 7 · Kelime Takibi',
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
                        'gözümüzü hızlıca kelime kelime okumaya '
                        'alıştırmak.\n\nYöntem: Metnin tamamı önümüzde '
                        'duracak; sırası gelen kelime büyüyüp renklenecek, '
                        'biz de onu takip ederek sırayla okuyacağız.',
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
            child: _buildWordFlow(_warmupWords, _activeStep, fontSize: 22),
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
                  IconButton(
                    onPressed: () =>
                        showReadingThemePicker(context, () => setState(() {})),
                    icon: const Icon(Icons.palette_outlined),
                    tooltip: 'Metin rengini değiştir',
                    visualDensity: VisualDensity.compact,
                  ),
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
                color: SettingsManager.readingBackgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SettingsManager.readingBorderColor),
              ),
              child: _buildWordFlow(
                page,
                _activeStep,
                fontSize: 18,
                activeColor: SettingsManager.readingAccentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Metnin TAMAMI baştan beri görünür — normal bir metin gibi doğal
  // olarak alt satıra geçiyor. Sadece o an sırası gelen kelime büyüyüp
  // renkleniyor, geri kalan kelimeler sönük gri duruyor. Her kelime AYRI
  // bir Wrap öğesi ve büyüme AnimatedScale (Transform) ile yapılıyor —
  // font boyutu değil ölçek değiştiği için kelimenin ayırdığı yer
  // ASLA büyümüyor, dolayısıyla etraftaki metin kaymıyor/kaçmıyor.
  Widget _buildWordFlow(
    List<String> pageWords,
    int activeIndex, {
    required double fontSize,
    Color? activeColor,
  }) {
    final highlightColor = activeColor ?? _color;
    final wrap = Wrap(
      alignment: WrapAlignment.start,
      // Büyüyen kelime komşu kelimelere değmesin diye aralar bilerek
      // geniş tutuluyor.
      spacing: 18,
      runSpacing: 14,
      children: [
        for (int i = 0; i < pageWords.length; i++)
          AnimatedScale(
            scale: i == activeIndex ? 1.3 : 1.0,
            duration: const Duration(milliseconds: 160),
            alignment: Alignment.center,
            child: Text(
              pageWords[i],
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: i == activeIndex
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: i == activeIndex ? highlightColor : Colors.grey.shade400,
              ),
            ),
          ),
      ],
    );
    // Kısa sayfalarda (ör. antreman) içerik kutunun tepesinde sıkışıp
    // altında boş alan kalmasın diye dikey ortalanıyor; uzun sayfalarda
    // taşarsa yine kaydırılabiliyor.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Align(alignment: Alignment.topLeft, child: wrap),
          ),
        );
      },
    );
  }
}

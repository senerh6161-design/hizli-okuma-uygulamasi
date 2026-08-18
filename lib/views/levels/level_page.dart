import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/word_data.dart';
import '../../models/progress_manager.dart';
import '../../models/school_level.dart';
import '../../models/achievement.dart';
import '../../models/comprehension_data.dart';
import '../exercises/comprehension_page.dart';

/// Tek bir okuma egzersizi seviyesini tanımlar.
/// Hız (WPM) ve süre, seçilen SchoolLevelConfig'in defaultWpm'ine göre
/// TÜRETİLİR — böylece "İlkokul" ve "Yetişkin" seçtiğinde gerçekten
/// farklı bir deneyim yaşarsın, sadece farklı bir ekran değil.
class ReadingLevel {
  final int index;
  final String title;
  final String desc;
  final int wpm;
  final int durationSeconds;
  final bool isPair;

  const ReadingLevel({
    required this.index,
    required this.title,
    required this.desc,
    required this.wpm,
    required this.durationSeconds,
    required this.isPair,
  });

  int get speedMs => (60000 / wpm).round();
}

class LevelPage extends StatelessWidget {
  final SchoolLevelConfig schoolLevel;

  const LevelPage({super.key, required this.schoolLevel});

  // WPM'i 5'in katına yuvarlar ve 60-900 aralığında tutar (daha okunur
  // rakamlar: 97.5 yerine 100 gibi).
  static int _roundWpm(double value) {
    final clamped = value.clamp(60.0, 900.0);
    return (clamped / 5).round() * 5;
  }

  List<ReadingLevel> get _levels {
    // Kişisel WPM Testi yapılmışsa (ProgressManager.personalWpmBaseline)
    // taban hız OKUL ORTALAMASI değil, kullanıcının GERÇEK ölçülen hızı
    // olur. Test yapılmamışsa okul yaş grubunun varsayılanına düşer.
    final rawBase = ProgressManager.personalWpmBaseline ?? schoolLevel.defaultWpm;
    // Anlama Testi performansına göre ProgressManager.speedAdjustment ile
    // ayrıca ölçekleniyor (bkz. recordComprehensionResult).
    // %90+ anlama -> tempo artar, %70 altı -> tempo azalır.
    final base = rawBase * ProgressManager.speedAdjustment;
    // Seviyeler artık sabit bir fark (ör. "-150 WPM") değil, taban hıza
    // ORANLA hesaplanıyor. Böylece İlkokul (150 WPM taban) ile Yetişkin
    // (500 WPM taban) arasında Seviye 5, İlkokul'u yapay şekilde yetişkin
    // seviyesine sıçratmıyor — her yaş grubu kendi içinde makul bir tempo
    // artışı yaşıyor ve gruplar birbirine karışmıyor.
    return [
      ReadingLevel(
        index: 1,
        title: 'Seviye 1 · Isınma',
        desc: 'Tek kelimeler, rahat bir tempoda ısınıyoruz',
        wpm: _roundWpm(base * 0.65),
        durationSeconds: 60,
        isPair: false,
      ),
      ReadingLevel(
        index: 2,
        title: 'Seviye 2 · Temel',
        desc: 'Tek kelimeler, biraz daha hızlı akış',
        wpm: _roundWpm(base * 0.85),
        durationSeconds: 50,
        isPair: false,
      ),
      ReadingLevel(
        index: 3,
        title: 'Seviye 3 · Gelişen',
        desc: 'İkili kelime öbeklerine geçiyoruz',
        wpm: _roundWpm(base * 1.0),
        durationSeconds: 40,
        isPair: true,
      ),
      ReadingLevel(
        index: 4,
        title: 'Seviye 4 · İleri',
        desc: 'İkili öbekler, yüksek tempoda',
        wpm: _roundWpm(base * 1.2),
        durationSeconds: 25,
        isPair: true,
      ),
      ReadingLevel(
        index: 5,
        title: 'Seviye 5 · Uzman',
        desc: 'Maksimum hız, kısa ve yoğun tur',
        wpm: _roundWpm(base * 1.4),
        durationSeconds: 15,
        isPair: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final levels = _levels;
    final adjustment = ProgressManager.speedAdjustment;
    final showAdjustmentBadge = (adjustment - 1.0).abs() > 0.001;

    return Scaffold(
      appBar: AppBar(
        title: Text('${schoolLevel.title.split('(').first.trim()} Seviyeleri'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Icon(
                  ProgressManager.personalWpmBaseline != null ? Icons.verified : Icons.info_outline,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ProgressManager.personalWpmBaseline != null
                        ? 'Taban hız: kişisel ölçümün (~${ProgressManager.personalWpmBaseline} WPM)'
                        : 'Taban hız: ${schoolLevel.title.split('(').first.trim()} ortalaması — "Seviyeni Ölç" ile kişiselleştirebilirsin',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
          if (showAdjustmentBadge)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: adjustment > 1.0 ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    adjustment > 1.0 ? Icons.trending_up : Icons.trending_down,
                    size: 18,
                    color: adjustment > 1.0 ? Colors.green.shade700 : Colors.orange.shade800,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      adjustment > 1.0
                          ? 'Anlama testlerindeki başarına göre tempo x${adjustment.toStringAsFixed(2)} artırıldı.'
                          : 'Anlama testine göre tempo x${adjustment.toStringAsFixed(2)} yavaşlatıldı — önce anlamak önemli.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: adjustment > 1.0 ? Colors.green.shade800 : Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: levels.length,
              itemBuilder: (context, index) {
                final lvl = levels[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(18),
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                      child: Text(
                        '${lvl.index}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4F46E5),
                          fontSize: 18,
                        ),
                      ),
                    ),
                    title: Text(
                      lvl.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${lvl.desc}\nHedef: ~${lvl.wpm} WPM · ${lvl.durationSeconds} sn',
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ActiveReadingSession(
                            schoolLevel: schoolLevel,
                            readingLevel: lvl,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum _SessionPhase { ready, countdown, running, finished }

class ActiveReadingSession extends StatefulWidget {
  final SchoolLevelConfig schoolLevel;
  final ReadingLevel readingLevel;

  const ActiveReadingSession({
    super.key,
    required this.schoolLevel,
    required this.readingLevel,
  });

  @override
  State<ActiveReadingSession> createState() => _ActiveReadingSessionState();
}

class _ActiveReadingSessionState extends State<ActiveReadingSession> {
  final Random _random = Random();

  Timer? _wordTimer;
  Timer? _tickTimer;
  Timer? _countdownTimer;

  _SessionPhase phase = _SessionPhase.ready;
  int countdownValue = 3;

  List<String> _queue = [];
  int _queueIndex = 0;
  String currentWord = '';

  int readCount = 0;
  int calculatedWpm = 0;
  int remainingMs = 0;
  List<Achievement> _newAchievements = [];

  // Gerçek Metin Modu: kelime listesi yerine gerçek bir paragrafı
  // kelime kelime akıtır. Kelimeler ASLA karıştırılmaz — cümle sırası
  // korunur, yoksa metin anlamsızlaşır.
  bool useRealText = false;
  ReadingPassage? _currentRealPassage;

  @override
  void initState() {
    super.initState();
    remainingMs = widget.readingLevel.durationSeconds * 1000;
  }

  // Kelime havuzunu karıştırıp yeni bir tur hazırlar. Süre kelime
  // sayısından uzun sürerse, listeyi TEKRAR karıştırarak devam eder —
  // yani kelimeler hep aynı sırayla "başa sarmaz", her turda farklı dizilir.
  //
  // Gerçek Metin Modu'ndaysa farklı çalışır: karıştırma YOK (cümle sırası
  // bozulmamalı), bunun yerine havuzdaki metin bitince YENİ bir paragrafa
  // geçilir.
  void _refillQueue() {
    if (useRealText) {
      final passages = ComprehensionData.passages;
      ReadingPassage next;
      if (passages.length > 1 && _currentRealPassage != null) {
        final others = passages.where((p) => p.id != _currentRealPassage!.id).toList();
        next = others[_random.nextInt(others.length)];
      } else {
        next = passages[_random.nextInt(passages.length)];
      }
      _currentRealPassage = next;
      _queue = next.content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      _queueIndex = 0;
      return;
    }

    _queue = widget.readingLevel.isPair
        ? (List<String>.from(WordData.pairs)..shuffle(_random))
        : (List<String>.from(WordData.singleWords)..shuffle(_random));
    _queueIndex = 0;
  }

  String _nextWord() {
    if (_queueIndex >= _queue.length) {
      _refillQueue();
    }
    final word = _queue[_queueIndex];
    _queueIndex++;
    return word;
  }

  void _startCountdown() {
    setState(() {
      phase = _SessionPhase.countdown;
      countdownValue = 3;
    });
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 700), (t) {
      if (!mounted) return;
      if (countdownValue <= 1) {
        t.cancel();
        _startSession();
      } else {
        setState(() => countdownValue--);
      }
    });
  }

  void _startSession() {
    if (useRealText) {
      _currentRealPassage = null;
    }
    _refillQueue();
    setState(() {
      phase = _SessionPhase.running;
      readCount = 0;
      calculatedWpm = 0;
      remainingMs = widget.readingLevel.durationSeconds * 1000;
      currentWord = _nextWord();
    });

    _wordTimer = Timer.periodic(
      Duration(milliseconds: widget.readingLevel.speedMs),
      (_) {
        if (!mounted) return;
        setState(() {
          readCount++;
          calculatedWpm =
              (readCount * (60000 / widget.readingLevel.speedMs)).round();
          currentWord = _nextWord();
        });
      },
    );

    _tickTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) return;
      if (remainingMs <= 100) {
        t.cancel();
        _finishSession();
      } else {
        setState(() => remainingMs -= 100);
      }
    });
  }

  void _finishSession() {
    _wordTimer?.cancel();
    _tickTimer?.cancel();
    if (!mounted) return;

    final unlocked = ProgressManager.addCompletedExercise(
      type: useRealText
          ? '${widget.schoolLevel.title} · ${widget.readingLevel.title} (Gerçek Metin)'
          : '${widget.schoolLevel.title} · ${widget.readingLevel.title}',
      result: '$calculatedWpm WPM',
      newWpm: calculatedWpm,
    );

    setState(() {
      phase = _SessionPhase.finished;
      _newAchievements = unlocked;
    });
  }

  void _restart() {
    setState(() {
      phase = _SessionPhase.ready;
      _newAchievements = [];
    });
  }

  double get _progress {
    final total = widget.readingLevel.durationSeconds * 1000;
    if (total <= 0) return 0;
    return (1 - (remainingMs / total)).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _wordTimer?.cancel();
    _tickTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.readingLevel.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: switch (phase) {
            _SessionPhase.ready => _buildReady(),
            _SessionPhase.countdown => _buildCountdown(),
            _SessionPhase.running => _buildRunning(),
            _SessionPhase.finished => _buildFinished(),
          },
        ),
      ),
    );
  }

  Widget _buildReady() {
    final lvl = widget.readingLevel;
    return Column(
      children: [
        const Spacer(),
        const Icon(Icons.speed_rounded, size: 64, color: Color(0xFF4F46E5)),
        const SizedBox(height: 16),
        Text(
          lvl.title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          lvl.desc,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            _infoChip(Icons.bolt, '~${lvl.wpm} WPM'),
            _infoChip(Icons.timer_outlined, '${lvl.durationSeconds} sn'),
            _infoChip(
              lvl.isPair ? Icons.link : Icons.short_text,
              lvl.isPair ? 'İkili öbek' : 'Tek kelime',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text(
              '📖 Gerçek Metin Modu',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: const Text(
              'Kelime listesi yerine gerçek bir paragrafı okursun',
              style: TextStyle(fontSize: 11),
            ),
            value: useRealText,
            onChanged: (val) => setState(() => useRealText = val),
          ),
        ),
        const Spacer(),
        Text(
          'Başınızı ve dudaklarınızı oynatmadan, yalnızca gözlerinizle takip edin.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _startCountdown,
            icon: const Icon(Icons.play_arrow),
            label: const Text(
              'BAŞLAT',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF4F46E5)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF4F46E5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown() {
    return Center(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(countdownValue),
        tween: Tween(begin: 0.5, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: Text(
          countdownValue.toString(),
          style: const TextStyle(
            fontSize: 96,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4F46E5),
          ),
        ),
      ),
    );
  }

  Widget _buildRunning() {
    final baseFont = widget.schoolLevel.fontSize;
    final fontSize = widget.readingLevel.isPair ? baseFont * 0.75 : baseFont;

    return Column(
      children: [
        if (useRealText && _currentRealPassage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '📖 ${_currentRealPassage!.title}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Okunan: $readCount',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
            Text(
              '$calculatedWpm WPM',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.85, end: 1.0).animate(animation),
                        child: child,
                      ),
                    ),
                    child: Padding(
                      key: ValueKey('$currentWord-$readCount'),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        currentWord,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(
                    width: 8,
                    height: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 4,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF4F46E5)),
                  ),
                  Text(
                    '${(remainingMs / 1000).ceil()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _finishSession,
                icon: const Icon(Icons.stop),
                label: const Text('BİTİR'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _achievementChip(Achievement achievement) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(achievement.icon, size: 16, color: Colors.amber.shade800),
          const SizedBox(width: 6),
          Text(
            achievement.title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinished() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
        const SizedBox(height: 16),
        const Text('Harika iş! 🎉', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(
          '${widget.readingLevel.title} tamamlandı',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                '$calculatedWpm',
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
              ),
              const Text('Ortalama WPM', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              Text('Toplam $readCount kelime okundu', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (_newAchievements.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            '🎉 Yeni Başarım Kazandın!',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _newAchievements.map(_achievementChip).toList(),
          ),
        ],
        if (useRealText && _currentRealPassage != null) ...[
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ComprehensionPage(
                      passage: _currentRealPassage,
                      skipReadingPhase: true,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.quiz_outlined),
              label: const Text('📖 Az Önce Okuduğun Metnin Sorularına Geç'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: const Color(0xFF4F46E5),
                side: const BorderSide(color: Color(0xFF4F46E5)),
              ),
            ),
          ),
        ],
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Seviyelere Dön'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _restart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Tekrar Dene'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
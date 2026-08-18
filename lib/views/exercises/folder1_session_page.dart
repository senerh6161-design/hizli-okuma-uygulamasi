import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/comprehension_data.dart';
import '../../models/progress_manager.dart';
import '../../models/sound_manager.dart';
import '../../models/settings_manager.dart';
import '../../models/school_level.dart';
import '../levels/level_page.dart';
import 'eye_coordination_page.dart';
import 'circular_sequence_page.dart';
import 'arrow_word_cycle_page.dart';
import 'growing_words_page.dart';
import 'attention_questions_page.dart';
import 'word_hide_seek_page.dart';
import 'object_flow_counting_page.dart';
import 'word_flow_counting_page.dart';
import 'exercise_menu_page.dart';

enum _Phase { intro, preTopic, preText, preQuiz, activities, postTopic, postText, postQuiz, results }

class _ActivityRef {
  final String title;
  final IconData icon;
  final Widget Function() build;
  const _ActivityRef(this.title, this.icon, this.build);
}

/// Öğretmen dokümanındaki tam akış: önce kısa bir metinle okuma hızı
/// ölçülür, ardından Klasör 1'deki 10 etkinlik tamamlanır, sonra FARKLI bir
/// metinle tekrar hız ölçülür, her iki metinden sonra da D/Y sorularıyla
/// anlama kontrol edilir. Sonunda okuma hızı ve dikkat puanı AYRI AYRI
/// gösterilir.
class Folder1SessionPage extends StatefulWidget {
  const Folder1SessionPage({super.key});

  @override
  State<Folder1SessionPage> createState() => _Folder1SessionPageState();
}

class _Folder1SessionPageState extends State<Folder1SessionPage> {
  final Random _random = Random();
  _Phase _phase = _Phase.intro;

  ReadingPassage? _preText;
  ReadingPassage? _postText;

  DateTime? _readStart;
  Timer? _tickTimer;
  int _elapsedSeconds = 0;

  int _preWpm = 0;
  int _postWpm = 0;
  int _preComprehensionPercent = 0;
  int _postComprehensionPercent = 0;

  int _quizIndex = 0;
  int _quizCorrect = 0;

  late final List<_ActivityRef> _activities;
  final Set<int> _activityDone = {};

  @override
  void initState() {
    super.initState();

    _activities = [
      _ActivityRef('Göz Koordinasyonu', Icons.visibility_outlined, () => const EyeCoordinationPage()),
      _ActivityRef('Hızlı Okuma', Icons.speed, () => LevelPage(schoolLevel: SchoolLevelConfig.levels[1])),
      _ActivityRef(
        'Dairesel Sıralama',
        Icons.donut_large,
        () => const CircularSequencePage(
          availableModes: [CircularMode.numbers12, CircularMode.numbers20],
          appBarTitle: '🔄 Dairesel Sıralama (Sayılar)',
        ),
      ),
      _ActivityRef(
        'Dairesel Gün/Ay',
        Icons.calendar_month,
        () => const CircularSequencePage(
          availableModes: [CircularMode.days, CircularMode.months],
          appBarTitle: '🔄 Dairesel Gün/Ay Sıralama',
        ),
      ),
      _ActivityRef('Kelime Döngüsü', Icons.sync, () => const ArrowWordCyclePage()),
      _ActivityRef('Uzayan Kelimeler', Icons.expand, () => const GrowingWordsPage()),
      _ActivityRef('Dikkat Soruları', Icons.help_center, () => const AttentionQuestionsPage()),
      _ActivityRef('Nesne Akışı', Icons.category, () => const ObjectFlowCountingPage()),
      _ActivityRef('Kelime Akışı', Icons.waves, () => const WordFlowCountingPage()),
      _ActivityRef('Kelimelerle Saklambaç', Icons.extension, () => const WordHideSeekPage()),
    ];
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  int _computeWpm(ReadingPassage passage) {
    final start = _readStart;
    final elapsed = start == null
        ? _elapsedSeconds.toDouble()
        : DateTime.now().difference(start).inMilliseconds / 1000.0;
    final wordCount = passage.content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final minutes = max(elapsed / 60.0, 0.05);
    return (wordCount / minutes).round().clamp(40, 1200).toInt();
  }

  void _startTimer() {
    _tickTimer?.cancel();
    _elapsedSeconds = 0;
    _readStart = DateTime.now();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
    });
  }

  void _goToPreTopic() {
    setState(() => _phase = _Phase.preTopic);
  }

  ReadingPassage _pickPassage(String? topicId, {ReadingPassage? avoid}) {
    final pool = ComprehensionData.passagesForTopic(topicId);
    final shuffled = List<ReadingPassage>.from(pool)..shuffle(_random);
    if (avoid != null && shuffled.length > 1) {
      return shuffled.firstWhere((p) => p.id != avoid.id, orElse: () => shuffled.first);
    }
    return shuffled.first;
  }

  void _choosePreTopic(String? topicId) {
    setState(() {
      _preText = _pickPassage(topicId);
      _phase = _Phase.preText;
    });
    _startTimer();
  }

  void _finishPreText() {
    _tickTimer?.cancel();
    _preWpm = _computeWpm(_preText!);
    setState(() {
      _phase = _Phase.preQuiz;
      _quizIndex = 0;
      _quizCorrect = 0;
    });
  }

  void _answerQuiz(ReadingPassage passage, int index, VoidCallback onDone) {
    final q = passage.questions[_quizIndex];
    if (index == q['correct']) {
      _quizCorrect++;
      SoundManager.playCorrect();
    } else {
      SoundManager.playGentleTap();
    }
    if (_quizIndex < passage.questions.length - 1) {
      setState(() => _quizIndex++);
    } else {
      onDone();
    }
  }

  void _finishPreQuiz() {
    _preComprehensionPercent = ((_quizCorrect / _preText!.questions.length) * 100).round();
    ProgressManager.recordComprehensionResult(
      correct: _quizCorrect,
      total: _preText!.questions.length,
      title: 'Klasör 1 · Ön Metin',
    );
    setState(() => _phase = _Phase.activities);
  }

  Future<void> _openActivity(int index) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => _activities[index].build()));
    if (!mounted) return;
    setState(() => _activityDone.add(index));
  }

  void _goToPostTopic() {
    setState(() => _phase = _Phase.postTopic);
  }

  void _choosePostTopic(String? topicId) {
    setState(() {
      _postText = _pickPassage(topicId, avoid: _preText);
      _phase = _Phase.postText;
    });
    _startTimer();
  }

  void _finishPostText() {
    _tickTimer?.cancel();
    _postWpm = _computeWpm(_postText!);
    setState(() {
      _phase = _Phase.postQuiz;
      _quizIndex = 0;
      _quizCorrect = 0;
    });
  }

  void _finishPostQuiz() {
    _postComprehensionPercent = ((_quizCorrect / _postText!.questions.length) * 100).round();
    ProgressManager.recordComprehensionResult(
      correct: _quizCorrect,
      total: _postText!.questions.length,
      title: 'Klasör 1 · Son Metin',
    );
    _finishSession();
  }

  void _finishSession() {
    SoundManager.playSuccess();
    final unlocked = ProgressManager.addCompletedExercise(
      type: 'Klasör 1 Oturumu',
      result: 'Hız $_preWpm→$_postWpm WPM · Dikkat %${ProgressManager.attentionSuccess}',
    );
    if (unlocked.isNotEmpty) SoundManager.playAchievement();
    setState(() => _phase = _Phase.results);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🎬 Klasör 1 Oturumu')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: switch (_phase) {
            _Phase.intro => _buildIntro(),
            _Phase.preText => _buildReadingView(_preText, 'ÖN METİN', _finishPreText),
            _Phase.preQuiz => _quizBody(_preText, isPost: false),
            _Phase.activities => _buildActivitiesView(),
            _Phase.postText => _buildReadingView(_postText, 'SON METİN', _finishPostText),
            _Phase.postQuiz => _quizBody(_postText, isPost: true),
            _Phase.results => _buildResultsView(),
          },
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Column(
      children: [
        const Spacer(),
        const Icon(Icons.auto_stories, size: 64, color: Color(0xFF4F46E5)),
        const SizedBox(height: 20),
        const Text(
          'Klasör 1 Oturumu',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'Önce kısa bir metin okuyup hızını ölçeceğiz.\n'
          'Sonra ${_activities.length} etkinliği tamamlayacaksın.\n'
          'En sonunda FARKLI bir metinle tekrar ölçüm yapıp\n'
          'D/Y sorularını çözeceksin.\n\n'
          'Sonunda okuma hızını ve dikkat puanını ayrı ayrı göreceksin.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.5),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _startPreText,
            icon: const Icon(Icons.play_arrow),
            label: const Text('OTURUMU BAŞLAT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExerciseMenuPage()),
            );
          },
          child: Text(
            'Sadece tek tek pratik yapmak istiyorum',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildReadingView(ReadingPassage passage, String label, VoidCallback onFinish) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(10)),
              child: Text('$_elapsedSeconds sn',
                  style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(passage.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(passage.content, style: const TextStyle(fontSize: 17, height: 1.6, color: Colors.black87)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: onFinish,
            icon: const Icon(Icons.check),
            label: const Text('OKUDUM, BİTTİM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _quizBody(ReadingPassage passage, {required bool isPost}) {
    final q = passage.questions[_quizIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
          child: Text(
            '${isPost ? "SON" : "ÖN"} METİN · D/Y ${_quizIndex + 1}/${passage.questions.length}',
            style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const SizedBox(height: 24),
        Text(q['question'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: _dyButton('D) Doğru', Colors.green, () => _handleQuizAnswer(passage, 0, isPost)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _dyButton('Y) Yanlış', Colors.red, () => _handleQuizAnswer(passage, 1, isPost)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dyButton(String label, Color color, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 22),
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
    );
  }

  void _handleQuizAnswer(ReadingPassage passage, int index, bool isPost) {
    _answerQuiz(passage, index, isPost ? _finishPostQuiz : _finishPreQuiz);
  }

  Widget _buildActivitiesView() {
    final allDone = _activityDone.length == _activities.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_activities.length} Etkinlik', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('${_activityDone.length}/${_activities.length} tamamlandı',
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: _activities.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final activity = _activities[index];
              final done = _activityDone.contains(index);
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _openActivity(index),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: done ? Colors.green.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: done ? Colors.green.shade300 : Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(activity.icon, color: done ? Colors.green.shade700 : const Color(0xFF4F46E5)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(activity.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                      Icon(
                        done ? Icons.check_circle : Icons.arrow_forward_ios,
                        color: done ? Colors.green : Colors.grey,
                        size: done ? 22 : 16,
                      ),
                    ],
                  ),
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
            onPressed: allDone ? _goToPostText : null,
            icon: const Icon(Icons.arrow_forward),
            label: Text(
              allDone ? 'SON METNE GEÇ' : 'Önce tüm etkinlikleri tamamla',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

  Widget _buildResultsView() {
    final wpmDelta = _postWpm - _preWpm;
    final comprehensionDelta = _postComprehensionPercent - _preComprehensionPercent;
    final attentionScore = ProgressManager.attentionSuccess;

    return Column(
      children: [
        const Icon(Icons.emoji_events, size: 60, color: Colors.amber),
        const SizedBox(height: 12),
        const Text('Oturum Tamamlandı! 🎉', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            children: [
              _resultCard(
                icon: Icons.speed,
                color: const Color(0xFF4F46E5),
                title: 'Okuma Hızı',
                mainValue: '$_preWpm → $_postWpm WPM',
                subValue: wpmDelta >= 0 ? '+$wpmDelta WPM arttı' : '$wpmDelta WPM azaldı',
                subColor: wpmDelta >= 0 ? Colors.green : Colors.orange,
              ),
              const SizedBox(height: 12),
              _resultCard(
                icon: Icons.psychology,
                color: Colors.orange,
                title: 'Dikkat Puanı',
                mainValue: '%$attentionScore',
                subValue: '${_activities.length} etkinlikteki performansın',
                subColor: Colors.grey,
              ),
              const SizedBox(height: 12),
              _resultCard(
                icon: Icons.menu_book,
                color: Colors.green,
                title: 'Anlama (D/Y)',
                mainValue: '%$_preComprehensionPercent → %$_postComprehensionPercent',
                subValue: comprehensionDelta >= 0 ? '+$comprehensionDelta puan arttı' : '$comprehensionDelta puan azaldı',
                subColor: comprehensionDelta >= 0 ? Colors.green : Colors.orange,
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Bitir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _resultCard({
    required IconData icon,
    required Color color,
    required String title,
    required String mainValue,
    required String subValue,
    required Color subColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color.withValues(alpha: 0.12), child: Icon(icon, color: color)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(mainValue, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(subValue, style: TextStyle(color: subColor, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

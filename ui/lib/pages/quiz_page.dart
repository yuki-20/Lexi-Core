/// LexiCore — Quiz Page (v3.1)
/// Multiple-choice quiz with feedback, explanations, and pet unlock.
library;

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/liquid_glass_theme.dart';
import '../services/engine_service.dart';
import '../widgets/glass_panel.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final _engine = EngineService();
  String _state = 'start'; // 'start', 'question', 'result'
  List<dynamic> _questions = [];
  int _qIndex = 0;
  int _score = 0;
  int? _selectedOption;
  bool _answered = false;
  final List<Map<String, dynamic>> _answers = [];
  final Stopwatch _timer = Stopwatch();
  int _quizCount = 10;
  bool _isGenerating = false;
  String _generatingStatus = '';

  Future<void> _startQuiz() async {
    setState(() { _isGenerating = true; _generatingStatus = 'Generating quiz...'; });
    final data = await _engine.generateQuiz(count: _quizCount);
    if (!mounted) return;
    setState(() => _isGenerating = false);
    if (data == null || (data['questions'] as List?)?.isEmpty == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough words for quiz. Add more words first!')),
      );
      return;
    }
    _timer.reset();
    _timer.start();
    setState(() {
      _questions = (data['questions'] as List?) ?? [];
      _qIndex = 0;
      _score = 0;
      _selectedOption = null;
      _answered = false;
      _answers.clear();
      _state = 'question';
    });
  }

  void _selectOption(int index) {
    if (_answered) return;
    final q = _questions[_qIndex];
    final correct = (q['correct_index'] as int?) ?? 0;

    setState(() {
      _selectedOption = index;
      _answered = true;
      if (index == correct) _score++;
    });

    _answers.add({
      'word': q['word'],
      'user_answer': q['options'][index],
      'correct_answer': q['options'][correct],
      'is_correct': index == correct,
    });
  }

  void _nextQuestion() {
    if (_qIndex < _questions.length - 1) {
      setState(() {
        _qIndex++;
        _selectedOption = null;
        _answered = false;
      });
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    _timer.stop();
    // Show result immediately — don't block on API
    setState(() {
      _state = 'result';
    });
    // Background: submit and surface any newly unlocked pets
    try {
      final result = await _engine.submitQuiz(
        answers: _answers,
        durationS: _timer.elapsedMilliseconds / 1000,
      );
      final newPets = List<String>.from(result?['new_pets_unlocked'] ?? const []);
      if (newPets.isNotEmpty && mounted) {
        const petNames = {
          'ember_fox': 'Ember Fox',
          'volt_owl': 'Volt Owl',
          'aqua_dragon': 'Aqua Dragon',
          'prisma': 'Prisma',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'New pet unlocked: ${newPets.map((id) => petNames[id] ?? id).join(', ')}!',
            ),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case 'question':
        return _buildQuestion();
      case 'result':
        return _buildResult();
      case 'history':
        return _buildHistory();
      default:
        return _buildStart();
    }
  }

  // Custom word source
  final _customWordsController = TextEditingController();
  String _quizSource = 'saved'; // 'saved', 'custom', 'file'

  Future<void> _startQuizFromCustomWords() async {
    final text = _customWordsController.text.trim();
    if (text.isEmpty) return;
    final words = text.split(RegExp(r'[,\n;|]+')).map((w) => w.trim()).where((w) => w.isNotEmpty).toList();
    if (words.length < 4) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Need at least 4 words for a quiz!')),
        );
      }
      return;
    }
    setState(() { _isGenerating = true; _generatingStatus = 'Digesting ${words.length} words & generating quiz...'; });
    final data = await _engine.generateQuizFromWords(words, count: _quizCount);
    if (!mounted) return;
    setState(() => _isGenerating = false);
    if (data == null || (data['questions'] as List?)?.isEmpty == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not generate quiz from these words')),
      );
      return;
    }
    _timer.reset();
    _timer.start();
    setState(() {
      _questions = data['questions'];
      _qIndex = 0;
      _score = 0;
      _selectedOption = null;
      _answered = false;
      _answers.clear();
      _state = 'question';
    });
  }

  Future<void> _startQuizFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'json'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;

    final file = File(path);
    final text = await file.readAsString();
    final words = text.split(RegExp(r'[\n,;|\t]+')).map((w) => w.trim()).where((w) => w.isNotEmpty && w.length < 100).toList();
    if (words.length < 4) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Need at least 4 words in the file!')),
        );
      }
      return;
    }
    setState(() { _isGenerating = true; _generatingStatus = 'Digesting ${words.length} words & generating quiz...'; });
    final data = await _engine.generateQuizFromWords(words, count: _quizCount);
    if (!mounted) return;
    setState(() => _isGenerating = false);
    if (data == null || (data['questions'] as List?)?.isEmpty == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not generate quiz from file words')),
      );
      return;
    }
    _timer.reset();
    _timer.start();
    setState(() {
      _questions = data['questions'];
      _qIndex = 0;
      _score = 0;
      _selectedOption = null;
      _answered = false;
      _answers.clear();
      _state = 'question';
    });
  }

  Widget _buildStart() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: GlassPanel(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🧠', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 20),
              Text('Vocabulary Quiz', style: LiquidGlassTheme.heading),
              const SizedBox(height: 8),
              Text(
                'Choose your word source',
                style: LiquidGlassTheme.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Source selector chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _SourceChip(
                    icon: Icons.bookmark_rounded,
                    label: 'Saved Words',
                    selected: _quizSource == 'saved',
                    onTap: () => setState(() => _quizSource = 'saved'),
                  ),
                  _SourceChip(
                    icon: Icons.edit_note_rounded,
                    label: 'Custom Words',
                    selected: _quizSource == 'custom',
                    onTap: () => setState(() => _quizSource = 'custom'),
                  ),
                  _SourceChip(
                    icon: Icons.upload_file_rounded,
                    label: 'From File',
                    selected: _quizSource == 'file',
                    onTap: () => setState(() => _quizSource = 'file'),
                  ),
                ],
              ),

              // Custom words input
              if (_quizSource == 'custom') ...[
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withValues(alpha: 0.04),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: TextField(
                    controller: _customWordsController,
                    style: LiquidGlassTheme.body.copyWith(
                      color: LiquidGlassTheme.textPrimary, fontSize: 13,
                    ),
                    maxLines: 4,
                    minLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Enter words separated by commas or newlines\ne.g. apple, banana, cherry, dolphin',
                      hintStyle: LiquidGlassTheme.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.2), fontSize: 12,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Question count slider
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Questions:', style: LiquidGlassTheme.bodySmall.copyWith(
                    color: LiquidGlassTheme.textSecondary,
                  )),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: LiquidGlassTheme.accentPrimary,
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                        thumbColor: LiquidGlassTheme.accentPrimary,
                        overlayColor: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.1),
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                      ),
                      child: Slider(
                        value: _quizCount.toDouble(),
                        min: 5,
                        max: 30,
                        divisions: 5,
                        label: '$_quizCount',
                        onChanged: (v) => setState(() => _quizCount = v.round()),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.15),
                    ),
                    child: Text('$_quizCount', style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: LiquidGlassTheme.accentPrimary,
                    )),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Loading state
              if (_isGenerating)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: LiquidGlassTheme.accentPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(_generatingStatus, style: LiquidGlassTheme.bodySmall.copyWith(
                        color: LiquidGlassTheme.accentPrimary,
                      )),
                    ],
                  ),
                ),

              // Start button
              GestureDetector(
                onTap: _isGenerating ? null : () {
                  switch (_quizSource) {
                    case 'custom':
                      _startQuizFromCustomWords();
                      break;
                    case 'file':
                      _startQuizFromFile();
                      break;
                    default:
                      _startQuiz();
                  }
                },
                child: GlassPanel(
                  borderRadius: LiquidGlassTheme.borderRadiusPill,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_quizSource == 'file')
                        const Icon(Icons.upload_file_rounded, size: 18, color: LiquidGlassTheme.accentPrimary)
                      else
                        const Icon(Icons.play_arrow_rounded, size: 18, color: LiquidGlassTheme.accentPrimary),
                      const SizedBox(width: 8),
                      Text(
                        _quizSource == 'file' ? 'Pick File & Start' : 'Start Quiz',
                        style: LiquidGlassTheme.headingSm.copyWith(
                          color: LiquidGlassTheme.accentPrimary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.92, 0.92)),
      ),
    );
  }

  Widget _buildQuestion() {
    final q = _questions[_qIndex];
    final options = List<String>.from(q['options']);
    final correct = (q['correct_index'] as int?) ?? 0;
    final progress = (_qIndex + 1) / _questions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress
          Row(
            children: [
              Text(
                'Question ${_qIndex + 1} of ${_questions.length}',
                style: LiquidGlassTheme.label,
              ),
              const Spacer(),
              Text('$_score correct', style: LiquidGlassTheme.bodySmall),
            ],
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: LiquidGlassTheme.glassFill,
              valueColor: const AlwaysStoppedAnimation(LiquidGlassTheme.accentPrimary),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 32),

          // Word
          Center(
            child: Text(
              q['word'] ?? '',
              style: LiquidGlassTheme.heading.copyWith(fontSize: 32),
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.05, end: 0),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Select the correct definition',
              style: LiquidGlassTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 32),

          // Options A/B/C/D
          ...options.asMap().entries.map((entry) {
            final idx = entry.key;
            final text = entry.value;
            final letters = ['A', 'B', 'C', 'D'];
            final isSelected = _selectedOption == idx;
            final isCorrect = idx == correct;

            Color borderColor = Colors.transparent;
            Color bgColor = LiquidGlassTheme.glassFill;
            if (_answered) {
              if (isCorrect) {
                borderColor = Colors.greenAccent;
                bgColor = Colors.greenAccent.withValues(alpha: 0.1);
              } else if (isSelected && !isCorrect) {
                borderColor = Colors.redAccent;
                bgColor = Colors.redAccent.withValues(alpha: 0.1);
              }
            } else if (isSelected) {
              borderColor = LiquidGlassTheme.accentPrimary;
              bgColor = LiquidGlassTheme.accentPrimary.withValues(alpha: 0.1);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _selectOption(idx),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(LiquidGlassTheme.borderRadiusSm),
                    color: bgColor,
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: isSelected
                              ? LiquidGlassTheme.accentPrimary.withValues(alpha: 0.2)
                              : LiquidGlassTheme.glassFill,
                        ),
                        child: Center(
                          child: Text(
                            letters[idx],
                            style: LiquidGlassTheme.label.copyWith(
                              color: isSelected ? LiquidGlassTheme.accentPrimary : LiquidGlassTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(text, style: LiquidGlassTheme.body.copyWith(
                          color: LiquidGlassTheme.textPrimary,
                        )),
                      ),
                      if (_answered && isCorrect)
                        const Icon(Icons.check_circle, color: Colors.greenAccent, size: 22),
                      if (_answered && isSelected && !isCorrect)
                        const Icon(Icons.cancel, color: Colors.redAccent, size: 22),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 200 + idx * 80), duration: 350.ms)
               .slideX(begin: 0.03, end: 0),
            );
          }),

          // Explanation (after answer)
          if (_answered && q['explanation'] != null) ...[
            const SizedBox(height: 12),
            GlassPanel(
              padding: const EdgeInsets.all(18),
              borderRadius: LiquidGlassTheme.borderRadiusSm,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      q['explanation'],
                      style: LiquidGlassTheme.body,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
          ],

          if (_answered) ...[
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: _nextQuestion,
                child: GlassPanel(
                  borderRadius: LiquidGlassTheme.borderRadiusPill,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  child: Text(
                    _qIndex < _questions.length - 1 ? 'Next Question →' : 'See Results',
                    style: LiquidGlassTheme.label.copyWith(
                      color: LiquidGlassTheme.accentPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
          ],
        ],
      ),
    );
  }

  Widget _buildResult() {
    final pct = _questions.isNotEmpty ? (_score / _questions.length * 100) : 0;
    final emoji = pct >= 90 ? '🏆' : pct >= 70 ? '🎉' : pct >= 50 ? '👍' : '💪';
    final elapsed = _timer.elapsed;
    final avgPerQ = _questions.isNotEmpty
        ? (elapsed.inSeconds / _questions.length).toStringAsFixed(1)
        : '0';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
      child: Column(
        children: [
          // Main score card
          GlassPanel(
            padding: const EdgeInsets.all(36),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 16),
                Text('Quiz Complete!', style: LiquidGlassTheme.heading),
                const SizedBox(height: 16),
                Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: LiquidGlassTheme.heading.copyWith(
                    fontSize: 56,
                    color: pct >= 70 ? Colors.greenAccent : pct >= 50 ? Colors.orangeAccent : Colors.redAccent,
                  ),
                ),
                Text(
                  '$_score of ${_questions.length} correct',
                  style: LiquidGlassTheme.body,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),

          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              Expanded(child: _StatCard(
                icon: Icons.timer_outlined,
                label: 'Time',
                value: '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
              )),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(
                icon: Icons.speed_rounded,
                label: 'Avg / Question',
                value: '${avgPerQ}s',
              )),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(
                icon: Icons.check_circle_outline,
                label: 'Accuracy',
                value: '${pct.toStringAsFixed(0)}%',
              )),
            ],
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 20),

          // Question breakdown
          Text('Question Breakdown', style: LiquidGlassTheme.label),
          const SizedBox(height: 10),

          ...List.generate(_answers.length, (i) {
            final a = _answers[i];
            final correct = a['is_correct'] == true;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GlassPanel(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                borderRadius: 12,
                child: Row(
                  children: [
                    Icon(
                      correct ? Icons.check_circle : Icons.cancel,
                      size: 18,
                      color: correct ? Colors.greenAccent : Colors.redAccent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a['word'] ?? '',
                            style: LiquidGlassTheme.headingSm.copyWith(fontSize: 13),
                          ),
                          if (!correct)
                            Text(
                              'Your answer: ${a['user_answer'] ?? ''}',
                              style: LiquidGlassTheme.bodySmall.copyWith(
                                color: Colors.redAccent.withValues(alpha: 0.7),
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 300 + i * 30), duration: 200.ms);
          }),

          const SizedBox(height: 24),

          // History button + actions
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => setState(() => _state = 'start'),
                child: GlassPanel(
                  borderRadius: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text('Done', style: LiquidGlassTheme.label.copyWith(color: LiquidGlassTheme.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _startQuiz,
                child: GlassPanel(
                  borderRadius: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text('Try Again', style: LiquidGlassTheme.label.copyWith(color: LiquidGlassTheme.accentPrimary)),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => setState(() => _state = 'history'),
                child: GlassPanel(
                  borderRadius: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bar_chart_rounded, size: 16, color: LiquidGlassTheme.accentSecondary),
                      const SizedBox(width: 6),
                      Text('History', style: LiquidGlassTheme.label.copyWith(color: LiquidGlassTheme.accentSecondary)),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadHistory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: LiquidGlassTheme.accentPrimary));
        }

        final history = snapshot.data!;
        if (history.isEmpty) {
          return Center(
            child: GlassPanel(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.quiz_outlined, size: 56, color: LiquidGlassTheme.textMuted),
                  const SizedBox(height: 16),
                  Text('No quiz history yet', style: LiquidGlassTheme.headingSm),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => setState(() => _state = 'start'),
                    child: GlassPanel(
                      borderRadius: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Text('Take a Quiz', style: LiquidGlassTheme.label.copyWith(color: LiquidGlassTheme.accentPrimary)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Compute chart data
        final chartEntries = history.reversed.toList();
        final maxScore = 100.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _state = 'start'),
                    child: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: LiquidGlassTheme.textMuted),
                  ),
                  const SizedBox(width: 8),
                  Text('Quiz History', style: LiquidGlassTheme.heading),
                ],
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 20),

              // Chart
              GlassPanel(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Score Over Time', style: LiquidGlassTheme.label),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 160,
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _QuizChartPainter(
                          scores: chartEntries.map((h) => (h['score_pct'] as num?)?.toDouble() ?? 0).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

              const SizedBox(height: 20),

              // Stats summary
              Row(
                children: [
                  Expanded(child: _StatCard(
                    icon: Icons.emoji_events_rounded,
                    label: 'Best Score',
                    value: '${chartEntries.map((h) => (h['score_pct'] as num?)?.toDouble() ?? 0).reduce((a, b) => a > b ? a : b).toStringAsFixed(0)}%',
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(
                    icon: Icons.quiz_outlined,
                    label: 'Total Quizzes',
                    value: '${history.length}',
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(
                    icon: Icons.trending_up_rounded,
                    label: 'Average',
                    value: '${(chartEntries.map((h) => (h['score_pct'] as num?)?.toDouble() ?? 0).reduce((a, b) => a + b) / chartEntries.length).toStringAsFixed(0)}%',
                  )),
                ],
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: 20),

              // Recent quizzes list
              Text('Recent Quizzes', style: LiquidGlassTheme.label),
              const SizedBox(height: 10),

              ...history.take(10).map((h) {
                final scorePct = (h['score_pct'] as num?)?.toDouble() ?? 0;
                final correct = h['correct'] ?? 0;
                final total = h['total_q'] ?? 0;
                final rawDate = (h['taken_at'] ?? h['created_at'])?.toString() ?? '';
                final date = rawDate.length >= 16 ? rawDate.substring(0, 16) : rawDate;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassPanel(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    borderRadius: 12,
                    child: Row(
                      children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: scorePct >= 70
                                ? Colors.greenAccent.withValues(alpha: 0.12)
                                : Colors.orangeAccent.withValues(alpha: 0.12),
                          ),
                          child: Center(
                            child: Text(
                              '${scorePct.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: scorePct >= 70 ? Colors.greenAccent : Colors.orangeAccent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$correct/$total correct', style: LiquidGlassTheme.headingSm.copyWith(fontSize: 13)),
                              Text(date, style: LiquidGlassTheme.bodySmall.copyWith(fontSize: 10)),
                            ],
                          ),
                        ),
                        // Mini bar
                        SizedBox(
                          width: 60, height: 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: scorePct / 100,
                              backgroundColor: Colors.white.withValues(alpha: 0.06),
                              valueColor: AlwaysStoppedAnimation(
                                scorePct >= 70 ? Colors.greenAccent : Colors.orangeAccent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms);
              }),
            ],
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadHistory() async {
    final history = await _engine.getQuizHistory(limit: 20);
    return List<Map<String, dynamic>>.from(history);
  }
}

class _SourceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SourceChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? LiquidGlassTheme.accentPrimary.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: selected
                ? LiquidGlassTheme.accentPrimary.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16,
              color: selected ? LiquidGlassTheme.accentPrimary : LiquidGlassTheme.textMuted),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? LiquidGlassTheme.accentPrimary : LiquidGlassTheme.textSecondary,
            )),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      borderRadius: 14,
      child: Column(
        children: [
          Icon(icon, size: 20, color: LiquidGlassTheme.accentPrimary),
          const SizedBox(height: 8),
          Text(value, style: LiquidGlassTheme.headingSm.copyWith(fontSize: 16)),
          const SizedBox(height: 2),
          Text(label, style: LiquidGlassTheme.bodySmall.copyWith(fontSize: 9)),
        ],
      ),
    );
  }
}

class _QuizChartPainter extends CustomPainter {
  final List<double> scores;

  _QuizChartPainter({required this.scores});

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    final w = size.width;
    final h = size.height;
    final padding = 8.0;
    final chartW = w - padding * 2;
    final chartH = h - padding * 2;

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 0.5;

    for (var i = 0; i <= 4; i++) {
      final y = padding + chartH * (1 - i / 4);
      canvas.drawLine(Offset(padding, y), Offset(w - padding, y), gridPaint);
    }

    if (scores.length == 1) {
      // Single dot
      final dotPaint = Paint()..color = const Color(0xFFB388FF);
      canvas.drawCircle(Offset(w / 2, padding + chartH * (1 - scores[0] / 100)), 4, dotPaint);
      return;
    }

    // Line path
    final path = Path();
    final fillPath = Path();
    final points = <Offset>[];

    for (var i = 0; i < scores.length; i++) {
      final x = padding + (i / (scores.length - 1)) * chartW;
      final y = padding + chartH * (1 - scores[i] / 100);
      points.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, h - padding);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(points.last.dx, h - padding);
    fillPath.close();

    // Gradient fill
    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, padding),
        Offset(0, h),
        [
          const Color(0xFFB388FF).withValues(alpha: 0.25),
          const Color(0xFFB388FF).withValues(alpha: 0.0),
        ],
      );
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = const Color(0xFFB388FF)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Dots
    final dotPaint = Paint()..color = const Color(0xFFB388FF);
    final dotBorder = Paint()
      ..color = const Color(0xFF1A1332)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (final p in points) {
      canvas.drawCircle(p, 4, dotPaint);
      canvas.drawCircle(p, 4, dotBorder);
    }
  }

  @override
  bool shouldRepaint(covariant _QuizChartPainter old) => old.scores != scores;
}

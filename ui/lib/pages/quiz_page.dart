/// LexiCore — Quiz Page (v3.1)
/// Multiple-choice quiz with feedback, explanations, and pet unlock.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  Future<void> _startQuiz() async {
    final data = await _engine.generateQuiz(count: 10);
    if (data == null || (data['questions'] as List?)?.isEmpty == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not enough words for quiz. Add more words first!')),
        );
      }
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
    await _engine.submitQuiz(
      answers: _answers,
      durationS: _timer.elapsedMilliseconds / 1000,
    );
    final newPets = await _engine.checkPetUnlocks();
    setState(() {
      _state = 'result';
    });
    if (newPets.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🎉 New pet unlocked: ${newPets.join(', ')}!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case 'question':
        return _buildQuestion();
      case 'result':
        return _buildResult();
      default:
        return _buildStart();
    }
  }

  Widget _buildStart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassPanel(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🧠', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 24),
              Text('Vocabulary Quiz', style: LiquidGlassTheme.heading),
              const SizedBox(height: 12),
              Text(
                'Test your knowledge with\n10 multiple-choice questions',
                style: LiquidGlassTheme.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _startQuiz,
                child: GlassPanel(
                  borderRadius: LiquidGlassTheme.borderRadiusPill,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  child: Text(
                    'Start Quiz',
                    style: LiquidGlassTheme.headingSm.copyWith(
                      color: LiquidGlassTheme.accentPrimary,
                      fontSize: 16,
                    ),
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

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: GlassPanel(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 20),
              Text('Quiz Complete!', style: LiquidGlassTheme.heading),
              const SizedBox(height: 20),
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: LiquidGlassTheme.heading.copyWith(
                  fontSize: 48,
                  color: pct >= 70 ? Colors.greenAccent : Colors.orangeAccent,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$_score of ${_questions.length} correct',
                style: LiquidGlassTheme.body,
              ),
              const SizedBox(height: 32),
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
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: _startQuiz,
                    child: GlassPanel(
                      borderRadius: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Text('Try Again', style: LiquidGlassTheme.label.copyWith(color: LiquidGlassTheme.accentPrimary)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9)),
      ),
    );
  }
}

/// LexiCore — Quiz Page
/// Multiple choice quiz with right/wrong feedback and explanations.
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
  List<Map<String, dynamic>> _questions = [];
  int _currentQ = 0;
  String? _selectedAnswer;
  bool _answered = false;
  List<Map<String, dynamic>> _answers = [];
  bool _quizActive = false;
  bool _quizDone = false;
  Map<String, dynamic>? _quizResult;
  DateTime? _startTime;
  bool _isLoading = false;

  Future<void> _startQuiz({int? deckId}) async {
    setState(() => _isLoading = true);
    final data = await _engine.generateQuiz(deckId: deckId);
    if (data == null || data.containsKey('error')) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data?['error'] ?? 'Need at least 4 saved words for a quiz')),
        );
      }
      return;
    }

    final questions = List<Map<String, dynamic>>.from(data['questions'] ?? []);
    setState(() {
      _questions = questions;
      _currentQ = 0;
      _selectedAnswer = null;
      _answered = false;
      _answers = [];
      _quizActive = true;
      _quizDone = false;
      _startTime = DateTime.now();
      _isLoading = false;
    });
  }

  void _selectAnswer(String answer) {
    if (_answered) return;
    final q = _questions[_currentQ];
    final isCorrect = answer == q['correct_answer'];

    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      _answers.add({
        'word': q['word'],
        'user_answer': answer,
        'correct_answer': q['correct_answer'],
        'is_correct': isCorrect,
        'explanation': q['explanation'],
      });
    });
  }

  Future<void> _nextQuestion() async {
    if (_currentQ < _questions.length - 1) {
      setState(() {
        _currentQ++;
        _selectedAnswer = null;
        _answered = false;
      });
    } else {
      // Submit quiz
      final duration = DateTime.now().difference(_startTime!).inSeconds.toDouble();
      final result = await _engine.submitQuiz(
        answers: _answers,
        durationS: duration,
      );
      setState(() {
        _quizDone = true;
        _quizActive = false;
        _quizResult = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_quizDone) return _buildResults();
    if (_quizActive) return _buildQuestion();
    return _buildStart();
  }

  Widget _buildStart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.quiz_rounded, size: 64, color: LiquidGlassTheme.accentPrimary)
                .animate().scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 500.ms),
            const SizedBox(height: 24),
            Text('Quiz Mode', style: LiquidGlassTheme.heading).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Text(
              'Test your knowledge with multiple-choice questions',
              style: LiquidGlassTheme.body,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 40),

            GlassPanel(
              borderRadius: 30,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: InkWell(
                onTap: _isLoading ? null : () => _startQuiz(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoading)
                      const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: LiquidGlassTheme.accentPrimary),
                      )
                    else
                      const Icon(Icons.play_arrow_rounded, color: LiquidGlassTheme.accentPrimary),
                    const SizedBox(width: 10),
                    Text('Start Quiz', style: LiquidGlassTheme.headingSm.copyWith(fontSize: 16)),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    final q = _questions[_currentQ];
    final options = List<String>.from(q['options'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress
          Row(
            children: [
              Text(
                'Question ${_currentQ + 1}/${_questions.length}',
                style: LiquidGlassTheme.label,
              ),
              const Spacer(),
              Text(
                '${_answers.where((a) => a['is_correct'] == true).length} correct',
                style: LiquidGlassTheme.bodySmall.copyWith(color: Colors.greenAccent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentQ + 1) / _questions.length,
              backgroundColor: LiquidGlassTheme.glassFill,
              color: LiquidGlassTheme.accentPrimary,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 28),

          // Word
          GlassPanel(
            padding: const EdgeInsets.all(28),
            child: Center(
              child: Text(
                q['word'] ?? '',
                style: LiquidGlassTheme.heading.copyWith(fontSize: 32),
              ),
            ),
          ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95)),
          const SizedBox(height: 8),
          Center(
            child: Text('What does this word mean?', style: LiquidGlassTheme.bodySmall),
          ),
          const SizedBox(height: 24),

          // Options
          ...options.asMap().entries.map((entry) {
            final option = entry.value;
            final isSelected = _selectedAnswer == option;
            final isCorrect = option == q['correct_answer'];

            Color? borderColor;
            Color? fillColor;
            if (_answered) {
              if (isCorrect) {
                borderColor = Colors.greenAccent;
                fillColor = Colors.greenAccent.withValues(alpha: 0.1);
              } else if (isSelected && !isCorrect) {
                borderColor = Colors.redAccent;
                fillColor = Colors.redAccent.withValues(alpha: 0.1);
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => _selectAnswer(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(LiquidGlassTheme.borderRadiusSm),
                    color: fillColor ?? LiquidGlassTheme.glassFill,
                    border: Border.all(
                      color: borderColor ??
                          (isSelected ? LiquidGlassTheme.accentPrimary : LiquidGlassTheme.glassBorder),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (borderColor ?? LiquidGlassTheme.glassBorder).withValues(alpha: 0.2),
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + entry.key), // A, B, C, D
                            style: LiquidGlassTheme.label.copyWith(
                              color: borderColor ?? LiquidGlassTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option,
                          style: LiquidGlassTheme.body.copyWith(
                            color: LiquidGlassTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (_answered && isCorrect)
                        const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 22),
                      if (_answered && isSelected && !isCorrect)
                        const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 22),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 100 * entry.key), duration: 300.ms),
            );
          }),

          // Explanation
          if (_answered) ...[
            const SizedBox(height: 16),
            GlassPanel(
              padding: const EdgeInsets.all(16),
              borderRadius: LiquidGlassTheme.borderRadiusSm,
              child: Row(
                children: [
                  Icon(
                    _selectedAnswer == q['correct_answer']
                        ? Icons.lightbulb_rounded
                        : Icons.info_outline_rounded,
                    color: _selectedAnswer == q['correct_answer']
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      q['explanation'] ?? '',
                      style: LiquidGlassTheme.body,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),

            const SizedBox(height: 20),
            Center(
              child: GlassPanel(
                borderRadius: 30,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                child: InkWell(
                  onTap: _nextQuestion,
                  child: Text(
                    _currentQ < _questions.length - 1 ? 'Next Question →' : 'See Results',
                    style: LiquidGlassTheme.headingSm.copyWith(fontSize: 14, color: LiquidGlassTheme.accentPrimary),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResults() {
    final correct = _quizResult?['correct'] ?? 0;
    final total = _quizResult?['total'] ?? 0;
    final score = _quizResult?['score_pct'] ?? 0.0;
    final newPets = List<String>.from(_quizResult?['new_pets_unlocked'] ?? []);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              score >= 100 ? Icons.emoji_events_rounded : Icons.analytics_rounded,
              size: 64,
              color: score >= 100 ? Colors.amber : LiquidGlassTheme.accentPrimary,
            ).animate().scale(begin: const Offset(0, 0), end: const Offset(1, 1), duration: 500.ms, curve: Curves.elasticOut),

            const SizedBox(height: 20),
            Text(
              score >= 100 ? 'Perfect Score!' : 'Quiz Complete!',
              style: LiquidGlassTheme.heading,
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 16),
            GlassPanel(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    '${score.toStringAsFixed(0)}%',
                    style: LiquidGlassTheme.heading.copyWith(
                      fontSize: 48,
                      color: score >= 80 ? Colors.greenAccent : Colors.orangeAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('$correct / $total correct', style: LiquidGlassTheme.body),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),

            if (newPets.isNotEmpty) ...[
              const SizedBox(height: 20),
              GlassPanel(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    Text('New Pet Unlocked!', style: LiquidGlassTheme.headingSm),
                    ...newPets.map((p) => Text(p, style: LiquidGlassTheme.body)),
                  ],
                ),
              ).animate().fadeIn(delay: 800.ms).scale(begin: const Offset(0.8, 0.8)),
            ],

            const SizedBox(height: 32),
            GlassPanel(
              borderRadius: 30,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              child: InkWell(
                onTap: () => setState(() {
                  _quizDone = false;
                  _quizActive = false;
                }),
                child: Text('Try Again', style: LiquidGlassTheme.headingSm.copyWith(
                  fontSize: 14, color: LiquidGlassTheme.accentPrimary,
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

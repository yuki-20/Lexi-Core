/// LexiCore — Performance & Streak Pets Page
/// Analytics dashboard with quiz history, effort metrics, and pet collection.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/liquid_glass_theme.dart';
import '../services/engine_service.dart';
import '../widgets/glass_panel.dart';

class PerformancePage extends StatefulWidget {
  const PerformancePage({super.key});

  @override
  State<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage> {
  final _engine = EngineService();
  Map<String, dynamic> _perf = {};
  List<Map<String, dynamic>> _quizHistory = [];
  List<Map<String, dynamic>> _pets = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final perf = await _engine.getPerformance();
    final history = await _engine.getQuizHistory();
    final pets = await _engine.getAllPets();
    await _engine.checkPetUnlocks();
    if (mounted) {
      setState(() {
        _perf = perf;
        _quizHistory = history;
        _pets = pets;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = _perf['quiz'] as Map<String, dynamic>? ?? {};
    final cards = _perf['flashcards'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Performance', style: LiquidGlassTheme.heading)
              .animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 20),

          // ── Stats Grid ──
          Row(
            children: [
              _StatCard(
                icon: Icons.local_fire_department_rounded,
                label: 'Streak',
                value: '${_perf['streak_days'] ?? 0}',
                unit: 'days',
                color: Colors.orangeAccent,
              ),
              const SizedBox(width: 12),
              _StatCard(
                icon: Icons.bolt_rounded,
                label: 'Total EXP',
                value: '${_perf['total_exp'] ?? 0}',
                unit: 'xp',
                color: LiquidGlassTheme.accentPrimary,
              ),
            ],
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(
                icon: Icons.search_rounded,
                label: 'Searches',
                value: '${_perf['total_searches'] ?? 0}',
                unit: 'total',
                color: LiquidGlassTheme.accentSecondary,
              ),
              const SizedBox(width: 12),
              _StatCard(
                icon: Icons.bookmark_rounded,
                label: 'Saved',
                value: '${_perf['total_saved'] ?? 0}',
                unit: 'words',
                color: LiquidGlassTheme.accentTertiary,
              ),
            ],
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 24),

          // ── Quiz Performance ──
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quiz Performance', style: LiquidGlassTheme.headingSm),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MiniStat(label: 'Quizzes', value: '${quiz['total_quizzes'] ?? 0}'),
                    _MiniStat(label: 'Avg Score', value: '${(quiz['avg_score'] ?? 0).toStringAsFixed(0)}%'),
                    _MiniStat(label: 'Best', value: '${(quiz['best_score'] ?? 0).toStringAsFixed(0)}%'),
                    _MiniStat(label: 'Accuracy', value:
                      quiz['total_questions'] != null && quiz['total_questions'] > 0
                        ? '${((quiz['total_correct'] / quiz['total_questions']) * 100).toStringAsFixed(0)}%'
                        : '0%'
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 16),

          // ── Flashcard Stats ──
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Flashcard Stats', style: LiquidGlassTheme.headingSm),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MiniStat(label: 'Cards', value: '${cards['total_cards'] ?? 0}'),
                    _MiniStat(label: 'Reviews', value: '${cards['total_reviews'] ?? 0}'),
                    _MiniStat(label: 'Mastery', value: '${(cards['avg_mastery'] ?? 0).toStringAsFixed(1)}/5'),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms),

          const SizedBox(height: 24),

          // ── Pets Collection ──
          Text('Pet Collection', style: LiquidGlassTheme.headingSm)
              .animate().fadeIn(delay: 600.ms),
          const SizedBox(height: 12),

          ...(_pets.map((pet) {
            final unlocked = pet['unlocked'] == true;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassPanel(
                padding: const EdgeInsets.all(16),
                borderRadius: LiquidGlassTheme.borderRadiusSm,
                child: Row(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: unlocked
                            ? LinearGradient(colors: [
                                LiquidGlassTheme.accentPrimary.withValues(alpha: 0.3),
                                LiquidGlassTheme.accentSecondary.withValues(alpha: 0.2),
                              ])
                            : null,
                        color: unlocked ? null : LiquidGlassTheme.glassFill,
                      ),
                      child: Center(
                        child: Text(
                          _petEmoji(pet['emoji'] ?? ''),
                          style: TextStyle(fontSize: unlocked ? 28 : 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pet['name'] ?? '',
                            style: LiquidGlassTheme.headingSm.copyWith(
                              fontSize: 15,
                              color: unlocked ? LiquidGlassTheme.textPrimary : LiquidGlassTheme.textMuted,
                            ),
                          ),
                          Text(
                            pet['desc'] ?? '',
                            style: LiquidGlassTheme.bodySmall.copyWith(
                              color: unlocked ? LiquidGlassTheme.textSecondary : LiquidGlassTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (unlocked)
                      const Icon(Icons.check_circle, color: Colors.greenAccent, size: 22)
                    else
                      Icon(Icons.lock_rounded, color: LiquidGlassTheme.textMuted.withValues(alpha: 0.5), size: 20),
                  ],
                ),
              ).animate().fadeIn(delay: const Duration(milliseconds: 700)),
            );
          })),

          // ── Quiz History ──
          if (_quizHistory.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Recent Quizzes', style: LiquidGlassTheme.headingSm)
                .animate().fadeIn(delay: const Duration(milliseconds: 800)),
            const SizedBox(height: 10),
            ..._quizHistory.take(5).map((q) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassPanel(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                borderRadius: LiquidGlassTheme.borderRadiusSm,
                child: Row(
                  children: [
                    Text(
                      '${(q['score_pct'] ?? 0).toStringAsFixed(0)}%',
                      style: LiquidGlassTheme.headingSm.copyWith(
                        fontSize: 16,
                        color: (q['score_pct'] ?? 0) >= 80 ? Colors.greenAccent : Colors.orangeAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${q['correct']}/${q['total_q']} correct',
                        style: LiquidGlassTheme.body,
                      ),
                    ),
                    Text(
                      q['taken_at']?.toString().substring(0, 10) ?? '',
                      style: LiquidGlassTheme.mono,
                    ),
                  ],
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }

  String _petEmoji(String name) {
    switch (name) {
      case 'fox': return '🦊';
      case 'owl': return '🦉';
      case 'dragon': return '🐉';
      case 'unicorn': return '🦄';
      default: return '🐾';
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value, unit;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassPanel(
        padding: const EdgeInsets.all(16),
        borderRadius: LiquidGlassTheme.borderRadiusSm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(value, style: LiquidGlassTheme.heading.copyWith(fontSize: 22, color: color)),
            Text('$label ($unit)', style: LiquidGlassTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: LiquidGlassTheme.headingSm.copyWith(fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: LiquidGlassTheme.bodySmall),
      ],
    );
  }
}

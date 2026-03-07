/// LexiCore — Performance & Pet Collection Page (v3.1)
/// Analytics dashboard with expandable pet info cards.
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
  int? _expandedPetIndex;

  // Pet detailed info
  static const _petInfo = {
    'ember_fox': {
      'emoji': '🦊',
      'name': 'Ember Fox',
      'desc': 'A swift and cunning companion born from the flames of dedication.',
      'unlock': '7-day study streak',
      'ability': 'Grants +10% bonus EXP on all quiz completions',
      'lore': 'Ember Fox appears to those who show unwavering daily commitment. Its fiery tail leaves a trail of knowledge wherever it goes.',
    },
    'volt_owl': {
      'emoji': '🦉',
      'name': 'Volt Owl',
      'desc': 'A wise guardian that watches over your learning journey.',
      'unlock': '30-day study streak',
      'ability': 'Unlocks quiz hints — reveals one incorrect option per question',
      'lore': 'Volt Owl has witnessed a thousand learners grow. Its electric feathers crackle with accumulated wisdom from ages past.',
    },
    'aqua_dragon': {
      'emoji': '🐉',
      'name': 'Aqua Dragon',
      'desc': 'An ancient beast of immense knowledge and power.',
      'unlock': '100-day study streak',
      'ability': 'Doubles streak EXP gains and unlocks advanced analytics',
      'lore': 'Aqua Dragon dwells in the deepest library ocean. Only the most persistent scholars can summon it from the depths.',
    },
    'prisma': {
      'emoji': '🦄',
      'name': 'Prisma',
      'desc': 'A mythical creature of pure light — the ultimate companion.',
      'unlock': 'Score 100% on 3 different quizzes',
      'ability': 'Adds rainbow shimmer effect to all glass panels + triples EXP',
      'lore': 'Prisma exists between dimensions of perfect knowledge. It chooses only those who have proven mastery beyond doubt.',
    },
  };

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
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Performance', style: LiquidGlassTheme.heading)
              .animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 24),

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
              const SizedBox(width: 14),
              _StatCard(
                icon: Icons.bolt_rounded,
                label: 'Total EXP',
                value: '${_perf['total_exp'] ?? 0}',
                unit: 'xp',
                color: LiquidGlassTheme.accentPrimary,
              ),
            ],
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.05, end: 0),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatCard(
                icon: Icons.search_rounded,
                label: 'Searches',
                value: '${_perf['total_searches'] ?? 0}',
                unit: 'total',
                color: LiquidGlassTheme.accentSecondary,
              ),
              const SizedBox(width: 14),
              _StatCard(
                icon: Icons.bookmark_rounded,
                label: 'Saved',
                value: '${_perf['total_saved'] ?? 0}',
                unit: 'words',
                color: LiquidGlassTheme.accentTertiary,
              ),
            ],
          ).animate().fadeIn(delay: 250.ms, duration: 400.ms).slideY(begin: 0.05, end: 0),

          const SizedBox(height: 28),

          // ── Quiz Performance ──
          GlassPanel(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quiz Performance', style: LiquidGlassTheme.headingSm),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MiniStat(label: 'Quizzes', value: '${quiz['total_quizzes'] ?? 0}'),
                    _MiniStat(label: 'Avg', value: '${(quiz['avg_score'] ?? 0).toStringAsFixed(0)}%'),
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
          ).animate().fadeIn(delay: 350.ms, duration: 400.ms).slideY(begin: 0.05, end: 0),

          const SizedBox(height: 16),

          // ── Flashcard Stats ──
          GlassPanel(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Flashcard Stats', style: LiquidGlassTheme.headingSm),
                const SizedBox(height: 18),
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
          ).animate().fadeIn(delay: 450.ms, duration: 400.ms).slideY(begin: 0.05, end: 0),

          const SizedBox(height: 28),

          // ── Pet Collection ──
          Row(
            children: [
              Text('Pet Collection', style: LiquidGlassTheme.headingSm),
              const SizedBox(width: 8),
              Text('(${_pets.where((p) => p['unlocked'] == true).length}/${_petInfo.length})',
                style: LiquidGlassTheme.bodySmall),
            ],
          ).animate().fadeIn(delay: 550.ms),
          const SizedBox(height: 14),

          ...(_pets.asMap().entries.map((entry) {
            final pet = entry.value;
            final petId = pet['id'] ?? '';
            final info = _petInfo[petId] ?? {};
            final unlocked = pet['unlocked'] == true;
            final isExpanded = _expandedPetIndex == entry.key;
            final emoji = info['emoji'] ?? '🐾';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() {
                  _expandedPetIndex = isExpanded ? null : entry.key;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: GlassPanel(
                    padding: const EdgeInsets.all(18),
                    borderRadius: LiquidGlassTheme.borderRadiusSm,
                    child: Column(
                      children: [
                        // Pet header row
                        Row(
                          children: [
                            Container(
                              width: 56, height: 56,
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
                                child: Text(emoji, style: TextStyle(fontSize: unlocked ? 30 : 22)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    info['name'] ?? pet['name'] ?? '',
                                    style: LiquidGlassTheme.headingSm.copyWith(
                                      fontSize: 16,
                                      color: unlocked ? LiquidGlassTheme.textPrimary : LiquidGlassTheme.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    info['desc'] ?? '',
                                    style: LiquidGlassTheme.bodySmall.copyWith(
                                      color: unlocked ? LiquidGlassTheme.textSecondary : LiquidGlassTheme.textMuted,
                                    ),
                                    maxLines: isExpanded ? null : 1,
                                    overflow: isExpanded ? null : TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (unlocked)
                              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 22)
                            else
                              Icon(Icons.lock_rounded, color: LiquidGlassTheme.textMuted.withValues(alpha: 0.5), size: 20),
                            const SizedBox(width: 4),
                            AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 250),
                              child: const Icon(Icons.expand_more, color: LiquidGlassTheme.textMuted, size: 20),
                            ),
                          ],
                        ),

                        // Expanded info
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(color: LiquidGlassTheme.glassBorder, height: 1),
                                const SizedBox(height: 14),

                                _PetInfoRow(
                                  icon: Icons.lock_open_rounded,
                                  label: 'Unlock Requirement',
                                  value: info['unlock'] ?? '',
                                  color: Colors.orangeAccent,
                                ),
                                const SizedBox(height: 10),
                                _PetInfoRow(
                                  icon: Icons.auto_awesome_rounded,
                                  label: 'Ability',
                                  value: info['ability'] ?? '',
                                  color: LiquidGlassTheme.accentPrimary,
                                ),
                                const SizedBox(height: 10),
                                _PetInfoRow(
                                  icon: Icons.auto_stories_rounded,
                                  label: 'Lore',
                                  value: info['lore'] ?? '',
                                  color: LiquidGlassTheme.accentSecondary,
                                ),
                              ],
                            ),
                          ),
                          crossFadeState: isExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 300),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 600 + entry.key * 100), duration: 400.ms),
            );
          })),

          // ── Quiz History ──
          if (_quizHistory.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Recent Quizzes', style: LiquidGlassTheme.headingSm)
                .animate().fadeIn(delay: const Duration(milliseconds: 900)),
            const SizedBox(height: 12),
            ..._quizHistory.take(5).toList().asMap().entries.map((entry) {
              final q = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassPanel(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  borderRadius: LiquidGlassTheme.borderRadiusSm,
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: ((q['score_pct'] ?? 0) >= 80 ? Colors.greenAccent : Colors.orangeAccent)
                              .withValues(alpha: 0.12),
                        ),
                        child: Center(
                          child: Text(
                            '${(q['score_pct'] ?? 0).toStringAsFixed(0)}%',
                            style: LiquidGlassTheme.label.copyWith(
                              color: (q['score_pct'] ?? 0) >= 80 ? Colors.greenAccent : Colors.orangeAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${q['correct']}/${q['total_q']} correct',
                              style: LiquidGlassTheme.body,
                            ),
                            Text(
                              q['taken_at']?.toString().substring(0, 10) ?? '',
                              style: LiquidGlassTheme.mono,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 950 + entry.key * 80), duration: 300.ms),
              );
            }),
          ],
        ],
      ),
    );
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
        padding: const EdgeInsets.all(18),
        borderRadius: LiquidGlassTheme.borderRadiusSm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 10),
            Text(value, style: LiquidGlassTheme.heading.copyWith(fontSize: 24, color: color)),
            const SizedBox(height: 2),
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
        const SizedBox(height: 4),
        Text(label, style: LiquidGlassTheme.bodySmall),
      ],
    );
  }
}

class _PetInfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _PetInfoRow({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: LiquidGlassTheme.label.copyWith(color: color)),
              const SizedBox(height: 2),
              Text(value, style: LiquidGlassTheme.body),
            ],
          ),
        ),
      ],
    );
  }
}

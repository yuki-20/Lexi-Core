/// LexiCore — Performance & Analytics Page (v5.0)
/// Professional analytics dashboard with:
///   - XP level overview with progress bar
///   - Quick stats (Dictionary, Streak, EXP — moved from home)
///   - Quiz accuracy analysis
///   - Word mastery badges
///   - Pet collection showcase
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
  bool _loading = true;

  // Stats
  int _dictSize = 0;
  int _streakDays = 0;
  int _totalExp = 0;
  int _wordsSaved = 0;
  int _searchCount = 0;

  // XP / Level
  int _level = 1;
  String _levelTitle = 'Novice';
  double _xpProgress = 0.0;
  int _xpIntoLevel = 0;
  int _xpForNext = 100;

  // Quiz
  int _quizzesTaken = 0;
  int _quizCorrect = 0;
  int _quizTotal = 0;

  // Pets
  List<Map<String, dynamic>> _pets = [];

  // Quests
  List<Map<String, dynamic>> _quests = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Fire ALL requests in parallel instead of sequentially
      final results = await Future.wait([
        _engine.getStats().timeout(const Duration(seconds: 5), onTimeout: () => <String, dynamic>{}),
        _engine.getPerformance().timeout(const Duration(seconds: 5), onTimeout: () => <String, dynamic>{}),
        _engine.getXpStatus().timeout(const Duration(seconds: 5), onTimeout: () => <String, dynamic>{}),
        _engine.getAllPets().timeout(const Duration(seconds: 5), onTimeout: () => <Map<String, dynamic>>[]),
        _engine.getSavedWords().timeout(const Duration(seconds: 5), onTimeout: () => <Map<String, dynamic>>[]),
        _engine.getQuests().timeout(const Duration(seconds: 5), onTimeout: () => <Map<String, dynamic>>[]),
      ]);

      if (!mounted) return;

      final stats = results[0] as Map<String, dynamic>;
      final performance = results[1] as Map<String, dynamic>;
      final xpStatus = results[2] as Map<String, dynamic>;
      final pets = results[3] as List;
      final saved = results[4] as List;
      final quests = results[5] as List;

      final learning = stats['learning'] as Map? ?? {};
      final quizPerf = performance['quiz'] as Map? ?? {};

      setState(() {
        _dictSize = (stats['dictionary_size'] as num?)?.toInt() ?? 0;
        _streakDays = (learning['streak_days'] as num?)?.toInt() ?? 0;
        _totalExp = (learning['total_exp'] as num?)?.toInt() ?? 0;
        _wordsSaved = saved.length;
        _searchCount = (performance['total_searches'] as num?)?.toInt() ?? 0;

        _level = (xpStatus['level'] as num?)?.toInt() ?? 1;
        _levelTitle = xpStatus['title']?.toString() ?? 'Novice';
        _xpProgress = (xpStatus['progress'] as num?)?.toDouble() ?? 0.0;
        _xpIntoLevel = (xpStatus['xp_into_level'] as num?)?.toInt() ?? 0;
        _xpForNext = (xpStatus['xp_for_next'] as num?)?.toInt() ?? 100;

        _quizzesTaken = (quizPerf['total_quizzes'] as num?)?.toInt() ?? 0;
        _quizCorrect = (quizPerf['correct_answers'] as num?)?.toInt() ?? 0;
        _quizTotal = (quizPerf['total_answers'] as num?)?.toInt() ?? 0;

        _pets = List<Map<String, dynamic>>.from(pets);
        _quests = List<Map<String, dynamic>>.from(quests);

        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(
        color: LiquidGlassTheme.accentPrimary,
      ));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Text('Performance Analytics', style: LiquidGlassTheme.heading)
              .animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 6),
          Text('Track your learning journey', style: LiquidGlassTheme.bodySmall)
              .animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 28),

          // ── Level Overview ──
          GlassPanel(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    // Level circle
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            LiquidGlassTheme.accentPrimary,
                            LiquidGlassTheme.accentSecondary,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$_level',
                          style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_levelTitle, style: LiquidGlassTheme.headingSm),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _xpProgress,
                              minHeight: 8,
                              backgroundColor: Colors.white.withValues(alpha: 0.08),
                              color: LiquidGlassTheme.accentPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_xpIntoLevel / $_xpForNext XP to Level ${_level + 1}',
                            style: LiquidGlassTheme.bodySmall.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms)
           .slideY(begin: 0.04, end: 0),

          const SizedBox(height: 20),

          // ── Daily & Weekly Quests ──
          if (_quests.isNotEmpty) ...[
            Row(
              children: [
                Text('🎯 Quests', style: LiquidGlassTheme.label),
                const Spacer(),
                // Quest reset timer
                Builder(builder: (_) {
                  final now = DateTime.now();
                  final midnight = DateTime(now.year, now.month, now.day + 1);
                  final diff = midnight.difference(now);
                  final h = diff.inHours;
                  final m = diff.inMinutes % 60;
                  return Text(
                    'Resets in ${h}h ${m}m',
                    style: LiquidGlassTheme.bodySmall.copyWith(
                      fontSize: 10,
                      color: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.7),
                    ),
                  );
                }),
              ],
            ).animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 12),
            ..._quests.asMap().entries.map((entry) {
              final i = entry.key;
              final q = entry.value;
              final progress = (q['progress'] as num?)?.toInt() ?? 0;
              final target = (q['target'] as num?)?.toInt() ?? 1;
              final completed = q['completed'] == true;
              final xpReward = (q['xp'] as num?)?.toInt() ?? 0;
              final isDaily = q['type'] == 'daily';
              final ratio = (progress / target).clamp(0.0, 1.0);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassPanel(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // Quest type badge
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(colors: [
                            (completed ? Colors.green : (isDaily ? LiquidGlassTheme.accentPrimary : Colors.amber)).withValues(alpha: 0.2),
                            (completed ? Colors.green : (isDaily ? LiquidGlassTheme.accentPrimary : Colors.amber)).withValues(alpha: 0.05),
                          ]),
                        ),
                        child: Center(
                          child: Icon(
                            completed ? Icons.check_circle_rounded : (isDaily ? Icons.today_rounded : Icons.date_range_rounded),
                            size: 18,
                            color: completed ? Colors.green : (isDaily ? LiquidGlassTheme.accentPrimary : Colors.amber),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    q['name']?.toString() ?? 'Quest',
                                    style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600,
                                      color: completed ? Colors.green : LiquidGlassTheme.textPrimary,
                                      decoration: completed ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: (completed ? Colors.green : Colors.amber).withValues(alpha: 0.15),
                                  ),
                                  child: Text(
                                    '+$xpReward XP',
                                    style: TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.w700,
                                      color: completed ? Colors.green : Colors.amber,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${q['desc'] ?? ''} • $progress/$target',
                              style: LiquidGlassTheme.bodySmall.copyWith(fontSize: 11, color: LiquidGlassTheme.textMuted),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 4,
                                backgroundColor: Colors.white.withValues(alpha: 0.06),
                                color: completed ? Colors.green : LiquidGlassTheme.accentPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: (280 + i * 60).ms, duration: 400.ms)
                 .slideY(begin: 0.03, end: 0),
              );
            }),
            const SizedBox(height: 8),
          ],

          // ── Quick Stats Grid (moved from Home) ──
          Row(
            children: [
              Expanded(child: _StatTile(
                icon: Icons.menu_book_rounded,
                iconColor: LiquidGlassTheme.accentPrimary,
                value: '$_dictSize',
                label: 'Dictionary',
                delay: 300,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(
                icon: Icons.local_fire_department,
                iconColor: Colors.orangeAccent,
                value: '${_streakDays}d',
                label: 'Streak',
                delay: 350,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(
                icon: Icons.bolt_rounded,
                iconColor: LiquidGlassTheme.accentSecondary,
                value: '$_totalExp',
                label: 'Total XP',
                delay: 400,
              )),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _StatTile(
                icon: Icons.bookmark_rounded,
                iconColor: const Color(0xFF69F0AE),
                value: '$_wordsSaved',
                label: 'Saved Words',
                delay: 450,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(
                icon: Icons.search_rounded,
                iconColor: const Color(0xFF40C4FF),
                value: '$_searchCount',
                label: 'Searches',
                delay: 500,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(
                icon: Icons.quiz_rounded,
                iconColor: const Color(0xFFFF4081),
                value: '$_quizzesTaken',
                label: 'Quizzes',
                delay: 550,
              )),
            ],
          ),

          const SizedBox(height: 28),

          // ── Quiz Performance Analysis ──
          Text('Quiz Performance', style: LiquidGlassTheme.label)
              .animate().fadeIn(delay: 600.ms),
          const SizedBox(height: 12),
          GlassPanel(
            padding: const EdgeInsets.all(24),
            child: _quizTotal > 0
                ? Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${(_quizCorrect / _quizTotal * 100).toStringAsFixed(1)}%',
                                  style: LiquidGlassTheme.heading.copyWith(
                                    fontSize: 36,
                                    color: _quizCorrect / _quizTotal >= 0.7
                                        ? const Color(0xFF69F0AE)
                                        : Colors.orangeAccent,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('Accuracy', style: LiquidGlassTheme.bodySmall),
                              ],
                            ),
                          ),
                          Container(
                            width: 1, height: 50,
                            color: LiquidGlassTheme.glassBorder,
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '$_quizCorrect / $_quizTotal',
                                  style: LiquidGlassTheme.headingSm,
                                ),
                                const SizedBox(height: 4),
                                Text('Correct Answers', style: LiquidGlassTheme.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Accuracy bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _quizTotal > 0 ? _quizCorrect / _quizTotal : 0,
                          minHeight: 12,
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          color: _quizCorrect / _quizTotal >= 0.7
                              ? const Color(0xFF69F0AE)
                              : Colors.orangeAccent,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _quizCorrect / _quizTotal >= 0.9
                                ? '🏆 Outstanding!'
                                : _quizCorrect / _quizTotal >= 0.7
                                    ? '🎉 Great job!'
                                    : _quizCorrect / _quizTotal >= 0.5
                                        ? '👍 Keep going!'
                                        : '💪 Room to improve',
                            style: LiquidGlassTheme.bodySmall,
                          ),
                          Text(
                            '$_quizzesTaken quizzes taken',
                            style: LiquidGlassTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text('📝', style: TextStyle(fontSize: 36)),
                          const SizedBox(height: 12),
                          Text('No quizzes taken yet',
                            style: LiquidGlassTheme.body),
                          const SizedBox(height: 4),
                          Text('Take your first quiz to see analytics here',
                            style: LiquidGlassTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
          ).animate().fadeIn(delay: 650.ms, duration: 500.ms)
           .slideY(begin: 0.04, end: 0),

          const SizedBox(height: 28),

          // ── Pet Collection ──
          Text('Pet Collection', style: LiquidGlassTheme.label)
              .animate().fadeIn(delay: 700.ms),
          const SizedBox(height: 12),
          ..._pets.asMap().entries.map((entry) {
            final i = entry.key;
            final pet = entry.value;
            final unlocked = pet['unlocked'] == true;
            const petEmojis = {
              'ember_fox': '🦊', 'volt_owl': '🦉',
              'aqua_dragon': '🐉', 'prisma': '🦄',
            };
            final emoji = petEmojis[pet['id']] ?? '🐾';

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassPanel(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: unlocked
                            ? LinearGradient(colors: [
                                LiquidGlassTheme.accentPrimary.withValues(alpha: 0.2),
                                LiquidGlassTheme.accentSecondary.withValues(alpha: 0.1),
                              ])
                            : null,
                        color: unlocked ? null : Colors.white.withValues(alpha: 0.05),
                      ),
                      child: Center(
                        child: Opacity(
                          opacity: unlocked ? 1.0 : 0.35,
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 26),
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
                            pet['name']?.toString() ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: unlocked
                                  ? LiquidGlassTheme.textPrimary
                                  : LiquidGlassTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pet['description']?.toString().isNotEmpty == true
                                ? pet['description'].toString()
                                : (unlocked ? 'Your companion!' : 'Not yet unlocked'),
                            style: LiquidGlassTheme.bodySmall.copyWith(
                              fontSize: 12,
                              color: unlocked
                                  ? LiquidGlassTheme.textSecondary
                                  : LiquidGlassTheme.textMuted,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (pet['requirement'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                unlocked
                                    ? '✅ ${pet['requirement']}'
                                    : '🔑 ${pet['requirement']}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: unlocked
                                      ? Colors.greenAccent.withValues(alpha: 0.7)
                                      : Colors.amber.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (unlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(colors: [
                            LiquidGlassTheme.accentPrimary.withValues(alpha: 0.2),
                            LiquidGlassTheme.accentSecondary.withValues(alpha: 0.15),
                          ]),
                        ),
                        child: const Text('✓ Unlocked', style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: LiquidGlassTheme.accentPrimary,
                        )),
                      ),
                  ],
                ),
              ).animate().fadeIn(delay: (750 + i * 80).ms, duration: 400.ms)
               .slideX(begin: 0.03, end: 0),
            );
          }),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value, label;
  final int delay;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 10),
          Text(value, style: LiquidGlassTheme.headingSm.copyWith(fontSize: 22)),
          const SizedBox(height: 2),
          Text(label, style: LiquidGlassTheme.bodySmall.copyWith(fontSize: 11)),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms, duration: 400.ms)
     .slideY(begin: 0.06, end: 0);
  }
}

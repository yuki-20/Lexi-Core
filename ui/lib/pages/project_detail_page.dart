/// LexiCore — Project Detail Page (v5.1)
/// Shows project info, its decks, and allows creating new decks / quiz / flashcards.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/liquid_glass_theme.dart';
import '../services/engine_service.dart';
import '../widgets/glass_panel.dart';
import 'flashcards_page.dart';
import 'quiz_page.dart';

class ProjectDetailPage extends StatefulWidget {
  final int projectId;
  final String projectName;
  final Color projectColor;

  const ProjectDetailPage({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.projectColor,
  });

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  final _engine = EngineService();
  Map<String, dynamic>? _project;
  List<Map<String, dynamic>> _decks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    final project = await _engine.getProject(widget.projectId);
    if (mounted) {
      setState(() {
        _project = project;
        _decks = List<Map<String, dynamic>>.from(project?['decks'] ?? []);
        _isLoading = false;
      });
    }
  }

  Future<void> _createDeck() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LiquidGlassTheme.bgDeep,
        title: const Text('New Deck', style: TextStyle(color: LiquidGlassTheme.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: LiquidGlassTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Deck name...',
            hintStyle: TextStyle(color: LiquidGlassTheme.textMuted),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: LiquidGlassTheme.glassBorder),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await _engine.createProjectDeck(widget.projectId, name);
      _loadProject();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: LiquidGlassTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 12, height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.projectColor,
              ),
            ),
            const SizedBox(width: 10),
            Text(widget.projectName, style: LiquidGlassTheme.headingSm),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: LiquidGlassTheme.accentPrimary),
            tooltip: 'Add Deck',
            onPressed: _createDeck,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: LiquidGlassTheme.accentPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Project Info ──
                  if (_project?['description']?.toString().isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        _project!['description'],
                        style: LiquidGlassTheme.body.copyWith(color: LiquidGlassTheme.textSecondary),
                      ),
                    ),

                  // ── Quick Actions ──
                  Row(
                    children: [
                      _ActionChip(
                        icon: Icons.quiz_rounded,
                        label: 'Generate Quiz',
                        color: LiquidGlassTheme.accentPrimary,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const QuizPage(),
                          ));
                        },
                      ),
                      const SizedBox(width: 12),
                      _ActionChip(
                        icon: Icons.style_rounded,
                        label: 'Flashcards',
                        color: LiquidGlassTheme.accentSecondary,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const FlashcardsPage(),
                          ));
                        },
                      ),
                    ],
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 28),

                  // ── Decks ──
                  Text('Decks', style: LiquidGlassTheme.label)
                      .animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 12),

                  if (_decks.isEmpty)
                    GlassPanel(
                      child: Column(
                        children: [
                          const Icon(Icons.folder_open_rounded, size: 40, color: LiquidGlassTheme.textMuted),
                          const SizedBox(height: 12),
                          Text('No decks yet', style: LiquidGlassTheme.body),
                          const SizedBox(height: 4),
                          Text('Tap + to create your first deck',
                            style: LiquidGlassTheme.bodySmall.copyWith(color: LiquidGlassTheme.textMuted)),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms)
                  else
                    ...List.generate(_decks.length, (i) {
                      final deck = _decks[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassPanel(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(colors: [
                                    widget.projectColor.withValues(alpha: 0.3),
                                    widget.projectColor.withValues(alpha: 0.1),
                                  ]),
                                ),
                                child: const Center(
                                  child: Icon(Icons.style_rounded, size: 20,
                                    color: LiquidGlassTheme.textPrimary),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      deck['name']?.toString() ?? 'Untitled',
                                      style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w600,
                                        color: LiquidGlassTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Created ${deck['created_at']?.toString().split('T').first ?? ''}',
                                      style: LiquidGlassTheme.bodySmall.copyWith(
                                        color: LiquidGlassTheme.textMuted, fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded,
                                color: LiquidGlassTheme.textMuted, size: 20),
                            ],
                          ),
                        ).animate().fadeIn(delay: (300 + i * 80).ms)
                         .slideX(begin: 0.03, end: 0),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ]),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color,
            )),
          ],
        ),
      ),
    );
  }
}

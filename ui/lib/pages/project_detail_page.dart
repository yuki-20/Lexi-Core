/// LexiCore — Project Detail Page (v5.1)
/// Shows project info, its decks, and allows creating new decks / quiz / flashcards.
/// Embeds quiz/flashcard views inline to avoid push-route black screen issues.
library;

import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/liquid_glass_theme.dart';
import '../services/engine_service.dart';
import '../widgets/glass_panel.dart';
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

class _ProjectDetailPageState extends State<ProjectDetailPage>
    with TickerProviderStateMixin {
  final _engine = EngineService();
  Map<String, dynamic>? _project;
  List<Map<String, dynamic>> _decks = [];
  bool _isLoading = true;

  // Sub-view: null = project detail, 'quiz' = quiz, 'flashcards' = flashcards
  String? _subView;

  // Word selection for flashcard creation
  List<Map<String, dynamic>> _savedWords = [];
  Set<String> _selectedWords = {};

  // Background animation controllers
  late AnimationController _meshController;
  late List<AnimationController> _orbControllers;

  static const _orbConfigs = <_ProjectOrbConfig>[
    _ProjectOrbConfig(Color(0xFF7C4DFF), 260, 0.40, Offset(0.15, 0.20)),
    _ProjectOrbConfig(Color(0xFF00BCD4), 220, 0.35, Offset(0.80, 0.15)),
    _ProjectOrbConfig(Color(0xFFFF4081), 300, 0.30, Offset(0.50, 0.55)),
    _ProjectOrbConfig(Color(0xFF69F0AE), 180, 0.25, Offset(0.85, 0.75)),
    _ProjectOrbConfig(Color(0xFFFFAB40), 240, 0.33, Offset(0.20, 0.80)),
  ];

  @override
  void initState() {
    super.initState();
    _loadProject();
    _meshController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _orbControllers = List.generate(_orbConfigs.length, (i) {
      return AnimationController(
        vsync: this,
        duration: Duration(seconds: 12 + i * 3),
      )..repeat();
    });
  }

  @override
  void dispose() {
    _meshController.dispose();
    for (final c in _orbControllers) {
      c.dispose();
    }
    super.dispose();
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

  Future<void> _loadSavedWords() async {
    final words = await _engine.getSavedWords();
    if (mounted) {
      setState(() => _savedWords = words);
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
    // Title + back button text
    String title;
    VoidCallback onBack;
    if (_subView == 'quiz') {
      title = 'Quiz — ${widget.projectName}';
      onBack = () => setState(() => _subView = null);
    } else if (_subView == 'flashcards') {
      title = 'Flashcards — ${widget.projectName}';
      onBack = () => setState(() => _subView = null);
    } else {
      title = widget.projectName;
      onBack = () => Navigator.pop(context);
    }

    return Scaffold(
      backgroundColor: LiquidGlassTheme.bgDeep,
      body: Stack(
        children: [
          // ── Layer 1: Gradient mesh ──
          AnimatedBuilder(
            animation: _meshController,
            builder: (context, _) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _ProjectMeshPainter(progress: _meshController.value),
            ),
          ),

          // ── Layer 2: Ambient orbs ──
          ...List.generate(_orbConfigs.length, (i) => _ProjectOrb(
            controller: _orbControllers[i],
            config: _orbConfigs[i],
            index: i,
          )),

          // ── Layer 3: Frosted blur ──
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(
                color: LiquidGlassTheme.bgDeep.withValues(alpha: 0.3),
              ),
            ),
          ),

          // ── Layer 4: Content ──
          SafeArea(
            child: Column(
              children: [
                // ── Glass AppBar ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                          color: LiquidGlassTheme.textPrimary, size: 22),
                        onPressed: onBack,
                      ),
                      const SizedBox(width: 4),
                      if (_subView == null) ...[
                        Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.projectColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Text(title, style: LiquidGlassTheme.headingSm,
                          overflow: TextOverflow.ellipsis),
                      ),
                      if (_subView == null)
                        IconButton(
                          icon: const Icon(Icons.add_rounded, color: LiquidGlassTheme.accentPrimary),
                          tooltip: 'Add Deck',
                          onPressed: _createDeck,
                        ),
                    ],
                  ),
                ),
                // ── Body ──
                Expanded(
                  child: _subView == 'quiz'
                    ? const QuizPage()
                    : _subView == 'flashcards'
                      ? _buildFlashcardCreator()
                      : _buildProjectContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: LiquidGlassTheme.accentPrimary));
    }

    return SingleChildScrollView(
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
                onTap: () => setState(() => _subView = 'quiz'),
              ),
              const SizedBox(width: 12),
              _ActionChip(
                icon: Icons.style_rounded,
                label: 'Flashcards',
                color: LiquidGlassTheme.accentSecondary,
                onTap: () {
                  _loadSavedWords();
                  setState(() => _subView = 'flashcards');
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
    );
  }

  Widget _buildFlashcardCreator() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select words to create flashcards',
            style: LiquidGlassTheme.body.copyWith(color: LiquidGlassTheme.textSecondary)),
          const SizedBox(height: 16),

          // Select all / create
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  if (_selectedWords.length == _savedWords.length) {
                    _selectedWords.clear();
                  } else {
                    _selectedWords = _savedWords.map((w) => w['word']?.toString() ?? '').toSet();
                  }
                }),
                child: Row(
                  children: [
                    Icon(
                      _selectedWords.length == _savedWords.length && _savedWords.isNotEmpty
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      size: 20, color: LiquidGlassTheme.accentPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text('Select All (${_selectedWords.length}/${_savedWords.length})',
                      style: LiquidGlassTheme.bodySmall.copyWith(
                        color: LiquidGlassTheme.accentPrimary,
                        fontWeight: FontWeight.w600,
                      )),
                  ],
                ),
              ),
              const Spacer(),
              if (_selectedWords.isNotEmpty)
                GestureDetector(
                  onTap: () async {
                    final deckName = '${widget.projectName} Cards';
                    await _engine.createProjectDeck(widget.projectId, deckName);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Created "$deckName" with ${_selectedWords.length} words!')),
                      );
                      setState(() {
                        _selectedWords.clear();
                        _subView = null;
                      });
                      _loadProject();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(colors: [
                        LiquidGlassTheme.accentPrimary,
                        LiquidGlassTheme.accentSecondary,
                      ]),
                    ),
                    child: Text(
                      'Create Deck (${_selectedWords.length})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (_savedWords.isEmpty)
            GlassPanel(
              child: Column(
                children: [
                  const Icon(Icons.bookmark_border_rounded, size: 40, color: LiquidGlassTheme.textMuted),
                  const SizedBox(height: 12),
                  Text('No saved words yet', style: LiquidGlassTheme.body),
                  const SizedBox(height: 4),
                  Text('Save words from the dictionary to create flashcards',
                    style: LiquidGlassTheme.bodySmall.copyWith(color: LiquidGlassTheme.textMuted)),
                ],
              ),
            )
          else
            ...List.generate(_savedWords.length, (i) {
              final word = _savedWords[i];
              final wordStr = word['word']?.toString() ?? '';
              final isSelected = _selectedWords.contains(wordStr);

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () => setState(() {
                    isSelected ? _selectedWords.remove(wordStr) : _selectedWords.add(wordStr);
                  }),
                  child: GlassPanel(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                          size: 22,
                          color: isSelected ? LiquidGlassTheme.accentPrimary : LiquidGlassTheme.textMuted,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(wordStr, style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600,
                                color: isSelected ? LiquidGlassTheme.textPrimary : LiquidGlassTheme.textSecondary,
                              )),
                              if (word['definition'] != null)
                                Text(
                                  word['definition'].toString(),
                                  style: LiquidGlassTheme.bodySmall.copyWith(fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
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

// ── Background Painters (inline, matching main shell) ──────────────

class _ProjectMeshPainter extends CustomPainter {
  final double progress;
  _ProjectMeshPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF080812));
    final meshPoints = [
      _PM(Offset(size.width * 0.2, size.height * 0.15), const Color(0xFF1A0533), 0.6),
      _PM(Offset(size.width * 0.8, size.height * 0.2), const Color(0xFF0A1628), 0.5),
      _PM(Offset(size.width * 0.5, size.height * 0.5), const Color(0xFF150A28), 0.7),
      _PM(Offset(size.width * 0.15, size.height * 0.75), const Color(0xFF0A1A20), 0.5),
      _PM(Offset(size.width * 0.85, size.height * 0.8), const Color(0xFF1A0A22), 0.4),
    ];
    for (final p in meshPoints) {
      final dx = math.sin(progress * math.pi * 2) * size.width * 0.05;
      final dy = math.cos(progress * math.pi * 2) * size.height * 0.03;
      final center = p.center + Offset(dx, dy);
      final paint = Paint()
        ..shader = RadialGradient(colors: [
          p.color.withValues(alpha: 0.8), p.color.withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(center: center, radius: size.width * p.radius));
      canvas.drawCircle(center, size.width * p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ProjectMeshPainter old) => old.progress != progress;
}

class _PM {
  final Offset center; final Color color; final double radius;
  const _PM(this.center, this.color, this.radius);
}

class _ProjectOrb extends AnimatedWidget {
  final _ProjectOrbConfig config;
  final int index;
  const _ProjectOrb({required AnimationController controller, required this.config, required this.index})
    : super(listenable: controller);

  @override
  Widget build(BuildContext context) {
    final t = (listenable as AnimationController).value;
    final size = MediaQuery.of(context).size;
    final dx = math.sin(t * math.pi + index * 1.3) * size.width * 0.06;
    final dy = math.cos(t * math.pi + index * 0.9) * size.height * 0.04;
    final x = config.basePos.dx * size.width + dx;
    final y = config.basePos.dy * size.height + dy;
    final orbSize = config.size + math.sin(t * math.pi * 2) * 20;
    final alpha = config.alpha + math.sin(t * math.pi) * 0.08;

    return Positioned(
      left: x - orbSize / 2, top: y - orbSize / 2,
      child: Container(
        width: orbSize, height: orbSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            config.color.withValues(alpha: alpha.clamp(0.0, 1.0)),
            config.color.withValues(alpha: alpha * 0.4),
            config.color.withValues(alpha: 0.0),
          ], stops: const [0.0, 0.5, 1.0]),
        ),
      ),
    );
  }
}

class _ProjectOrbConfig {
  final Color color; final double size; final double alpha; final Offset basePos;
  const _ProjectOrbConfig(this.color, this.size, this.alpha, this.basePos);
}

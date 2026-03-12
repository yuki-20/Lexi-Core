/// LexiCore Engine v5.5 — Liquid Glass Sidebar Layout
/// Left glass sidebar with vertical navigation, level badge, + pet companion.
/// Center area with page content over liquid glass background.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'theme/liquid_glass_theme.dart';

import 'services/engine_service.dart';
import 'pages/home_page.dart';
import 'pages/flashcards_page.dart';
import 'pages/quiz_page.dart';
import 'pages/saved_words_page.dart';
import 'pages/performance_page.dart';
import 'pages/settings_page.dart';
import 'pages/projects_page.dart';
import 'pages/lexi_ai_page.dart';
import 'pages/dictionary_page.dart';
import 'pages/splash_screen.dart';

import 'package:media_kit/media_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const LexiCoreApp());
}

class LexiCoreApp extends StatefulWidget {
  const LexiCoreApp({super.key});

  @override
  State<LexiCoreApp> createState() => _LexiCoreAppState();
}

class _LexiCoreAppState extends State<LexiCoreApp> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LexiCore',
      debugShowCheckedModeBanner: false,
      theme: LiquidGlassTheme.dark,
      home: _showSplash
          ? SplashScreen(onComplete: () {
              if (mounted) setState(() => _showSplash = false);
            })
          : const LexiCoreShell(),
    );
  }
}

/// ══════════════════════════════════════════════════════════════════
/// Shell: Sidebar + Content Area over Liquid Glass Background
/// ══════════════════════════════════════════════════════════════════

class LexiCoreShell extends StatefulWidget {
  const LexiCoreShell({super.key});

  @override
  State<LexiCoreShell> createState() => _LexiCoreShellState();
}

class _LexiCoreShellState extends State<LexiCoreShell>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  late final List<AnimationController> _orbControllers;
  late AnimationController _meshController;
  late AnimationController _pageController;
  StreamSubscription<DateTime>? _progressSubscription;

  // Sidebar hover state
  bool _sidebarExpanded = false;

  // Pet + XP data
  final _engine = EngineService();
  Map<String, dynamic>? _activePet;
  int _streakDays = 0;
  int _level = 1;
  String _levelTitle = 'Novice';
  double _xpProgress = 0.0;

  static const _orbConfigs = <_OrbConfig>[
    _OrbConfig(Color(0xFF7C4DFF), 280, 0.45, Offset(0.15, 0.20)),
    _OrbConfig(Color(0xFF00BCD4), 240, 0.40, Offset(0.80, 0.15)),
    _OrbConfig(Color(0xFFFF4081), 320, 0.35, Offset(0.50, 0.55)),
    _OrbConfig(Color(0xFF69F0AE), 200, 0.30, Offset(0.85, 0.75)),
    _OrbConfig(Color(0xFFFFAB40), 260, 0.38, Offset(0.20, 0.80)),
    _OrbConfig(Color(0xFFE040FB), 220, 0.32, Offset(0.65, 0.30)),
    _OrbConfig(Color(0xFF40C4FF), 300, 0.28, Offset(0.35, 0.90)),
  ];

  @override
  void initState() {
    super.initState();
    _orbControllers = List.generate(_orbConfigs.length, (i) {
      return AnimationController(
        vsync: this,
        duration: Duration(seconds: 8 + i * 3),
      )..repeat(reverse: true);
    });
    _meshController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);
    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _progressSubscription = _engine.progressStream.listen((_) {
      _loadPetData();
    });
    _loadPetData();
  }

  Future<void> _loadPetData() async {
    try {
      // Wait for backend to be ready (important on fresh install — auto-build takes time)
      await _engine.waitForReady();
      final pets = await _engine.getAllPets();
      final stats = await _engine.getStats();
      final xpStatus = await _engine.getXpStatus();
      if (mounted) {
        setState(() {
          _activePet = pets.lastWhere(
            (p) => p['unlocked'] == true,
            orElse: () => <String, dynamic>{},
          );
          _streakDays = (stats['learning'] as Map?)?['streak_days'] ?? 0;
          _level = (xpStatus['level'] as num?)?.toInt() ?? 1;
          _levelTitle = xpStatus['title']?.toString() ?? 'Novice';
          _xpProgress = (xpStatus['progress'] as num?)?.toDouble() ?? 0.0;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final c in _orbControllers) {
      c.dispose();
    }
    _progressSubscription?.cancel();
    _meshController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _pageController.forward(from: 0);
  }

  static const _navItems = <_NavItem>[
    _NavItem(Icons.home_rounded, 'Home'),
    _NavItem(Icons.folder_rounded, 'Projects'),
    _NavItem(Icons.style_rounded, 'Flashcards'),
    _NavItem(Icons.quiz_rounded, 'Quiz'),
    _NavItem(Icons.bookmark_rounded, 'Saved Words'),
    _NavItem(Icons.menu_book_rounded, 'Dictionary'),
    _NavItem(Icons.analytics_rounded, 'Performance'),
    _NavItem(Icons.smart_toy_rounded, 'Lexi AI'),
    _NavItem(Icons.settings_rounded, 'Settings'),
  ];

  final _pages = const <Widget>[
    HomePage(),
    ProjectsPage(),
    FlashcardsPage(),
    QuizPage(),
    SavedWordsPage(),
    DictionaryPage(),
    PerformancePage(),
    LexiAiPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = _sidebarExpanded ? 220.0 : 76.0;

    return Scaffold(
      backgroundColor: LiquidGlassTheme.bgDeep,
      body: Stack(
        children: [
          // ── Layer 1: Base gradient mesh ──
          AnimatedBuilder(
            animation: _meshController,
            builder: (context, _) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _GradientMeshPainter(progress: _meshController.value),
            ),
          ),

          // ── Layer 2: Vivid ambient orbs ──
          ...List.generate(_orbConfigs.length, (i) => _VividOrb(
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

          // ── Layer 4: Sidebar + Content ──
          SafeArea(
            child: Row(
              children: [
                // ── Sidebar ──
                MouseRegion(
                  onEnter: (_) => setState(() => _sidebarExpanded = true),
                  onExit: (_) => setState(() => _sidebarExpanded = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: sidebarWidth,
                    child: _buildSidebar(),
                  ),
                ),

                // ── Content Area ──
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.02),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          )),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(_currentIndex),
                      child: _pages[_currentIndex],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 0, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0x1CFFFFFF),
            const Color(0x0AFFFFFF),
            const Color(0x06FFFFFF),
          ],
        ),
        border: Border.all(color: LiquidGlassTheme.glassBorder.withValues(alpha: 0.4), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: -5,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Column(
            children: [
              // ── Logo / Brand ──
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final showText = constraints.maxWidth > 120;
                    return showText
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset('assets/images/app_icon.png',
                                    width: 28, height: 28, fit: BoxFit.contain),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text('LexiCore', style: TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w700,
                                    foreground: Paint()..shader = const LinearGradient(
                                      colors: [LiquidGlassTheme.accentPrimary, LiquidGlassTheme.accentSecondary],
                                    ).createShader(const Rect.fromLTWH(0, 0, 100, 20)),
                                    letterSpacing: -0.5,
                                  ), overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset('assets/images/app_icon.png',
                              width: 32, height: 32, fit: BoxFit.contain),
                          );
                  },
                ),
              ),

              // ── Level Badge ──
              if (_sidebarExpanded)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: LinearGradient(colors: [
                                  LiquidGlassTheme.accentPrimary.withValues(alpha: 0.3),
                                  LiquidGlassTheme.accentSecondary.withValues(alpha: 0.2),
                                ]),
                              ),
                              child: Text('Lv.$_level', style: const TextStyle(
                                fontSize: 9, fontWeight: FontWeight.w700,
                                color: LiquidGlassTheme.accentPrimary,
                              )),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(_levelTitle, style: const TextStyle(
                                fontSize: 9, color: LiquidGlassTheme.textMuted,
                              ), overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: _xpProgress,
                            minHeight: 3,
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            color: LiquidGlassTheme.accentPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(colors: [
                        LiquidGlassTheme.accentPrimary.withValues(alpha: 0.3),
                        LiquidGlassTheme.accentSecondary.withValues(alpha: 0.2),
                      ]),
                    ),
                    child: Text('$_level', style: const TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w700,
                      color: LiquidGlassTheme.accentPrimary,
                    )),
                  ),
                ),

              Divider(color: LiquidGlassTheme.glassBorder.withValues(alpha: 0.3), height: 1, indent: 12, endIndent: 12),
              const SizedBox(height: 8),

              // ── Nav Items ──
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _navItems.length,
                  itemBuilder: (ctx, i) => _buildNavItem(i),
                ),
              ),

              // ── Pet Companion ──
              _buildPetSection(),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final isActive = index == _currentIndex;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onTap: () => _onNavTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          clipBehavior: Clip.hardEdge,
          padding: EdgeInsets.symmetric(
            horizontal: _sidebarExpanded ? 14 : 0,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isActive
                ? LiquidGlassTheme.accentPrimary.withValues(alpha: 0.15)
                : Colors.transparent,
          ),
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final wide = constraints.maxWidth > 100;
              if (wide) {
                return Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 3,
                      height: isActive ? 20 : 0,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: isActive ? LiquidGlassTheme.accentPrimary : Colors.transparent,
                      ),
                    ),
                    index == 7
                        ? Image.asset('assets/images/lexi_ai_icon.gif',
                            width: 20, height: 20)
                        : Icon(item.icon, size: 20,
                            color: isActive ? LiquidGlassTheme.accentPrimary : LiquidGlassTheme.textMuted,
                          ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive ? LiquidGlassTheme.textPrimary : LiquidGlassTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              } else {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      index == 7
                          ? Image.asset('assets/images/lexi_ai_icon.gif',
                              width: 20, height: 20)
                          : Icon(item.icon, size: 20,
                              color: isActive ? LiquidGlassTheme.accentPrimary : LiquidGlassTheme.textMuted,
                            ),
                      if (isActive)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 4, height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: LiquidGlassTheme.accentPrimary,
                          ),
                        ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPetSection() {
    // Pet emoji map
    const petEmojis = {
      'ember_fox': '🦊',
      'volt_owl': '🦉',
      'aqua_dragon': '🐉',
      'prisma': '🦄',
    };

    final hasPet = _activePet != null && _activePet!.isNotEmpty && _activePet!['unlocked'] == true;
    final petId = _activePet?['id'] ?? '';
    final petEmoji = petEmojis[petId] ?? '🐾';
    final petName = _activePet?['name'] ?? 'No pet yet';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            LiquidGlassTheme.accentPrimary.withValues(alpha: 0.08),
            LiquidGlassTheme.accentSecondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: LiquidGlassTheme.glassBorder.withValues(alpha: 0.3)),
      ),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final wide = constraints.maxWidth > 100;
          return Column(
            children: [
              Text(
                hasPet ? petEmoji : '🐾',
                style: const TextStyle(fontSize: 24),
              ),
              if (wide) ...[
                const SizedBox(height: 6),
                Text(
                  hasPet ? petName : 'No pet yet',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: hasPet ? LiquidGlassTheme.textPrimary : LiquidGlassTheme.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department, size: 12, color: Colors.orangeAccent),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        '$_streakDays day streak',
                        style: const TextStyle(fontSize: 10, color: Colors.orangeAccent),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 2),
                const Icon(Icons.local_fire_department, size: 10, color: Colors.orangeAccent),
              ],
            ],
          );
        },
      ),
    );
  }

}

// ══════════════════════════════════════════════════════════════════
//  BACKGROUND PAINTERS & ORBS (unchanged)
// ══════════════════════════════════════════════════════════════════

class _GradientMeshPainter extends CustomPainter {
  final double progress;
  _GradientMeshPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF080812),
    );

    final meshPoints = [
      _MeshPoint(Offset(size.width * 0.2, size.height * 0.15), const Color(0xFF1A0533), 0.6),
      _MeshPoint(Offset(size.width * 0.8, size.height * 0.2), const Color(0xFF0A1628), 0.5),
      _MeshPoint(Offset(size.width * 0.5, size.height * 0.5), const Color(0xFF150A28), 0.7),
      _MeshPoint(Offset(size.width * 0.15, size.height * 0.75), const Color(0xFF0A1A20), 0.5),
      _MeshPoint(Offset(size.width * 0.85, size.height * 0.8), const Color(0xFF1A0A22), 0.4),
    ];

    for (final point in meshPoints) {
      final dx = math.sin(progress * math.pi * 2) * size.width * 0.05;
      final dy = math.cos(progress * math.pi * 2) * size.height * 0.03;
      final center = point.center + Offset(dx, dy);

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            point.color.withValues(alpha: 0.8),
            point.color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: size.width * point.radius));
      canvas.drawCircle(center, size.width * point.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GradientMeshPainter old) => old.progress != progress;
}

class _MeshPoint {
  final Offset center;
  final Color color;
  final double radius;
  const _MeshPoint(this.center, this.color, this.radius);
}

class _VividOrb extends AnimatedWidget {
  final _OrbConfig config;
  final int index;

  const _VividOrb({
    required AnimationController controller,
    required this.config,
    required this.index,
  }) : super(listenable: controller);

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
      left: x - orbSize / 2,
      top: y - orbSize / 2,
      child: Container(
        width: orbSize,
        height: orbSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              config.color.withValues(alpha: alpha.clamp(0.0, 1.0)),
              config.color.withValues(alpha: alpha * 0.4),
              config.color.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

class _OrbConfig {
  final Color color;
  final double size;
  final double alpha;
  final Offset basePos;
  const _OrbConfig(this.color, this.size, this.alpha, this.basePos);
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

/// LexiCore Engine v3.1 — Liquid Glass Desktop App
/// iOS 26 Liquid Glass UI with authentic gradient mesh background,
/// 6-tab navigation, and smooth page transitions.
library;

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'theme/liquid_glass_theme.dart';
import 'widgets/glass_panel.dart';
import 'pages/home_page.dart';
import 'pages/flashcards_page.dart';
import 'pages/quiz_page.dart';
import 'pages/saved_words_page.dart';
import 'pages/performance_page.dart';
import 'pages/settings_page.dart';
import 'pages/projects_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LexiCoreApp());
}

class LexiCoreApp extends StatelessWidget {
  const LexiCoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LexiCore Engine',
      debugShowCheckedModeBanner: false,
      theme: LiquidGlassTheme.dark,
      home: const LexiCoreShell(),
    );
  }
}

/// ══════════════════════════════════════════════════════════════════
/// Shell: iOS 26 Gradient Mesh + Glass Nav + Pages
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

  // iOS 26 vibrant orb colors — much brighter than v3.0
  static const _orbConfigs = [
    _OrbConfig(Color(0xFFAB47BC), 280, 0.45, Offset(0.12, 0.10)),  // vivid purple
    _OrbConfig(Color(0xFF00BCD4), 320, 0.40, Offset(0.80, 0.18)),  // cyan
    _OrbConfig(Color(0xFFFF4081), 260, 0.38, Offset(0.50, 0.55)),  // hot pink
    _OrbConfig(Color(0xFF2979FF), 350, 0.42, Offset(0.15, 0.72)),  // electric blue
    _OrbConfig(Color(0xFFFF9100), 240, 0.35, Offset(0.85, 0.80)),  // amber
    _OrbConfig(Color(0xFF69F0AE), 200, 0.30, Offset(0.45, 0.30)),  // mint green
    _OrbConfig(Color(0xFFE040FB), 220, 0.33, Offset(0.70, 0.65)),  // magenta
  ];

  @override
  void initState() {
    super.initState();
    _orbControllers = List.generate(7, (i) =>
      AnimationController(
        vsync: this,
        duration: Duration(seconds: 6 + i * 2),
      )..repeat(reverse: true),
    );
    _meshController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);
    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    for (final c in _orbControllers) {
      c.dispose();
    }
    _meshController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _pageController.forward(from: 0);
  }

  final _pages = const <Widget>[
    HomePage(),
    ProjectsPage(),
    FlashcardsPage(),
    QuizPage(),
    SavedWordsPage(),
    PerformancePage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTheme.bgDeep,
      body: Stack(
        children: [
          // ── Layer 1: Base gradient mesh ──
          AnimatedBuilder(
            animation: _meshController,
            builder: (context, _) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _GradientMeshPainter(
                progress: _meshController.value,
              ),
            ),
          ),

          // ── Layer 2: Vivid ambient orbs ──
          ...List.generate(_orbConfigs.length, (i) => _VividOrb(
            controller: _orbControllers[i],
            config: _orbConfigs[i],
            index: i,
          )),

          // ── Layer 3: Frosted blur over the background ──
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(
                color: LiquidGlassTheme.bgDeep.withValues(alpha: 0.3),
              ),
            ),
          ),

          // ── Layer 4: Page content ──
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.03),
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

          // ── Layer 5: Glass bottom nav ──
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _GlassBottomNav(
              currentIndex: _currentIndex,
              onTap: _onTabTap,
            ),
          ),
        ],
      ),
    );
  }
}

/// ── iOS 26 Gradient Mesh Painter ──
class _GradientMeshPainter extends CustomPainter {
  final double progress;
  _GradientMeshPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Deep base
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF080812),
    );

    // Animated gradient mesh — large, overlapping radial gradients
    final meshPoints = [
      _MeshPoint(Offset(size.width * 0.2, size.height * 0.15),
          const Color(0xFF1A0533), 0.6),
      _MeshPoint(Offset(size.width * 0.8, size.height * 0.2),
          const Color(0xFF0A1628), 0.5),
      _MeshPoint(Offset(size.width * 0.5, size.height * 0.5),
          const Color(0xFF150A28), 0.7),
      _MeshPoint(Offset(size.width * 0.15, size.height * 0.75),
          const Color(0xFF0A1A20), 0.5),
      _MeshPoint(Offset(size.width * 0.85, size.height * 0.8),
          const Color(0xFF1A0A22), 0.4),
    ];

    for (final point in meshPoints) {
      final dx = math.sin(progress * math.pi * 2) * size.width * 0.05;
      final dy = math.cos(progress * math.pi * 2) * size.height * 0.03;
      final center = point.center + Offset(dx, dy);

      final paint = Paint()
        ..shader = RadialGradient(
          center: Alignment(
            (center.dx / size.width * 2 - 1),
            (center.dy / size.height * 2 - 1),
          ),
          radius: point.radius,
          colors: [
            point.color,
            point.color.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size);

      canvas.drawRect(Offset.zero & size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GradientMeshPainter old) =>
      old.progress != progress;
}

class _MeshPoint {
  final Offset center;
  final Color color;
  final double radius;
  const _MeshPoint(this.center, this.color, this.radius);
}

/// ── Vivid Ambient Orb ──
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

    // Animate position with slow drift
    final dx = math.sin(t * math.pi + index * 1.3) * size.width * 0.06;
    final dy = math.cos(t * math.pi + index * 0.9) * size.height * 0.04;
    final x = config.basePos.dx * size.width + dx;
    final y = config.basePos.dy * size.height + dy;
    final orbSize = config.size + math.sin(t * math.pi * 2) * 20;

    // Pulsing opacity
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

/// ── Glass Bottom Navigation Bar ──
class _GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _GlassBottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(Icons.home_rounded, 'Home'),
    _NavItem(Icons.folder_rounded, 'Projects'),
    _NavItem(Icons.style_rounded, 'Cards'),
    _NavItem(Icons.quiz_rounded, 'Quiz'),
    _NavItem(Icons.bookmark_rounded, 'Words'),
    _NavItem(Icons.analytics_rounded, 'Stats'),
    _NavItem(Icons.settings_rounded, 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _items.asMap().entries.map((entry) {
          final isActive = entry.key == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(entry.key),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isActive
                      ? LiquidGlassTheme.accentPrimary.withValues(alpha: 0.15)
                      : Colors.transparent,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedScale(
                      scale: isActive ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        entry.value.icon,
                        size: 20,
                        color: isActive
                            ? LiquidGlassTheme.accentPrimary
                            : LiquidGlassTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive
                            ? LiquidGlassTheme.accentPrimary
                            : LiquidGlassTheme.textMuted,
                      ),
                      child: Text(entry.value.label),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 500.ms)
     .slideY(begin: 0.2, end: 0);
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

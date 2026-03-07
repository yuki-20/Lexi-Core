/// LexiCore Engine v3.0 — Liquid Glass Desktop App
/// iOS 26 Liquid Glass UI with 5-tab navigation.
library;

import 'dart:math' as math;
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

/// ── Shell: Ambient background + Bottom Nav + Pages ──

class LexiCoreShell extends StatefulWidget {
  const LexiCoreShell({super.key});

  @override
  State<LexiCoreShell> createState() => _LexiCoreShellState();
}

class _LexiCoreShellState extends State<LexiCoreShell>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  // Ambient orb animations
  late final List<AnimationController> _orbControllers;

  static const _orbColors = [
    Color(0xFF7B2FBE), // purple
    Color(0xFF00BCD4), // cyan
    Color(0xFFE91E63), // pink
    Color(0xFF2962FF), // blue
    Color(0xFFFF9100), // amber
  ];

  @override
  void initState() {
    super.initState();
    _orbControllers = List.generate(5, (i) =>
      AnimationController(
        vsync: this,
        duration: Duration(seconds: 8 + i * 3),
      )..repeat(reverse: true),
    );
  }

  @override
  void dispose() {
    for (final c in _orbControllers) {
      c.dispose();
    }
    super.dispose();
  }

  final _pages = const <Widget>[
    HomePage(),
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
          // ── Ambient Orbs ──
          ...List.generate(5, (i) => _AmbientOrb(
            controller: _orbControllers[i],
            color: _orbColors[i],
            index: i,
          )),

          // ── Page Content ──
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: KeyedSubtree(
                key: ValueKey(_currentIndex),
                child: _pages[_currentIndex],
              ),
            ),
          ),

          // ── Glass Bottom Nav ──
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: _GlassBottomNav(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
            ),
          ),
        ],
      ),
    );
  }
}

/// ── Ambient Orb ──
class _AmbientOrb extends AnimatedWidget {
  final Color color;
  final int index;

  const _AmbientOrb({
    required AnimationController controller,
    required this.color,
    required this.index,
  }) : super(listenable: controller);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as AnimationController;
    final size = MediaQuery.of(context).size;

    // Each orb has a unique path
    final t = animation.value;
    final positions = [
      Offset(size.width * 0.15, size.height * (0.15 + 0.1 * math.sin(t * math.pi))),
      Offset(size.width * (0.7 + 0.1 * math.cos(t * math.pi)), size.height * 0.25),
      Offset(size.width * 0.5, size.height * (0.6 + 0.08 * math.sin(t * math.pi))),
      Offset(size.width * (0.2 + 0.1 * math.sin(t * math.pi)), size.height * 0.75),
      Offset(size.width * (0.8 - 0.1 * math.cos(t * math.pi)), size.height * 0.85),
    ];

    final pos = positions[index % positions.length];
    final orbSize = 120.0 + index * 30.0;

    return Positioned(
      left: pos.dx - orbSize / 2,
      top: pos.dy - orbSize / 2,
      child: Container(
        width: orbSize,
        height: orbSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.2 + 0.05 * math.sin(t * math.pi)),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

/// ── Glass Bottom Navigation Bar ──
class _GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _GlassBottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(Icons.home_rounded, 'Home'),
    _NavItem(Icons.style_rounded, 'Cards'),
    _NavItem(Icons.quiz_rounded, 'Quiz'),
    _NavItem(Icons.bookmark_rounded, 'Words'),
    _NavItem(Icons.analytics_rounded, 'Stats'),
    _NavItem(Icons.settings_rounded, 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _items.asMap().entries.map((entry) {
          final isActive = entry.key == currentIndex;
          return GestureDetector(
            onTap: () => onTap(entry.key),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: EdgeInsets.symmetric(
                horizontal: isActive ? 16 : 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isActive
                    ? LiquidGlassTheme.accentPrimary.withValues(alpha: 0.15)
                    : Colors.transparent,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    entry.value.icon,
                    size: isActive ? 24 : 22,
                    color: isActive
                        ? LiquidGlassTheme.accentPrimary
                        : LiquidGlassTheme.textMuted,
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 10,
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
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 500.ms)
     .slideY(begin: 0.3, end: 0);
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

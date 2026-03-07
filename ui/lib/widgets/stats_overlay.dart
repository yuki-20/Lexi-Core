/// LexiCore — Stats Overlay Widget
/// Performance micro-metrics display.
library;

import 'package:flutter/material.dart';
import '../theme/liquid_glass_theme.dart';
import '../widgets/glass_panel.dart';

class StatsOverlay extends StatelessWidget {
  final int dictionarySize;
  final int streakDays;
  final int totalExp;
  final double cacheHitRate;

  const StatsOverlay({
    super.key,
    this.dictionarySize = 0,
    this.streakDays = 0,
    this.totalExp = 0,
    this.cacheHitRate = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: LiquidGlassTheme.borderRadiusSm,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enableCursorGlow: false,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatChip(
            icon: Icons.auto_stories_rounded,
            label: '$dictionarySize',
            tooltip: 'Words in dictionary',
            color: LiquidGlassTheme.accentPrimary,
          ),
          _divider(),
          _StatChip(
            icon: Icons.local_fire_department_rounded,
            label: '$streakDays',
            tooltip: 'Day streak',
            color: LiquidGlassTheme.accentTertiary,
          ),
          _divider(),
          _StatChip(
            icon: Icons.bolt_rounded,
            label: '$totalExp',
            tooltip: 'Total EXP',
            color: LiquidGlassTheme.accentSecondary,
          ),
          _divider(),
          _StatChip(
            icon: Icons.memory_rounded,
            label: '${(cacheHitRate * 100).toStringAsFixed(0)}%',
            tooltip: 'Cache hit rate',
            color: LiquidGlassTheme.posVerb,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 16,
    margin: const EdgeInsets.symmetric(horizontal: 10),
    color: LiquidGlassTheme.glassBorder,
  );
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color.withValues(alpha: 0.8)),
          const SizedBox(width: 4),
          Text(label, style: LiquidGlassTheme.mono.copyWith(
            color: color,
            fontSize: 12,
          )),
        ],
      ),
    );
  }
}

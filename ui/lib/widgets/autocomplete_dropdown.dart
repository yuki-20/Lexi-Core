/// LexiCore — Autocomplete Dropdown
/// Liquid-unroll dropdown with stagger animations.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/liquid_glass_theme.dart';
import '../widgets/glass_panel.dart';

class AutocompleteDropdown extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onSelect;
  final double timingMs;

  const AutocompleteDropdown({
    super.key,
    required this.suggestions,
    required this.onSelect,
    this.timingMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return GlassPanel(
      borderRadius: LiquidGlassTheme.borderRadiusSm,
      padding: const EdgeInsets.symmetric(vertical: 6),
      enableCursorGlow: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...suggestions.asMap().entries.map((entry) {
            final index = entry.key;
            final word = entry.value;
            return _SuggestionTile(
              word: word,
              onTap: () => onSelect(word),
              delay: index * 40,
            );
          }),
          // Timing footer
          if (timingMs > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 12, bottom: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Trie: ${timingMs.toStringAsFixed(3)}ms',
                  style: LiquidGlassTheme.mono.copyWith(fontSize: 9),
                ),
              ),
            ),
        ],
      ),
    ).animate()
     .fadeIn(duration: 200.ms)
     .slideY(begin: -0.05, end: 0, duration: 250.ms, curve: Curves.easeOut);
  }
}

class _SuggestionTile extends StatefulWidget {
  final String word;
  final VoidCallback onTap;
  final int delay;

  const _SuggestionTile({
    required this.word,
    required this.onTap,
    this.delay = 0,
  });

  @override
  State<_SuggestionTile> createState() => _SuggestionTileState();
}

class _SuggestionTileState extends State<_SuggestionTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _hovering
                ? LiquidGlassTheme.accentPrimary.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: _hovering
                    ? LiquidGlassTheme.accentPrimary
                    : LiquidGlassTheme.textMuted,
              ),
              const SizedBox(width: 10),
              Text(
                widget.word,
                style: LiquidGlassTheme.body.copyWith(
                  color: _hovering
                      ? LiquidGlassTheme.textPrimary
                      : LiquidGlassTheme.textSecondary,
                  fontWeight: _hovering ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: widget.delay))
     .fadeIn(duration: 200.ms)
     .slideX(begin: -0.1, end: 0, duration: 200.ms);
  }
}

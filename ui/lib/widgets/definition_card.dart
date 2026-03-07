/// LexiCore — Definition Card Widget
/// Glass panel displaying word definition with POS pills and performance metrics.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/liquid_glass_theme.dart';
import '../widgets/glass_panel.dart';
import '../services/engine_service.dart';

class DefinitionCard extends StatelessWidget {
  final SearchResult result;
  final VoidCallback? onSave;
  final bool isSaved;

  const DefinitionCard({
    super.key,
    required this.result,
    this.onSave,
    this.isSaved = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Word + Save Button ──
          Row(
            children: [
              Expanded(
                child: Text(
                  result.word,
                  style: LiquidGlassTheme.heading.copyWith(
                    color: LiquidGlassTheme.textPrimary.withValues(alpha: 0.95),
                  ),
                ),
              ),
              _SaveButton(onTap: onSave, isSaved: isSaved),
            ],
          ),
          const SizedBox(height: 8),

          // ── POS Pills ──
          if (result.pos.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: result.pos.map((p) => _PosPill(label: p)).toList(),
            ),
          const SizedBox(height: 16),

          // ── Definitions ──
          ...result.definitions.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(right: 10, top: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.15),
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: LiquidGlassTheme.bodySmall.copyWith(
                          color: LiquidGlassTheme.accentPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(entry.value, style: LiquidGlassTheme.body),
                  ),
                ],
              ),
            );
          }),

          // ── Synonyms ──
          if (result.synonyms.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Synonyms', style: LiquidGlassTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: LiquidGlassTheme.accentSecondary,
            )),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: result.synonyms.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: LiquidGlassTheme.glassBorder),
                  color: LiquidGlassTheme.glassFill,
                ),
                child: Text(s, style: LiquidGlassTheme.bodySmall.copyWith(
                  color: LiquidGlassTheme.textSecondary,
                )),
              )).toList(),
            ),
          ],

          // ── Examples ──
          if (result.examples.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Examples', style: LiquidGlassTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: LiquidGlassTheme.accentSecondary,
            )),
            const SizedBox(height: 6),
            ...result.examples.map((ex) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('" ', style: LiquidGlassTheme.body.copyWith(
                    color: LiquidGlassTheme.accentPrimary,
                    fontStyle: FontStyle.italic,
                    fontSize: 18,
                  )),
                  Expanded(
                    child: Text(ex, style: LiquidGlassTheme.body.copyWith(
                      fontStyle: FontStyle.italic,
                      color: LiquidGlassTheme.textSecondary.withValues(alpha: 0.7),
                    )),
                  ),
                ],
              ),
            )),
          ],

          // ── Etymology ──
          if (result.etymology.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(LiquidGlassTheme.borderRadiusXs),
                color: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.06),
                border: Border.all(
                  color: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, size: 16,
                    color: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(result.etymology, style: LiquidGlassTheme.bodySmall.copyWith(
                      color: LiquidGlassTheme.textSecondary.withValues(alpha: 0.8),
                    )),
                  ),
                ],
              ),
            ),
          ],

          // ── Performance Metrics ──
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              '⚡ ${result.source ?? "engine"} | ${result.timingMs.toStringAsFixed(3)}ms',
              style: LiquidGlassTheme.mono.copyWith(fontSize: 10),
            ),
          ),
        ],
      ),
    ).animate()
     .fadeIn(duration: 350.ms)
     .slideY(begin: 0.05, end: 0, duration: 400.ms, curve: Curves.easeOut)
     .scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1), duration: 350.ms);
  }
}

// ── POS Pill ──
class _PosPill extends StatelessWidget {
  final String label;
  const _PosPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final color = LiquidGlassTheme.getPosColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: LiquidGlassTheme.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ── Save Button ──
class _SaveButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isSaved;
  const _SaveButton({this.onTap, this.isSaved = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: isSaved
                ? LinearGradient(colors: [
                    LiquidGlassTheme.accentPrimary.withValues(alpha: 0.3),
                    LiquidGlassTheme.accentSecondary.withValues(alpha: 0.2),
                  ])
                : null,
            border: Border.all(
              color: isSaved
                  ? LiquidGlassTheme.accentPrimary.withValues(alpha: 0.5)
                  : LiquidGlassTheme.glassBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                size: 16,
                color: isSaved ? LiquidGlassTheme.accentPrimary : LiquidGlassTheme.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                isSaved ? 'Saved' : 'Save',
                style: LiquidGlassTheme.bodySmall.copyWith(
                  color: isSaved ? LiquidGlassTheme.accentPrimary : LiquidGlassTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

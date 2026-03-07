/// LexiCore — Glass Panel Widget
/// Frosted glass container with animated borders and hover effects.
library;

import 'package:flutter/material.dart';
import '../theme/liquid_glass_theme.dart';

class GlassPanel extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double blur;
  final bool enableCursorGlow;

  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = LiquidGlassTheme.borderRadius,
    this.padding = const EdgeInsets.all(20),
    this.blur = LiquidGlassTheme.glassBlur,
    this.enableCursorGlow = true,
  });

  @override
  State<GlassPanel> createState() => _GlassPanelState();
}

class _GlassPanelState extends State<GlassPanel> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          // Glass fill — semi-transparent dark surface
          color: const Color(0x1AFFFFFF),
          border: Border.all(
            color: _isHovering
                ? LiquidGlassTheme.glassHighlight.withValues(alpha: 0.25)
                : LiquidGlassTheme.glassBorder,
            width: 1,
          ),
          // Specular top edge illusion via gradient
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0x20FFFFFF),
              const Color(0x0DFFFFFF),
              const Color(0x08FFFFFF),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: LiquidGlassTheme.accentPrimary.withValues(alpha: _isHovering ? 0.08 : 0.03),
              blurRadius: 30,
              spreadRadius: -5,
            ),
            // Inner glow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: -8,
            ),
          ],
        ),
        child: Padding(
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );
  }
}

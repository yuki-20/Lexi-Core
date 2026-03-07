/// LexiCore — Glass Panel Widget
/// Frosted glass container with specular edge lighting and cursor glow.
library;

import 'dart:ui';
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
  Offset _cursorPos = Offset.zero;
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      onHover: (event) => setState(() => _cursorPos = event.localPosition),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: _isHovering
                ? LiquidGlassTheme.glassHighlight.withValues(alpha: 0.25)
                : LiquidGlassTheme.glassBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: LiquidGlassTheme.accentPrimary.withValues(alpha: _isHovering ? 0.08 : 0.03),
              blurRadius: 30,
              spreadRadius: -5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: widget.blur,
              sigmaY: widget.blur,
            ),
            child: Stack(
              children: [
                // Base glass fill
                Container(
                  decoration: BoxDecoration(
                    color: LiquidGlassTheme.glassFill,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                  ),
                ),
                // Specular top edge shine
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 1,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LiquidGlassTheme.specularBorder,
                    ),
                  ),
                ),
                // Cursor glow
                if (widget.enableCursorGlow && _isHovering)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(widget.borderRadius),
                          gradient: RadialGradient(
                            center: Alignment(
                              (_cursorPos.dx / (context.size?.width ?? 300)) * 2 - 1,
                              (_cursorPos.dy / (context.size?.height ?? 200)) * 2 - 1,
                            ),
                            radius: 0.6,
                            colors: [
                              LiquidGlassTheme.accentPrimary.withValues(alpha: 0.12),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                // Content
                Padding(
                  padding: widget.padding,
                  child: widget.child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// LexiCore — Liquid Glass Panel (iOS 26 Style)
/// Authentic frosted glass with backdrop blur, specular highlights,
/// prismatic edge lighting, and cursor-reactive glow.
library;

import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/liquid_glass_theme.dart';

class GlassPanel extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double blur;
  final bool enableCursorGlow;
  final bool enableSpecular;

  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = LiquidGlassTheme.borderRadius,
    this.padding = const EdgeInsets.all(20),
    this.blur = LiquidGlassTheme.glassBlur,
    this.enableCursorGlow = true,
    this.enableSpecular = true,
  });

  @override
  State<GlassPanel> createState() => _GlassPanelState();
}

class _GlassPanelState extends State<GlassPanel>
    with SingleTickerProviderStateMixin {
  Offset _cursorPos = Offset.zero;
  bool _isHovering = false;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() {
        _isHovering = false;
        _cursorPos = Offset.zero;
      }),
      onHover: (event) => setState(() => _cursorPos = event.localPosition),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: [
            // Outer diffuse glow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
            // Subtle accent glow on hover
            if (_isHovering)
              BoxShadow(
                color: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.1),
                blurRadius: 40,
                spreadRadius: -8,
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
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _LiquidGlassPainter(
                    cursorPos: _cursorPos,
                    isHovering: _isHovering,
                    borderRadius: widget.borderRadius,
                    shimmerProgress: _shimmerController.value,
                    enableSpecular: widget.enableSpecular,
                    enableCursorGlow: widget.enableCursorGlow,
                  ),
                  child: child,
                );
              },
              child: Padding(
                padding: widget.padding,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for iOS 26 liquid glass effects
class _LiquidGlassPainter extends CustomPainter {
  final Offset cursorPos;
  final bool isHovering;
  final double borderRadius;
  final double shimmerProgress;
  final bool enableSpecular;
  final bool enableCursorGlow;

  _LiquidGlassPainter({
    required this.cursorPos,
    required this.isHovering,
    required this.borderRadius,
    required this.shimmerProgress,
    required this.enableSpecular,
    required this.enableCursorGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // 1. Base glass fill — semi-transparent with slight saturation
    final basePaint = Paint()
      ..color = const Color(0x18FFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, basePaint);

    // 2. Secondary inner fill — very subtle gradient
    final innerGradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0x12FFFFFF),
          const Color(0x08FFFFFF),
          const Color(0x05FFFFFF),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, innerGradient);

    // 3. Specular top-edge highlight (iOS 26 signature)
    if (enableSpecular) {
      final specularRect = Rect.fromLTWH(0, 0, size.width, 1.5);
      final specularPaint = Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0x00FFFFFF),
            Color(0x40FFFFFF),
            Color(0x60FFFFFF),
            Color(0x40FFFFFF),
            Color(0x00FFFFFF),
          ],
          stops: [0.0, 0.2, 0.5, 0.8, 1.0],
        ).createShader(specularRect);
      canvas.drawRect(specularRect, specularPaint);
    }

    // 4. Prismatic edge shimmer (rainbow refraction)
    if (enableSpecular) {
      final shimmerX = shimmerProgress * (size.width + 200) - 100;
      final shimmerPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.transparent,
            const Color(0x10FF6B6B), // red
            const Color(0x10FFD93D), // yellow
            const Color(0x0C6BCB77), // green
            const Color(0x104ECDC4), // teal
            const Color(0x10A78BFA), // purple
            Colors.transparent,
          ],
          stops: const [0.0, 0.15, 0.3, 0.45, 0.6, 0.8, 1.0],
          transform: GradientRotation(math.pi / 6),
        ).createShader(Rect.fromLTWH(shimmerX - 80, 0, 160, size.height));
      canvas.save();
      canvas.clipRRect(rrect);
      canvas.drawRect(rect, shimmerPaint);
      canvas.restore();
    }

    // 5. Cursor glow — radial light following mouse
    if (enableCursorGlow && isHovering && cursorPos != Offset.zero) {
      final glowPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment(
            (cursorPos.dx / size.width * 2 - 1).clamp(-1.0, 1.0),
            (cursorPos.dy / size.height * 2 - 1).clamp(-1.0, 1.0),
          ),
          radius: 0.5,
          colors: [
            const Color(0x1AFFFFFF),
            const Color(0x08FFFFFF),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(rect);
      canvas.save();
      canvas.clipRRect(rrect);
      canvas.drawRect(rect, glowPaint);
      canvas.restore();
    }

    // 6. Glass border — thin, with varying opacity
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.fromRGBO(255, 255, 255, isHovering ? 0.35 : 0.22),
          Color.fromRGBO(255, 255, 255, isHovering ? 0.15 : 0.08),
          Color.fromRGBO(255, 255, 255, isHovering ? 0.10 : 0.05),
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidGlassPainter oldDelegate) {
    return oldDelegate.cursorPos != cursorPos ||
        oldDelegate.isHovering != isHovering ||
        oldDelegate.shimmerProgress != shimmerProgress;
  }
}


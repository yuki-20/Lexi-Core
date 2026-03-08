import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/liquid_glass_theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  bool _videoReady = false;
  bool _showOverlay = false;
  double _progress = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _initVideo();
    // Show overlay after a slight delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showOverlay = true);
    });
    // Simulate loading progress
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        _progress += 0.012;
        if (_progress >= 1.0) {
          _progress = 1.0;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _initVideo() async {
    _videoController = VideoPlayerController.asset('assets/videos/Intro.mp4');
    try {
      await _videoController.initialize();
      await _videoController.setLooping(false);
      await _videoController.setVolume(0.5);
      await _videoController.play();
      if (mounted) setState(() => _videoReady = true);

      _videoController.addListener(() {
        if (_videoController.value.position >= _videoController.value.duration &&
            _videoController.value.duration > Duration.zero) {
          _finishSplash();
        }
      });

      // Safety timeout — if video is >8s, auto-skip
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) _finishSplash();
      });
    } catch (e) {
      // Video failed — skip to app after 3s
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) _finishSplash();
      });
    }
  }

  void _finishSplash() {
    _progressTimer?.cancel();
    widget.onComplete();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: GestureDetector(
        onTap: _finishSplash, // Tap to skip
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.3),
                  radius: 1.2,
                  colors: [
                    Color(0xFF1A1A2E),
                    Color(0xFF0A0A0F),
                  ],
                ),
              ),
            ),

            // Video player (centered, letterboxed)
            if (_videoReady)
              Center(
                child: AspectRatio(
                  aspectRatio: _videoController.value.aspectRatio,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: VideoPlayer(_videoController),
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms),

            // Glass overlay
            if (_showOverlay)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(40, 40, 40, 60),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF0A0A0F).withOpacity(0.8),
                        const Color(0xFF0A0A0F),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App name
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            LiquidGlassTheme.accentPrimary,
                            Color(0xFFBB86FC),
                            LiquidGlassTheme.accentSecondary,
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'LexiCore',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 3,
                          ),
                        ),
                      ).animate()
                        .fadeIn(duration: 800.ms, delay: 200.ms)
                        .slideY(begin: 0.3, end: 0, duration: 600.ms),

                      const SizedBox(height: 8),

                      Text(
                        'Vocabulary Learning Platform',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.5),
                          letterSpacing: 2,
                          fontWeight: FontWeight.w300,
                        ),
                      ).animate()
                        .fadeIn(duration: 600.ms, delay: 600.ms),

                      const SizedBox(height: 32),

                      // Progress bar (glass style)
                      Container(
                        height: 4,
                        width: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: Colors.white.withOpacity(0.1),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 50),
                            width: 200 * _progress,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              gradient: const LinearGradient(
                                colors: [
                                  LiquidGlassTheme.accentPrimary,
                                  Color(0xFFBB86FC),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: LiquidGlassTheme.accentPrimary.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate()
                        .fadeIn(duration: 400.ms, delay: 800.ms),

                      const SizedBox(height: 16),

                      // Skip hint
                      Text(
                        'Tap to skip',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ).animate()
                        .fadeIn(duration: 400.ms, delay: 1500.ms),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

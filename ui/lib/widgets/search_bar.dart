/// LexiCore — Search Bar Widget
/// Pill-shaped glass search input with micro-animations.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/liquid_glass_theme.dart';
import '../widgets/glass_panel.dart';

class SearchBar extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onChanged;
  final VoidCallback? onMicTap;
  final bool isLoading;

  const SearchBar({
    super.key,
    required this.onSearch,
    required this.onChanged,
    this.onMicTap,
    this.isLoading = false,
  });

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Search icon
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(10),
            child: Icon(
              Icons.search_rounded,
              color: _isFocused
                  ? LiquidGlassTheme.accentPrimary
                  : LiquidGlassTheme.textMuted,
              size: 22,
            ),
          ),
          // Text field
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: LiquidGlassTheme.body.copyWith(color: LiquidGlassTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search for a word...',
                hintStyle: LiquidGlassTheme.body.copyWith(
                  color: LiquidGlassTheme.textMuted,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: widget.onChanged,
              onSubmitted: widget.onSearch,
            ),
          ),
          // Loading indicator
          if (widget.isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.6),
                ),
              ),
            ),
          // Clear button
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: LiquidGlassTheme.textMuted,
                size: 20,
              ),
              onPressed: () {
                _controller.clear();
                widget.onChanged('');
              },
            ),
          // Mic button
          if (widget.onMicTap != null)
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    LiquidGlassTheme.accentPrimary.withValues(alpha: 0.3),
                    LiquidGlassTheme.accentSecondary.withValues(alpha: 0.2),
                  ],
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.mic_rounded, size: 20),
                color: LiquidGlassTheme.textPrimary,
                onPressed: widget.onMicTap,
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }
}

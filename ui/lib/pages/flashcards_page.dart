/// LexiCore — Flashcards Page (v3.1)
/// Deck management, 3D flip study mode, improved spacing + animations.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/liquid_glass_theme.dart';
import '../services/engine_service.dart';
import '../widgets/glass_panel.dart';

class FlashcardsPage extends StatefulWidget {
  const FlashcardsPage({super.key});

  @override
  State<FlashcardsPage> createState() => _FlashcardsPageState();
}

class _FlashcardsPageState extends State<FlashcardsPage> {
  final _engine = EngineService();
  List<Map<String, dynamic>> _decks = [];
  bool _loading = true;

  // Study mode
  bool _studying = false;
  List<Map<String, dynamic>> _cards = [];
  int _cardIndex = 0;
  bool _showingFront = true;

  @override
  void initState() {
    super.initState();
    _loadDecks();
  }

  Future<void> _loadDecks() async {
    setState(() => _loading = true);
    final decks = await _engine.getDecks();
    if (mounted) {
      setState(() {
        _decks = decks;
        _loading = false;
      });
    }
  }

  Future<void> _createDeck() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LiquidGlassTheme.bgDeep,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Create Deck', style: LiquidGlassTheme.headingSm),
        content: TextField(
          controller: controller,
          style: LiquidGlassTheme.body.copyWith(color: LiquidGlassTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Deck name',
            hintStyle: LiquidGlassTheme.body,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await _engine.createDeck(name);
      _loadDecks();
    }
  }

  Future<void> _deleteDeck(int id) async {
    await _engine.deleteDeck(id);
    _loadDecks();
  }

  Future<void> _startStudy(int deckId) async {
    final cards = await _engine.getCards(deckId);
    if (cards.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No cards in this deck')),
        );
      }
      return;
    }
    setState(() {
      _studying = true;
      _cards = cards;
      _cardIndex = 0;
      _showingFront = true;
    });
  }

  void _flipCard() {
    setState(() => _showingFront = !_showingFront);
  }

  void _nextCard(bool easy) {
    if (_cardIndex < _cards.length - 1) {
      setState(() {
        _cardIndex++;
        _showingFront = true;
      });
    } else {
      setState(() {
        _studying = false;
        _cards = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_studying) return _buildStudyMode();
    return _buildDeckList();
  }

  Widget _buildDeckList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Flashcard Decks', style: LiquidGlassTheme.heading)),
              GlassPanel(
                borderRadius: 30,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GestureDetector(
                  onTap: _createDeck,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, size: 18, color: LiquidGlassTheme.accentPrimary),
                      const SizedBox(width: 6),
                      Text('New', style: LiquidGlassTheme.label.copyWith(
                        color: LiquidGlassTheme.accentPrimary,
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 28),

          if (_loading)
            const Center(child: CircularProgressIndicator(color: LiquidGlassTheme.accentPrimary))
          else if (_decks.isEmpty)
            Center(
              child: GlassPanel(
                child: Column(
                  children: [
                    const Icon(Icons.style_outlined, size: 56, color: LiquidGlassTheme.textMuted),
                    const SizedBox(height: 16),
                    Text('No decks yet', style: LiquidGlassTheme.headingSm),
                    const SizedBox(height: 8),
                    Text(
                      'Create a deck to start studying\nwith flashcards',
                      style: LiquidGlassTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0),
            )
          else
            ..._decks.asMap().entries.map((entry) {
              final deck = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GlassPanel(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(colors: [
                            LiquidGlassTheme.accentPrimary.withValues(alpha: 0.3),
                            LiquidGlassTheme.accentSecondary.withValues(alpha: 0.15),
                          ]),
                        ),
                        child: const Center(
                          child: Icon(Icons.style_rounded, color: LiquidGlassTheme.accentPrimary, size: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(deck['name'] ?? 'Untitled', style: LiquidGlassTheme.headingSm.copyWith(fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(
                              '${deck['card_count'] ?? 0} cards • ${deck['source'] ?? 'manual'}',
                              style: LiquidGlassTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      GlassPanel(
                        borderRadius: 12,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: GestureDetector(
                          onTap: () => _startStudy(deck['id']),
                          child: Text('Study', style: LiquidGlassTheme.label.copyWith(
                            color: LiquidGlassTheme.accentPrimary,
                          )),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: LiquidGlassTheme.textMuted),
                        onPressed: () => _deleteDeck(deck['id']),
                      ),
                    ],
                  ),
                ).animate()
                 .fadeIn(delay: Duration(milliseconds: 150 * entry.key), duration: 400.ms)
                 .slideY(begin: 0.05, end: 0),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStudyMode() {
    if (_cards.isEmpty) return const SizedBox.shrink();
    final card = _cards[_cardIndex];
    final progress = (_cardIndex + 1) / _cards.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              GlassPanel(
                borderRadius: 12,
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () => setState(() => _studying = false),
                  child: const Icon(Icons.arrow_back, size: 20, color: LiquidGlassTheme.textSecondary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Card ${_cardIndex + 1} of ${_cards.length}',
                      style: LiquidGlassTheme.label,
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: LiquidGlassTheme.glassFill,
                        valueColor: const AlwaysStoppedAnimation(LiquidGlassTheme.accentPrimary),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 40),

          // 3D Flip Card
          Expanded(
            child: GestureDetector(
              onTap: _flipCard,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) {
                  final rotate = Tween(begin: math.pi / 2, end: 0.0).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                  );
                  return AnimatedBuilder(
                    animation: rotate,
                    builder: (ctx, ch) => Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(rotate.value),
                      child: ch,
                    ),
                    child: child,
                  );
                },
                child: GlassPanel(
                  key: ValueKey(_showingFront ? 'front' : 'back-$_cardIndex'),
                  borderRadius: 24,
                  padding: const EdgeInsets.all(36),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _showingFront ? '📝' : '💡',
                          style: const TextStyle(fontSize: 36),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _showingFront
                              ? (card['word'] ?? '')
                              : (card['definition'] ?? 'No definition'),
                          style: _showingFront
                              ? LiquidGlassTheme.heading.copyWith(fontSize: 30)
                              : LiquidGlassTheme.body.copyWith(fontSize: 17, height: 1.6),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _showingFront ? 'Tap to reveal' : 'Tap to flip back',
                          style: LiquidGlassTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Buttons
          if (!_showingFront)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StudyButton(
                  label: 'Hard',
                  color: LiquidGlassTheme.accentTertiary,
                  icon: Icons.refresh_rounded,
                  onTap: () => _nextCard(false),
                ),
                const SizedBox(width: 20),
                _StudyButton(
                  label: 'Easy',
                  color: Colors.greenAccent,
                  icon: Icons.check_rounded,
                  onTap: () => _nextCard(true),
                ),
              ],
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }
}

class _StudyButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _StudyButton({required this.label, required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassPanel(
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: LiquidGlassTheme.label.copyWith(color: color, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

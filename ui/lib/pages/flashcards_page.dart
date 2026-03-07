/// LexiCore — Flashcards Page
/// Deck list, create decks, study mode with card flip animation.
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
  bool _isStudying = false;
  List<Map<String, dynamic>> _studyCards = [];
  int _currentCard = 0;
  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();
    _loadDecks();
  }

  Future<void> _loadDecks() async {
    final decks = await _engine.getDecks();
    if (mounted) setState(() => _decks = decks);
  }

  Future<void> _createDeck() async {
    final name = await _showNameDialog('Create Deck', 'Deck name');
    if (name == null || name.isEmpty) return;
    await _engine.createDeck(name);
    _loadDecks();
  }

  Future<void> _studyDeck(int deckId) async {
    final cards = await _engine.getCards(deckId);
    if (cards.isEmpty) return;
    cards.shuffle();
    setState(() {
      _studyCards = cards;
      _currentCard = 0;
      _showAnswer = false;
      _isStudying = true;
    });
  }

  void _nextCard() {
    if (_currentCard < _studyCards.length - 1) {
      setState(() { _currentCard++; _showAnswer = false; });
    } else {
      setState(() => _isStudying = false);
    }
  }

  Future<String?> _showNameDialog(String title, String hint) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LiquidGlassTheme.bgDeep,
        title: Text(title, style: LiquidGlassTheme.headingSm),
        content: TextField(
          controller: controller,
          style: LiquidGlassTheme.body.copyWith(color: LiquidGlassTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
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
  }

  @override
  Widget build(BuildContext context) {
    if (_isStudying) return _buildStudyMode();
    return _buildDeckList();
  }

  Widget _buildDeckList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Flashcards', style: LiquidGlassTheme.heading),
              ),
              IconButton(
                onPressed: _createDeck,
                icon: const Icon(Icons.add_rounded, color: LiquidGlassTheme.accentPrimary),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 20),

          if (_decks.isEmpty)
            Center(
              child: GlassPanel(
                child: Column(
                  children: [
                    const Icon(Icons.style_outlined, size: 48, color: LiquidGlassTheme.textMuted),
                    const SizedBox(height: 12),
                    Text('No decks yet', style: LiquidGlassTheme.body),
                    const SizedBox(height: 8),
                    Text('Create a deck to start studying!', style: LiquidGlassTheme.bodySmall),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),

          ..._decks.asMap().entries.map((entry) {
            final deck = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassPanel(
                child: InkWell(
                  onTap: () => _studyDeck(deck['id']),
                  borderRadius: BorderRadius.circular(LiquidGlassTheme.borderRadius),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            colors: [
                              LiquidGlassTheme.accentPrimary.withValues(alpha: 0.3),
                              LiquidGlassTheme.accentSecondary.withValues(alpha: 0.2),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.style_rounded, color: LiquidGlassTheme.textPrimary, size: 24),
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
                              '${deck['card_count'] ?? 0} cards',
                              style: LiquidGlassTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: LiquidGlassTheme.textMuted),
                        onPressed: () async {
                          await _engine.deleteDeck(deck['id']);
                          _loadDecks();
                        },
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 100 * entry.key), duration: 400.ms)
               .slideX(begin: 0.05, end: 0),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStudyMode() {
    final card = _studyCards[_currentCard];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Card ${_currentCard + 1} / ${_studyCards.length}',
              style: LiquidGlassTheme.bodySmall,
            ),
            const SizedBox(height: 24),

            GestureDetector(
              onTap: () => setState(() => _showAnswer = !_showAnswer),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  final rotate = Tween(begin: math.pi / 2, end: 0.0).animate(animation);
                  return AnimatedBuilder(
                    animation: rotate,
                    builder: (_, child) => Transform(
                      transform: Matrix4.rotationY(rotate.value),
                      alignment: Alignment.center,
                      child: child,
                    ),
                    child: child,
                  );
                },
                child: GlassPanel(
                  key: ValueKey(_showAnswer),
                  padding: const EdgeInsets.all(40),
                  borderRadius: LiquidGlassTheme.borderRadiusLg,
                  child: SizedBox(
                    width: double.infinity,
                    height: 200,
                    child: Center(
                      child: Text(
                        _showAnswer
                            ? (card['definition'] ?? 'No definition')
                            : (card['word'] ?? ''),
                        style: _showAnswer
                            ? LiquidGlassTheme.body.copyWith(fontSize: 16)
                            : LiquidGlassTheme.heading,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              _showAnswer ? 'Tap to see word' : 'Tap to reveal answer',
              style: LiquidGlassTheme.bodySmall,
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StudyButton(
                  icon: Icons.close_rounded,
                  color: Colors.redAccent,
                  label: 'Hard',
                  onTap: _nextCard,
                ),
                const SizedBox(width: 20),
                _StudyButton(
                  icon: Icons.check_rounded,
                  color: Colors.greenAccent,
                  label: 'Easy',
                  onTap: _nextCard,
                ),
              ],
            ),

            const SizedBox(height: 20),
            TextButton(
              onPressed: () => setState(() => _isStudying = false),
              child: Text('Exit Study', style: LiquidGlassTheme.body.copyWith(
                color: LiquidGlassTheme.accentPrimary,
              )),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudyButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _StudyButton({required this.icon, required this.color, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: 30,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(label, style: LiquidGlassTheme.body.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

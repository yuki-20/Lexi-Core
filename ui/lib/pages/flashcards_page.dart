/// LexiCore — Flashcards Page (v5.4)
/// Deck management, editing, 3D flip study mode, improved spacing + animations.
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

  // Edit mode
  bool _editing = false;
  int _editDeckId = 0;
  String _editDeckName = '';
  List<Map<String, dynamic>> _editCards = [];

  @override
  void initState() {
    super.initState();
    _loadDecks();
  }

  Future<void> _loadDecks() async {
    setState(() => _loading = true);
    await _engine.waitForReady();
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

  // ── Deck Editing ────────────────────────────────────────────────
  Future<void> _editDeck(Map<String, dynamic> deck) async {
    final deckId = deck['id'] as int;
    final cards = await _engine.getCards(deckId);
    setState(() {
      _editing = true;
      _editDeckId = deckId;
      _editDeckName = deck['name'] ?? 'Untitled';
      _editCards = cards;
    });
  }

  Future<void> _renameDeckDialog() async {
    final controller = TextEditingController(text: _editDeckName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LiquidGlassTheme.bgDeep,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Rename Deck', style: LiquidGlassTheme.headingSm),
        content: TextField(
          controller: controller,
          autofocus: true,
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
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty && newName != _editDeckName) {
      await _engine.renameDeck(_editDeckId, newName);
      setState(() => _editDeckName = newName);
      _loadDecks();
    }
  }

  Future<void> _addCardToDeck() async {
    final picked = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => _WordPickerDialog(engine: _engine),
    );
    if (picked != null && picked['word']!.isNotEmpty) {
      await _engine.addCard(
        _editDeckId, picked['word']!,
        definition: picked['definition']?.isNotEmpty == true ? picked['definition'] : null,
      );
      final cards = await _engine.getCards(_editDeckId);
      setState(() => _editCards = cards);
      _loadDecks();
    }
  }

  Future<void> _editCardDialog(Map<String, dynamic> card) async {
    final wordCtrl = TextEditingController(text: card['word'] ?? '');
    final defCtrl = TextEditingController(text: card['definition'] ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LiquidGlassTheme.bgDeep,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Card', style: LiquidGlassTheme.headingSm),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: wordCtrl,
              autofocus: true,
              style: LiquidGlassTheme.body.copyWith(color: LiquidGlassTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Word',
                labelStyle: LiquidGlassTheme.bodySmall,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: defCtrl,
              style: LiquidGlassTheme.body.copyWith(color: LiquidGlassTheme.textPrimary),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Definition',
                labelStyle: LiquidGlassTheme.bodySmall,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == true) {
      await _engine.updateCard(
        _editDeckId, card['id'] as int,
        word: wordCtrl.text,
        definition: defCtrl.text,
      );
      final cards = await _engine.getCards(_editDeckId);
      setState(() => _editCards = cards);
    }
  }

  Future<void> _deleteCardFromDeck(int cardId) async {
    await _engine.deleteCard(cardId);
    final cards = await _engine.getCards(_editDeckId);
    setState(() => _editCards = cards);
    _loadDecks();
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) return _buildDeckEditor();
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
                      // Edit button
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 18, color: LiquidGlassTheme.accentPrimary),
                        tooltip: 'Edit deck',
                        onPressed: () => _editDeck(deck),
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

  // ── Deck Editor ─────────────────────────────────────────────────
  Widget _buildDeckEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              GlassPanel(
                borderRadius: 12,
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () => setState(() {
                    _editing = false;
                    _editCards = [];
                  }),
                  child: const Icon(Icons.arrow_back, size: 20, color: LiquidGlassTheme.textSecondary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: _renameDeckDialog,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          _editDeckName,
                          style: LiquidGlassTheme.heading.copyWith(fontSize: 22),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.edit_rounded, size: 16, color: LiquidGlassTheme.textMuted),
                    ],
                  ),
                ),
              ),
              GlassPanel(
                borderRadius: 30,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GestureDetector(
                  onTap: _addCardToDeck,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, size: 18, color: LiquidGlassTheme.accentPrimary),
                      const SizedBox(width: 6),
                      Text('Add Card', style: LiquidGlassTheme.label.copyWith(
                        color: LiquidGlassTheme.accentPrimary,
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 8),
          Text(
            '${_editCards.length} cards',
            style: LiquidGlassTheme.bodySmall,
          ),
          const SizedBox(height: 20),

          if (_editCards.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    const Icon(Icons.note_add_outlined, size: 48, color: LiquidGlassTheme.textMuted),
                    const SizedBox(height: 16),
                    Text('No cards yet', style: LiquidGlassTheme.headingSm),
                    const SizedBox(height: 8),
                    Text(
                      'Tap "Add Card" to add words\nto this deck',
                      style: LiquidGlassTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),
            )
          else
            ..._editCards.asMap().entries.map((entry) {
              final card = entry.value;
              final cardId = card['id'] as int;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassPanel(
                  padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
                  child: Row(
                    children: [
                      // Card number
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.15),
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: LiquidGlassTheme.label.copyWith(
                              color: LiquidGlassTheme.accentPrimary, fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Word + definition
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card['word'] ?? '',
                              style: LiquidGlassTheme.headingSm.copyWith(fontSize: 15),
                            ),
                            if (card['definition'] != null && card['definition'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  card['definition'].toString(),
                                  style: LiquidGlassTheme.bodySmall.copyWith(fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Edit button
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 16, color: LiquidGlassTheme.accentPrimary),
                        tooltip: 'Edit',
                        onPressed: () => _editCardDialog(card),
                      ),
                      // Delete button
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16, color: LiquidGlassTheme.textMuted),
                        tooltip: 'Remove',
                        onPressed: () => _deleteCardFromDeck(cardId),
                      ),
                    ],
                  ),
                ).animate()
                 .fadeIn(delay: Duration(milliseconds: 60 * entry.key), duration: 300.ms)
                 .slideX(begin: 0.03, end: 0),
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

// ══════════════════════════════════════════════════════════════════════════
// Word Picker Dialog — 3 tabs: Saved Words, Dictionary Search, Manual
// ══════════════════════════════════════════════════════════════════════════
class _WordPickerDialog extends StatefulWidget {
  final EngineService engine;
  const _WordPickerDialog({required this.engine});
  @override
  State<_WordPickerDialog> createState() => _WordPickerDialogState();
}

class _WordPickerDialogState extends State<_WordPickerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Saved words tab
  List<Map<String, dynamic>> _savedWords = [];
  bool _loadingSaved = true;

  // Dictionary tab
  final _searchCtrl = TextEditingController();
  List<String> _suggestions = [];
  String? _selectedDictWord;
  String? _selectedDictDef;
  bool _searchingDef = false;

  // Manual tab
  final _manualWordCtrl = TextEditingController();
  final _manualDefCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadSavedWords();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    _manualWordCtrl.dispose();
    _manualDefCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedWords() async {
    final words = await widget.engine.getSavedWords();
    if (mounted) setState(() { _savedWords = words; _loadingSaved = false; });
  }

  Future<void> _onSearchChanged(String value) async {
    if (value.isEmpty) {
      setState(() { _suggestions = []; _selectedDictWord = null; _selectedDictDef = null; });
      return;
    }
    final results = await widget.engine.getAutocomplete(value);
    if (mounted) {
      setState(() {
        _suggestions = results.map((r) => r.word).where((s) => s.isNotEmpty).toList();
      });
    }
  }

  Future<void> _selectDictWord(String word) async {
    setState(() { _selectedDictWord = word; _searchingDef = true; _selectedDictDef = null; });
    try {
      final result = await widget.engine.searchExact(word);
      final defText = result.definitions.isNotEmpty ? result.definitions.join('; ') : '';
      if (mounted) setState(() { _selectedDictDef = defText; _searchingDef = false; });
    } catch (_) {
      if (mounted) setState(() { _selectedDictDef = ''; _searchingDef = false; });
    }
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: LiquidGlassTheme.body.copyWith(color: Colors.white.withValues(alpha: 0.3)),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.05),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: LiquidGlassTheme.accentPrimary),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: LiquidGlassTheme.bgDeep,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 60),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline_rounded, color: LiquidGlassTheme.accentPrimary, size: 22),
                  const SizedBox(width: 10),
                  Text('Add Card', style: LiquidGlassTheme.headingSm),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: LiquidGlassTheme.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── Tab Bar ──
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withValues(alpha: 0.05),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.2),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: LiquidGlassTheme.accentPrimary,
                unselectedLabelColor: LiquidGlassTheme.textMuted,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 12),
                dividerHeight: 0,
                tabs: const [
                  Tab(text: '⭐ Saved', height: 36),
                  Tab(text: '📖 Dictionary', height: 36),
                  Tab(text: '✏️ Manual', height: 36),
                ],
              ),
            ),

            // ── Tab Content ──
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildSavedTab(),
                  _buildDictionaryTab(),
                  _buildManualTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: Saved Words ──
  Widget _buildSavedTab() {
    if (_loadingSaved) {
      return const Center(child: CircularProgressIndicator(color: LiquidGlassTheme.accentPrimary));
    }
    if (_savedWords.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bookmark_border_rounded, size: 40, color: LiquidGlassTheme.textMuted),
            const SizedBox(height: 12),
            Text('No saved words yet', style: LiquidGlassTheme.body),
            const SizedBox(height: 4),
            Text('Save words from search to see them here', style: LiquidGlassTheme.bodySmall),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: _savedWords.length,
      itemBuilder: (ctx, i) {
        final w = _savedWords[i];
        final word = w['word']?.toString() ?? '';
        final def = w['definition']?.toString() ?? '';
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pop(context, {'word': word, 'definition': def}),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withValues(alpha: 0.04),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.15),
                      ),
                      child: Center(
                        child: Text(
                          word.isNotEmpty ? word[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: LiquidGlassTheme.accentPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(word, style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: LiquidGlassTheme.textPrimary,
                          )),
                          if (def.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(def, style: LiquidGlassTheme.bodySmall.copyWith(fontSize: 11),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.add_rounded, size: 18, color: LiquidGlassTheme.accentPrimary),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Tab 2: Dictionary Search ──
  Widget _buildDictionaryTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: _searchCtrl,
            style: LiquidGlassTheme.body.copyWith(color: LiquidGlassTheme.textPrimary, fontSize: 14),
            decoration: _inputDeco('Search dictionary...').copyWith(
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: LiquidGlassTheme.textMuted),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 10),

          // Selected word preview
          if (_selectedDictWord != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.08),
                border: Border.all(color: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(_selectedDictWord!, style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: LiquidGlassTheme.accentPrimary,
                      )),
                      const Spacer(),
                      if (_searchingDef)
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: LiquidGlassTheme.accentPrimary,
                        ))
                      else
                        GestureDetector(
                          onTap: () => Navigator.pop(context, {
                            'word': _selectedDictWord!,
                            'definition': _selectedDictDef ?? '',
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: LiquidGlassTheme.accentPrimary,
                            ),
                            child: const Text('Add', style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white,
                            )),
                          ),
                        ),
                    ],
                  ),
                  if (_selectedDictDef != null && _selectedDictDef!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _selectedDictDef!,
                      style: LiquidGlassTheme.bodySmall.copyWith(fontSize: 12),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

          // Suggestions list
          Expanded(
            child: _suggestions.isEmpty
                ? Center(
                    child: Text(
                      _searchCtrl.text.isEmpty ? 'Type to search the dictionary' : 'No results found',
                      style: LiquidGlassTheme.bodySmall,
                    ),
                  )
                : ListView.builder(
                    itemCount: _suggestions.length,
                    itemBuilder: (ctx, i) {
                      final word = _suggestions[i];
                      final isSelected = word == _selectedDictWord;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => _selectDictWord(word),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: isSelected
                                    ? LiquidGlassTheme.accentPrimary.withValues(alpha: 0.12)
                                    : Colors.white.withValues(alpha: 0.03),
                                border: Border.all(
                                  color: isSelected
                                      ? LiquidGlassTheme.accentPrimary.withValues(alpha: 0.4)
                                      : Colors.white.withValues(alpha: 0.05),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(word, style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w500,
                                    color: isSelected ? LiquidGlassTheme.accentPrimary : LiquidGlassTheme.textPrimary,
                                  )),
                                  const Spacer(),
                                  Icon(
                                    isSelected ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: isSelected ? LiquidGlassTheme.accentPrimary : LiquidGlassTheme.textMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── Tab 3: Manual Entry ──
  Widget _buildManualTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        children: [
          TextField(
            controller: _manualWordCtrl,
            autofocus: false,
            style: LiquidGlassTheme.body.copyWith(color: LiquidGlassTheme.textPrimary, fontSize: 14),
            decoration: _inputDeco('Word'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _manualDefCtrl,
            style: LiquidGlassTheme.body.copyWith(color: LiquidGlassTheme.textPrimary, fontSize: 14),
            maxLines: 3,
            decoration: _inputDeco('Definition (optional)'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () {
                if (_manualWordCtrl.text.trim().isNotEmpty) {
                  Navigator.pop(context, {
                    'word': _manualWordCtrl.text.trim(),
                    'definition': _manualDefCtrl.text.trim(),
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(colors: [
                    LiquidGlassTheme.accentPrimary,
                    LiquidGlassTheme.accentSecondary,
                  ]),
                ),
                child: const Center(
                  child: Text('Add Card', style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white,
                  )),
                ),
              ),
            ),
          ),
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

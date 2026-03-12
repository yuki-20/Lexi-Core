/// LexiCore — Dictionary Browser Page (v5.5)
/// Browse all words in the dictionary sorted alphabetically with letter navigation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/liquid_glass_theme.dart';
import '../services/engine_service.dart';
import '../widgets/glass_panel.dart';

class DictionaryPage extends StatefulWidget {
  const DictionaryPage({super.key});

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  final _engine = EngineService();
  final _searchController = TextEditingController();

  Map<String, int> _letterCounts = {};
  List<String> _words = [];
  String _selectedLetter = '';
  int _totalWords = 0;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _loading = true;
  String? _expandedWord;
  Map<String, dynamic>? _expandedDef;

  @override
  void initState() {
    super.initState();
    _loadLetters();
  }

  Future<void> _loadLetters() async {
    try {
      final data = await _engine.getDictionaryLetters()
          .timeout(const Duration(seconds: 5), onTimeout: () => <String, dynamic>{'letters': <String, dynamic>{}, 'total': 0});
      if (mounted) {
        final letters = (data['letters'] as Map<String, dynamic>?) ?? {};
        setState(() {
          _letterCounts = letters.map((k, v) => MapEntry(k, v as int));
          _totalWords = data['total'] as int? ?? 0;
        });
        _loadWords();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadWords({int page = 1}) async {
    setState(() => _loading = true);
    try {
      final data = await _engine.getDictionaryWords(
        letter: _selectedLetter,
        page: page,
        limit: 100,
      ).timeout(const Duration(seconds: 5), onTimeout: () => <String, dynamic>{'words': <String>[], 'page': 1, 'pages': 0});
      if (mounted) {
        setState(() {
          _words = List<String>.from(data['words'] ?? []);
          _currentPage = data['page'] as int? ?? 1;
          _totalPages = data['pages'] as int? ?? 0;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectLetter(String letter) {
    setState(() {
      _selectedLetter = letter == _selectedLetter ? '' : letter;
      _expandedWord = null;
      _expandedDef = null;
    });
    _loadWords();
  }

  Future<void> _expandWord(String word) async {
    if (_expandedWord == word) {
      setState(() {
        _expandedWord = null;
        _expandedDef = null;
      });
      return;
    }

    // Try local binary dictionary first
    Map<String, dynamic>? result = await _engine.lookupWord(word);

    // Fallback: try full search (includes online)
    if (result == null) {
      var searchResult = await _engine.searchExact(word);
      if (!searchResult.found) {
        searchResult = await _engine.searchOnline(word);
      }
      if (searchResult.found) {
        result = {
          'word': searchResult.word,
          'definitions': searchResult.definitions,
          'found': true,
        };
      }
    }

    // Fallback: check saved words for stored definition
    if (result == null) {
      try {
        final saved = await _engine.getSavedWords();
        final match = saved.firstWhere(
          (w) => (w['word'] as String?)?.toLowerCase() == word.toLowerCase(),
          orElse: () => {},
        );
        if (match.isNotEmpty && match['definition'] != null) {
          result = {
            'word': word,
            'definitions': [match['definition']],
            'found': true,
          };
        }
      } catch (_) {}
    }

    setState(() {
      _expandedWord = word;
      _expandedDef = result;
    });
  }

  List<String> get _filteredWords {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _words;
    return _words.where((w) => w.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(
            children: [
              Expanded(child: Text('Dictionary', style: LiquidGlassTheme.heading)),
              Text(
                '$_totalWords words',
                style: LiquidGlassTheme.bodySmall,
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
        ),
        const SizedBox(height: 12),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GlassPanel(
            borderRadius: 14,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              style: LiquidGlassTheme.body.copyWith(color: LiquidGlassTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Filter words...',
                hintStyle: LiquidGlassTheme.body,
                border: InputBorder.none,
                icon: const Icon(Icons.search, size: 18, color: LiquidGlassTheme.textMuted),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Alphabet bar
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _LetterChip(
                letter: 'ALL',
                count: _totalWords,
                isSelected: _selectedLetter.isEmpty,
                onTap: () => _selectLetter(''),
              ),
              ...List.generate(26, (i) {
                final letter = String.fromCharCode(65 + i);
                final count = _letterCounts[letter] ?? 0;
                if (count == 0) return const SizedBox.shrink();
                return _LetterChip(
                  letter: letter,
                  count: count,
                  isSelected: _selectedLetter == letter,
                  onTap: () => _selectLetter(letter),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Word list
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: LiquidGlassTheme.accentPrimary))
              : _filteredWords.isEmpty
                  ? Center(
                      child: Text('No words found', style: LiquidGlassTheme.bodySmall),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                      itemCount: _filteredWords.length + (_totalPages > 1 ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        if (i == _filteredWords.length) {
                          return _buildPagination();
                        }
                        final word = _filteredWords[i];
                        final isExpanded = _expandedWord == word;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: GestureDetector(
                            onTap: () => _expandWord(word),
                            child: GlassPanel(
                              borderRadius: 12,
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        word,
                                        style: LiquidGlassTheme.headingSm.copyWith(fontSize: 15),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        isExpanded ? Icons.expand_less : Icons.expand_more,
                                        size: 18,
                                        color: LiquidGlassTheme.textMuted,
                                      ),
                                    ],
                                  ),
                                  if (isExpanded && _expandedDef != null) ...[
                                    const SizedBox(height: 8),
                                    Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                                    const SizedBox(height: 8),
                                    Text(
                                      _formatDefinition(_expandedDef!),
                                      style: LiquidGlassTheme.bodySmall.copyWith(
                                        fontSize: 13, height: 1.5,
                                      ),
                                      maxLines: 10,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ).animate().fadeIn(
                              delay: Duration(milliseconds: 20 * (i % 20)),
                              duration: 200.ms,
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  String _formatDefinition(Map<String, dynamic> def) {
    final defs = def['definitions'];
    if (defs == null) return 'No definition available';
    if (defs is List) {
      return defs.take(3).map((d) => '• $d').join('\n');
    }
    return defs.toString();
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_currentPage > 1)
            GestureDetector(
              onTap: () => _loadWords(page: _currentPage - 1),
              child: GlassPanel(
                borderRadius: 10,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('← Prev', style: LiquidGlassTheme.label.copyWith(
                  color: LiquidGlassTheme.accentPrimary,
                )),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Page $_currentPage / $_totalPages',
              style: LiquidGlassTheme.bodySmall,
            ),
          ),
          if (_currentPage < _totalPages)
            GestureDetector(
              onTap: () => _loadWords(page: _currentPage + 1),
              child: GlassPanel(
                borderRadius: 10,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Next →', style: LiquidGlassTheme.label.copyWith(
                  color: LiquidGlassTheme.accentPrimary,
                )),
              ),
            ),
        ],
      ),
    );
  }
}

class _LetterChip extends StatelessWidget {
  final String letter;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  const _LetterChip({required this.letter, required this.count, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected
                ? LiquidGlassTheme.accentPrimary.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: isSelected
                  ? LiquidGlassTheme.accentPrimary.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? LiquidGlassTheme.accentPrimary : LiquidGlassTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

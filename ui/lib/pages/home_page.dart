/// LexiCore — Home Page (v4.0)
/// Centered search with rotating welcome text, Claude-style layout.
library;

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/liquid_glass_theme.dart';
import '../services/engine_service.dart';
import '../widgets/glass_panel.dart';
import '../widgets/search_bar.dart' as lexi;
import '../widgets/definition_card.dart';
import '../widgets/autocomplete_dropdown.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _engine = EngineService();
  SearchResult? _result;
  List<String> _suggestions = [];
  Map<String, dynamic>? _wotd;
  Map<String, dynamic>? _stats;
  bool _isLoading = false;
  bool _isSaved = false;

  // Rotating welcome messages
  static const _welcomeMessages = [
    'What shall we explore today?',
    'Ready to expand your vocabulary?',
    'Every word is a new adventure ✨',
    'Curiosity is the spark of learning 🔥',
    'Let\'s discover something new together',
    'Your vocabulary journey continues...',
    'Words shape the way we think 💡',
    'What word are you curious about?',
  ];

  late final String _welcomeText;

  @override
  void initState() {
    super.initState();
    _engine.connectWebSocket();
    _welcomeText = _welcomeMessages[Random().nextInt(_welcomeMessages.length)];
    _loadData();
  }

  Future<void> _loadData() async {
    final stats = await _engine.getStats();
    final wotd = await _engine.getWordOfTheDay();
    if (mounted) {
      setState(() {
        _stats = stats;
        _wotd = wotd;
      });
    }
  }

  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _isLoading = true; _suggestions = []; });

    var result = await _engine.searchExact(query);
    if (!result.found) {
      result = await _engine.searchOnline(query);
    }

    if (mounted) {
      setState(() {
        _result = result;
        _isLoading = false;
        _isSaved = false;
      });
    }
  }

  void _onSearchChanged(String value) async {
    if (value.length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    final items = await _engine.getAutocomplete(value);
    if (mounted) setState(() => _suggestions = items.map((i) => i.word).toList());
  }

  Future<void> _onSaveWord() async {
    if (_result == null || !_result!.found) return;
    final ok = await _engine.saveWord(_result!.word,
        definition: _result!.definitions.isNotEmpty ? _result!.definitions.first : null);
    if (ok && mounted) setState(() => _isSaved = true);
  }

  @override
  Widget build(BuildContext context) {
    final hasResult = _result != null && _result!.found;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
      child: Column(
        children: [
          // ── Centered Welcome + Search ──
          SizedBox(
            height: hasResult ? 180 : 280,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _welcomeText,
                  style: LiquidGlassTheme.heading.copyWith(
                    fontSize: hasResult ? 20 : 28,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(duration: 600.ms),
                SizedBox(height: hasResult ? 16 : 28),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: lexi.SearchBar(
                    onSearch: _onSearch,
                    onChanged: _onSearchChanged,
                    isLoading: _isLoading,
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms)
                 .slideY(begin: 0.05, end: 0),
              ],
            ),
          ),

          // ── Autocomplete ──
          if (_suggestions.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: AutocompleteDropdown(
                suggestions: _suggestions,
                onSelect: (word) {
                  setState(() => _suggestions = []);
                  _onSearch(word);
                },
              ),
            ),

          // ── Definition Card ──
          if (hasResult)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefinitionCard(
                    result: _result!,
                    onSave: _onSaveWord,
                    isSaved: _isSaved,
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
                  if (_result!.source != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          Icon(
                            _result!.source == 'online' ? Icons.cloud_outlined : Icons.storage_outlined,
                            size: 14,
                            color: _result!.source == 'online'
                                ? LiquidGlassTheme.accentSecondary
                                : LiquidGlassTheme.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _result!.source == 'online' ? 'Online result' : _result!.source ?? '',
                            style: LiquidGlassTheme.bodySmall.copyWith(
                              color: _result!.source == 'online'
                                  ? LiquidGlassTheme.accentSecondary
                                  : LiquidGlassTheme.textMuted,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms),
                    ),
                  const SizedBox(height: 28),
                ],
              ),
            ),

          // ── Bottom Row: WOTD + Stats ──
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Word of the Day ──
                if (_wotd != null && _wotd!['word'] != null)
                  Expanded(
                    flex: 3,
                    child: GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('✨', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Text('Word of the Day',
                                style: LiquidGlassTheme.label.copyWith(
                                  color: LiquidGlassTheme.accentPrimary,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _wotd!['word'] ?? '',
                            style: LiquidGlassTheme.headingSm,
                          ),
                          const SizedBox(height: 6),
                          Builder(builder: (_) {
                            final def = _wotd!['definition'];
                            String text = '';
                            if (def is Map) {
                              final defs = def['definitions'] as List?;
                              text = (defs != null && defs.isNotEmpty)
                                  ? defs.first.toString()
                                  : '';
                            } else if (def != null) {
                              text = def.toString();
                            }
                            if (text.isEmpty) return const SizedBox.shrink();
                            return Text(
                              text,
                              style: LiquidGlassTheme.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            );
                          }),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms, duration: 500.ms)
                     .slideY(begin: 0.06, end: 0),
                  ),

                if (_wotd != null && _stats != null) const SizedBox(width: 14),

                // ── Quick Stats Column ──
                if (_stats != null && _stats!.isNotEmpty)
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _QuickStat(
                          icon: Icons.menu_book_rounded,
                          label: 'Dictionary',
                          value: '${_stats!['dictionary_size'] ?? 0}',
                        ),
                        const SizedBox(height: 10),
                        _QuickStat(
                          icon: Icons.local_fire_department_rounded,
                          label: 'Streak',
                          value: '${(_stats!['learning'] as Map?)?['streak_days'] ?? 0}d',
                        ),
                        const SizedBox(height: 10),
                        _QuickStat(
                          icon: Icons.bolt_rounded,
                          label: 'EXP',
                          value: '${(_stats!['learning'] as Map?)?['total_exp'] ?? 0}',
                        ),
                      ],
                    ).animate().fadeIn(delay: 500.ms, duration: 400.ms)
                     .slideY(begin: 0.05, end: 0),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _QuickStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      borderRadius: LiquidGlassTheme.borderRadiusSm,
      child: Row(
        children: [
          Icon(icon, size: 18, color: LiquidGlassTheme.accentPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: LiquidGlassTheme.headingSm.copyWith(fontSize: 16)),
                Text(label, style: LiquidGlassTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

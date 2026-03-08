/// LexiCore — Home Page (v5.1)
/// Personalized welcome text with username, centered search, WOTD only.
/// - WOTD uses online mode with 2-hour rotation
/// - WOTD hidden when user queries a word
/// - Refresh button to manually rotate WOTD
/// - Real-time autocomplete on every character typed
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
  bool _isLoading = false;
  bool _isSaved = false;
  String _userName = '';
  bool _wotdRefreshing = false;

  // Personalized welcome messages — {name} will be replaced with username
  static const _welcomeTemplates = [
    '{name} returns! 🎉',
    '{name}, wanna search something great?',
    'Welcome back, {name}! Ready to learn? ✨',
    '{name}, let\'s discover a new word today!',
    'Hey {name}! What word catches your eye? 👀',
    '{name}, your vocabulary journey continues... 🚀',
    'Good to see you, {name}! Let\'s explore 🔍',
    '{name}, every word is a small victory 💡',
  ];

  late final String _welcomeText;

  @override
  void initState() {
    super.initState();
    _engine.connectWebSocket();
    _welcomeText = _welcomeTemplates[Random().nextInt(_welcomeTemplates.length)];
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await _engine.getProfile();
    final wotd = await _engine.getWordOfTheDay(mode: 'online', hours: 2);

    // Award daily login XP
    await _engine.awardXp('daily_login');

    if (mounted) {
      setState(() {
        _userName = profile['display_name']?.toString() ?? 'Learner';
        _wotd = wotd;
      });
    }
  }

  Future<void> _refreshWotd() async {
    setState(() => _wotdRefreshing = true);
    // Use a slightly different hour window to get a new word
    final rng = Random();
    final wotd = await _engine.getWordOfTheDay(mode: 'online', hours: 1 + rng.nextInt(3));
    if (mounted) {
      setState(() {
        _wotd = wotd;
        _wotdRefreshing = false;
      });
    }
  }

  String get _personalizedWelcome => _welcomeText.replaceAll('{name}', _userName.isEmpty ? 'Learner' : _userName);

  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _isLoading = true; _suggestions = []; });

    var result = await _engine.searchExact(query);
    if (!result.found) {
      result = await _engine.searchOnline(query);
    }

    // Award XP for searching
    await _engine.awardXp('search');

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
    if (ok) {
      await _engine.awardXp('save');
      if (mounted) setState(() => _isSaved = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasResult = _result != null && _result!.found;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
      child: Column(
        children: [
          // ── Personalized Welcome + Search ──
          SizedBox(
            height: hasResult ? 160 : 300,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    _personalizedWelcome,
                    key: ValueKey(_personalizedWelcome),
                    style: LiquidGlassTheme.heading.copyWith(
                      fontSize: hasResult ? 18 : 26,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(duration: 600.ms),
                SizedBox(height: hasResult ? 14 : 24),
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

          // ── Return Button ──
          if (hasResult)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () => setState(() {
                  _result = null;
                  _isSaved = false;
                }),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 16, color: LiquidGlassTheme.accentPrimary),
                    const SizedBox(width: 6),
                    Text('Back to home', style: LiquidGlassTheme.bodySmall.copyWith(
                      color: LiquidGlassTheme.accentPrimary,
                      fontWeight: FontWeight.w600,
                    )),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),
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
                            _result!.source == 'online' ? 'Online result' : 'Local dictionary',
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

          // ── Word of the Day (hidden when user has queried a word) ──
          if (!hasResult && _wotd != null && _wotd!['word'] != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: GestureDetector(
                onTap: () {
                  final word = _wotd!['word']?.toString();
                  if (word != null && word.isNotEmpty) _onSearch(word);
                },
                child: GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('✨', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Word of the Day',
                              style: LiquidGlassTheme.label.copyWith(
                                color: LiquidGlassTheme.accentPrimary,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _wotdRefreshing ? null : () {
                              // Stop propagation to parent
                              _refreshWotd();
                            },
                            child: AnimatedRotation(
                              turns: _wotdRefreshing ? 1 : 0,
                              duration: const Duration(milliseconds: 500),
                              child: Icon(
                                Icons.refresh_rounded,
                                size: 18,
                                color: _wotdRefreshing
                                    ? LiquidGlassTheme.textMuted
                                    : LiquidGlassTheme.accentPrimary.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_wotd!['source'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                _wotd!['source'] == 'online' ? Icons.cloud_outlined : Icons.storage_outlined,
                                size: 11,
                                color: LiquidGlassTheme.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Rotates every ${_wotd!['rotation_hours'] ?? 2}h',
                                style: LiquidGlassTheme.bodySmall.copyWith(
                                  fontSize: 10,
                                  color: LiquidGlassTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 14),
                      Text(
                        _wotd!['word']?.toString() ?? '',
                        style: LiquidGlassTheme.headingSm.copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.4),
                          decorationStyle: TextDecorationStyle.dotted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Builder(builder: (_) {
                        final def = _wotd!['definition'];
                        String text = '';
                        if (def is Map) {
                          final defs = def['definitions'] as List?;
                          text = (defs != null && defs.isNotEmpty)
                              ? defs.first.toString() : '';
                        } else if (def != null) {
                          text = def.toString();
                        }
                        if (text.isEmpty) return const SizedBox.shrink();
                        return Text(
                          text,
                          style: LiquidGlassTheme.body,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        );
                      }),
                      const SizedBox(height: 8),
                      Text(
                        'Tap anywhere to explore full definition →',
                        style: LiquidGlassTheme.bodySmall.copyWith(
                          color: LiquidGlassTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 500.ms)
               .slideY(begin: 0.06, end: 0),
            ),
        ],
      ),
    );
  }
}

/// LexiCore Engine — Liquid Glass Desktop App
/// Main entry point with Acrylic window + full search UI.
library;

import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'theme/liquid_glass_theme.dart';
import 'services/engine_service.dart';
import 'widgets/glass_panel.dart';
import 'widgets/search_bar.dart' as lexi;
import 'widgets/definition_card.dart';
import 'widgets/autocomplete_dropdown.dart';
import 'widgets/stats_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Window.initialize();
  await Window.setEffect(
    effect: WindowEffect.acrylic,
    color: const Color(0xCC0A0A12),
    dark: true,
  );
  await Window.setWindowBackgroundColorToClear();
  runApp(const LexiCoreApp());
}

class LexiCoreApp extends StatelessWidget {
  const LexiCoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LexiCore Engine',
      debugShowCheckedModeBanner: false,
      theme: LiquidGlassTheme.dark,
      home: const LexiCoreHome(),
    );
  }
}

class LexiCoreHome extends StatefulWidget {
  const LexiCoreHome({super.key});

  @override
  State<LexiCoreHome> createState() => _LexiCoreHomeState();
}

class _LexiCoreHomeState extends State<LexiCoreHome>
    with TickerProviderStateMixin {
  final _engine = EngineService();

  // State
  SearchResult? _currentResult;
  List<String> _suggestions = [];
  double _autocompleteTimingMs = 0;
  bool _isSearching = false;
  bool _isWordSaved = false;

  // Stats
  int _dictSize = 0;
  int _streakDays = 0;
  int _totalExp = 0;
  double _cacheHitRate = 0;

  // Word of the Day
  String? _wotdWord;
  Map<String, dynamic>? _wotdDef;

  @override
  void initState() {
    super.initState();
    _engine.connectWebSocket();
    _loadStats();
    _loadWotd();

    // Listen to WebSocket autocomplete
    _engine.autocompleteStream.listen((result) {
      if (mounted) {
        setState(() {
          _suggestions = result.suggestions;
          _autocompleteTimingMs = result.timingMs;
        });
      }
    });
  }

  Future<void> _loadStats() async {
    final stats = await _engine.getStats();
    if (mounted && stats.isNotEmpty) {
      setState(() {
        _dictSize = stats['dictionary_size'] ?? 0;
        final learning = stats['learning'] as Map<String, dynamic>? ?? {};
        _streakDays = learning['streak_days'] ?? 0;
        _totalExp = learning['total_exp'] ?? 0;
        final cache = stats['cache'] as Map<String, dynamic>? ?? {};
        _cacheHitRate = (cache['hit_rate'] ?? 0).toDouble();
      });
    }
  }

  Future<void> _loadWotd() async {
    final data = await _engine.getWordOfTheDay();
    if (mounted && data != null) {
      setState(() {
        _wotdWord = data['word'];
        _wotdDef = data['definition'];
      });
    }
  }

  void _onSearchChanged(String value) {
    if (value.length >= 2) {
      _engine.sendAutocomplete(value);
    } else {
      setState(() => _suggestions = []);
    }
  }

  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
      _suggestions = [];
    });

    final result = await _engine.searchExact(query);

    if (!result.found) {
      // Try fuzzy
      final fuzzy = await _engine.searchFuzzy(query);
      if (fuzzy.isNotEmpty) {
        final fuzzyResult = await _engine.searchExact(fuzzy.first);
        setState(() {
          _currentResult = fuzzyResult.found ? fuzzyResult : null;
          _isSearching = false;
        });
        return;
      }
    }

    setState(() {
      _currentResult = result.found ? result : null;
      _isSearching = false;
      _isWordSaved = false;
    });
    _loadStats(); // refresh stats
  }

  void _onSuggestionSelected(String word) {
    _onSearch(word);
  }

  Future<void> _onSaveWord() async {
    if (_currentResult == null) return;
    final success = await _engine.saveWord(
      _currentResult!.word,
      definition: _currentResult!.definitions.join('; '),
    );
    if (success && mounted) {
      setState(() => _isWordSaved = true);
    }
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            LiquidGlassTheme.bgGradientStart,
            LiquidGlassTheme.bgGradientEnd,
            Color(0xFF0F0A1A),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Background ambient orbs
            ..._buildAmbientOrbs(),

            // Main content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                child: Column(
                  children: [
                    // Header
                    _buildHeader(),
                    const SizedBox(height: 24),

                    // Search bar
                    lexi.SearchBar(
                      onSearch: _onSearch,
                      onChanged: _onSearchChanged,
                      isLoading: _isSearching,
                    ),

                    // Autocomplete
                    if (_suggestions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: AutocompleteDropdown(
                          suggestions: _suggestions,
                          onSelect: _onSuggestionSelected,
                          timingMs: _autocompleteTimingMs,
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Content area
                    Expanded(
                      child: SingleChildScrollView(
                        child: _currentResult != null
                            ? DefinitionCard(
                                result: _currentResult!,
                                onSave: _onSaveWord,
                                isSaved: _isWordSaved,
                              )
                            : _buildWelcome(),
                      ),
                    ),

                    // Stats bar
                    const SizedBox(height: 12),
                    StatsOverlay(
                      dictionarySize: _dictSize,
                      streakDays: _streakDays,
                      totalExp: _totalExp,
                      cacheHitRate: _cacheHitRate,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Logo
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                LiquidGlassTheme.accentPrimary.withValues(alpha: 0.3),
                LiquidGlassTheme.accentSecondary.withValues(alpha: 0.2),
              ],
            ),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: LiquidGlassTheme.accentPrimary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'LexiCore',
          style: LiquidGlassTheme.headingSm.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'v2.0',
          style: LiquidGlassTheme.mono.copyWith(
            fontSize: 11,
            color: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.7),
          ),
        ),
        const Spacer(),
        // Engine status indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: LiquidGlassTheme.glassBorder),
            color: LiquidGlassTheme.glassFill,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _dictSize > 0 ? Colors.green : Colors.orange,
                  boxShadow: [
                    BoxShadow(
                      color: (_dictSize > 0 ? Colors.green : Colors.orange).withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _dictSize > 0 ? 'Engine Online' : 'Connecting...',
                style: LiquidGlassTheme.bodySmall.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildWelcome() {
    return Column(
      children: [
        const SizedBox(height: 40),
        // Animated logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                LiquidGlassTheme.accentPrimary.withValues(alpha: 0.2),
                Colors.transparent,
              ],
            ),
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 40,
            color: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.6),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 2000.ms),
        const SizedBox(height: 20),
        Text(
          'Search any word',
          style: LiquidGlassTheme.headingSm.copyWith(
            color: LiquidGlassTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Real-time autocomplete  •  Fuzzy matching  •  Phonetic search',
          style: LiquidGlassTheme.bodySmall,
          textAlign: TextAlign.center,
        ),

        // Word of the Day
        if (_wotdWord != null) ...[
          const SizedBox(height: 30),
          GlassPanel(
            borderRadius: LiquidGlassTheme.borderRadiusSm,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.today_rounded, size: 14,
                      color: LiquidGlassTheme.accentTertiary.withValues(alpha: 0.8)),
                    const SizedBox(width: 6),
                    Text('Word of the Day', style: LiquidGlassTheme.bodySmall.copyWith(
                      color: LiquidGlassTheme.accentTertiary,
                      fontWeight: FontWeight.w600,
                    )),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _onSearch(_wotdWord!),
                  child: Text(
                    _wotdWord!,
                    style: LiquidGlassTheme.heading.copyWith(fontSize: 24),
                  ),
                ),
                if (_wotdDef != null && _wotdDef!['definitions'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      (_wotdDef!['definitions'] as List).first.toString(),
                      style: LiquidGlassTheme.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
        ],
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  List<Widget> _buildAmbientOrbs() {
    return [
      Positioned(
        top: -100,
        right: -50,
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                LiquidGlassTheme.accentPrimary.withValues(alpha: 0.08),
                Colors.transparent,
              ],
            ),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 4000.ms),
      ),
      Positioned(
        bottom: -80,
        left: -60,
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                LiquidGlassTheme.accentSecondary.withValues(alpha: 0.06),
                Colors.transparent,
              ],
            ),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .scale(begin: const Offset(1.1, 1.1), end: const Offset(0.9, 0.9), duration: 5000.ms),
      ),
      Positioned(
        top: 200,
        left: 100,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                LiquidGlassTheme.accentTertiary.withValues(alpha: 0.04),
                Colors.transparent,
              ],
            ),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 3000.ms),
      ),
    ];
  }
}

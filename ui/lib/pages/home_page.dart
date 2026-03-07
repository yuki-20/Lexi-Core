/// LexiCore — Home Page
/// Main dashboard with welcome banner, search, WOTD, and quick actions.
library;

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
  String _welcomeMsg = '';
  bool _isLoading = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _engine.connectWebSocket();
    _loadData();
  }

  Future<void> _loadData() async {
    final welcome = await _engine.getWelcome();
    final stats = await _engine.getStats();
    final wotd = await _engine.getWordOfTheDay();
    if (mounted) {
      setState(() {
        _welcomeMsg = welcome['message'] ?? 'Welcome!';
        _stats = stats;
        _wotd = wotd;
      });
    }
  }

  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _isLoading = true; _suggestions = []; });

    var result = await _engine.searchExact(query);

    // Online fallback
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Welcome Banner ──
          Text(
            _welcomeMsg,
            style: LiquidGlassTheme.heading.copyWith(fontSize: 26),
          ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.05, end: 0),
          const SizedBox(height: 4),
          Text(
            'What would you like to learn today?',
            style: LiquidGlassTheme.body,
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
          const SizedBox(height: 24),

          // ── Search Bar ──
          lexi.SearchBar(
            onSearch: _onSearch,
            onChanged: _onSearchChanged,
            isLoading: _isLoading,
          ),

          // ── Autocomplete ──
          if (_suggestions.isNotEmpty)
            AutocompleteDropdown(
              suggestions: _suggestions,
              onSelect: (word) {
                setState(() => _suggestions = []);
                _onSearch(word);
              },
            ),

          const SizedBox(height: 20),

          // ── Definition Card ──
          if (_result != null && _result!.found)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefinitionCard(
                  result: _result!,
                  onSave: _onSaveWord,
                  isSaved: _isSaved,
                ),
                if (_result!.source != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
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
                    ).animate().fadeIn(delay: 300.ms),
                  ),
              ],
            ),

          // ── Word of the Day ──
          if (_wotd != null && _wotd!['word'] != null) ...[
            const SizedBox(height: 24),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text('Word of the Day',
                        style: LiquidGlassTheme.label.copyWith(
                          color: LiquidGlassTheme.accentPrimary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _wotd!['word'] ?? '',
                    style: LiquidGlassTheme.headingSm,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 500.ms)
             .slideY(begin: 0.1, end: 0),
          ],

          // ── Quick Stats ──
          if (_stats != null && _stats!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                _QuickStat(
                  icon: Icons.menu_book_rounded,
                  label: 'Words',
                  value: '${_stats!['dictionary_size'] ?? 0}',
                ),
                const SizedBox(width: 12),
                _QuickStat(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Streak',
                  value: '${(_stats!['learning'] as Map?)?['streak_days'] ?? 0}d',
                ),
                const SizedBox(width: 12),
                _QuickStat(
                  icon: Icons.bolt_rounded,
                  label: 'EXP',
                  value: '${(_stats!['learning'] as Map?)?['total_exp'] ?? 0}',
                ),
              ],
            ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
          ],
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
    return Expanded(
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        borderRadius: LiquidGlassTheme.borderRadiusSm,
        child: Column(
          children: [
            Icon(icon, size: 22, color: LiquidGlassTheme.accentPrimary),
            const SizedBox(height: 6),
            Text(value, style: LiquidGlassTheme.headingSm.copyWith(fontSize: 16)),
            Text(label, style: LiquidGlassTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

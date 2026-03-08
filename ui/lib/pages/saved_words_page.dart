/// LexiCore — Saved Words & File Manager Page (v5.5)
/// Browse saved words with Digested/Undigested separation,
/// background definition fetching with progress bar.
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../theme/liquid_glass_theme.dart';
import '../services/engine_service.dart';
import '../widgets/glass_panel.dart';

class SavedWordsPage extends StatefulWidget {
  const SavedWordsPage({super.key});

  @override
  State<SavedWordsPage> createState() => _SavedWordsPageState();
}

class _SavedWordsPageState extends State<SavedWordsPage> with SingleTickerProviderStateMixin {
  final _engine = EngineService();
  late TabController _tabController;
  List<Map<String, dynamic>> _allWords = [];
  List<Map<String, dynamic>> _importedFiles = [];
  bool _isImporting = false;

  // Digest state
  bool _isDigesting = false;
  double _digestProgress = 0;
  int _digestCurrent = 0;
  int _digestTotal = 0;
  String _digestingWord = '';

  List<Map<String, dynamic>> get _digested =>
      _allWords.where((w) => w['definition'] != null && w['definition'].toString().isNotEmpty).toList();

  List<Map<String, dynamic>> get _undigested =>
      _allWords.where((w) => w['definition'] == null || w['definition'].toString().isEmpty).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _engine.waitForReady();
    final words = await _engine.getSavedWords();
    final files = await _engine.getImportedFiles();
    if (mounted) {
      setState(() {
        _allWords = words;
        _importedFiles = files;
      });
    }
  }

  Future<void> _deleteWord(String word) async {
    await _engine.deleteSavedWord(word);
    _loadData();
  }

  Future<void> _deleteFile(int fileId) async {
    await _engine.deleteImportedFile(fileId);
    _loadData();
  }

  Future<void> _importFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'json'],
    );
    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null) return;

    setState(() => _isImporting = true);
    final response = await _engine.importFile(path);
    setState(() => _isImporting = false);

    if (mounted) {
      if (response != null && response['words_imported'] != null) {
        // Cleanup any comma-separated entries
        try {
          await http.post(Uri.parse('http://127.0.0.1:8741/api/saved/cleanup'));
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported ${response['words_imported']} words!')),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response?['error']?.toString() ?? 'Import failed')),
        );
      }
    }
  }

  Future<void> _digestAll() async {
    if (_isDigesting) return;
    final undigestedCount = _undigested.length;
    if (undigestedCount == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All words already have definitions!')),
        );
      }
      return;
    }

    setState(() {
      _isDigesting = true;
      _digestProgress = 0;
      _digestCurrent = 0;
      _digestTotal = undigestedCount;
      _digestingWord = '';
    });

    try {
      final request = http.Request(
        'POST',
        Uri.parse('http://127.0.0.1:8741/api/saved/digest'),
      );
      final streamedResponse = await http.Client().send(request);

      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          if (line.startsWith('data: ')) {
            try {
              final data = jsonDecode(line.substring(6));
              if (data['done'] == true) {
                // Done!
                if (mounted) {
                  setState(() {
                    _isDigesting = false;
                    _digestProgress = 1.0;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Digested ${data['found']}/${data['total']} words'),
                    ),
                  );
                  _loadData();
                }
              } else {
                if (mounted) {
                  setState(() {
                    _digestProgress = (data['progress'] as num).toDouble() / 100;
                    _digestCurrent = (data['current'] as num).toInt();
                    _digestTotal = (data['total'] as num).toInt();
                    _digestingWord = data['word']?.toString() ?? '';
                  });
                }
              }
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDigesting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Digest failed')),
        );
      }
    }
  }

  Future<void> _createDeckFromSaved() async {
    if (_allWords.isEmpty) return;
    final words = _allWords.map((w) => w['word'] as String).toList();
    await _engine.createDeckFromWords('My Saved Words', words);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deck created from saved words!')),
      );
    }
  }

  Future<void> _addToDictionary() async {
    final result = await _engine.addSavedToDictionary();
    final added = result['added'] ?? 0;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          added > 0
              ? '📖 Added $added words to dictionary!'
              : '📖 All saved words are already in dictionary',
        )),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final digestedCount = _digested.length;
    final undigestedCount = _undigested.length;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Row(
            children: [
              Expanded(child: Text('My Words', style: LiquidGlassTheme.heading)),
              if (_allWords.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: _addToDictionary,
                    child: GlassPanel(
                      borderRadius: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.menu_book_rounded, size: 16, color: LiquidGlassTheme.accentPrimary),
                          const SizedBox(width: 4),
                          Text('Dict', style: LiquidGlassTheme.label.copyWith(
                            fontSize: 11,
                            color: LiquidGlassTheme.accentPrimary,
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GlassPanel(
                    borderRadius: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: GestureDetector(
                      onTap: _createDeckFromSaved,
                      child: const Icon(Icons.style_outlined, size: 18, color: LiquidGlassTheme.accentPrimary),
                    ),
                  ),
                ),
              ],
              GlassPanel(
                borderRadius: 20,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: GestureDetector(
                  onTap: _isImporting ? null : _importFile,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isImporting)
                        const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: LiquidGlassTheme.accentPrimary),
                        )
                      else
                        const Icon(Icons.upload_file_rounded, size: 18, color: LiquidGlassTheme.accentSecondary),
                      const SizedBox(width: 6),
                      Text('Import', style: LiquidGlassTheme.label.copyWith(color: LiquidGlassTheme.accentSecondary)),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
        ),

        // Digest progress bar
        if (_isDigesting)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: GlassPanel(
              padding: const EdgeInsets.all(14),
              borderRadius: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: LiquidGlassTheme.accentPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Digesting: $_digestingWord  ($_digestCurrent/$_digestTotal)',
                          style: LiquidGlassTheme.bodySmall.copyWith(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${(_digestProgress * 100).round()}%',
                        style: LiquidGlassTheme.label.copyWith(
                          color: LiquidGlassTheme.accentPrimary, fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _digestProgress,
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      valueColor: const AlwaysStoppedAnimation(LiquidGlassTheme.accentPrimary),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
          ),

        // Tab bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GlassPanel(
            borderRadius: 30,
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                color: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.2),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: LiquidGlassTheme.accentPrimary,
              unselectedLabelColor: LiquidGlassTheme.textMuted,
              labelStyle: LiquidGlassTheme.label,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: 'All (${_allWords.length})'),
                Tab(text: '✅ Digested ($digestedCount)'),
                Tab(text: '⏳ Undigested ($undigestedCount)'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildWordList(_allWords),
              _buildWordList(_digested),
              _buildUndigestedTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUndigestedTab() {
    final list = _undigested;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, size: 56, color: LiquidGlassTheme.accentPrimary),
                const SizedBox(height: 16),
                Text('All caught up!', style: LiquidGlassTheme.headingSm),
                const SizedBox(height: 8),
                Text('Every word has a definition', style: LiquidGlassTheme.bodySmall),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
        ),
      );
    }

    return Column(
      children: [
        // Digest All button
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: GestureDetector(
            onTap: _isDigesting ? null : _digestAll,
            child: GlassPanel(
              borderRadius: 14,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_fix_high_rounded,
                    size: 18,
                    color: _isDigesting
                        ? LiquidGlassTheme.textMuted
                        : LiquidGlassTheme.accentPrimary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isDigesting
                        ? 'Digesting...'
                        : 'Digest All ${list.length} Words',
                    style: LiquidGlassTheme.label.copyWith(
                      color: _isDigesting
                          ? LiquidGlassTheme.textMuted
                          : LiquidGlassTheme.accentPrimary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
          ),
        ),

        // Word list
        Expanded(child: _buildWordList(list)),
      ],
    );
  }

  Widget _buildWordList(List<Map<String, dynamic>> words) {
    if (words.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bookmark_border_rounded, size: 56, color: LiquidGlassTheme.textMuted),
                const SizedBox(height: 16),
                Text('No words here', style: LiquidGlassTheme.headingSm),
                const SizedBox(height: 8),
                Text('Import a file or search for words!', style: LiquidGlassTheme.bodySmall),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        final hasDefinition = word['definition'] != null && word['definition'].toString().isNotEmpty;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            borderRadius: LiquidGlassTheme.borderRadiusSm,
            child: Row(
              children: [
                // Status icon
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: hasDefinition
                        ? LiquidGlassTheme.accentPrimary.withValues(alpha: 0.12)
                        : Colors.orange.withValues(alpha: 0.12),
                  ),
                  child: Center(
                    child: hasDefinition
                        ? Text(
                            (word['word'] ?? '?')[0].toUpperCase(),
                            style: LiquidGlassTheme.headingSm.copyWith(
                              fontSize: 16, color: LiquidGlassTheme.accentPrimary,
                            ),
                          )
                        : const Icon(Icons.help_outline_rounded, size: 18, color: Colors.orange),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        word['word'] ?? '',
                        style: LiquidGlassTheme.headingSm.copyWith(fontSize: 15),
                      ),
                      if (hasDefinition)
                        Text(
                          word['definition'],
                          style: LiquidGlassTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          'No definition yet',
                          style: LiquidGlassTheme.bodySmall.copyWith(
                            color: Colors.orange.withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      if (word['source_file'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.attach_file_rounded, size: 10, color: LiquidGlassTheme.accentSecondary),
                              const SizedBox(width: 4),
                              Text(
                                word['source_file'],
                                style: LiquidGlassTheme.mono.copyWith(
                                  fontSize: 9, color: LiquidGlassTheme.accentSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: LiquidGlassTheme.textMuted),
                  onPressed: () => _deleteWord(word['word']),
                ),
              ],
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 20 * (index % 20)), duration: 300.ms)
           .slideX(begin: 0.03, end: 0),
        );
      },
    );
  }
}

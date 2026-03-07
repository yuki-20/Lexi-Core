/// LexiCore — Saved Words & File Manager Page
/// Browse saved words, import files, manage word sources.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  List<Map<String, dynamic>> _savedWords = [];
  List<Map<String, dynamic>> _importedFiles = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final words = await _engine.getSavedWords();
    final files = await _engine.getImportedFiles();
    if (mounted) {
      setState(() {
        _savedWords = words;
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

  Future<void> _createDeckFromSaved() async {
    if (_savedWords.isEmpty) return;
    final words = _savedWords.map((w) => w['word'] as String).toList();
    await _engine.createDeckFromWords(
      'My Saved Words',
      words,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deck created from saved words!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            children: [
              Expanded(child: Text('My Words', style: LiquidGlassTheme.heading)),
              if (_savedWords.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.style_outlined, color: LiquidGlassTheme.accentPrimary, size: 22),
                  tooltip: 'Create Flashcard Deck',
                  onPressed: _createDeckFromSaved,
                ),
            ],
          ).animate().fadeIn(duration: 400.ms),
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
                Tab(text: 'Saved (${_savedWords.length})'),
                Tab(text: 'Imported (${_importedFiles.length})'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSavedList(),
              _buildImportedList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSavedList() {
    if (_savedWords.isEmpty) {
      return Center(
        child: GlassPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bookmark_border_rounded, size: 48, color: LiquidGlassTheme.textMuted),
              const SizedBox(height: 12),
              Text('No saved words yet', style: LiquidGlassTheme.body),
              const SizedBox(height: 6),
              Text('Search for words and save them!', style: LiquidGlassTheme.bodySmall),
            ],
          ),
        ).animate().fadeIn(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      itemCount: _savedWords.length,
      itemBuilder: (context, index) {
        final word = _savedWords[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            borderRadius: LiquidGlassTheme.borderRadiusSm,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(word['word'] ?? '', style: LiquidGlassTheme.headingSm.copyWith(fontSize: 15)),
                      if (word['definition'] != null)
                        Text(
                          word['definition'],
                          style: LiquidGlassTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (word['source_file'] != null)
                        Text(
                          'From: ${word['source_file']}',
                          style: LiquidGlassTheme.mono.copyWith(fontSize: 10, color: LiquidGlassTheme.accentSecondary),
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
          ).animate().fadeIn(delay: Duration(milliseconds: 50 * index), duration: 300.ms),
        );
      },
    );
  }

  Widget _buildImportedList() {
    if (_importedFiles.isEmpty) {
      return Center(
        child: GlassPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.upload_file_rounded, size: 48, color: LiquidGlassTheme.textMuted),
              const SizedBox(height: 12),
              Text('No imported files', style: LiquidGlassTheme.body),
              const SizedBox(height: 6),
              Text('Import a .txt or .json file with words', style: LiquidGlassTheme.bodySmall),
            ],
          ),
        ).animate().fadeIn(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      itemCount: _importedFiles.length,
      itemBuilder: (context, index) {
        final file = _importedFiles[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            borderRadius: LiquidGlassTheme.borderRadiusSm,
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: LiquidGlassTheme.accentSecondary.withValues(alpha: 0.15),
                  ),
                  child: const Center(
                    child: Icon(Icons.description_rounded, color: LiquidGlassTheme.accentSecondary, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(file['filename'] ?? '', style: LiquidGlassTheme.headingSm.copyWith(fontSize: 14)),
                      Text('${file['word_count'] ?? 0} words', style: LiquidGlassTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: LiquidGlassTheme.textMuted),
                  onPressed: () => _deleteFile(file['id']),
                ),
              ],
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 50 * index), duration: 300.ms),
        );
      },
    );
  }
}

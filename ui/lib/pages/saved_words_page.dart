/// LexiCore — Saved Words & File Manager Page (v3.1)
/// Browse saved words, import files via file_picker, manage word sources.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
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
  bool _isImporting = false;

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
      if (response != null && response['status'] == 'imported') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported ${response['word_count']} words!')),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response?['error'] ?? 'Import failed')),
        );
      }
    }
  }

  Future<void> _createDeckFromSaved() async {
    if (_savedWords.isEmpty) return;
    final words = _savedWords.map((w) => w['word'] as String).toList();
    await _engine.createDeckFromWords('My Saved Words', words);
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
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Row(
            children: [
              Expanded(child: Text('My Words', style: LiquidGlassTheme.heading)),
              if (_savedWords.isNotEmpty)
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

        const SizedBox(height: 16),

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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bookmark_border_rounded, size: 56, color: LiquidGlassTheme.textMuted),
                const SizedBox(height: 16),
                Text('No saved words yet', style: LiquidGlassTheme.headingSm),
                const SizedBox(height: 8),
                Text('Search for words and save them!', style: LiquidGlassTheme.bodySmall),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      itemCount: _savedWords.length,
      itemBuilder: (context, index) {
        final word = _savedWords[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            borderRadius: LiquidGlassTheme.borderRadiusSm,
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.12),
                  ),
                  child: Center(
                    child: Text(
                      (word['word'] ?? '?')[0].toUpperCase(),
                      style: LiquidGlassTheme.headingSm.copyWith(
                        fontSize: 16, color: LiquidGlassTheme.accentPrimary,
                      ),
                    ),
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
                      if (word['definition'] != null)
                        Text(
                          word['definition'],
                          style: LiquidGlassTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
          ).animate().fadeIn(delay: Duration(milliseconds: 40 * index), duration: 300.ms)
           .slideX(begin: 0.03, end: 0),
        );
      },
    );
  }

  Widget _buildImportedList() {
    if (_importedFiles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.upload_file_rounded, size: 56, color: LiquidGlassTheme.textMuted),
                const SizedBox(height: 16),
                Text('No imported files', style: LiquidGlassTheme.headingSm),
                const SizedBox(height: 8),
                Text('Tap Import to add a .txt or .json file', style: LiquidGlassTheme.bodySmall),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      itemCount: _importedFiles.length,
      itemBuilder: (context, index) {
        final file = _importedFiles[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            borderRadius: LiquidGlassTheme.borderRadiusSm,
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: LiquidGlassTheme.accentSecondary.withValues(alpha: 0.12),
                  ),
                  child: const Center(
                    child: Icon(Icons.description_rounded, color: LiquidGlassTheme.accentSecondary, size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file['filename'] ?? '',
                        style: LiquidGlassTheme.headingSm.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${file['word_count'] ?? 0} words imported',
                        style: LiquidGlassTheme.bodySmall,
                      ),
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

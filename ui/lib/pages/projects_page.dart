/// LexiCore — Projects Page
/// Create and manage learning projects with color coding.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/liquid_glass_theme.dart';
import '../services/engine_service.dart';
import '../widgets/glass_panel.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final _engine = EngineService();
  List<Map<String, dynamic>> _projects = [];
  bool _loading = true;

  static const _projectColors = [
    '#7C4DFF', '#00BCD4', '#FF4081', '#FF9100',
    '#69F0AE', '#448AFF', '#FF5252', '#FFD740',
  ];

  static const _projectIcons = [
    'folder', 'book', 'science', 'language',
    'school', 'code', 'music', 'art',
  ];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _loading = true);
    final projects = await _engine.getProjects();
    if (mounted) {
      setState(() {
        _projects = projects;
        _loading = false;
      });
    }
  }

  IconData _iconForName(String name) {
    switch (name) {
      case 'book': return Icons.menu_book_rounded;
      case 'science': return Icons.science_rounded;
      case 'language': return Icons.language_rounded;
      case 'school': return Icons.school_rounded;
      case 'code': return Icons.code_rounded;
      case 'music': return Icons.music_note_rounded;
      case 'art': return Icons.palette_rounded;
      default: return Icons.folder_rounded;
    }
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return LiquidGlassTheme.accentPrimary;
    }
  }

  Future<void> _createProject() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedColor = _projectColors[0];
    String selectedIcon = _projectIcons[0];

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: LiquidGlassTheme.bgDeep,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('New Project', style: LiquidGlassTheme.headingSm),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  style: LiquidGlassTheme.body.copyWith(color: LiquidGlassTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Project name',
                    hintStyle: LiquidGlassTheme.body,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  style: LiquidGlassTheme.body.copyWith(color: LiquidGlassTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Description (optional)',
                    hintStyle: LiquidGlassTheme.body,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Text('Color', style: LiquidGlassTheme.label),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _projectColors.map((c) {
                    final isSelected = selectedColor == c;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = c),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _parseColor(c),
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2.5)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Icon', style: LiquidGlassTheme.label),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _projectIcons.map((icon) {
                    final isSelected = selectedIcon == icon;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIcon = icon),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: isSelected
                              ? _parseColor(selectedColor).withValues(alpha: 0.2)
                              : LiquidGlassTheme.glassFill,
                          border: isSelected
                              ? Border.all(color: _parseColor(selectedColor))
                              : null,
                        ),
                        child: Center(
                          child: Icon(
                            _iconForName(icon),
                            size: 20,
                            color: isSelected
                                ? _parseColor(selectedColor)
                                : LiquidGlassTheme.textMuted,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, {
                'name': nameController.text,
                'description': descController.text,
                'color': selectedColor,
                'icon': selectedIcon,
              }),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (result != null && result['name']!.isNotEmpty) {
      await _engine.createProject(
        result['name']!,
        description: result['description'] ?? '',
        color: result['color'] ?? '#7C4DFF',
        icon: result['icon'] ?? 'folder',
      );
      _loadProjects();
    }
  }

  Future<void> _renameProject(Map<String, dynamic> project) async {
    final controller = TextEditingController(text: project['name']?.toString() ?? '');
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LiquidGlassTheme.bgDeep,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Rename Project', style: LiquidGlassTheme.headingSm),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: LiquidGlassTheme.body.copyWith(color: LiquidGlassTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'New name',
            hintStyle: LiquidGlassTheme.body,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null && newName.trim().isNotEmpty) {
      await _engine.updateProject(project['id'], name: newName.trim());
      _loadProjects();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Projects', style: LiquidGlassTheme.heading),
              ),
              GlassPanel(
                borderRadius: 30,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GestureDetector(
                  onTap: _createProject,
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
          const SizedBox(height: 8),
          Text(
            'Organize your learning into projects',
            style: LiquidGlassTheme.bodySmall,
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 24),

          if (_loading)
            const Center(child: CircularProgressIndicator(color: LiquidGlassTheme.accentPrimary))
          else if (_projects.isEmpty)
            Center(
              child: GlassPanel(
                child: Column(
                  children: [
                    const Icon(Icons.folder_open_rounded, size: 56, color: LiquidGlassTheme.textMuted),
                    const SizedBox(height: 16),
                    Text('No projects yet', style: LiquidGlassTheme.headingSm),
                    const SizedBox(height: 8),
                    Text(
                      'Create a project to group your\nflashcard decks and quizzes',
                      style: LiquidGlassTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0)
          else
            ..._projects.asMap().entries.map((entry) {
              final project = entry.value;
              final color = _parseColor(project['color'] ?? '#7C4DFF');
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GlassPanel(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                colors: [
                                  color.withValues(alpha: 0.35),
                                  color.withValues(alpha: 0.15),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                _iconForName(project['icon'] ?? 'folder'),
                                color: color,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  project['name'] ?? 'Untitled',
                                  style: LiquidGlassTheme.headingSm.copyWith(fontSize: 17),
                                ),
                                if (project['description'] != null && project['description'].toString().isNotEmpty)
                                  Text(
                                    project['description'],
                                    style: LiquidGlassTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 20, color: LiquidGlassTheme.textMuted),
                            color: LiquidGlassTheme.bgDeep,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onSelected: (action) async {
                              if (action == 'rename') {
                                _renameProject(project);
                              } else if (action == 'delete') {
                                await _engine.deleteProject(project['id']);
                                _loadProjects();
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'rename', child: Text('Rename')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete Project')),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _ProjectStat(
                            icon: Icons.style_rounded,
                            label: '${project['deck_count'] ?? 0} decks',
                            color: color,
                          ),
                          const SizedBox(width: 16),
                          _ProjectStat(
                            icon: Icons.quiz_rounded,
                            label: '${project['quiz_count'] ?? 0} quizzes',
                            color: color,
                          ),
                        ],
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
}

class _ProjectStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ProjectStat({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Text(label, style: LiquidGlassTheme.bodySmall),
      ],
    );
  }
}

/// LexiCore — Settings / Profile Page (v5.2)
/// Full profile with cover image, avatar, display name, learning preferences,
/// data management, appearance theme, and about section.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/liquid_glass_theme.dart';
import '../services/engine_service.dart';
import '../widgets/glass_panel.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _engine = EngineService();
  final _nameController = TextEditingController();

  String _displayName = 'Learner';
  String _avatarEmoji = '🧑‍🎓';
  bool _hasCustomAvatar = false;
  String? _customAvatarPath;
  String? _coverPath;

  // Learning preferences
  int _dailyGoal = 10;  // words per day
  bool _notificationsEnabled = true;
  String _customInstructions = '';
  final _instructionsController = TextEditingController();

  // Theme cover color
  Color _coverColor = LiquidGlassTheme.accentPrimary;

  static const _avatarOptions = ['🧑‍🎓', '👨‍💻', '👩‍💻', '🧑‍🔬', '🦊', '🐉', '🦄', '🎃', '🌟', '💎'];
  static const _coverColors = [
    Color(0xFF7C4DFF), Color(0xFF00BCD4), Color(0xFFFF4081),
    Color(0xFF69F0AE), Color(0xFFFFAB40), Color(0xFF2979FF),
    Color(0xFFE040FB), Color(0xFFFF6E40),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _engine.getProfile();
    if (mounted) {
      setState(() {
        _displayName = profile['name']?.toString() ?? 'Learner';
        _nameController.text = _displayName;
        _avatarEmoji = profile['avatar_emoji']?.toString() ?? '🧑‍🎓';
        _customAvatarPath = profile['avatar_path']?.toString();
        _hasCustomAvatar = _customAvatarPath != null && _customAvatarPath!.isNotEmpty;
        _coverPath = profile['cover_path']?.toString();
        if (_coverPath != null && _coverPath!.isEmpty) _coverPath = null;
        _dailyGoal = int.tryParse(profile['daily_goal']?.toString() ?? '') ?? 10;
        _notificationsEnabled = profile['notifications'] != 'false';
        _customInstructions = profile['custom_instructions']?.toString() ?? '';
        _instructionsController.text = _customInstructions;
        // Restore accent color
        final colorHex = profile['cover_color']?.toString();
        if (colorHex != null && colorHex.isNotEmpty) {
          try {
            _coverColor = Color(int.parse(colorHex, radix: 16));
          } catch (_) {}
        }
      });
    }
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      await _engine.updateProfile('name', name);
      setState(() => _displayName = name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name updated!')),
        );
      }
    }
  }

  void _selectAvatar(String emoji) {
    setState(() {
      _avatarEmoji = emoji;
      _hasCustomAvatar = false;
      _customAvatarPath = null;
    });
    _engine.updateProfile('avatar_emoji', emoji);
    _engine.updateProfile('avatar_path', '');
  }

  Future<void> _uploadAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.first.path;
      if (path != null) {
        setState(() {
          _customAvatarPath = path;
          _hasCustomAvatar = true;
        });
        _engine.updateProfile('avatar_path', path);
      }
    }
  }

  Future<void> _uploadCover() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.first.path;
      if (path != null) {
        setState(() => _coverPath = path);
        _engine.updateProfile('cover_path', path);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Profile Cover + Avatar ──
          _buildProfileHeader(),
          const SizedBox(height: 28),

          // ── Quick Avatar ──
          Text('QUICK AVATAR', style: LiquidGlassTheme.label)
              .animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 10),
          GlassPanel(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _avatarOptions.map((emoji) {
                final isSelected = !_hasCustomAvatar && _avatarEmoji == emoji;
                return GestureDetector(
                  onTap: () => _selectAvatar(emoji),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: isSelected
                          ? LiquidGlassTheme.accentPrimary.withValues(alpha: 0.2)
                          : LiquidGlassTheme.glassFill,
                      border: Border.all(
                        color: isSelected ? LiquidGlassTheme.accentPrimary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
                  ),
                );
              }).toList(),
            ),
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 24),

          // ── Display Name ──
          Text('DISPLAY NAME', style: LiquidGlassTheme.label)
              .animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 10),
          GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            borderRadius: LiquidGlassTheme.borderRadiusSm,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    style: LiquidGlassTheme.body.copyWith(color: LiquidGlassTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      hintStyle: LiquidGlassTheme.body,
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _saveName(),
                  ),
                ),
                GestureDetector(
                  onTap: _saveName,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.15),
                    ),
                    child: const Icon(Icons.check_rounded, color: LiquidGlassTheme.accentPrimary, size: 18),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 600.ms),

          const SizedBox(height: 32),

          // ── Cover Theme Color ──
          Text('COVER THEME', style: LiquidGlassTheme.label)
              .animate().fadeIn(delay: 650.ms),
          const SizedBox(height: 10),
          GlassPanel(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose your profile accent color',
                  style: LiquidGlassTheme.bodySmall.copyWith(color: LiquidGlassTheme.textMuted)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _coverColors.map((color) {
                    final isSelected = _coverColor == color;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _coverColor = color);
                        _engine.updateProfile('cover_color', color.toARGB32().toRadixString(16));
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: isSelected ? 3 : 0,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: -2),
                          ] : null,
                        ),
                        child: isSelected ? const Center(
                          child: Icon(Icons.check_rounded, size: 18, color: Colors.white),
                        ) : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _uploadCover,
                  child: Row(
                    children: [
                      Icon(Icons.image_rounded, size: 16, color: LiquidGlassTheme.accentPrimary),
                      const SizedBox(width: 8),
                      Text('Upload cover image',
                        style: LiquidGlassTheme.bodySmall.copyWith(
                          color: LiquidGlassTheme.accentPrimary,
                          fontWeight: FontWeight.w600,
                        )),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 700.ms),

          const SizedBox(height: 32),

          // ── Learning Preferences ──
          Text('LEARNING PREFERENCES', style: LiquidGlassTheme.label)
              .animate().fadeIn(delay: 750.ms),
          const SizedBox(height: 10),
          GlassPanel(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                // Daily word goal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Daily word goal', style: LiquidGlassTheme.body),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() { if (_dailyGoal > 1) _dailyGoal--; }),
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: LiquidGlassTheme.glassFill,
                            ),
                            child: const Center(child: Icon(Icons.remove, size: 16, color: LiquidGlassTheme.textMuted)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text('$_dailyGoal', style: LiquidGlassTheme.headingSm.copyWith(fontSize: 16)),
                        ),
                        GestureDetector(
                          onTap: () => setState(() { if (_dailyGoal < 100) _dailyGoal++; }),
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.15),
                            ),
                            child: const Center(child: Icon(Icons.add, size: 16, color: LiquidGlassTheme.accentPrimary)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: LiquidGlassTheme.glassBorder.withValues(alpha: 0.3), height: 1),
                const SizedBox(height: 16),
                // Notifications
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Reminder notifications', style: LiquidGlassTheme.body),
                    Switch(
                      value: _notificationsEnabled,
                      onChanged: (v) => setState(() => _notificationsEnabled = v),
                      activeTrackColor: LiquidGlassTheme.accentPrimary,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 800.ms),

          const SizedBox(height: 32),

          // ── Custom AI Instructions ──
          Text('CUSTOM AI INSTRUCTIONS', style: LiquidGlassTheme.label)
              .animate().fadeIn(delay: 820.ms),
          const SizedBox(height: 6),
          Text(
            'Tell Lexi AI how you want it to behave. These instructions are added to every conversation.',
            style: LiquidGlassTheme.bodySmall.copyWith(color: LiquidGlassTheme.textMuted, fontSize: 11),
          ).animate().fadeIn(delay: 830.ms),
          const SizedBox(height: 10),
          GlassPanel(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                TextField(
                  controller: _instructionsController,
                  style: LiquidGlassTheme.body.copyWith(
                    color: LiquidGlassTheme.textPrimary, fontSize: 13, height: 1.5,
                  ),
                  maxLines: 6,
                  minLines: 3,
                  decoration: InputDecoration(
                    hintText: 'e.g. Always respond in Vietnamese. Focus on IELTS vocabulary. Keep answers short and concise.',
                    hintStyle: LiquidGlassTheme.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.2), fontSize: 12,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () async {
                      final text = _instructionsController.text.trim();
                      await _engine.updateProfile('custom_instructions', text);
                      setState(() => _customInstructions = text);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Custom instructions saved!')),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.15),
                      ),
                      child: Text('Save', style: LiquidGlassTheme.label.copyWith(
                        color: LiquidGlassTheme.accentPrimary,
                      )),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 850.ms),

          const SizedBox(height: 32),

          // ── Data Management ──
          Text('DATA', style: LiquidGlassTheme.label)
              .animate().fadeIn(delay: 850.ms),
          const SizedBox(height: 10),
          GlassPanel(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _SettingRow(
                  icon: Icons.download_rounded,
                  label: 'Export Progress',
                  subtitle: 'Save your data as JSON',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Exporting data...')),
                    );
                  },
                ),
                Divider(color: LiquidGlassTheme.glassBorder.withValues(alpha: 0.3), height: 24),
                _SettingRow(
                  icon: Icons.cloud_sync_rounded,
                  label: 'Sync Dictionary',
                  subtitle: 'Re-index your offline dictionary',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Syncing dictionary...')),
                    );
                  },
                ),
                Divider(color: LiquidGlassTheme.glassBorder.withValues(alpha: 0.3), height: 24),
                _SettingRow(
                  icon: Icons.delete_outline_rounded,
                  label: 'Reset Progress',
                  subtitle: 'Clear all learning data',
                  color: Colors.redAccent,
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: LiquidGlassTheme.bgDeep,
                        title: const Text('Reset Progress?', style: TextStyle(color: LiquidGlassTheme.textPrimary)),
                        content: const Text('This will clear all your learning progress, quiz history, and XP.',
                          style: TextStyle(color: LiquidGlassTheme.textSecondary)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Reset', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Progress reset!')),
                      );
                    }
                  },
                ),
              ],
            ),
          ).animate().fadeIn(delay: 900.ms),

          const SizedBox(height: 32),

          // ── About ──
          Text('ABOUT', style: LiquidGlassTheme.label)
              .animate().fadeIn(delay: 950.ms),
          const SizedBox(height: 10),
          GlassPanel(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _InfoRow(label: 'App', value: 'LexiCore Engine'),
                _InfoRow(label: 'Version', value: '5.5.0'),
                _InfoRow(label: 'UI Engine', value: 'Flutter + Liquid Glass'),
                _InfoRow(label: 'Backend', value: 'Python FastAPI'),
                _InfoRow(label: 'Design', value: 'iOS 26 Liquid Glass'),
                _InfoRow(label: 'AI Models', value: 'DeepSeek R1, Gemma 3, Llama 4'),
                _InfoRow(label: 'Features', value: 'Dictionary, Quiz, Flashcards, AI'),
                _InfoRow(label: 'Audio', value: 'Google TTS Pronunciation'),
                _InfoRow(label: 'Web Search', value: 'DuckDuckGo RAG'),
                _InfoRow(label: 'Storage', value: 'SQLite + Custom Binary Index'),
              ],
            ),
          ).animate().fadeIn(delay: 1000.ms),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: _coverPath == null
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _coverColor.withValues(alpha: 0.4),
                _coverColor.withValues(alpha: 0.1),
                LiquidGlassTheme.bgDeep,
              ],
            )
          : null,
        image: _coverPath != null
          ? DecorationImage(
              image: FileImage(File(_coverPath!)),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                LiquidGlassTheme.bgDeep.withValues(alpha: 0.4),
                BlendMode.darken,
              ),
            )
          : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cover overlay gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    LiquidGlassTheme.bgDeep.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Positioned(
            left: 24, bottom: 20,
            child: Row(
              children: [
                // Avatar
                GestureDetector(
                  onTap: _uploadAvatar,
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _coverColor.withValues(alpha: 0.4),
                          LiquidGlassTheme.accentSecondary.withValues(alpha: 0.2),
                        ],
                      ),
                      border: Border.all(color: LiquidGlassTheme.bgDeep, width: 3),
                      boxShadow: [
                        BoxShadow(color: _coverColor.withValues(alpha: 0.3), blurRadius: 16, spreadRadius: -4),
                      ],
                    ),
                    child: _hasCustomAvatar && _customAvatarPath != null
                        ? ClipOval(
                            child: Image.file(File(_customAvatarPath!),
                              fit: BoxFit.cover, width: 72, height: 72,
                              errorBuilder: (_, __, ___) =>
                                Center(child: Text(_avatarEmoji, style: const TextStyle(fontSize: 36))),
                            ),
                          )
                        : Center(child: Text(_avatarEmoji, style: const TextStyle(fontSize: 36))),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_displayName, style: LiquidGlassTheme.headingSm),
                    const SizedBox(height: 2),
                    Text('LexiCore Student', style: LiquidGlassTheme.bodySmall.copyWith(
                      color: LiquidGlassTheme.textMuted,
                    )),
                  ],
                ),
              ],
            ),
          ),
          // Edit cover button
          Positioned(
            right: 12, top: 12,
            child: GestureDetector(
              onTap: _uploadCover,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.4),
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0);
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final VoidCallback onTap;
  final Color? color;

  const _SettingRow({
    required this.icon, required this.label, required this.subtitle,
    required this.onTap, this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? LiquidGlassTheme.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500,
                  color: color ?? LiquidGlassTheme.textPrimary,
                )),
                Text(subtitle, style: LiquidGlassTheme.bodySmall.copyWith(fontSize: 11)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 18,
            color: color ?? LiquidGlassTheme.textMuted),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: LiquidGlassTheme.body),
          Text(value, style: LiquidGlassTheme.bodySmall),
        ],
      ),
    );
  }
}

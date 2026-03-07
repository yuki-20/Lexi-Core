/// LexiCore — Settings Page (v3.1)
/// Profile (name, custom avatar upload), app settings, account management.
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
  String? _customAvatarPath;
  bool _hasCustomAvatar = false;

  final _avatarOptions = ['🧑‍🎓', '🦊', '🦉', '🐉', '🦄', '🌟', '🎓', '🔬', '📚', '🎯', '🧠', '💡'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _engine.getProfile();
    if (mounted) {
      setState(() {
        _displayName = profile['display_name']?.toString() ?? 'Learner';
        _avatarEmoji = profile['avatar']?.toString() ?? '🧑‍🎓';
        _customAvatarPath = profile['avatar_path']?.toString();
        _hasCustomAvatar = _customAvatarPath != null && _customAvatarPath!.isNotEmpty;
        _nameController.text = _displayName;
      });
    }
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    await _engine.updateProfile('display_name', name);
    setState(() => _displayName = name);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated!')),
      );
    }
  }

  Future<void> _selectAvatar(String emoji) async {
    await _engine.updateProfile('avatar', emoji);
    setState(() {
      _avatarEmoji = emoji;
      _hasCustomAvatar = false;
    });
  }

  Future<void> _uploadAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null) return;

    final ok = await _engine.uploadAvatar(path);
    if (ok && mounted) {
      setState(() {
        _customAvatarPath = path;
        _hasCustomAvatar = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar uploaded!')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: LiquidGlassTheme.heading)
              .animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 28),

          // ── Profile Card ──
          GlassPanel(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                // Avatar
                GestureDetector(
                  onTap: _uploadAvatar,
                  child: Stack(
                    children: [
                      Container(
                        width: 88, height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              LiquidGlassTheme.accentPrimary.withValues(alpha: 0.3),
                              LiquidGlassTheme.accentSecondary.withValues(alpha: 0.2),
                            ],
                          ),
                        ),
                        child: _hasCustomAvatar && _customAvatarPath != null
                            ? ClipOval(
                                child: Image.file(
                                  File(_customAvatarPath!),
                                  fit: BoxFit.cover,
                                  width: 88,
                                  height: 88,
                                  errorBuilder: (_, __, ___) =>
                                      Center(child: Text(_avatarEmoji, style: const TextStyle(fontSize: 44))),
                                ),
                              )
                            : Center(child: Text(_avatarEmoji, style: const TextStyle(fontSize: 44))),
                      ),
                      Positioned(
                        right: 0, bottom: 0,
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: LiquidGlassTheme.accentPrimary,
                            border: Border.all(color: LiquidGlassTheme.bgDeep, width: 2),
                          ),
                          child: const Center(
                            child: Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().scale(begin: const Offset(0.85, 0.85), duration: 500.ms, curve: Curves.elasticOut),
                const SizedBox(height: 14),
                Text(_displayName, style: LiquidGlassTheme.headingSm),
                const SizedBox(height: 4),
                Text('LexiCore Student', style: LiquidGlassTheme.bodySmall),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.05, end: 0),

          const SizedBox(height: 24),

          // ── Emoji Avatar Picker ──
          Text('Quick Avatar', style: LiquidGlassTheme.label)
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
                        color: isSelected
                            ? LiquidGlassTheme.accentPrimary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
                  ),
                );
              }).toList(),
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

          const SizedBox(height: 24),

          // ── Name Field ──
          Text('Display Name', style: LiquidGlassTheme.label)
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
                GlassPanel(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: _saveName,
                    child: const Icon(Icons.check_rounded, color: LiquidGlassTheme.accentPrimary, size: 18),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

          const SizedBox(height: 32),

          // ── App Info ──
          Text('About', style: LiquidGlassTheme.label)
              .animate().fadeIn(delay: 700.ms),
          const SizedBox(height: 10),
          GlassPanel(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _InfoRow(label: 'App', value: 'LexiCore Engine'),
                _InfoRow(label: 'Version', value: '3.1.0'),
                _InfoRow(label: 'UI Engine', value: 'Flutter + Liquid Glass'),
                _InfoRow(label: 'Backend', value: 'Python FastAPI'),
                _InfoRow(label: 'Design', value: 'iOS 26 Liquid Glass'),
              ],
            ),
          ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
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

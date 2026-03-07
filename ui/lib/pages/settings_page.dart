/// LexiCore — Settings Page
/// Profile (name, avatar), app settings, account management.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    setState(() => _avatarEmoji = emoji);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: LiquidGlassTheme.heading)
              .animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 24),

          // ── Profile Card ──
          GlassPanel(
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 80, height: 80,
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
                  child: Center(
                    child: Text(_avatarEmoji, style: const TextStyle(fontSize: 40)),
                  ),
                ).animate().scale(begin: const Offset(0.8, 0.8), duration: 500.ms, curve: Curves.elasticOut),
                const SizedBox(height: 12),
                Text(_displayName, style: LiquidGlassTheme.headingSm),
                const SizedBox(height: 4),
                Text('LexiCore Student', style: LiquidGlassTheme.bodySmall),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 20),

          // ── Avatar Picker ──
          Text('Choose Avatar', style: LiquidGlassTheme.label)
              .animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 10),
          GlassPanel(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _avatarOptions.map((emoji) {
                final isSelected = _avatarEmoji == emoji;
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
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 20),

          // ── Name Field ──
          Text('Display Name', style: LiquidGlassTheme.label)
              .animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 10),
          GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                IconButton(
                  icon: const Icon(Icons.check_rounded, color: LiquidGlassTheme.accentPrimary),
                  onPressed: _saveName,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 600.ms),

          const SizedBox(height: 32),

          // ── App Info ──
          Text('About', style: LiquidGlassTheme.label)
              .animate().fadeIn(delay: 700.ms),
          const SizedBox(height: 10),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: 'App', value: 'LexiCore Engine'),
                _InfoRow(label: 'Version', value: '3.0.0'),
                _InfoRow(label: 'UI Engine', value: 'Flutter + Liquid Glass'),
                _InfoRow(label: 'Backend', value: 'Python FastAPI'),
                _InfoRow(label: 'Design', value: 'iOS 26 Liquid Glass'),
              ],
            ),
          ).animate().fadeIn(delay: 800.ms),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
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

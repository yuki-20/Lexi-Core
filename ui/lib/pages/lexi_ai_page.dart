/// LexiCore — Lexi-AI Chat Page (v5.4.1)
/// Perplexity-inspired AI chat interface with streaming CoT,
/// markdown rendering, web search, vision support, and encrypted API backend.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/liquid_glass_theme.dart';
import '../services/engine_service.dart';

class LexiAiPage extends StatefulWidget {
  const LexiAiPage({super.key});

  @override
  State<LexiAiPage> createState() => _LexiAiPageState();
}

class _LexiAiPageState extends State<LexiAiPage> {
  final _engine = EngineService();
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();

  // Chat state
  List<Map<String, String>> _messages = [];
  Map<int, String> _thinkingTexts = {}; // CoT per assistant message index
  bool _isLoading = false;
  String _streamingAnswer = ''; // real-time answer buffer
  String _streamingThinking = ''; // real-time thinking buffer
  int? _conversationId;
  String _chatTitle = 'New Chat';
  bool _hasStarted = false;
  bool _webSearchEnabled = false; // web search toggle
  List<String> _pendingImages = []; // base64 images for vision models

  // Vision model support
  static const _visionModels = {'gemma-3-27b-it'};
  bool get _isVisionModel => _visionModels.contains(_selectedModel);

  // Model selector
  String _selectedModel = 'DeepSeek-R1';
  static const _chatModels = <_ModelInfo>[
    _ModelInfo('DeepSeek-R1', 'DeepSeek', Icons.psychology_rounded),
    _ModelInfo('DeepSeek-V3.2-Speciale', 'DeepSeek V3.2', Icons.auto_awesome),
    _ModelInfo('Qwen3-32B', 'Qwen3 32B', Icons.hub_rounded),
    _ModelInfo('Qwen2.5-Coder-32B-Instruct', 'Qwen Coder', Icons.code_rounded),
    _ModelInfo('Llama-3.3-70B-Instruct', 'Llama 3.3 70B', Icons.pets_rounded),
    _ModelInfo('gemma-3-27b-it', 'Gemma 3', Icons.diamond_rounded),
    _ModelInfo('GLM-4.5', 'GLM 4.5', Icons.blur_on_rounded),
    _ModelInfo('GLM-4.7', 'GLM 4.7', Icons.blur_circular_rounded),
    _ModelInfo('gpt-oss-120b', 'GPT-OSS 120B', Icons.memory_rounded),
    _ModelInfo('gpt-oss-20b', 'GPT-OSS 20B', Icons.developer_board_rounded),
  ];

  // History panel
  List<Map<String, dynamic>> _history = [];
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final h = await _engine.getAiHistory();
    if (mounted) setState(() => _history = h);
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isLoading) return;
    _msgController.clear();

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
      _hasStarted = true;
      _streamingAnswer = '';
      _streamingThinking = '';
    });
    _scrollToBottom();

    if (_chatTitle == 'New Chat' && _messages.length == 1) {
      _chatTitle = text.length > 40 ? '${text.substring(0, 40)}...' : text;
    }

    // Use streaming endpoint
    final imagesToSend = _pendingImages.isNotEmpty ? List<String>.from(_pendingImages) : null;
    setState(() => _pendingImages = []);

    await for (final event in _engine.streamAiChat(
      _messages,
      model: _selectedModel,
      webSearch: _webSearchEnabled,
      images: imagesToSend,
    )) {
      if (!mounted) break;
      final type = event['type']?.toString() ?? '';
      final content = event['content']?.toString() ?? '';

      if (type == 'thinking') {
        setState(() => _streamingThinking += content);
        _scrollToBottom();
      } else if (type == 'answer') {
        setState(() => _streamingAnswer += content);
        _scrollToBottom();
      } else if (type == 'done') {
        final finalAnswer = event['answer']?.toString() ?? _streamingAnswer;
        final finalThinking = event['thinking']?.toString() ?? _streamingThinking;
        final msgIndex = _messages.length;
        setState(() {
          _messages.add({'role': 'assistant', 'content': finalAnswer});
          if (finalThinking.isNotEmpty) {
            _thinkingTexts[msgIndex] = finalThinking;
          }
          _isLoading = false;
          _streamingAnswer = '';
          _streamingThinking = '';
        });
        _scrollToBottom();
        _saveConversation();
        break;
      } else if (type == 'error') {
        setState(() {
          _messages.add({'role': 'assistant', 'content': 'Error: $content'});
          _isLoading = false;
          _streamingAnswer = '';
          _streamingThinking = '';
        });
        _scrollToBottom();
        break;
      }
    }
  }

  Future<void> _saveConversation() async {
    final id = await _engine.saveAiConversation(
      conversationId: _conversationId,
      title: _chatTitle,
      model: _selectedModel,
      messages: _messages,
    );
    if (id != null && mounted) {
      setState(() => _conversationId = id);
      _loadHistory();
    }
  }

  Future<void> _loadConversation(Map<String, dynamic> conv) async {
    final full = await _engine.getAiConversation(conv['id'] as int);
    if (full != null && mounted) {
      final msgs = (full['messages'] as List?)?.map((m) =>
        Map<String, String>.from({
          'role': m['role'].toString(),
          'content': m['content'].toString(),
        })
      ).toList() ?? [];
      setState(() {
        _conversationId = conv['id'] as int;
        _chatTitle = conv['title']?.toString() ?? 'Chat';
        _selectedModel = conv['model']?.toString() ?? 'DeepSeek-R1';
        _messages = msgs;
        _showHistory = false;
        _hasStarted = true;
      });
      _scrollToBottom();
    }
  }

  void _newChat() {
    setState(() {
      _messages = [];
      _thinkingTexts = {};
      _conversationId = null;
      _chatTitle = 'New Chat';
      _hasStarted = false;
      _streamingAnswer = '';
      _streamingThinking = '';
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _hasStarted ? _buildChatView() : _buildWelcomeView(),
        if (_showHistory) _buildHistoryPanel(),
      ],
    );
  }

  // ── Welcome / Landing (Perplexity-style) ──────────────────────
  Widget _buildWelcomeView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo icon
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset('assets/images/lexi_logo.png',
                  width: 56, height: 56, fit: BoxFit.contain),
              ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),
              const SizedBox(height: 16),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [LiquidGlassTheme.accentPrimary, LiquidGlassTheme.accentSecondary],
                ).createShader(bounds),
                child: const Text('Lexi AI',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w300, color: Colors.white, letterSpacing: -0.5),
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
              const SizedBox(height: 32),

              // ── Main Input Card ──
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _msgController,
                      style: LiquidGlassTheme.body.copyWith(
                        color: LiquidGlassTheme.textPrimary, fontSize: 15,
                      ),
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Ask anything...',
                        hintStyle: LiquidGlassTheme.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.3), fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      child: Row(
                        children: [
                          _ToolbarButton(
                            icon: Icons.history_rounded,
                            tooltip: 'History',
                            onTap: () => setState(() => _showHistory = !_showHistory),
                          ),
                          const SizedBox(width: 4),
                          _buildModelDropdown(),
                          const SizedBox(width: 4),
                          // Web search toggle
                          Tooltip(
                            message: _webSearchEnabled ? 'Web Search: ON' : 'Web Search: OFF',
                            child: _ToolbarButton(
                              icon: Icons.language_rounded,
                              tooltip: '',
                              isActive: _webSearchEnabled,
                              onTap: () => setState(() => _webSearchEnabled = !_webSearchEnabled),
                            ),
                          ),
                          // Vision model attach button
                          if (_isVisionModel) ...[
                            const SizedBox(width: 4),
                            Tooltip(
                              message: 'Attach Image (Gemma 3 Vision)',
                              child: _ToolbarButton(
                                icon: Icons.attach_file_rounded,
                                tooltip: '',
                                isActive: _pendingImages.isNotEmpty,
                                onTap: _pickImage,
                              ),
                            ),
                          ],
                          const Spacer(),
                          GestureDetector(
                            onTap: _sendMessage,
                            child: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [
                                  LiquidGlassTheme.accentPrimary,
                                  LiquidGlassTheme.accentSecondary,
                                ]),
                              ),
                              child: const Center(
                                child: Icon(Icons.arrow_upward_rounded, size: 18, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.05, end: 0),

              const SizedBox(height: 28),

              // ── Suggestion Chips ──
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _SuggestionChip(
                    icon: Icons.school_rounded,
                    label: 'Explain a word',
                    onTap: () {
                      _msgController.text = 'Explain the word "ephemeral" with examples and etymology';
                      _sendMessage();
                    },
                  ),
                  _SuggestionChip(
                    icon: Icons.quiz_rounded,
                    label: 'Quiz me',
                    onTap: () {
                      _msgController.text = 'Quiz me on my recently saved words';
                      _sendMessage();
                    },
                  ),
                  _SuggestionChip(
                    icon: Icons.lightbulb_rounded,
                    label: 'Study tips',
                    onTap: () {
                      _msgController.text = 'Give me vocabulary study tips based on my learning progress';
                      _sendMessage();
                    },
                  ),
                  _SuggestionChip(
                    icon: Icons.translate_rounded,
                    label: 'Compare words',
                    onTap: () {
                      _msgController.text = 'What is the difference between "affect" and "effect"?';
                      _sendMessage();
                    },
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  // ── Chat View ─────────────────────────────────────────────────
  Widget _buildChatView() {
    return Column(
      children: [
        _buildChatHeader(),
        Expanded(child: _buildMessageList()),
        _buildChatInput(),
      ],
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Row(
        children: [
          _ToolbarButton(
            icon: Icons.history_rounded,
            tooltip: 'History',
            isActive: _showHistory,
            onTap: () => setState(() => _showHistory = !_showHistory),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_chatTitle, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500,
              color: LiquidGlassTheme.textSecondary,
            ), overflow: TextOverflow.ellipsis),
          ),
          _buildModelDropdown(),
          const SizedBox(width: 8),
          _ToolbarButton(
            icon: Icons.add_rounded,
            tooltip: 'New Chat',
            onTap: _newChat,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildModelDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedModel,
          isDense: true,
          dropdownColor: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(fontSize: 12, color: LiquidGlassTheme.textSecondary),
          icon: const Icon(Icons.expand_more_rounded, size: 16, color: LiquidGlassTheme.textMuted),
          items: _chatModels.map((m) => DropdownMenuItem(
            value: m.id,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(m.icon, size: 14, color: LiquidGlassTheme.accentPrimary),
                const SizedBox(width: 8),
                Text(m.label, style: const TextStyle(fontSize: 12)),
              ],
            ),
          )).toList(),
          onChanged: (v) { if (v != null) setState(() => _selectedModel = v); },
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    final extraItems = _isLoading ? 1 : 0; // streaming indicator
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: _messages.length + extraItems,
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          // Show streaming content
          return _buildStreamingMessage();
        }
        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        return isUser
            ? _buildUserMessage(msg)
            : _buildAssistantMessage(msg, index);
      },
    );
  }

  Widget _buildUserMessage(Map<String, String> msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.2),
            ),
            child: const Center(
              child: Icon(Icons.person_rounded, size: 16, color: LiquidGlassTheme.accentPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('You', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: LiquidGlassTheme.textPrimary,
                )),
                const SizedBox(height: 4),
                SelectableText(
                  msg['content'] ?? '',
                  style: LiquidGlassTheme.body.copyWith(fontSize: 14, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildAssistantMessage(Map<String, String> msg, int index) {
    final thinking = _thinkingTexts[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CoT accordion (above answer)
          if (thinking != null && thinking.isNotEmpty)
            _CoTAccordion(thinking: thinking),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI avatar — teal logo
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset('assets/images/lexi_logo.png',
                  width: 24, height: 24, fit: BoxFit.contain),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Lexi', style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: LiquidGlassTheme.accentPrimary,
                        )),
                        const SizedBox(width: 8),
                        Text(_selectedModel, style: TextStyle(
                          fontSize: 10, color: LiquidGlassTheme.textMuted,
                        )),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Markdown rendered content
                    MarkdownBody(
                      data: msg['content'] ?? '',
                      selectable: true,
                      styleSheet: _buildMarkdownStyle(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.02, end: 0);
  }

  /// Real-time streaming message — shows thinking and answer as they arrive.
  Widget _buildStreamingMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live thinking accordion (above answer)
          if (_streamingThinking.isNotEmpty)
            _CoTAccordion(thinking: _streamingThinking, initiallyExpanded: true),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset('assets/images/lexi_logo.png',
                  width: 24, height: 24, fit: BoxFit.contain),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Lexi', style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: LiquidGlassTheme.accentPrimary,
                        )),
                        const SizedBox(width: 8),
                        Text(_selectedModel, style: TextStyle(
                          fontSize: 10, color: LiquidGlassTheme.textMuted,
                        )),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 12, height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5, color: LiquidGlassTheme.accentPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Show streamed answer in real-time with markdown
                    if (_streamingAnswer.isNotEmpty)
                      MarkdownBody(
                        data: _streamingAnswer,
                        selectable: true,
                        styleSheet: _buildMarkdownStyle(),
                      )
                    else if (_streamingThinking.isNotEmpty)
                      Text('Thinking...', style: TextStyle(
                        fontSize: 13, color: LiquidGlassTheme.textMuted, fontStyle: FontStyle.italic,
                      ))
                    else
                      Row(
                        children: [
                          SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: LiquidGlassTheme.accentPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('Thinking...', style: TextStyle(
                            fontSize: 13, color: LiquidGlassTheme.textMuted,
                          )),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  MarkdownStyleSheet _buildMarkdownStyle() {
    return MarkdownStyleSheet(
      p: LiquidGlassTheme.body.copyWith(
        fontSize: 14, height: 1.7, color: LiquidGlassTheme.textSecondary,
      ),
      h1: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: LiquidGlassTheme.textPrimary),
      h2: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: LiquidGlassTheme.textPrimary),
      h3: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: LiquidGlassTheme.textPrimary),
      strong: TextStyle(fontWeight: FontWeight.w700, color: LiquidGlassTheme.textPrimary),
      em: TextStyle(fontStyle: FontStyle.italic, color: LiquidGlassTheme.textSecondary),
      code: TextStyle(
        fontSize: 13, fontFamily: 'monospace',
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        color: const Color(0xFF00E5FF),
      ),
      codeblockDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      codeblockPadding: const EdgeInsets.all(12),
      blockquoteDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.06),
        border: Border(left: BorderSide(
          color: LiquidGlassTheme.accentPrimary, width: 3,
        )),
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      listBullet: TextStyle(fontSize: 14, color: LiquidGlassTheme.textSecondary),
      tableHead: TextStyle(fontWeight: FontWeight.w600, color: LiquidGlassTheme.textPrimary),
      tableBody: TextStyle(color: LiquidGlassTheme.textSecondary),
      tableBorder: TableBorder.all(color: Colors.white.withValues(alpha: 0.1)),
      tableCellsPadding: const EdgeInsets.all(8),
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result != null) {
      for (final file in result.files) {
        if (file.path != null) {
          final bytes = await File(file.path!).readAsBytes();
          final ext = file.extension?.toLowerCase() ?? 'jpeg';
          final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
          final b64 = 'data:$mime;base64,${base64Encode(bytes)}';
          setState(() => _pendingImages.add(b64));
        }
      }
    }
  }

  Widget _buildChatInput() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Image preview chips
        if (_pendingImages.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _pendingImages.length,
              itemBuilder: (ctx, i) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          base64Decode(_pendingImages[i].split(',').last),
                          width: 50, height: 50, fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: -4, right: -4,
                        child: GestureDetector(
                          onTap: () => setState(() => _pendingImages.removeAt(i)),
                          child: Container(
                            width: 18, height: 18,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.redAccent,
                            ),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Container(
            decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _msgController,
                style: LiquidGlassTheme.body.copyWith(
                  color: LiquidGlassTheme.textPrimary, fontSize: 14,
                ),
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Ask a follow-up...',
                  hintStyle: LiquidGlassTheme.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(18, 14, 0, 14),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            // Web search toggle
            Tooltip(
              message: _webSearchEnabled ? 'Web Search: ON' : 'Web Search: OFF',
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: GestureDetector(
                  onTap: () => setState(() => _webSearchEnabled = !_webSearchEnabled),
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _webSearchEnabled
                          ? LiquidGlassTheme.accentPrimary.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                        color: _webSearchEnabled
                            ? LiquidGlassTheme.accentPrimary.withValues(alpha: 0.5)
                            : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.travel_explore_rounded,
                        size: 16,
                        color: _webSearchEnabled
                            ? LiquidGlassTheme.accentPrimary
                            : LiquidGlassTheme.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Image attach for vision models
            if (_isVisionModel)
              Tooltip(
                message: 'Attach Image (Gemma 3 Vision)',
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _pendingImages.isNotEmpty
                            ? LiquidGlassTheme.accentSecondary.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                          color: _pendingImages.isNotEmpty
                              ? LiquidGlassTheme.accentSecondary.withValues(alpha: 0.5)
                              : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.attach_file_rounded,
                          size: 16,
                          color: _pendingImages.isNotEmpty
                              ? LiquidGlassTheme.accentSecondary
                              : LiquidGlassTheme.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: _isLoading ? null : _sendMessage,
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _isLoading ? null : LinearGradient(colors: [
                      LiquidGlassTheme.accentPrimary,
                      LiquidGlassTheme.accentSecondary,
                    ]),
                    color: _isLoading ? Colors.white.withValues(alpha: 0.08) : null,
                  ),
                  child: Center(
                    child: Icon(
                      _isLoading ? Icons.more_horiz_rounded : Icons.arrow_upward_rounded,
                      size: 16, color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
      ],
    ).animate().fadeIn(delay: 100.ms);
  }

  // ── History Panel ─────────────────────────────────────────────
  Widget _buildHistoryPanel() {
    return Positioned(
      left: 0, top: 0, bottom: 0,
      width: 280,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D1A).withValues(alpha: 0.97),
          border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  const Text('History', style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: LiquidGlassTheme.textPrimary,
                  )),
                  const Spacer(),
                  // Delete All button
                  if (_history.isNotEmpty)
                    GestureDetector(
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: const Color(0xFF1A1A2E),
                            title: const Text('Delete All Chats', style: TextStyle(color: Colors.white)),
                            content: Text('Delete all ${_history.length} conversations?', style: const TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete All', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _engine.deleteAllAiConversations();
                          _newChat();
                          _loadHistory();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.redAccent.withValues(alpha: 0.1),
                        ),
                        child: const Icon(Icons.delete_sweep_rounded, size: 16, color: Colors.redAccent),
                      ),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _newChat,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                      child: const Icon(Icons.add_rounded, size: 16, color: LiquidGlassTheme.textMuted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _showHistory = false),
                    child: const Icon(Icons.close_rounded, size: 18, color: LiquidGlassTheme.textMuted),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
            Expanded(
              child: _history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 28,
                            color: Colors.white.withValues(alpha: 0.15)),
                          const SizedBox(height: 8),
                          Text('No conversations yet', style: TextStyle(
                            fontSize: 12, color: Colors.white.withValues(alpha: 0.3),
                          )),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      itemCount: _history.length,
                      itemBuilder: (context, i) {
                        final conv = _history[i];
                        final isActive = conv['id'] == _conversationId;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: GestureDetector(
                            onTap: () => _loadConversation(conv),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: isActive
                                    ? LiquidGlassTheme.accentPrimary.withValues(alpha: 0.12)
                                    : Colors.transparent,
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded, size: 14,
                                    color: isActive ? LiquidGlassTheme.accentPrimary : LiquidGlassTheme.textMuted),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      conv['title']?.toString() ?? 'Chat',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isActive
                                            ? LiquidGlassTheme.textPrimary
                                            : LiquidGlassTheme.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      await _engine.deleteAiConversation(conv['id'] as int);
                                      if (conv['id'] == _conversationId) _newChat();
                                      _loadHistory();
                                    },
                                    child: Icon(Icons.close_rounded, size: 14,
                                      color: Colors.white.withValues(alpha: 0.15)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 150.ms).slideX(begin: -0.05, end: 0);
  }
}

// ── Helper Widgets ────────────────────────────────────────────────

class _ModelInfo {
  final String id, label;
  final IconData icon;
  const _ModelInfo(this.id, this.label, this.icon);
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isActive;

  const _ToolbarButton({
    required this.icon, required this.tooltip,
    required this.onTap, this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isActive
                ? LiquidGlassTheme.accentPrimary.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.06),
          ),
          child: Center(
            child: Icon(icon, size: 16,
              color: isActive ? LiquidGlassTheme.accentPrimary : LiquidGlassTheme.textMuted),
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: LiquidGlassTheme.textMuted),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(
              fontSize: 12, color: LiquidGlassTheme.textSecondary,
            )),
          ],
        ),
      ),
    );
  }
}

/// Expandable chain-of-thought accordion.
class _CoTAccordion extends StatefulWidget {
  final String thinking;
  final bool initiallyExpanded;
  const _CoTAccordion({required this.thinking, this.initiallyExpanded = false});

  @override
  State<_CoTAccordion> createState() => _CoTAccordionState();
}

class _CoTAccordionState extends State<_CoTAccordion> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.06),
        border: Border.all(color: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology_rounded,
                    size: 14,
                    color: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text('Thinking process', style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.8),
                  )),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more_rounded, size: 16,
                      color: LiquidGlassTheme.accentPrimary.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SelectableText(
                widget.thinking,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: LiquidGlassTheme.textMuted.withValues(alpha: 0.8),
                  fontFamily: 'monospace',
                ),
              ),
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

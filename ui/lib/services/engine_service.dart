/// LexiCore — Engine API Service (v3.0)
/// Communicates with the Python FastAPI backend at localhost:8741.
/// Covers all v3.0 endpoints: search, flashcards, quiz, file import,
/// performance, profile, pets, welcome, pronunciation.
library;

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

const String _baseUrl = 'http://127.0.0.1:8741';
const String _wsUrl = 'ws://127.0.0.1:8741/ws';

class EngineService {
  static final EngineService _instance = EngineService._();
  factory EngineService() => _instance;
  EngineService._();

  /// Poll backend until it's ready (up to 15 seconds).
  /// On fresh install, the auto-build takes extra time.
  Future<bool> waitForReady({int maxAttempts = 15}) async {
    for (int i = 0; i < maxAttempts; i++) {
      try {
        final resp = await http.get(
          Uri.parse('$_baseUrl/api/stats'),
        ).timeout(const Duration(seconds: 2));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          if (data['ready'] == true) return true;
        }
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 1));
    }
    return false;
  }


  WebSocketChannel? _ws;
  final _autocompleteController = StreamController<AutocompleteResult>.broadcast();
  Stream<AutocompleteResult> get autocompleteStream => _autocompleteController.stream;
  final _progressController = StreamController<DateTime>.broadcast();
  Stream<DateTime> get progressStream => _progressController.stream;

  void notifyProgressChanged() {
    if (!_progressController.isClosed) {
      _progressController.add(DateTime.now());
    }
  }

  // ── WebSocket ──
  void connectWebSocket() {
    try {
      _ws = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _ws!.stream.listen((message) {
        final data = jsonDecode(message);
        if (data['action'] == 'autocomplete') {
          _autocompleteController.add(AutocompleteResult(
            prefix: data['prefix'] ?? '',
            suggestions: List<String>.from(data['suggestions'] ?? []),
            timingMs: (data['timing_ms'] ?? 0).toDouble(),
          ));
        }
      }, onError: (_) {}, onDone: () {});
    } catch (_) {}
  }

  void sendAutocomplete(String prefix, {int limit = 10}) {
    _ws?.sink.add(jsonEncode({
      'action': 'autocomplete',
      'prefix': prefix,
      'limit': limit,
    }));
  }

  // ══════════════════════════════════════════════════════════════════
  // SEARCH
  // ══════════════════════════════════════════════════════════════════

  Future<SearchResult> searchExact(String query) async {
    try {
      final resp = await http.get(
        Uri.parse('$_baseUrl/api/search?q=${Uri.encodeComponent(query)}'),
      ).timeout(const Duration(seconds: 5));
      final data = jsonDecode(resp.body);
      return SearchResult.fromJson(data);
    } catch (e) {
      return SearchResult(found: false, query: query, timingMs: 0);
    }
  }

  Future<SearchResult> searchOnline(String query) async {
    try {
      final resp = await http.get(
        Uri.parse('$_baseUrl/api/search/online?q=${Uri.encodeComponent(query)}'),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(resp.body);
      return SearchResult.fromJson(data);
    } catch (e) {
      return SearchResult(found: false, query: query, timingMs: 0, source: 'online');
    }
  }

  Future<List<String>> searchFuzzy(String query) async {
    try {
      final resp = await http.get(
        Uri.parse('$_baseUrl/api/fuzzy?q=${Uri.encodeComponent(query)}'),
      ).timeout(const Duration(seconds: 5));
      final data = jsonDecode(resp.body);
      return List<String>.from(data['suggestions'] ?? []);
    } catch (_) {
      return [];
    }
  }

  Future<List<AutocompleteItem>> getAutocomplete(String prefix) async {
    try {
      final resp = await http.get(
        Uri.parse('$_baseUrl/api/autocomplete?prefix=${Uri.encodeComponent(prefix)}&limit=10'),
      ).timeout(const Duration(seconds: 3));
      final data = jsonDecode(resp.body);
      return (data['suggestions'] as List).map((s) {
        if (s is Map) return AutocompleteItem(word: s['word']?.toString() ?? '');
        return AutocompleteItem(word: s.toString());
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // STATS & WELCOME
  // ══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getStats() async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/api/stats'))
          .timeout(const Duration(seconds: 3));
      return jsonDecode(resp.body);
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>?> getWordOfTheDay({String mode = 'online', int hours = 2}) async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/api/wotd?mode=$mode&hours=$hours'))
          .timeout(const Duration(seconds: 5));
      return jsonDecode(resp.body);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getWelcome() async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/api/welcome'))
          .timeout(const Duration(seconds: 3));
      return jsonDecode(resp.body);
    } catch (_) {
      return {'message': 'Welcome back!', 'name': 'Learner', 'streak': 0};
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // SAVED WORDS
  // ══════════════════════════════════════════════════════════════════

  Future<bool> saveWord(String word, {String? definition}) async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'word': word, 'definition': definition}),
      ).timeout(const Duration(seconds: 3));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getSavedWords() async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/api/saved'))
          .timeout(const Duration(seconds: 3));
      final data = jsonDecode(resp.body);
      return List<Map<String, dynamic>>.from(data['words'] ?? []);
    } catch (_) {
      return [];
    }
  }

  Future<bool> deleteSavedWord(String word) async {
    try {
      final resp = await http.delete(
        Uri.parse('$_baseUrl/api/saved/${Uri.encodeComponent(word)}'),
      ).timeout(const Duration(seconds: 3));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // FLASHCARD DECKS
  // ══════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getDecks() async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/api/decks'))
          .timeout(const Duration(seconds: 3));
      final data = jsonDecode(resp.body);
      return List<Map<String, dynamic>>.from(data['decks'] ?? []);
    } catch (_) {
      return [];
    }
  }

  Future<int?> createDeck(String name, {String source = 'manual'}) async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/decks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'source': source}),
      ).timeout(const Duration(seconds: 3));
      final data = jsonDecode(resp.body);
      return data['id'];
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteDeck(int deckId) async {
    try {
      final resp = await http.delete(
        Uri.parse('$_baseUrl/api/decks/$deckId'),
      ).timeout(const Duration(seconds: 3));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getCards(int deckId) async {
    try {
      final resp = await http.get(
        Uri.parse('$_baseUrl/api/decks/$deckId/cards'),
      ).timeout(const Duration(seconds: 3));
      final data = jsonDecode(resp.body);
      return List<Map<String, dynamic>>.from(data['cards'] ?? []);
    } catch (_) {
      return [];
    }
  }

  Future<bool> addCard(int deckId, String word, {String? definition}) async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/decks/$deckId/cards'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'word': word, 'definition': definition}),
      ).timeout(const Duration(seconds: 3));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> renameDeck(int deckId, String name) async {
    try {
      final resp = await http.put(
        Uri.parse('$_baseUrl/api/decks/$deckId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name}),
      ).timeout(const Duration(seconds: 3));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateCard(int deckId, int cardId, {String? word, String? definition}) async {
    try {
      final resp = await http.put(
        Uri.parse('$_baseUrl/api/decks/$deckId/cards/$cardId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (word != null) 'word': word,
          if (definition != null) 'definition': definition,
        }),
      ).timeout(const Duration(seconds: 3));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCard(int cardId) async {
    try {
      final resp = await http.delete(
        Uri.parse('$_baseUrl/api/cards/$cardId'),
      ).timeout(const Duration(seconds: 3));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> createDeckFromWords(
    String name, List<String> words, {int? count}
  ) async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/decks/from-words'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'words': words,
          if (count != null) 'count': count,
        }),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(resp.body);
    } catch (_) {
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // QUIZ
  // ══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> generateQuiz({int? deckId, int count = 10}) async {
    try {
      String url = '$_baseUrl/api/quiz/generate?count=$count';
      if (deckId != null) url += '&deck_id=$deckId';
      final resp = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      return jsonDecode(resp.body);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> generateQuizFromWords(
      List<String> words, {int count = 10}) async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/quiz/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'words': words, 'count': count}),
      ).timeout(const Duration(seconds: 30)); // longer timeout for online lookups
      return jsonDecode(resp.body);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> submitQuiz({
    int? deckId,
    required List<Map<String, dynamic>> answers,
    double? durationS,
  }) async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/quiz/submit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deck_id': deckId,
          'answers': answers,
          'duration_s': durationS,
        }),
      ).timeout(const Duration(seconds: 5));
      final data = Map<String, dynamic>.from(jsonDecode(resp.body));
      if (resp.statusCode == 200) {
        notifyProgressChanged();
      }
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getQuizHistory({int limit = 20}) async {
    try {
      final resp = await http.get(
        Uri.parse('$_baseUrl/api/quiz/history?limit=$limit'),
      ).timeout(const Duration(seconds: 3));
      final data = jsonDecode(resp.body);
      return List<Map<String, dynamic>>.from(data['history'] ?? []);
    } catch (_) {
      return [];
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // FILE IMPORT
  // ══════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getImportedFiles() async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/api/import/files'))
          .timeout(const Duration(seconds: 3));
      final data = jsonDecode(resp.body);
      return List<Map<String, dynamic>>.from(data['files'] ?? []);
    } catch (_) {
      return [];
    }
  }

  Future<bool> deleteImportedFile(int fileId) async {
    try {
      final resp = await http.delete(
        Uri.parse('$_baseUrl/api/import/files/$fileId'),
      ).timeout(const Duration(seconds: 3));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getFileWords(int fileId) async {
    try {
      final resp = await http.get(
        Uri.parse('$_baseUrl/api/import/files/$fileId/words'),
      ).timeout(const Duration(seconds: 3));
      final data = jsonDecode(resp.body);
      return List<Map<String, dynamic>>.from(data['words'] ?? []);
    } catch (_) {
      return [];
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // PROFILE
  // ══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/api/profile'))
          .timeout(const Duration(seconds: 3));
      final data = jsonDecode(resp.body);
      return Map<String, dynamic>.from(data['profile'] ?? {});
    } catch (_) {
      return {};
    }
  }

  Future<bool> updateProfile(String key, String value) async {
    try {
      final resp = await http.put(
        Uri.parse('$_baseUrl/api/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'key': key, 'value': value}),
      ).timeout(const Duration(seconds: 3));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // PETS
  // ══════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getAllPets() async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/api/pets'))
          .timeout(const Duration(seconds: 3));
      final data = jsonDecode(resp.body);
      return List<Map<String, dynamic>>.from(data['pets'] ?? []);
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> checkPetUnlocks() async {
    try {
      final resp = await http.post(Uri.parse('$_baseUrl/api/pets/check'))
          .timeout(const Duration(seconds: 3));
      final data = jsonDecode(resp.body);
      return List<String>.from(data['new_pets'] ?? []);
    } catch (_) {
      return [];
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // PERFORMANCE
  // ══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getPerformance() async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/api/performance'))
          .timeout(const Duration(seconds: 3));
      return jsonDecode(resp.body);
    } catch (_) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getPerformanceHistory() async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/api/performance/history'))
          .timeout(const Duration(seconds: 3));
      final data = jsonDecode(resp.body);
      return List<Map<String, dynamic>>.from(data['history'] ?? []);
    } catch (_) {
      return [];
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // PRONUNCIATION
  // ══════════════════════════════════════════════════════════════════

  Future<String?> getPronunciationUrl(String word, {String accent = 'us'}) async {
    try {
      final resp = await http.get(
        Uri.parse('$_baseUrl/api/pronounce?q=${Uri.encodeComponent(word)}&accent=$accent'),
      ).timeout(const Duration(seconds: 5));
      final data = jsonDecode(resp.body);
      return data['audio_url'];
    } catch (_) {
      return null;
    }
  }

  // ── Reverse Search ──
  Future<List<ReverseResult>> reverseSearch(String query) async {
    try {
      final resp = await http.get(
        Uri.parse('$_baseUrl/api/reverse?q=${Uri.encodeComponent(query)}'),
      ).timeout(const Duration(seconds: 5));
      final data = jsonDecode(resp.body);
      return (data['results'] as List)
          .map((r) => ReverseResult(word: r['word'], score: (r['score'] as num).toDouble()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════════
  // PROJECTS
  // ════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getProjects() async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/api/projects'))
          .timeout(const Duration(seconds: 3));
      final data = jsonDecode(resp.body);
      return List<Map<String, dynamic>>.from(data['projects'] ?? []);
    } catch (_) {
      return [];
    }
  }

  Future<int?> createProject(String name, {
    String description = '', String color = '#7C4DFF', String icon = 'folder',
  }) async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/projects'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'description': description, 'color': color, 'icon': icon}),
      ).timeout(const Duration(seconds: 3));
      final data = jsonDecode(resp.body);
      return data['id'];
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteProject(int projectId) async {
    try {
      final resp = await http.delete(Uri.parse('$_baseUrl/api/projects/$projectId'))
          .timeout(const Duration(seconds: 3));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateProject(int projectId, {String? name, String? description, String? color, String? icon}) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (color != null) body['color'] = color;
      if (icon != null) body['icon'] = icon;
      final resp = await http.put(
        Uri.parse('$_baseUrl/api/projects/$projectId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 3));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // FILE IMPORT (fixed with MultipartRequest)
  // ════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> importFile(String filePath) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/import/file'),
      );
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      final resp = await request.send().timeout(const Duration(seconds: 15));
      final body = await resp.stream.bytesToString();
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // AVATAR UPLOAD
  // ════════════════════════════════════════════════════════════════

  Future<bool> uploadAvatar(String filePath) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/profile/avatar'),
      );
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      final resp = await request.send().timeout(const Duration(seconds: 10));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  String get avatarUrl => '$_baseUrl/api/profile/avatar';

  // ══════════════════════════════════════════════════════════════════
  // XP & LEVELING
  // ══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getXpStatus() async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/api/xp/status'))
          .timeout(const Duration(seconds: 3));
      return Map<String, dynamic>.from(jsonDecode(resp.body));
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> awardXp(String action) async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/xp/award'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': action}),
      ).timeout(const Duration(seconds: 3));
      final data = Map<String, dynamic>.from(jsonDecode(resp.body));
      if (resp.statusCode == 200 && (data['awarded'] ?? 0) != 0) {
        notifyProgressChanged();
      }
      return data;
    } catch (_) {
      return {};
    }
  }

  // ── Quests ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getQuests() async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/api/quests'))
          .timeout(const Duration(seconds: 3));
      final data = jsonDecode(resp.body);
      return List<Map<String, dynamic>>.from(data['quests'] ?? []);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAchievements() async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/api/achievements'))
          .timeout(const Duration(seconds: 3));
      final data = jsonDecode(resp.body);
      return List<Map<String, dynamic>>.from(data['achievements'] ?? []);
    } catch (_) {
      return [];
    }
  }

  // ── Project Detail ─────────────────────────────────────────────

  Future<Map<String, dynamic>?> getProject(int projectId) async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/api/projects/$projectId'))
          .timeout(const Duration(seconds: 3));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> createProjectDeck(int projectId, String name) async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/projects/$projectId/deck'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'source': 'project:$projectId'}),
      ).timeout(const Duration(seconds: 3));
      return jsonDecode(resp.body);
    } catch (_) {
      return null;
    }
  }
  // ── v5.3 — Lexi-AI ────────────────────────────────────────────────

  Future<Map<String, dynamic>> sendAiChat(
    List<Map<String, String>> messages, {
    String model = 'DeepSeek-R1',
    int? conversationId,
  }) async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'messages': messages,
          'model': model,
          'conversation_id': conversationId,
        }),
      ).timeout(const Duration(seconds: 60));
      return Map<String, dynamic>.from(jsonDecode(resp.body));
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> getAiHistory() async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/api/ai/history'))
          .timeout(const Duration(seconds: 5));
      final data = jsonDecode(resp.body);
      return List<Map<String, dynamic>>.from(data['conversations'] ?? []);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getAiConversation(int convId) async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/api/ai/history/$convId'))
          .timeout(const Duration(seconds: 5));
      final data = jsonDecode(resp.body);
      return Map<String, dynamic>.from(data['conversation'] ?? {});
    } catch (_) {
      return null;
    }
  }

  Future<int?> saveAiConversation({
    int? conversationId,
    required String title,
    required String model,
    required List<Map<String, String>> messages,
  }) async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/ai/history'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'conversation_id': conversationId,
          'title': title,
          'model': model,
          'messages': messages,
        }),
      ).timeout(const Duration(seconds: 5));
      final data = jsonDecode(resp.body);
      return data['conversation_id'] as int?;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteAiConversation(int convId) async {
    try {
      await http.delete(Uri.parse('$_baseUrl/api/ai/history/$convId'))
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> lookupWord(String word) async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/api/search/${Uri.encodeComponent(word)}'))
          .timeout(const Duration(seconds: 5));
      final data = jsonDecode(resp.body);
      if (data['found'] == true) return data;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<int> deleteAllAiConversations() async {
    try {
      final resp = await http.delete(Uri.parse('$_baseUrl/api/ai/history'))
          .timeout(const Duration(seconds: 5));
      final data = jsonDecode(resp.body);
      return data['deleted'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }


  Future<Map<String, dynamic>> getDictionaryWords({String letter = '', int page = 1, int limit = 100}) async {
    try {
      final resp = await http.get(
        Uri.parse('$_baseUrl/api/dictionary/words?letter=$letter&page=$page&limit=$limit'),
      ).timeout(const Duration(seconds: 5));
      return jsonDecode(resp.body);
    } catch (_) {
      return {'words': [], 'total': 0, 'page': 1, 'pages': 0};
    }
  }

  Future<Map<String, dynamic>> addSavedToDictionary() async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/dictionary/add-saved'),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(resp.body);
    } catch (_) {
      return {'added': 0, 'message': 'Failed to add words'};
    }
  }

  Future<Map<String, dynamic>> getDictionaryLetters() async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/api/dictionary/letters'))
          .timeout(const Duration(seconds: 5));
      return jsonDecode(resp.body);
    } catch (_) {
      return {'letters': {}, 'total': 0};
    }
  }

  Stream<Map<String, dynamic>> importFileWithProgress(String filePath, {bool searchOnline = true}) async* {
    final client = http.Client();
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/import/file/stream?search_online=$searchOnline'),
      );
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      final response = await client.send(request).timeout(const Duration(minutes: 5));
      final stream = response.stream.transform(utf8.decoder).transform(const LineSplitter());
      await for (final line in stream) {
        if (line.startsWith('data: ')) {
          try {
            final data = jsonDecode(line.substring(6));
            yield data;
          } catch (_) {}
        }
      }
    } finally {
      client.close();
    }
  }

  /// Stream AI chat via SSE — yields events {type, content} in real-time.
  Stream<Map<String, dynamic>> streamAiChat(
    List<Map<String, String>> messages, {
    String model = 'DeepSeek-R1',
    bool webSearch = false,
    List<String>? images,
  }) async* {
    final client = http.Client();
    try {
      final request = http.Request(
        'POST',
        Uri.parse('$_baseUrl/api/ai/chat/stream'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'messages': messages,
        'model': model,
        'web_search': webSearch,
        if (images != null && images.isNotEmpty) 'images': images,
      });

      final response = await client.send(request).timeout(const Duration(seconds: 120));
      final stream = response.stream.transform(utf8.decoder).transform(const LineSplitter());

      await for (final line in stream) {
        if (!line.startsWith('data: ')) continue;
        final payload = line.substring(6).trim();
        if (payload.isEmpty) continue;
        try {
          final event = Map<String, dynamic>.from(jsonDecode(payload));
          yield event;
          if (event['type'] == 'done' || event['type'] == 'error') break;
        } catch (_) {}
      }
    } catch (e) {
      yield {'type': 'error', 'content': e.toString()};
    } finally {
      client.close();
    }
  }

  void dispose() {
    _ws?.sink.close();
    _autocompleteController.close();
  }
}

// ══════════════════════════════════════════════════════════════════════
// DATA MODELS
// ══════════════════════════════════════════════════════════════════════

class SearchResult {
  final bool found;
  final String query;
  final Map<String, dynamic>? definition;
  final String? source;
  final double timingMs;

  SearchResult({
    required this.found,
    required this.query,
    this.definition,
    this.source,
    this.timingMs = 0,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      found: json['found'] ?? false,
      query: json['query'] ?? '',
      definition: json['definition'],
      source: json['source'],
      timingMs: (json['timing_ms'] ?? 0).toDouble(),
    );
  }

  String get word => definition?['word'] ?? query;
  List<String> get pos => List<String>.from(definition?['pos'] ?? []);
  List<String> get definitions => List<String>.from(definition?['definitions'] ?? []);
  List<String> get synonyms => List<String>.from(definition?['synonyms'] ?? []);
  List<String> get examples => List<String>.from(definition?['examples'] ?? []);
  String get etymology => definition?['etymology'] ?? '';
  String? get audioUs => definition?['audio_us'];
  String? get audioUk => definition?['audio_uk'];
}

class AutocompleteResult {
  final String prefix;
  final List<String> suggestions;
  final double timingMs;
  AutocompleteResult({required this.prefix, required this.suggestions, this.timingMs = 0});
}

class AutocompleteItem {
  final String word;
  AutocompleteItem({required this.word});
}

class ReverseResult {
  final String word;
  final double score;
  ReverseResult({required this.word, required this.score});
}

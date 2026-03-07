/// LexiCore — Engine API Service
/// Communicates with the Python FastAPI backend at localhost:8741.
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

  WebSocketChannel? _ws;
  final _autocompleteController = StreamController<AutocompleteResult>.broadcast();
  Stream<AutocompleteResult> get autocompleteStream => _autocompleteController.stream;

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

  // ── HTTP Endpoints ──
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
        Uri.parse('$_baseUrl/api/autocomplete?prefix=${Uri.encodeComponent(prefix)}&limit=8'),
      ).timeout(const Duration(seconds: 3));
      final data = jsonDecode(resp.body);
      return (data['suggestions'] as List).map((s) => AutocompleteItem(word: s.toString())).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/api/stats'))
          .timeout(const Duration(seconds: 3));
      return jsonDecode(resp.body);
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>?> getWordOfTheDay() async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/api/wotd'))
          .timeout(const Duration(seconds: 3));
      return jsonDecode(resp.body);
    } catch (_) {
      return null;
    }
  }

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

  void dispose() {
    _ws?.sink.close();
    _autocompleteController.close();
  }
}

// ── Data Models ──

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

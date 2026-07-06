import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/vocabulary.dart';
import '../models/topic_data.dart';
import '../services/vocabulary_service.dart';
import '../services/topic_service.dart';

class FlashcardProvider extends ChangeNotifier {
  final VocabularyService _vocabService;
  final TopicService _topicService;

  bool _isLoading = false;
  List<Vocabulary> _data = [];
  List<SeedVocabItem> _seedData = [];
  List<String> _topics = [];
  String? _errorMessage;
  String _selectedTopic = 'all';
  bool _useSeedData = false;

  // ─── Session stats ──────────────────────────────────────
  int _sessionReviewed = 0;
  int _sessionCorrect = 0;

  // ─── Shuffle ────────────────────────────────────────────
  bool _shuffleEnabled = false;

  // ─── Skip known ─────────────────────────────────────────
  bool _skipKnown = false;

  bool get isLoading => _isLoading;
  List<dynamic> get _rawData => _useSeedData ? _seedData : _data;
  List<String> get topics => _topics;
  String? get errorMessage => _errorMessage;
  String get selectedTopic => _selectedTopic;
  int get sessionReviewed => _sessionReviewed;
  int get sessionCorrect => _sessionCorrect;
  int get sessionAccuracy => _sessionReviewed > 0 ? (_sessionCorrect / _sessionReviewed * 100).round() : 0;
  bool get shuffleEnabled => _shuffleEnabled;
  bool get skipKnown => _skipKnown;

  /// The filtered/shuffled deck.
  List<dynamic> get data {
    var items = _rawData;
    if (_skipKnown) {
      items = items.where((item) {
        if (item is Vocabulary) return item.reviewCount < 5;
        return true; // seed data always shown
      }).toList();
    }
    return items;
  }

  /// Returns a map of topic -> item count for the current deck.
  Map<String, int> get topicItemCount {
    final counts = <String, int>{};
    final items = _rawData;
    for (final item in items) {
      final topic = item is Vocabulary
          ? item.topic
          : (item.topic as String? ?? 'general');
      counts[topic] = (counts[topic] ?? 0) + 1;
    }
    return counts;
  }

  /// Compute mastery percentage for a given topic.
  double getTopicMastery(String topic) {
    final items = _data.where((v) => v.topic == topic).toList();
    if (items.isEmpty) return 0.0;
    final mastered = items.where((v) => v.reviewCount >= 5).length;
    return mastered / items.length;
  }

  FlashcardProvider(this._vocabService, this._topicService);

  void updateAuth(dynamic auth) {}

  void resetSession() {
    _sessionReviewed = 0;
    _sessionCorrect = 0;
    notifyListeners();
  }

  void toggleShuffle() {
    _shuffleEnabled = !_shuffleEnabled;
    if (_shuffleEnabled) {
      _shuffleDeck();
    }
    notifyListeners();
  }

  void setSkipKnown(bool value) {
    _skipKnown = value;
    notifyListeners();
  }

  void _shuffleDeck() {
    final random = Random();
    if (_useSeedData) {
      _seedData.shuffle(random);
    } else {
      _data.shuffle(random);
    }
  }

  Future<void> loadDeck({String? topic}) async {
    _isLoading = true;
    _errorMessage = null;
    if (topic != null) {
      _selectedTopic = topic;
    }
    resetSession();
    notifyListeners();

    try {
      // Try loading user vocabulary first
      final response = await _vocabService.getList(
        page: 1,
        limit: 100,
        topic: _selectedTopic == 'all' ? null : _selectedTopic,
      );
      _data = List<Vocabulary>.from(response['items'] as List);

      if (_data.isNotEmpty) {
        _useSeedData = false;
        final topicSet = <String>{};
        for (final item in _data) {
          if (item.topic.isNotEmpty) {
            topicSet.add(item.topic);
          }
        }
        _topics = topicSet.toList()..sort();

        if (_shuffleEnabled) _shuffleDeck();
      } else {
        // Fallback to seed data
        await _loadSeedDeck();
      }
    } catch (e) {
      // Fallback to seed data on error
      await _loadSeedDeck();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSeedDeck() async {
    try {
      final seedTopics = await _topicService.getSeedTopics();
      _topics = seedTopics.map((t) => t.title).toList();

      if (_selectedTopic != 'all') {
        // Find lesson ID from topic title
        final topicItem = seedTopics.where(
          (t) => t.title.toLowerCase().contains(_selectedTopic.toLowerCase()),
        ).firstOrNull;

        if (topicItem != null) {
          final lessonTopicMap = {
            'Greetings & Introductions': 'greetings',
            'Family & Relationships': 'family',
            'Numbers, Time & Dates': 'numbers',
            'Daily Routines': 'daily',
            'Food & Drinks': 'food',
            'Travel & Directions': 'travel',
            'Shopping & Prices': 'shopping',
            'Weather & Seasons': 'weather',
            'Health & Body': 'health',
            'Work & Business': 'work',
            'Education & School': 'education',
            'Entertainment & Hobbies': 'entertainment',
            'Technology & Internet': 'technology',
            'Emotions & Feelings': 'emotions',
            'Society & Culture': 'society',
          };
          final topicKey = lessonTopicMap[_selectedTopic] ?? _selectedTopic.toLowerCase();
          final result = await _topicService.getSeedVocab(topic: topicKey, limit: 50);
          _seedData = result['items'] as List<SeedVocabItem>;
          _useSeedData = _seedData.isNotEmpty;
        } else {
          _seedData = [];
          _useSeedData = false;
        }
      } else {
        // Load all seed vocab (all topics)
        final result = await _topicService.getSeedVocab(limit: 200);
        _seedData = result['items'] as List<SeedVocabItem>;
        _useSeedData = _seedData.isNotEmpty;
      }

      if (_shuffleEnabled) _shuffleDeck();
    } catch (e) {
      _errorMessage = 'Không thể tải flashcard lúc này.';
      _useSeedData = false;
      _seedData = [];
      _data = [];
    }
  }

  Future<void> setTopic(String topic) async {
    await loadDeck(topic: topic);
  }

  /// Review a vocabulary word with SM-2 quality rating.
  /// If [id] is null (seed data), skips the API call.
  /// Returns true on success, false on failure.
  Future<bool> reviewWord(String? id, int quality) async {
    _sessionReviewed++;
    if (quality >= 3) _sessionCorrect++;
    notifyListeners();

    if (id == null) return true; // seed data, skip API call
    try {
      await _vocabService.reviewWord(id, quality);
      return true;
    } catch (e) {
      _errorMessage = 'Không thể ghi nhận kết quả ôn tập.';
      notifyListeners();
      return false;
    }
  }
}

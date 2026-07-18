import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/vocabulary.dart';
import '../models/topic_data.dart';
import '../services/vocabulary_service.dart';
import '../services/topic_service.dart';

enum FlashcardStudyMode { mixed, due, newWords, weak }

enum FlashcardCardMode { random, wordFirst, meaningFirst, listening, typing }

class FlashcardProvider extends ChangeNotifier {
  final VocabularyService _vocabService;
  final TopicService _topicService;

  bool _isLoading = false;
  List<Vocabulary> _data = [];
  List<SeedVocabItem> _seedData = [];
  List<String> _topics = [];
  final Map<String, int> _seedTopicCounts = {};
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
  FlashcardStudyMode _studyMode = FlashcardStudyMode.mixed;
  FlashcardCardMode _cardMode = FlashcardCardMode.random;
  int _sessionLimit = 10;
  int _sessionMinutes = 10;
  int _sessionMastered = 0;
  int _sessionNeedsReview = 0;
  int _combo = 0;

  bool get isLoading => _isLoading;
  List<dynamic> get _rawData => _useSeedData ? _seedData : _data;
  List<String> get topics => _topics;
  String? get errorMessage => _errorMessage;
  String get selectedTopic => _selectedTopic;
  int get sessionReviewed => _sessionReviewed;
  int get sessionCorrect => _sessionCorrect;
  int get sessionAccuracy => _sessionReviewed > 0
      ? (_sessionCorrect / _sessionReviewed * 100).round()
      : 0;
  bool get shuffleEnabled => _shuffleEnabled;
  bool get skipKnown => _skipKnown;
  FlashcardStudyMode get studyMode => _studyMode;
  FlashcardCardMode get cardMode => _cardMode;
  int get sessionLimit => _sessionLimit;
  int get sessionMinutes => _sessionMinutes;
  int get sessionMastered => _sessionMastered;
  int get sessionNeedsReview => _sessionNeedsReview;
  int get combo => _combo;
  int get dueCount {
    final today = DateTime.now();
    return _data.where((item) {
      final due = item.nextReviewDate;
      return due != null &&
          !due.isAfter(DateTime(today.year, today.month, today.day));
    }).length;
  }

  /// The filtered/shuffled deck.
  List<dynamic> get data {
    var items = List<dynamic>.from(_rawData);
    if (_skipKnown) {
      items = items.where((item) {
        if (item is Vocabulary) return item.reviewCount < 5;
        return true; // seed data always shown
      }).toList();
    }
    if (_useSeedData &&
        (_studyMode == FlashcardStudyMode.due ||
            _studyMode == FlashcardStudyMode.weak)) {
      items = [];
    } else if (!_useSeedData) {
      final vocabItems = items.cast<Vocabulary>();
      final today = DateTime.now();
      bool isDue(Vocabulary item) =>
          item.nextReviewDate != null &&
          !item.nextReviewDate!.isAfter(
            DateTime(today.year, today.month, today.day),
          );
      switch (_studyMode) {
        case FlashcardStudyMode.due:
          items = vocabItems.where(isDue).toList();
        case FlashcardStudyMode.newWords:
          items = vocabItems.where((item) => item.reviewCount == 0).toList();
        case FlashcardStudyMode.weak:
          items = vocabItems
              .where(
                (item) =>
                    item.timesWrong > 0 && item.timesWrong >= item.timesCorrect,
              )
              .toList();
        case FlashcardStudyMode.mixed:
          final due = vocabItems.where(isDue).toList();
          final fresh = vocabItems
              .where((item) => item.reviewCount == 0 && !isDue(item))
              .toList();
          final rest = vocabItems
              .where((item) => !due.contains(item) && !fresh.contains(item))
              .toList();
          final dueTarget = (_sessionLimit * 0.7).ceil();
          items = [
            ...due.take(dueTarget),
            ...fresh.take(_sessionLimit - due.take(dueTarget).length),
            ...rest,
          ];
      }
    }
    return items.take(_sessionLimit).toList();
  }

  /// Returns a map of topic -> item count for the current deck.
  Map<String, int> get topicItemCount {
    if (_useSeedData) return Map<String, int>.from(_seedTopicCounts);
    final counts = <String, int>{..._seedTopicCounts};
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

  void resetSession() {
    _sessionReviewed = 0;
    _sessionCorrect = 0;
    _sessionMastered = 0;
    _sessionNeedsReview = 0;
    _combo = 0;
    notifyListeners();
  }

  void configureSession({
    required FlashcardStudyMode studyMode,
    required FlashcardCardMode cardMode,
    required int sessionLimit,
    required int sessionMinutes,
  }) {
    _studyMode = studyMode;
    _cardMode = cardMode;
    _sessionLimit = sessionLimit;
    _sessionMinutes = sessionMinutes;
    resetSession();
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
      final seedTopics = await _topicService.getSeedTopics();
      _seedTopicCounts
        ..clear()
        ..addEntries(
          seedTopics.map((item) => MapEntry(item.title, item.count)),
        );
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
        _topics = {
          ...seedTopics.map((item) => item.title),
          ...topicSet,
        }.toList()..sort();

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
      _seedTopicCounts
        ..clear()
        ..addEntries(
          seedTopics.map((item) => MapEntry(item.title, item.count)),
        );

      if (_selectedTopic != 'all') {
        // Find lesson ID from topic title
        final topicItem = seedTopics
            .where(
              (t) =>
                  t.title.toLowerCase().contains(_selectedTopic.toLowerCase()),
            )
            .firstOrNull;

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
          final topicKey =
              lessonTopicMap[_selectedTopic] ?? _selectedTopic.toLowerCase();
          final result = await _topicService.getSeedVocab(
            topic: topicKey,
            limit: 50,
          );
          _seedData = result['items'] as List<SeedVocabItem>;
          _useSeedData = _seedData.isNotEmpty;
        } else {
          _seedData = [];
          _useSeedData = false;
        }
      } else {
        // Load all seed vocab (all topics)
        final result = await _topicService.getSeedVocab(limit: 500);
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
    if (quality >= 3) {
      _sessionCorrect++;
      _combo++;
    } else {
      _combo = 0;
    }
    if (quality >= 4) _sessionMastered++;
    if (quality < 3) _sessionNeedsReview++;
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

  Future<bool> toggleBookmark(String? id) async {
    if (id == null) return false;
    try {
      final updated = await _vocabService.toggleBookmark(id);
      final index = _data.indexWhere((item) => item.id == id);
      if (index >= 0) _data[index] = updated;
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Không thể cập nhật từ đã lưu.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateNote(String? id, String note) async {
    if (id == null) return false;
    try {
      final updated = await _vocabService.update(id, {
        'personal_note': note.trim(),
      });
      final index = _data.indexWhere((item) => item.id == id);
      if (index >= 0) _data[index] = updated;
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Không thể lưu ghi chú cá nhân.';
      notifyListeners();
      return false;
    }
  }
}

import 'package:flutter/foundation.dart';

import '../models/topic_data.dart';
import '../services/topic_service.dart';

class TopicProvider extends ChangeNotifier {
  final TopicService _service;

  bool _isLoading = false;
  String? _errorMessage;
  List<SeedTopicItem> _topics = [];
  List<SeedVocabItem> _vocabItems = [];
  int _totalVocab = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _currentTopic;
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<SeedTopicItem> get topics => _topics;
  List<SeedVocabItem> get vocabItems => _vocabItems;
  int get totalVocab => _totalVocab;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  String? get currentTopic => _currentTopic;
  String get searchQuery => _searchQuery;

  List<SeedTopicItem> get filteredTopics {
    if (_searchQuery.isEmpty) return _topics;
    final q = _searchQuery.toLowerCase();
    return _topics.where((t) =>
        t.title.toLowerCase().contains(q) ||
        t.description.toLowerCase().contains(q)).toList();
  }

  TopicProvider(this._service);

  Future<void> loadTopics() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _topics = await _service.getSeedTopics();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách chủ đề.';
      _topics = [];
      debugPrint('TopicProvider error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadVocabByTopic({
    required String topic,
    int page = 1,
    String? search,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _currentTopic = topic;
    _currentPage = page;
    notifyListeners();

    try {
      final result = await _service.getSeedVocab(
        topic: topic,
        page: page,
        limit: 20,
        search: search,
      );
      _vocabItems = result['items'] as List<SeedVocabItem>;
      _totalVocab = result['total'] as int;
      _totalPages = result['pages'] as int;
    } catch (e) {
      _errorMessage = 'Không thể tải từ vựng.';
      _vocabItems = [];
      _totalVocab = 0;
      debugPrint('TopicProvider error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

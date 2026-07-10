import 'package:flutter/foundation.dart';

import '../data/mini_test_questions.dart';
import '../models/mock_test.dart';
import '../services/mock_test_service.dart';

class MockTestProvider extends ChangeNotifier {
  final MockTestService _service;

  bool _isLoading = false;
  String? _errorMessage;
  String _selectedLevel = 'beginner';
  String? _selectedTopic;
  List<String> _availableTopics = [];
  List<MockTestHistoryItem> _history = [];
  int _historyTotal = 0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedLevel => _selectedLevel;
  String? get selectedTopic => _selectedTopic;
  List<String> get availableTopics => _availableTopics;
  List<MockTestHistoryItem> get history => _history;
  int get historyTotal => _historyTotal;

  MockTestProvider(this._service);

  void setLevel(String level) {
    _selectedLevel = level;
    notifyListeners();
  }

  void setTopic(String? topic) {
    _selectedTopic = topic;
    notifyListeners();
  }

  Future<void> loadAvailableTopics() async {
    try {
      final remoteTopics = await _service.getAvailableTopics();
      // Luôn thêm 3 chủ đề từ local question bank
      _availableTopics = {...remoteTopics, ...MiniTestBank.topicKeys}.toList()..sort();
      notifyListeners();
    } catch (e) {
      // Fallback: chỉ dùng local topics
      _availableTopics = List.from(MiniTestBank.topicKeys);
      notifyListeners();
      debugPrint('MockTestProvider topics error: $e');
    }
  }

  /// Lấy câu hỏi từ local question bank (theo topic + level)
  List<MockTestQuestion> getLocalQuestions(String? topicKey, String? levelKey) {
    final all = <MockTestQuestion>[];
    final topics = topicKey != null ? [topicKey] : MiniTestBank.topicKeys;
    for (final t in topics) {
      final byTopic = MiniTestBank.data[t];
      if (byTopic == null) continue;
      if (levelKey != null && byTopic.containsKey(levelKey)) {
        all.addAll(byTopic[levelKey]!);
      } else {
        for (final qs in byTopic.values) {
          all.addAll(qs);
        }
      }
    }
    return all;
  }

  Future<void> loadHistory({int page = 1, int limit = 20}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.getHistory(page: page, limit: limit);
      _history = result['items'] as List<MockTestHistoryItem>;
      _historyTotal = result['total'] as int;
    } catch (e) {
      _errorMessage = 'Không thể tải lịch sử kiểm tra.';
      _history = [];
      _historyTotal = 0;
      debugPrint('MockTestProvider error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

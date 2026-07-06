import 'package:flutter/foundation.dart';

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

  void updateAuth(dynamic auth) {}

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
      _availableTopics = await _service.getAvailableTopics();
      notifyListeners();
    } catch (e) {
      debugPrint('MockTestProvider topics error: $e');
    }
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

import 'package:flutter/foundation.dart';
import '../models/vocabulary.dart';
import '../services/vocabulary_service.dart';
import 'auth_provider.dart';

class VocabularyProvider extends ChangeNotifier {
  final VocabularyService _service;
  List<Vocabulary> _items = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedTopic = 'all';
  int _total = 0;
  int _currentPage = 1;

  List<Vocabulary> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedTopic => _selectedTopic;
  int get total => _total;
  int get currentPage => _currentPage;

  List<Vocabulary> get filtered {
    var result = _items;
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((v) =>
              v.word.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              v.meaning.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    if (_selectedTopic != 'all') {
      result = result.where((v) => v.topic == _selectedTopic).toList();
    }
    return result;
  }

  List<String> get topics {
    final topicSet = <String>{};
    for (final v in _items) {
      topicSet.add(v.topic);
    }
    return topicSet.toList()..sort();
  }

  VocabularyProvider(this._service);

  void updateAuth(AuthProvider auth) {
    // Auth state changed, no special handling needed
  }

  Future<void> fetchAll({String? search, String? topic, int? limit}) async {
    _isLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    notifyListeners();

    try {
      final result = await _service.getList(
        page: _currentPage,
        limit: limit ?? 20,
        search: search ?? _searchQuery,
        topic: topic ?? _selectedTopic,
      );
      _items = result['items'] as List<Vocabulary>;
      _total = result['total'] as int;
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách từ vựng. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || _items.length >= _total) return;
    _isLoading = true;
    notifyListeners();

    try {
      _currentPage++;
      final result = await _service.getList(
        page: _currentPage,
        search: _searchQuery,
        topic: _selectedTopic,
      );
      _items.addAll(result['items'] as List<Vocabulary>);
    } catch (e) {
      _currentPage--;
      _errorMessage = 'Không thể tải thêm từ vựng.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> add(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.create(data);
      await fetchAll();
    } catch (e) {
      _errorMessage = 'Không thể thêm từ vựng. Vui lòng thử lại.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.update(id, data);
      await fetchAll();
    } catch (e) {
      _errorMessage = 'Không thể cập nhật từ vựng. Vui lòng thử lại.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> delete(String id) async {
    _errorMessage = null;

    try {
      await _service.delete(id);
      _items.removeWhere((v) => v.id == id);
      _total--;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể xoá từ vựng. Vui lòng thử lại.';
      notifyListeners();
    }
  }

  void setSearch(String query) {
    _searchQuery = query;
    fetchAll(search: query);
  }

  void setTopic(String topic) {
    _selectedTopic = topic;
    fetchAll(topic: topic);
  }
}

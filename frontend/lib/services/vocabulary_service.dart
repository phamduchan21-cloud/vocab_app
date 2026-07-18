import '../models/vocabulary.dart';
import 'api_service.dart';

class VocabularyService {
  final ApiService _api;

  VocabularyService(this._api);

  Future<Map<String, dynamic>> getList({
    int page = 1,
    int limit = 20,
    String? search,
    String? topic,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (topic != null && topic.isNotEmpty && topic != 'all') {
      params['topic'] = topic;
    }

    final response = await _api.get('/api/vocabularies', queryParams: params);
    final items = (response['items'] as List)
        .map((item) => Vocabulary.fromJson(item))
        .toList();
    return {
      'items': items,
      'total': response['total'] ?? 0,
      'page': response['page'] ?? page,
      'pages': response['pages'] ?? 1,
    };
  }

  Future<Vocabulary> getById(String id) async {
    final response = await _api.get('/api/vocabularies/$id');
    return Vocabulary.fromJson(response);
  }

  Future<Vocabulary> create(Map<String, dynamic> data) async {
    final response = await _api.post('/api/vocabularies', body: data);
    return Vocabulary.fromJson(response);
  }

  Future<Vocabulary> update(String id, Map<String, dynamic> data) async {
    final response = await _api.put('/api/vocabularies/$id', body: data);
    return Vocabulary.fromJson(response);
  }

  Future<void> delete(String id) async {
    await _api.delete('/api/vocabularies/$id');
  }

  Future<Vocabulary> reviewWord(String id, int quality) async {
    final response = await _api.put(
      '/api/vocabularies/$id/review',
      body: {'quality': quality},
    );
    return Vocabulary.fromJson(response);
  }

  Future<Vocabulary> toggleBookmark(String id) async {
    final response = await _api.post('/api/vocabularies/$id/bookmark');
    return Vocabulary.fromJson(response);
  }

  Future<Map<String, dynamic>> getBookmarked({
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _api.get(
      '/api/vocabularies/bookmarked/all',
      queryParams: {'page': page.toString(), 'limit': limit.toString()},
    );
    final items = (response['items'] as List)
        .map((item) => Vocabulary.fromJson(item))
        .toList();
    return {'items': items, 'total': response['total'] ?? 0};
  }
}

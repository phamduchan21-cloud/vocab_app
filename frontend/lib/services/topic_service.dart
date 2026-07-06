import '../models/topic_data.dart';
import 'api_service.dart';

class TopicService {
  final ApiService _api;

  TopicService(this._api);

  Future<List<SeedTopicItem>> getSeedTopics() async {
    final response = await _api.get('/api/vocabularies/seed-topics');
    final data = response as Map<String, dynamic>;
    return (data['topics'] as List)
        .map((item) => SeedTopicItem.fromJson(item))
        .toList();
  }

  Future<Map<String, dynamic>> getSeedVocab({
    String? topic,
    int? lessonId,
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (topic != null && topic.isNotEmpty) params['topic'] = topic;
    if (lessonId != null) params['lesson_id'] = lessonId.toString();
    if (search != null && search.isNotEmpty) params['search'] = search;

    final response = await _api.get('/api/vocabularies/seed-vocab',
        queryParams: params);
    final items = (response['items'] as List)
        .map((item) => SeedVocabItem.fromJson(item))
        .toList();
    return {
      'items': items,
      'total': response['total'] ?? 0,
      'page': response['page'] ?? page,
      'pages': response['pages'] ?? 1,
    };
  }
}

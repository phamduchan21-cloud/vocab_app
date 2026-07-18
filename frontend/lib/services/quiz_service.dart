import '../models/quiz_category.dart';
import '../models/quiz_result.dart';
import '../models/quiz_topic.dart';
import 'api_service.dart';

class QuizService {
  final ApiService _api;

  QuizService(this._api);

  Future<List<QuizCategory>> getCategories() async {
    final response = await _api.get('/api/quiz/categories');
    return (response as List)
        .map((item) => QuizCategory.fromJson(item))
        .toList();
  }

  Future<List<QuizTopic>> getTopics() async {
    final response = await _api.get('/api/quiz/topics');
    return (response as List)
        .map((item) => QuizTopic.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> generateQuiz({
    int count = 5,
    String? topic,
    String? skillType,
  }) async {
    final body = <String, dynamic>{'count': count};
    if (topic != null && topic.isNotEmpty && topic != 'all') {
      body['topic'] = topic;
    }
    if (skillType != null && skillType.isNotEmpty) {
      body['skill_type'] = skillType;
    }

    final response = await _api.post('/api/quiz/generate', body: body);
    return (response['questions'] as List)
        .map((q) => q as Map<String, dynamic>)
        .toList();
  }

  Future<QuizResult> submitQuiz({
    required String quizType,
    required List<Map<String, dynamic>> answers,
    String? topic,
    String? skillType,
  }) async {
    final body = <String, dynamic>{'quiz_type': quizType, 'answers': answers};
    if (topic != null && topic.isNotEmpty && topic != 'all') {
      body['topic'] = topic;
    }
    if (skillType != null && skillType.isNotEmpty) {
      body['skill_type'] = skillType;
    }

    final response = await _api.post('/api/quiz/submit', body: body);
    return QuizResult.fromJson(response);
  }

  Future<Map<String, dynamic>> getHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get(
      '/api/quiz/history',
      queryParams: {'page': page.toString(), 'limit': limit.toString()},
    );
    final items = (response['items'] as List)
        .map((item) => QuizResult.fromJson(item))
        .toList();
    return {'items': items, 'total': response['total'] ?? 0};
  }
}

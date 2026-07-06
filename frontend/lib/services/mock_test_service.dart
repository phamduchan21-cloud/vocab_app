import '../models/mock_test.dart';
import 'api_service.dart';

class MockTestService {
  final ApiService _api;

  MockTestService(this._api);

  Future<MockTestSession> generate(String level, [String? topic]) async {
    final body = <String, dynamic>{'level': level};
    if (topic != null && topic.isNotEmpty) {
      body['topic'] = topic;
    }
    final response = await _api.post('/api/mock-tests/generate', body: body);
    final data = response as Map<String, dynamic>;
    final questions = (data['questions'] as List)
        .map((q) => MockTestQuestion.fromJson(q))
        .toList();

    return MockTestSession(
      id: data['id'] ?? '',
      level: data['level'] ?? level,
      questions: questions,
      total: data['total'] ?? questions.length,
      durationMinutes: data['duration_minutes'] ?? 40,
    );
  }

  Future<List<String>> getAvailableTopics() async {
    final response = await _api.get('/api/mock-tests/available-topics');
    final data = response as Map<String, dynamic>;
    return (data['topics'] as List).map((t) => t.toString()).toList();
  }

  Future<Map<String, dynamic>> getHistory({int page = 1, int limit = 20}) async {
    final response = await _api.get('/api/mock-tests/history', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
    final items = (response['items'] as List)
        .map((item) => MockTestHistoryItem.fromJson(item))
        .toList();
    return {
      'items': items,
      'total': response['total'] ?? 0,
    };
  }

  Future<MockTestResult> submit(String testId, List<int?> answers, List<MockTestQuestion> questions) async {
    final answerList = List.generate(questions.length, (i) {
      final q = questions[i];
      final selectedIdx = answers[i];
      return {
        'question': q.question,
        'options': q.options,
        'selected': selectedIdx != null ? q.options[selectedIdx] : '',
        'correct_answer': q.correctAnswer,
        'is_correct': selectedIdx != null && q.options[selectedIdx] == q.correctAnswer,
      };
    });

    final response = await _api.post('/api/mock-tests/submit', body: {
      'test_id': testId,
      'answers': answerList,
    });

    return MockTestResult.fromJson(response as Map<String, dynamic>);
  }
}

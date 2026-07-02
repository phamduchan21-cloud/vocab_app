import '../models/mock_test.dart';
import 'api_service.dart';

class MockTestService {
  final ApiService _api;

  MockTestService(this._api);

  Future<MockTestSession> generate(String level) async {
    final response = await _api.post('/api/mock-tests/generate', body: {
      'level': level,
    });
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

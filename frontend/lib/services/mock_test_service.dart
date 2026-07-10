import '../data/mini_test_questions.dart';
import '../models/mock_test.dart';
import 'api_service.dart';

class MockTestService {
  final ApiService _api;

  MockTestService(this._api);

  Future<MockTestSession> generate(String level, [String? topic]) async {
    try {
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
    } catch (_) {
      // Fallback: use local question bank
      final questions = MiniTestBank.getQuestions(level, topic);
      if (questions.isEmpty) rethrow;
      return MockTestSession(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        level: level,
        questions: questions,
        total: questions.length,
        durationMinutes: level == 'beginner' ? 15 : level == 'intermediate' ? 30 : 45,
      );
    }
  }

  Future<List<String>> getAvailableTopics() async {
    try {
      final response = await _api.get('/api/mock-tests/available-topics');
      final data = response as Map<String, dynamic>;
      return (data['topics'] as List).map((t) => t.toString()).toList();
    } catch (_) {
      return MiniTestBank.topicKeys;
    }
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
    try {
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
    } catch (_) {
      // Local mode: build a result from the in-memory data
      int correct = 0;
      for (int i = 0; i < questions.length; i++) {
        if (answers[i] != null && questions[i].options[answers[i]!] == questions[i].correctAnswer) {
          correct++;
        }
      }
      final percent = questions.isEmpty ? 0.0 : (correct * 100 / questions.length);
      return MockTestResult(
        id: testId,
        testLevel: 'local',
        totalQuestions: questions.length,
        correctAnswers: correct,
        scorePercent: percent,
        predictedLevel: percent >= 90 ? 'A' : percent >= 75 ? 'B' : percent >= 50 ? 'C' : 'D',
      );
    }
  }
}

import '../data/mini_test_questions.dart';
import '../models/mock_test.dart';
import 'api_service.dart';

class MockTestService {
  final ApiService _api;

  MockTestService(this._api);

  Future<MockTestSession> generate(MockTestConfig config) async {
    try {
      final body = <String, dynamic>{
        'level': config.level,
        'question_count': config.questionCount,
        'duration_minutes': config.durationMinutes,
        'purpose': config.purpose,
      };
      if (config.topic != null && config.topic!.isNotEmpty) {
        body['topic'] = config.topic;
      }
      final response = await _api.post('/api/mock-tests/generate', body: body);
      final data = response as Map<String, dynamic>;
      final questions = (data['questions'] as List)
          .map((q) => MockTestQuestion.fromJson(q))
          .toList();

      return MockTestSession(
        id: data['id'] ?? '',
        level: data['level'] ?? config.level,
        questions: questions,
        total: data['total'] ?? questions.length,
        durationMinutes: data['duration_minutes'] ?? config.durationMinutes,
      );
    } catch (_) {
      final questions = _localQuestions(config);
      if (questions.isEmpty) rethrow;
      return MockTestSession(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        level: config.level,
        questions: questions,
        total: questions.length,
        durationMinutes: config.durationMinutes,
      );
    }
  }

  List<MockTestQuestion> _localQuestions(MockTestConfig config) {
    final pool = <MockTestQuestion>[];
    final topics = config.topic != null
        ? [config.topic!]
        : MiniTestBank.topicKeys;
    final levelKey = config.level == 'beginner'
        ? 'basic'
        : config.level == 'intermediate'
        ? 'intermediate'
        : 'advanced';
    for (final topic in topics) {
      final topicData = MiniTestBank.data[topic];
      if (topicData == null) continue;
      pool.addAll(topicData[levelKey] ?? topicData.values.expand((e) => e));
    }
    if (pool.isEmpty) return [];
    pool.shuffle();

    const types = [
      ('meaning_match', 'meaning'),
      ('listening', 'pronunciation'),
      ('matching', 'vocabulary'),
      ('fill_blank', 'context'),
    ];
    return List.generate(config.questionCount, (index) {
      final source = pool[index % pool.length];
      final type = types[index % types.length];
      if (type.$1 == 'listening') {
        final match = RegExp(r'"([^"\n]+)"').firstMatch(source.question);
        final audio = match?.group(1) ?? source.correctAnswer;
        return source.copyWith(
          question: 'Nghe và chọn nghĩa đúng của từ được phát âm.',
          questionType: type.$1,
          skill: type.$2,
          audioText: audio,
        );
      }
      return source.copyWith(questionType: type.$1, skill: type.$2);
    });
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

  Future<Map<String, dynamic>> getHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get(
      '/api/mock-tests/history',
      queryParams: {'page': page.toString(), 'limit': limit.toString()},
    );
    final items = (response['items'] as List)
        .map((item) => MockTestHistoryItem.fromJson(item))
        .toList();
    return {'items': items, 'total': response['total'] ?? 0};
  }

  Future<MockTestResult> submit(
    String testId,
    List<int?> answers,
    List<MockTestQuestion> questions, {
    required MockTestConfig config,
    required int durationSeconds,
  }) async {
    try {
      final answerList = List.generate(questions.length, (i) {
        final q = questions[i];
        final selectedIdx = answers[i];
        return {
          'question': q.question,
          'options': q.options,
          'selected': selectedIdx != null ? q.options[selectedIdx] : '',
          'correct_answer': q.correctAnswer,
          'is_correct':
              selectedIdx != null && q.options[selectedIdx] == q.correctAnswer,
          'question_type': q.questionType,
          'skill': q.skill,
          'explanation': q.explanation,
          'audio_text': q.audioText,
          'vocab_id': q.vocabId,
        };
      });

      final response = await _api.post(
        '/api/mock-tests/submit',
        body: {
          'test_id': testId,
          'answers': answerList,
          'duration_seconds': durationSeconds,
          'topic': config.topic,
          'purpose': config.purpose,
          'difficulty': config.level,
        },
      );

      return MockTestResult.fromJson(response as Map<String, dynamic>);
    } catch (_) {
      // Local mode: build a result from the in-memory data
      int correct = 0;
      for (int i = 0; i < questions.length; i++) {
        if (answers[i] != null &&
            questions[i].options[answers[i]!] == questions[i].correctAnswer) {
          correct++;
        }
      }
      final percent = questions.isEmpty
          ? 0.0
          : (correct * 100 / questions.length);
      final breakdown = <String, dynamic>{};
      for (var i = 0; i < questions.length; i++) {
        final skill = questions[i].skill;
        final stats =
            (breakdown[skill] ?? {'correct': 0, 'total': 0})
                as Map<String, dynamic>;
        stats['total'] = (stats['total'] as int) + 1;
        if (answers[i] != null &&
            questions[i].options[answers[i]!] == questions[i].correctAnswer) {
          stats['correct'] = (stats['correct'] as int) + 1;
        }
        stats['percent'] =
            (stats['correct'] as int) * 100 / (stats['total'] as int);
        breakdown[skill] = stats;
      }
      final details = List.generate(questions.length, (i) {
        final question = questions[i];
        final selected = answers[i] == null
            ? ''
            : question.options[answers[i]!];
        return {
          ...question.toJson(),
          'selected': selected,
          'correct_answer': question.correctAnswer,
          'is_correct': selected == question.correctAnswer,
        };
      });
      return MockTestResult(
        id: testId,
        testLevel: 'local',
        totalQuestions: questions.length,
        correctAnswers: correct,
        scorePercent: percent,
        predictedLevel: percent >= 90
            ? 'A'
            : percent >= 75
            ? 'B'
            : percent >= 50
            ? 'C'
            : 'D',
        details: details,
        durationSeconds: durationSeconds,
        xpEarned: correct * (config.level == 'advanced' ? 15 : 10),
        badge: percent == 100
            ? 'Bưu kiện hoàn hảo'
            : percent >= 90
            ? 'Tem vàng tri thức'
            : percent >= 75
            ? 'Chuyến thư bền bỉ'
            : null,
        topic: config.topic,
        breakdown: breakdown,
      );
    }
  }
}

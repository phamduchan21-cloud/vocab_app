class MockTestQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;

  MockTestQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });

  factory MockTestQuestion.fromJson(Map<String, dynamic> json) => MockTestQuestion(
        question: json['question'] ?? '',
        options: (json['options'] as List?)?.map((o) => o.toString()).toList() ?? [],
        correctAnswer: json['correctAnswer'] ?? '',
      );
}

class MockTestSession {
  final String id;
  final String level;
  final List<MockTestQuestion> questions;
  final int total;
  final int durationMinutes;
  final List<int?> answers; // index of selected option, null if not answered

  MockTestSession({
    required this.id,
    required this.level,
    required this.questions,
    required this.total,
    required this.durationMinutes,
    List<int?>? answers,
  }) : answers = answers ?? List.filled(questions.length, null);
}

class MockTestResult {
  final String id;
  final String testLevel;
  final int totalQuestions;
  final int correctAnswers;
  final double scorePercent;
  final String predictedLevel;
  final List<dynamic>? details;
  final DateTime? completedAt;

  MockTestResult({
    required this.id,
    required this.testLevel,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.scorePercent,
    required this.predictedLevel,
    this.details,
    this.completedAt,
  });

  factory MockTestResult.fromJson(Map<String, dynamic> json) => MockTestResult(
        id: json['id'] ?? '',
        testLevel: json['test_level'] ?? '',
        totalQuestions: json['total_questions'] ?? 0,
        correctAnswers: json['correct_answers'] ?? 0,
        scorePercent: (json['score_percent'] ?? 0.0).toDouble(),
        predictedLevel: json['predicted_level'] ?? '1급',
        details: json['details'],
        completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      );
}

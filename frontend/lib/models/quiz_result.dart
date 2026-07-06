class QuizResult {
  final String id;
  final String quizType;
  final String? topic;
  final int totalQuestions;
  final int correctAnswers;
  final double scorePercent;
  final List<dynamic>? details;
  final DateTime completedAt;

  QuizResult({
    required this.id,
    required this.quizType,
    this.topic,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.scorePercent,
    this.details,
    required this.completedAt,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) => QuizResult(
        id: json['id'],
        quizType: json['quiz_type'],
        topic: json['topic'],
        totalQuestions: json['total_questions'],
        correctAnswers: json['correct_answers'],
        scorePercent: (json['score_percent'] as num?)?.toDouble() ?? 0.0,
        details: json['details'],
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'])
            : DateTime.now(),
      );
}

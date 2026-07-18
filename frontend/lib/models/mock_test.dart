class MockTestQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;
  final String difficulty;
  final String questionType;
  final String skill;
  final String? audioText;
  final String? vocabId;

  const MockTestQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    this.difficulty = 'medium',
    this.questionType = 'meaning_match',
    this.skill = 'meaning',
    this.audioText,
    this.vocabId,
  });

  factory MockTestQuestion.fromJson(Map<String, dynamic> json) =>
      MockTestQuestion(
        question: json['question'] ?? '',
        options:
            (json['options'] as List?)?.map((o) => o.toString()).toList() ?? [],
        correctAnswer: json['correctAnswer'] ?? '',
        explanation: json['explanation'],
        difficulty: json['difficulty'] ?? 'medium',
        questionType: json['question_type'] ?? 'meaning_match',
        skill: json['skill'] ?? 'meaning',
        audioText: json['audio_text'],
        vocabId: json['vocab_id'],
      );

  Map<String, dynamic> toJson() => {
    'question': question,
    'options': options,
    'correctAnswer': correctAnswer,
    'explanation': explanation,
    'difficulty': difficulty,
    'question_type': questionType,
    'skill': skill,
    'audio_text': audioText,
    'vocab_id': vocabId,
  };

  MockTestQuestion copyWith({
    String? question,
    List<String>? options,
    String? correctAnswer,
    String? explanation,
    String? difficulty,
    String? questionType,
    String? skill,
    String? audioText,
    String? vocabId,
  }) => MockTestQuestion(
    question: question ?? this.question,
    options: options ?? this.options,
    correctAnswer: correctAnswer ?? this.correctAnswer,
    explanation: explanation ?? this.explanation,
    difficulty: difficulty ?? this.difficulty,
    questionType: questionType ?? this.questionType,
    skill: skill ?? this.skill,
    audioText: audioText ?? this.audioText,
    vocabId: vocabId ?? this.vocabId,
  );
}

class MockTestConfig {
  final String level;
  final String purpose;
  final String? topic;
  final int questionCount;
  final int durationMinutes;

  const MockTestConfig({
    required this.level,
    required this.purpose,
    required this.questionCount,
    required this.durationMinutes,
    this.topic,
  });
}

class MockTestSession {
  final String id;
  final String level;
  final List<MockTestQuestion> questions;
  final int total;
  final int durationMinutes;
  final List<int?> answers;

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
  final List<dynamic> details;
  final DateTime? completedAt;
  final int durationSeconds;
  final int xpEarned;
  final String? badge;
  final String? topic;
  final Map<String, dynamic> breakdown;

  const MockTestResult({
    required this.id,
    required this.testLevel,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.scorePercent,
    required this.predictedLevel,
    this.details = const [],
    this.completedAt,
    this.durationSeconds = 0,
    this.xpEarned = 0,
    this.badge,
    this.topic,
    this.breakdown = const {},
  });

  factory MockTestResult.fromJson(Map<String, dynamic> json) => MockTestResult(
    id: json['id'] ?? '',
    testLevel: json['test_level'] ?? '',
    totalQuestions: json['total_questions'] ?? 0,
    correctAnswers: json['correct_answers'] ?? 0,
    scorePercent: (json['score_percent'] ?? 0.0).toDouble(),
    predictedLevel: json['grade'] ?? json['predicted_level'] ?? 'C',
    details: (json['details'] as List?) ?? const [],
    completedAt: json['completed_at'] != null
        ? DateTime.parse(json['completed_at'])
        : null,
    durationSeconds: json['duration_seconds'] ?? 0,
    xpEarned: json['xp_earned'] ?? 0,
    badge: json['badge'],
    topic: json['topic'],
    breakdown: (json['breakdown'] as Map<String, dynamic>?) ?? const {},
  );
}

class MockTestHistoryItem {
  final String id;
  final String testLevel;
  final int totalQuestions;
  final int correctAnswers;
  final double scorePercent;
  final String grade;
  final DateTime? completedAt;
  final String? topic;

  const MockTestHistoryItem({
    required this.id,
    required this.testLevel,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.scorePercent,
    required this.grade,
    this.completedAt,
    this.topic,
  });

  factory MockTestHistoryItem.fromJson(Map<String, dynamic> json) =>
      MockTestHistoryItem(
        id: json['id'] ?? '',
        testLevel: json['test_level'] ?? '',
        totalQuestions: json['total_questions'] ?? 0,
        correctAnswers: json['correct_answers'] ?? 0,
        scorePercent: (json['score_percent'] ?? 0.0).toDouble(),
        grade: json['grade'] ?? 'C',
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'])
            : null,
        topic: json['topic'],
      );
}

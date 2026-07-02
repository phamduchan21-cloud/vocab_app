class DashboardStats {
  final int streak;
  final int xp;
  final int gems;
  final int level;
  final String levelTitle;
  final int weeklyProgress;
  final int vocabCount;
  final int quizCount;
  final int correctAnswers;
  final double accuracyRate;
  final List<DashboardVocab> recentVocabs;
  final List<DashboardQuiz> recentQuizzes;

  DashboardStats({
    this.streak = 0,
    this.xp = 0,
    this.gems = 0,
    this.level = 0,
    this.levelTitle = 'Mầm non',
    this.weeklyProgress = 0,
    this.vocabCount = 0,
    this.quizCount = 0,
    this.correctAnswers = 0,
    this.accuracyRate = 0.0,
    this.recentVocabs = const [],
    this.recentQuizzes = const [],
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        streak: json['streak'] ?? 0,
        xp: json['xp'] ?? 0,
        gems: json['gems'] ?? 0,
        level: json['level'] ?? 0,
        levelTitle: json['level_title'] ?? 'Mầm non',
        weeklyProgress: json['weekly_progress'] ?? 0,
        vocabCount: json['vocab_count'] ?? 0,
        quizCount: json['quiz_count'] ?? 0,
        correctAnswers: json['correct_answers'] ?? 0,
        accuracyRate: (json['accuracy_rate'] ?? 0.0).toDouble(),
        recentVocabs: (json['recent_vocabs'] as List?)
                ?.map((v) => DashboardVocab.fromJson(v))
                .toList() ??
            [],
        recentQuizzes: (json['recent_quizzes'] as List?)
                ?.map((q) => DashboardQuiz.fromJson(q))
                .toList() ??
            [],
      );
}

class DashboardVocab {
  final String id;
  final String word;
  final String meaning;
  final String topic;
  final DateTime? createdAt;

  DashboardVocab({
    required this.id,
    required this.word,
    required this.meaning,
    required this.topic,
    this.createdAt,
  });

  factory DashboardVocab.fromJson(Map<String, dynamic> json) =>
      DashboardVocab(
        id: json['id'],
        word: json['word'],
        meaning: json['meaning'],
        topic: json['topic'] ?? 'general',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
      );
}

class DashboardQuiz {
  final String id;
  final String quizType;
  final int totalQuestions;
  final int correctAnswers;
  final double scorePercent;
  final DateTime? completedAt;

  DashboardQuiz({
    required this.id,
    required this.quizType,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.scorePercent,
    this.completedAt,
  });

  factory DashboardQuiz.fromJson(Map<String, dynamic> json) => DashboardQuiz(
        id: json['id'],
        quizType: json['quiz_type'] ?? '',
        totalQuestions: json['total_questions'] ?? 0,
        correctAnswers: json['correct_answers'] ?? 0,
        scorePercent: (json['score_percent'] ?? 0.0).toDouble(),
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'])
            : null,
      );
}

class TodayReviewItem {
  final String id;
  final String word;
  final String meaning;
  final String? example;
  final String topic;
  final int reviewCount;
  final double easeFactor;
  final DateTime? createdAt;

  TodayReviewItem({
    required this.id,
    required this.word,
    required this.meaning,
    this.example,
    this.topic = 'general',
    this.reviewCount = 0,
    this.easeFactor = 2.5,
    this.createdAt,
  });

  factory TodayReviewItem.fromJson(Map<String, dynamic> json) =>
      TodayReviewItem(
        id: json['id'],
        word: json['word'],
        meaning: json['meaning'],
        example: json['example'],
        topic: json['topic'] ?? 'general',
        reviewCount: json['review_count'] ?? 0,
        easeFactor: (json['ease_factor'] ?? 2.5).toDouble(),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
      );
}

class TodayReviewData {
  final int total;
  final int completed;
  final List<TodayReviewItem> words;

  TodayReviewData({
    this.total = 0,
    this.completed = 0,
    this.words = const [],
  });

  factory TodayReviewData.fromJson(Map<String, dynamic> json) =>
      TodayReviewData(
        total: json['total'] ?? 0,
        completed: json['completed'] ?? 0,
        words: (json['words'] as List?)
                ?.map((w) => TodayReviewItem.fromJson(w))
                .toList() ??
            [],
      );

  int get remaining => total - completed;
}

class TopicProgressItem {
  final String topic;
  final int total;
  final int mastered;
  final double accuracy;

  TopicProgressItem({
    this.topic = 'general',
    this.total = 0,
    this.mastered = 0,
    this.accuracy = 0.0,
  });

  factory TopicProgressItem.fromJson(Map<String, dynamic> json) =>
      TopicProgressItem(
        topic: json['topic'] ?? 'general',
        total: json['total'] ?? 0,
        mastered: json['mastered'] ?? 0,
        accuracy: (json['accuracy'] ?? 0.0).toDouble(),
      );

  double get masteryPercent =>
      total > 0 ? (mastered / total * 100).clamp(0, 100) : 0;
}

class WeeklyActivityDay {
  final String date;
  final int xp;
  final int quizzes;
  final int learned;

  WeeklyActivityDay({
    required this.date,
    this.xp = 0,
    this.quizzes = 0,
    this.learned = 0,
  });

  factory WeeklyActivityDay.fromJson(Map<String, dynamic> json) =>
      WeeklyActivityDay(
        date: json['date'] ?? '',
        xp: json['xp'] ?? 0,
        quizzes: json['quizzes'] ?? 0,
        learned: json['learned'] ?? 0,
      );
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final int xp;
  final int streak;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.xp,
    required this.streak,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        rank: json['rank'] ?? 0,
        userId: json['user_id'] ?? '',
        username: json['username'] ?? 'Unknown',
        xp: json['xp'] ?? 0,
        streak: json['streak'] ?? 0,
      );
}

class DashboardData {
  final DashboardStats stats;
  final TodayReviewData review;
  final List<TopicProgressItem> topics;
  final List<LeaderboardEntry> leaderboard;
  final List<SkillItem> skills;
  final int topik1Completed;
  final int topik1Total;
  final int topik2Completed;
  final int topik2Total;

  DashboardData({
    required this.stats,
    required this.review,
    required this.topics,
    required this.leaderboard,
    this.skills = const [],
    this.topik1Completed = 0,
    this.topik1Total = 0,
    this.topik2Completed = 0,
    this.topik2Total = 0,
  });
}

// ─── Skill (Migii TOPIK inspired) ──────────────────────────────────

class SkillItem {
  final String type;
  final String title;
  final double accuracy;
  final int xp;
  final int completed;
  final int total;

  SkillItem({
    required this.type,
    required this.title,
    this.accuracy = 0.0,
    this.xp = 0,
    this.completed = 0,
    this.total = 0,
  });

  factory SkillItem.fromJson(Map<String, dynamic> json) => SkillItem(
        type: json['type'] ?? '',
        title: json['title'] ?? '',
        accuracy: (json['accuracy'] ?? 0.0).toDouble(),
        xp: json['xp'] ?? 0,
        completed: json['completed'] ?? 0,
        total: json['total'] ?? 0,
      );
}

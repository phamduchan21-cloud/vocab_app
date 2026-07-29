class AchievementItem {
  final String id;
  final String achievementKey;
  final String title;
  final String? description;
  final String? icon;
  final DateTime? unlockedAt;

  const AchievementItem({
    required this.id,
    required this.achievementKey,
    required this.title,
    this.description,
    this.icon,
    this.unlockedAt,
  });

  factory AchievementItem.fromJson(Map<String, dynamic> json) {
    return AchievementItem(
      id: json['id'] ?? '',
      achievementKey: json['achievement_key'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      icon: json['icon'],
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.tryParse(json['unlocked_at'])
          : null,
    );
  }
}

class StreakRewardResult {
  final int streak;
  final int rewardGems;
  final int rewardXp;
  final String message;

  const StreakRewardResult({
    required this.streak,
    required this.rewardGems,
    required this.rewardXp,
    required this.message,
  });

  factory StreakRewardResult.fromJson(Map<String, dynamic> json) {
    return StreakRewardResult(
      streak: json['streak'] ?? 0,
      rewardGems: json['reward_gems'] ?? 0,
      rewardXp: json['reward_xp'] ?? 0,
      message: json['message'] ?? '',
    );
  }
}

// ─── English Level ──────────────────────────────────────────────────

const List<Map<String, String>> englishLevels = [
  {'key': 'beginner', 'label': 'Sơ cấp (Beginner)', 'emoji': '🌱'},
  {'key': 'elementary', 'label': 'Tiểu học (Elementary)', 'emoji': '🌿'},
  {'key': 'intermediate', 'label': 'Trung cấp (Intermediate)', 'emoji': '🌳'},
  {
    'key': 'upper_intermediate',
    'label': 'Trung cao cấp (Upper Intermediate)',
    'emoji': '🌲',
  },
  {'key': 'advanced', 'label': 'Cao cấp (Advanced)', 'emoji': '🚀'},
  {'key': 'proficient', 'label': 'Thành thạo (Proficient)', 'emoji': '👑'},
];

String? getEnglishLevelLabel(String? key) {
  if (key == null) return null;
  try {
    return englishLevels.firstWhere((e) => e['key'] == key)['label'];
  } catch (_) {
    return null;
  }
}

String? getEnglishLevelEmoji(String? key) {
  if (key == null) return null;
  try {
    return englishLevels.firstWhere((e) => e['key'] == key)['emoji'];
  } catch (_) {
    return null;
  }
}

// ─── User Profile (full) ────────────────────────────────────────────

class UserProfile {
  final String id;
  final String email;
  final String? username;
  final String? englishLevel;
  final int dailyWordGoal;
  final int streak;
  final int xp;
  final int gems;
  final int level;
  final String levelTitle;
  final Map<String, dynamic> learningGoals;
  final DateTime? createdAt;

  UserProfile({
    required this.id,
    required this.email,
    this.username,
    this.englishLevel,
    this.dailyWordGoal = 10,
    this.streak = 0,
    this.xp = 0,
    this.gems = 0,
    this.level = 0,
    this.levelTitle = 'Mầm non',
    this.learningGoals = const {},
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] ?? '',
    email: json['email'] ?? '',
    username: json['username'],
    englishLevel: json['english_level'],
    dailyWordGoal: json['daily_word_goal'] ?? 10,
    streak: json['streak'] ?? 0,
    xp: json['xp'] ?? 0,
    gems: json['gems'] ?? 0,
    level: json['level'] ?? 0,
    levelTitle: json['level_title'] ?? 'Mầm non',
    learningGoals:
        (json['learning_goals'] as Map<String, dynamic>?) ?? const {},
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'])
        : null,
  );
}

class RewardSummary {
  final int claimableCount;
  final int xpTotal;
  final int gemsBalance;
  final int? nextStreak;
  final int streakProgress;

  const RewardSummary({
    this.claimableCount = 0,
    this.xpTotal = 0,
    this.gemsBalance = 0,
    this.nextStreak,
    this.streakProgress = 0,
  });

  factory RewardSummary.fromJson(Map<String, dynamic> json) => RewardSummary(
    claimableCount: json['claimable_count'] ?? 0,
    xpTotal: json['xp_total'] ?? 0,
    gemsBalance: json['gems_balance'] ?? 0,
    nextStreak: json['next_streak'],
    streakProgress: json['streak_progress'] ?? 0,
  );
}

class RewardItem {
  final String id;
  final String rewardKey;
  final String sourceType;
  final String title;
  final String? description;
  final int xpAmount;
  final int gemsAmount;
  final String status;
  final DateTime? unlockedAt;
  final DateTime? claimedAt;

  const RewardItem({
    required this.id,
    required this.rewardKey,
    required this.sourceType,
    required this.title,
    this.description,
    this.xpAmount = 0,
    this.gemsAmount = 0,
    required this.status,
    this.unlockedAt,
    this.claimedAt,
  });

  bool get isClaimable => status == 'pending';

  factory RewardItem.fromJson(Map<String, dynamic> json) => RewardItem(
    id: json['id'] ?? '',
    rewardKey: json['reward_key'] ?? '',
    sourceType: json['source_type'] ?? 'achievement',
    title: json['title'] ?? '',
    description: json['description'],
    xpAmount: json['xp_amount'] ?? 0,
    gemsAmount: json['gems_amount'] ?? 0,
    status: json['status'] ?? 'pending',
    unlockedAt: json['unlocked_at'] != null
        ? DateTime.tryParse(json['unlocked_at'])
        : null,
    claimedAt: json['claimed_at'] != null
        ? DateTime.tryParse(json['claimed_at'])
        : null,
  );
}

class RewardTransactionItem {
  final String id;
  final String sourceType;
  final int xpDelta;
  final int gemsDelta;
  final String? description;
  final DateTime? createdAt;

  const RewardTransactionItem({
    required this.id,
    required this.sourceType,
    this.xpDelta = 0,
    this.gemsDelta = 0,
    this.description,
    this.createdAt,
  });

  factory RewardTransactionItem.fromJson(Map<String, dynamic> json) =>
      RewardTransactionItem(
        id: json['id'] ?? '',
        sourceType: json['source_type'] ?? '',
        xpDelta: json['xp_delta'] ?? 0,
        gemsDelta: json['gems_delta'] ?? 0,
        description: json['description'],
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'])
            : null,
      );
}

class LearningPathStep {
  final String cefrLevel;
  final String title;
  final String description;
  final List<int> lessonIds;
  final List<String> topics;
  final String status;
  final double progressPercent;
  final double masteryPercent;
  final double quizAverage;
  final double miniTestScore;
  final int completedTopics;
  final int requiredTopics;
  final bool canComplete;
  final String reason;

  const LearningPathStep({
    required this.cefrLevel,
    required this.title,
    required this.description,
    this.lessonIds = const [],
    this.topics = const [],
    required this.status,
    this.progressPercent = 0,
    this.masteryPercent = 0,
    this.quizAverage = 0,
    this.miniTestScore = 0,
    this.completedTopics = 0,
    this.requiredTopics = 0,
    this.canComplete = false,
    this.reason = '',
  });

  factory LearningPathStep.fromJson(Map<String, dynamic> json) =>
      LearningPathStep(
        cefrLevel: json['cefr_level'] ?? 'A1',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        lessonIds: (json['lesson_ids'] as List? ?? const [])
            .map((value) => (value as num).toInt())
            .toList(),
        topics: (json['topics'] as List? ?? const [])
            .map((value) => value.toString())
            .toList(),
        status: json['status'] ?? 'locked',
        progressPercent: (json['progress_percent'] ?? 0).toDouble(),
        masteryPercent: (json['mastery_percent'] ?? 0).toDouble(),
        quizAverage: (json['quiz_average'] ?? 0).toDouble(),
        miniTestScore: (json['mini_test_score'] ?? 0).toDouble(),
        completedTopics: json['completed_topics'] ?? 0,
        requiredTopics: json['required_topics'] ?? 0,
        canComplete: json['can_complete'] ?? false,
        reason: json['reason'] ?? '',
      );
}

class LearningPathData {
  final String currentCefr;
  final int currentStep;
  final String placementSource;
  final double overallProgress;
  final List<LearningPathStep> steps;

  const LearningPathData({
    this.currentCefr = 'A1',
    this.currentStep = 0,
    this.placementSource = 'profile',
    this.overallProgress = 0,
    this.steps = const [],
  });

  LearningPathStep? get current {
    for (final step in steps) {
      if (step.cefrLevel == currentCefr) return step;
    }
    return null;
  }

  factory LearningPathData.fromJson(Map<String, dynamic> json) =>
      LearningPathData(
        currentCefr: json['current_cefr'] ?? 'A1',
        currentStep: json['current_step'] ?? 0,
        placementSource: json['placement_source'] ?? 'profile',
        overallProgress: (json['overall_progress'] ?? 0).toDouble(),
        steps: (json['steps'] as List? ?? const [])
            .map((item) => LearningPathStep.fromJson(item))
            .toList(),
      );
}

class TodayLearningPlan {
  final String cefrLevel;
  final int dueReviews;
  final int newWords;
  final String activityTitle;
  final String activityRoute;
  final int estimatedMinutes;
  final String reason;

  const TodayLearningPlan({
    this.cefrLevel = 'A1',
    this.dueReviews = 0,
    this.newWords = 0,
    this.activityTitle = 'Quiz củng cố',
    this.activityRoute = '/quiz',
    this.estimatedMinutes = 10,
    this.reason = '',
  });

  factory TodayLearningPlan.fromJson(Map<String, dynamic> json) =>
      TodayLearningPlan(
        cefrLevel: json['cefr_level'] ?? 'A1',
        dueReviews: json['due_reviews'] ?? 0,
        newWords: json['new_words'] ?? 0,
        activityTitle: json['activity_title'] ?? 'Quiz củng cố',
        activityRoute: json['activity_route'] ?? '/quiz',
        estimatedMinutes: json['estimated_minutes'] ?? 10,
        reason: json['reason'] ?? '',
      );
}

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
  {'key': 'upper_intermediate', 'label': 'Trung cao cấp (Upper Intermediate)', 'emoji': '🌲'},
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
      );
}

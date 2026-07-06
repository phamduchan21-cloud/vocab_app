import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dashboard_data.dart';
import '../models/profile_data.dart';
import '../models/quiz_result.dart';
import 'api_service.dart';

class ProfileService {
  final ApiService _api;

  ProfileService(this._api);

  Future<List<WeeklyActivityDay>> getWeeklyActivity() async {
    final response = await _api.get('/api/dashboard/weekly-activity');
    final data = response as Map<String, dynamic>;
    return (data['days'] as List? ?? const [])
        .map((item) => WeeklyActivityDay.fromJson(item))
        .toList();
  }

  Future<List<AchievementItem>> getAchievements() async {
    final response = await _api.get('/api/gamification/achievements');
    return (response as List)
        .map((item) => AchievementItem.fromJson(item))
        .toList();
  }

  Future<List<QuizResult>> getQuizHistory({int page = 1, int limit = 6}) async {
    final response = await _api.get('/api/quiz/history', queryParams: {
      'page': '$page',
      'limit': '$limit',
    });
    final data = response as Map<String, dynamic>;
    return (data['items'] as List? ?? const [])
        .map((item) => QuizResult.fromJson(item))
        .toList();
  }

  Future<StreakRewardResult> claimStreakReward() async {
    final response = await _api.post('/api/gamification/claim-streak-reward');
    return StreakRewardResult.fromJson(response as Map<String, dynamic>);
  }

  Future<void> updateDisplayName(String displayName) async {
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(data: {'username': displayName}),
    );
  }

  Future<UserProfile> getProfile() async {
    final response = await _api.get('/api/auth/profile');
    return UserProfile.fromJson(response as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> recordActivity(String activityType, {int xpEarned = 0}) async {
    final response = await _api.post('/api/gamification/record-activity', body: {
      'activity_type': activityType,
      'xp_earned': xpEarned,
    });
    return response as Map<String, dynamic>;
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _api.put('/api/auth/profile', body: data);
  }
}

import '../models/dashboard_data.dart';
import 'api_service.dart';

class DashboardService {
  final ApiService _api;

  DashboardService(this._api);

  Future<DashboardStats> getStats() async {
    final response = await _api.get('/api/dashboard');
    return DashboardStats.fromJson(response as Map<String, dynamic>);
  }

  Future<TodayReviewData> getTodayReview() async {
    final response = await _api.get('/api/dashboard/today-review');
    return TodayReviewData.fromJson(response as Map<String, dynamic>);
  }

  Future<List<TopicProgressItem>> getTopicProgress() async {
    final response = await _api.get('/api/dashboard/topic-progress');
    final data = response as Map<String, dynamic>;
    return (data['topics'] as List)
        .map((t) => TopicProgressItem.fromJson(t))
        .toList();
  }

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    final response = await _api.get('/api/gamification/leaderboard');
    final data = response as Map<String, dynamic>;
    return (data['entries'] as List)
        .map((e) => LeaderboardEntry.fromJson(e))
        .toList();
  }

  Future<List<WeeklyActivityDay>> getWeeklyActivity() async {
    final response = await _api.get('/api/dashboard/weekly-activity');
    final data = response as Map<String, dynamic>;
    return (data['days'] as List)
        .map((d) => WeeklyActivityDay.fromJson(d))
        .toList();
  }

  Future<List<SkillItem>> getSkills() async {
    final response = await _api.get('/api/dashboard/skills');
    final data = response as Map<String, dynamic>;
    return (data['skills'] as List)
        .map((s) => SkillItem.fromJson(s))
        .toList();
  }

  Future<Map<String, int>> getMockTestStats() async {
    try {
      final response = await _api.get('/api/mock-tests/history?limit=100');
      final data = response as Map<String, dynamic>;
      final items = data['items'] as List;
      int topik1Total = 0, topik1Done = 0, topik2Total = 0, topik2Done = 0;
      for (var item in items) {
        if (item['test_level'] == 'TOPIK_I') {
          topik1Total++;
          if (item['score_percent'] != null) topik1Done++;
        } else {
          topik2Total++;
          if (item['score_percent'] != null) topik2Done++;
        }
      }
      return {
        'topik1Completed': topik1Done,
        'topik1Total': topik1Total,
        'topik2Completed': topik2Done,
        'topik2Total': topik2Total,
      };
    } catch (e) {
      return {
        'topik1Completed': 0, 'topik1Total': 0,
        'topik2Completed': 0, 'topik2Total': 0,
      };
    }
  }
}

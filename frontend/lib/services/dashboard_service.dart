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

}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/dashboard_service.dart';
import '../services/api_service.dart';
import '../models/dashboard_data.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardService _service;

  bool _isLoading = false;
  DashboardData? _data;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  DashboardData? get data => _data;
  String? get errorMessage => _errorMessage;

  DashboardProvider(this._service);

  void updateAuth(dynamic auth) {
    // Auth state changed, no special handling needed
  }

  Future<void> loadDashboard() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getStats(),
        _service.getTodayReview(),
        _service.getTopicProgress(),
        _service.getLeaderboard(),
        _service.getSkills(),
        _service.getMockTestStats(),
      ]);

      final mockStats = results[5] as Map<String, int>;
      _data = DashboardData(
        stats: results[0] as DashboardStats,
        review: results[1] as TodayReviewData,
        topics: results[2] as List<TopicProgressItem>,
        leaderboard: results[3] as List<LeaderboardEntry>,
        skills: results[4] as List<SkillItem>,
        topik1Completed: mockStats['topik1Completed'] ?? 0,
        topik1Total: mockStats['topik1Total'] ?? 0,
        topik2Completed: mockStats['topik2Completed'] ?? 0,
        topik2Total: mockStats['topik2Total'] ?? 0,
      );
    } catch (e) {
      if (e is ApiAuthException) {
        _errorMessage = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      } else {
        _errorMessage = 'Không thể tải dữ liệu. Vui lòng thử lại sau.';
      }
      debugPrint('DashboardProvider error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadDashboard();
  }
}

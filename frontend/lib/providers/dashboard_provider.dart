import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/dashboard_service.dart';
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

  /// Safely execute an API call with timeout.
  /// Returns null on failure so one failing call doesn't crash the whole batch.
  Future<T?> _safeGet<T>(Future<T> Function() fn, {Duration timeout = const Duration(seconds: 5)}) async {
    try {
      return await fn().timeout(timeout);
    } catch (e) {
      debugPrint('DashboardProvider._safeGet error: $e');
      return null;
    }
  }

  Future<void> loadDashboard() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Run each request independently with individual timeout
      // so one slow/failed endpoint doesn't freeze the entire dashboard
      final results = await Future.wait([
        _safeGet(() => _service.getStats()),
        _safeGet(() => _service.getTodayReview()),
        _safeGet(() => _service.getTopicProgress()),
        _safeGet(() => _service.getLeaderboard()),
        _safeGet(() => _service.getSkills()),
      ]);

      _data = DashboardData(
        stats: (results[0] as DashboardStats?) ?? DashboardStats(),
        review: (results[1] as TodayReviewData?) ?? TodayReviewData(),
        topics: (results[2] as List<TopicProgressItem>?) ?? [],
        leaderboard: (results[3] as List<LeaderboardEntry>?) ?? [],
        skills: (results[4] as List<SkillItem>?) ?? [],
      );
    } catch (e) {
      if (_data == null) {
        _errorMessage = 'Không thể tải dữ liệu. Vui lòng thử lại.';
      }
      debugPrint('DashboardProvider error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _isLoading = false; // đảm bảo không bị block bởi check _isLoading trong loadDashboard
    _data = null;
    _errorMessage = null;
    notifyListeners();
    await loadDashboard();
  }
}

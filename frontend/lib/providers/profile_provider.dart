import 'package:flutter/foundation.dart';

import '../models/dashboard_data.dart';
import '../models/profile_data.dart';
import '../models/quiz_result.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _service;

  bool _isLoading = false;
  List<WeeklyActivityDay> _data = [];
  String? _errorMessage;
  List<AchievementItem> _achievements = [];
  List<QuizResult> _recentQuizzes = [];
  bool _isClaimingReward = false;
  bool _isUpdatingProfile = false;
  UserProfile? _userProfile;

  bool get isLoading => _isLoading;
  List<WeeklyActivityDay> get data => _data;
  String? get errorMessage => _errorMessage;
  List<AchievementItem> get achievements => _achievements;
  List<QuizResult> get recentQuizzes => _recentQuizzes;
  bool get isClaimingReward => _isClaimingReward;
  bool get isUpdatingProfile => _isUpdatingProfile;
  UserProfile? get userProfile => _userProfile;

  ProfileProvider(this._service);

  void updateAuth(dynamic auth) {}

  Future<void> loadProfile() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getWeeklyActivity(),
        _service.getAchievements(),
        _service.getQuizHistory(),
        _service.getProfile(),
      ]);

      _data = results[0] as List<WeeklyActivityDay>;
      _achievements = results[1] as List<AchievementItem>;
      _recentQuizzes = results[2] as List<QuizResult>;
      _userProfile = results[3] as UserProfile;
    } catch (e) {
      _errorMessage = 'Khong the tai ho so luc nay.';
      _data = [];
      _achievements = [];
      _recentQuizzes = [];
      _userProfile = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> claimStreakReward() async {
    if (_isClaimingReward) return null;

    _isClaimingReward = true;
    notifyListeners();
    try {
      final result = await _service.claimStreakReward();
      await loadProfile();
      return result.message;
    } catch (e) {
      return 'Bạn chưa thể nhận thưởng streak lúc này.';
    } finally {
      _isClaimingReward = false;
      notifyListeners();
    }
  }

  Future<String?> updateDisplayName(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Tên hiển thị không được để trống.';
    }

    try {
      await _service.updateDisplayName(trimmed);
      return null;
    } catch (e) {
      return 'Không thể cập nhật tên hiển thị.';
    }
  }

  Future<String?> updateEnglishLevel(String level) async {
    if (_isUpdatingProfile) return null;
    _isUpdatingProfile = true;
    notifyListeners();

    try {
      await _service.updateProfile({'english_level': level});
      await loadProfile();
      return null;
    } catch (e) {
      return 'Không thể cập nhật trình độ tiếng Anh.';
    } finally {
      _isUpdatingProfile = false;
      notifyListeners();
    }
  }

  Future<void> recordActivity(String activityType, {int xpEarned = 0}) async {
    try {
      await _service.recordActivity(activityType, xpEarned: xpEarned);
      await loadProfile();
    } catch (e) {
      debugPrint('recordActivity error: $e');
    }
  }

  Future<String?> updateDailyGoal(int goal) async {
    if (_isUpdatingProfile) return null;
    _isUpdatingProfile = true;
    notifyListeners();

    try {
      await _service.updateProfile({'daily_word_goal': goal});
      await loadProfile();
      return null;
    } catch (e) {
      return 'Không thể cập nhật mục tiêu học tập.';
    } finally {
      _isUpdatingProfile = false;
      notifyListeners();
    }
  }
}

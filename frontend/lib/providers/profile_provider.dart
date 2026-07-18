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

  Future<T?> _safeGet<T>(Future<T> Function() fn) async {
    try {
      return await fn().timeout(const Duration(seconds: 10));
    } catch (_) {
      return null;
    }
  }

  Future<void> loadProfile() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _safeGet(() => _service.getWeeklyActivity()),
        _safeGet(() => _service.getAchievements()),
        _safeGet(() => _service.getQuizHistory()),
        _safeGet(() => _service.getProfile()),
      ]);

      _data = (results[0] as List?)?.cast<WeeklyActivityDay>() ?? [];
      _achievements = (results[1] as List?)?.cast<AchievementItem>() ?? [];
      _recentQuizzes = (results[2] as List?)?.cast<QuizResult>() ?? [];
      _userProfile = results[3] as UserProfile?;
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
      await loadProfile();
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

  Future<String?> updateLearningPreferences(
    Map<String, dynamic> changes,
  ) async {
    if (_isUpdatingProfile) return null;
    _isUpdatingProfile = true;
    notifyListeners();

    try {
      final goals = <String, dynamic>{
        ...?_userProfile?.learningGoals,
        ...changes,
      };
      await _service.updateProfile({'learning_goals': goals});
      await loadProfile();
      return null;
    } catch (e) {
      return 'Không thể cập nhật cài đặt học tập.';
    } finally {
      _isUpdatingProfile = false;
      notifyListeners();
    }
  }

  Future<String?> completeOnboarding({
    required String englishLevel,
    required int dailyWordGoal,
    required Map<String, dynamic> learningGoals,
  }) async {
    if (_isUpdatingProfile) return null;
    _isUpdatingProfile = true;
    notifyListeners();

    try {
      await _service.updateProfile({
        'english_level': englishLevel,
        'daily_word_goal': dailyWordGoal,
        'learning_goals': learningGoals,
      });
      return null;
    } catch (_) {
      return 'Không thể lưu lộ trình lúc này. Vui lòng thử lại.';
    } finally {
      _isUpdatingProfile = false;
      notifyListeners();
    }
  }
}

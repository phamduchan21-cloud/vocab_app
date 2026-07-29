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
  RewardSummary _rewardSummary = const RewardSummary();
  List<RewardItem> _rewards = [];
  List<RewardTransactionItem> _rewardHistory = [];
  LearningPathData _learningPath = const LearningPathData();
  TodayLearningPlan _todayPlan = const TodayLearningPlan();

  bool get isLoading => _isLoading;
  List<WeeklyActivityDay> get data => _data;
  String? get errorMessage => _errorMessage;
  List<AchievementItem> get achievements => _achievements;
  List<QuizResult> get recentQuizzes => _recentQuizzes;
  bool get isClaimingReward => _isClaimingReward;
  bool get isUpdatingProfile => _isUpdatingProfile;
  UserProfile? get userProfile => _userProfile;
  RewardSummary get rewardSummary => _rewardSummary;
  List<RewardItem> get rewards => _rewards;
  List<RewardTransactionItem> get rewardHistory => _rewardHistory;
  LearningPathData get learningPath => _learningPath;
  TodayLearningPlan get todayPlan => _todayPlan;

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
        _safeGet(() => _service.getRewardSummary()),
        _safeGet(() => _service.getRewards()),
        _safeGet(() => _service.getRewardHistory()),
        _safeGet(() => _service.getLearningPath()),
        _safeGet(() => _service.getTodayLearningPlan()),
      ]);

      _data = (results[0] as List?)?.cast<WeeklyActivityDay>() ?? [];
      _achievements = (results[1] as List?)?.cast<AchievementItem>() ?? [];
      _recentQuizzes = (results[2] as List?)?.cast<QuizResult>() ?? [];
      _userProfile = results[3] as UserProfile?;
      _rewardSummary = results[4] as RewardSummary? ?? const RewardSummary();
      _rewards = (results[5] as List?)?.cast<RewardItem>() ?? [];
      _rewardHistory =
          (results[6] as List?)?.cast<RewardTransactionItem>() ?? [];
      _learningPath =
          results[7] as LearningPathData? ?? const LearningPathData();
      _todayPlan =
          results[8] as TodayLearningPlan? ?? const TodayLearningPlan();
    } catch (e) {
      _errorMessage = 'Khong the tai ho so luc nay.';
      _data = [];
      _achievements = [];
      _recentQuizzes = [];
      _userProfile = null;
      _rewardSummary = const RewardSummary();
      _rewards = [];
      _rewardHistory = [];
      _learningPath = const LearningPathData();
      _todayPlan = const TodayLearningPlan();
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

  Future<String?> claimReward(String rewardId) async {
    if (_isClaimingReward) return null;
    _isClaimingReward = true;
    notifyListeners();
    try {
      final result = await _service.claimReward(rewardId);
      await loadProfile();
      return result['message']?.toString() ?? 'Đã nhận phần thưởng.';
    } catch (_) {
      return 'Không thể nhận phần thưởng lúc này.';
    } finally {
      _isClaimingReward = false;
      notifyListeners();
    }
  }

  Future<String?> claimAllRewards() async {
    if (_isClaimingReward) return null;
    _isClaimingReward = true;
    notifyListeners();
    try {
      final result = await _service.claimAllRewards();
      await loadProfile();
      return result['message']?.toString() ?? 'Đã nhận các phần thưởng.';
    } catch (_) {
      return 'Không thể nhận tất cả phần thưởng lúc này.';
    } finally {
      _isClaimingReward = false;
      notifyListeners();
    }
  }

  Future<String?> updateCefrLevel(String cefrLevel) async {
    if (_isUpdatingProfile) return null;
    _isUpdatingProfile = true;
    notifyListeners();
    try {
      _learningPath = await _service.updatePlacement(cefrLevel);
      await loadProfile();
      return null;
    } catch (_) {
      return 'Không thể cập nhật chặng học lúc này.';
    } finally {
      _isUpdatingProfile = false;
      notifyListeners();
    }
  }

  Future<String?> completeCurrentPathStep() async {
    if (_isUpdatingProfile) return null;
    final current = _learningPath.current;
    if (current == null || !current.canComplete) {
      return current?.reason ?? 'Chặng học chưa sẵn sàng để hoàn thành.';
    }
    _isUpdatingProfile = true;
    notifyListeners();
    try {
      final result = await _service.completePathStep(current.cefrLevel);
      await loadProfile();
      return result['message']?.toString();
    } catch (_) {
      return 'Không thể hoàn thành chặng học lúc này.';
    } finally {
      _isUpdatingProfile = false;
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

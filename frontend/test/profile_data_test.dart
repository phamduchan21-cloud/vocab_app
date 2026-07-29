import 'package:flutter_test/flutter_test.dart';
import 'package:vocab_app/models/profile_data.dart';

void main() {
  test('RewardSummary parses persisted wallet and claimable count', () {
    final summary = RewardSummary.fromJson({
      'claimable_count': 3,
      'xp_total': 840,
      'gems_balance': 27,
      'next_streak': 30,
      'streak_progress': 14,
    });

    expect(summary.claimableCount, 3);
    expect(summary.xpTotal, 840);
    expect(summary.gemsBalance, 27);
    expect(summary.nextStreak, 30);
    expect(summary.streakProgress, 14);
  });

  test('LearningPathData identifies the current CEFR step', () {
    final path = LearningPathData.fromJson({
      'current_cefr': 'B1',
      'current_step': 2,
      'placement_source': 'placement_test',
      'overall_progress': 55.5,
      'steps': [
        {
          'cefr_level': 'A1',
          'title': 'Khởi hành',
          'description': 'Nền tảng',
          'status': 'waived',
        },
        {
          'cefr_level': 'B1',
          'title': 'Độc lập',
          'description': 'Giao tiếp độc lập',
          'status': 'current',
          'progress_percent': 61,
          'mastery_percent': 70,
          'quiz_average': 78,
          'mini_test_score': 72,
          'completed_topics': 3,
          'required_topics': 4,
          'can_complete': false,
          'reason': 'Cần hoàn thành chủ đề còn lại.',
        },
      ],
    });

    expect(path.currentCefr, 'B1');
    expect(path.current?.title, 'Độc lập');
    expect(path.current?.progressPercent, 61);
    expect(path.current?.status, 'current');
  });

  test('RewardItem only exposes claim for pending rewards', () {
    final pending = RewardItem.fromJson({
      'id': 'reward-1',
      'reward_key': 'streak_7',
      'title': 'Tem Lửa 7 Ngày',
      'status': 'pending',
    });
    final claimed = RewardItem.fromJson({
      'id': 'reward-2',
      'reward_key': 'streak_14',
      'title': 'Tem Lửa 14 Ngày',
      'status': 'claimed',
    });

    expect(pending.isClaimable, isTrue);
    expect(claimed.isClaimable, isFalse);
  });
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../app.dart';
import '../models/dashboard_data.dart';

class StreakBar extends StatelessWidget {
  final DashboardStats? stats;
  final bool isLoading;
  final String? errorMessage;

  const StreakBar({
    super.key,
    this.stats,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildSkeleton();
    if (errorMessage != null) return _buildError();
    if (stats == null || stats!.streak == 0 && stats!.vocabCount == 0) {
      return _buildEmpty();
    }
    return _buildContent();
  }

  Widget _buildSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: Row(
          children: [
            _skeletonBox(60, 20),
            const SizedBox(width: 16),
            Expanded(child: _skeletonBox(100, 20)),
            const SizedBox(width: 16),
            _skeletonBox(60, 20),
          ],
        ),
      ),
    );
  }

  Widget _skeletonBox(double w, double h) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildError() {
    return const SizedBox.shrink();
  }

  Widget _buildEmpty() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bắt đầu streak ngay hôm nay!',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final s = stats!;
    final message = _getStreakMessage(s.streak);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Streak
              Expanded(
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${s.streak}',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ngày liên tiếp',
                          style: GoogleFonts.nunito(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Weekly progress
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${s.weeklyProgress}%',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: s.weeklyProgress / 100,
                        backgroundColor: Colors.white24,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 4,
                      ),
                    ),
                    Text(
                      'tuần này',
                      style: GoogleFonts.nunito(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Gems
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text('💎', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 6),
                    Text(
                      '${s.gems}',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.nunito(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _getStreakMessage(int streak) {
    if (streak >= 100) return '👑 Huyền thoại! Bất bại!';
    if (streak >= 60) return '💪 Kiên trì quá! Gần tới 100 rồi!';
    if (streak >= 30) return '🔥 1 tháng — bạn thật xuất sắc! Cố lên!';
    if (streak >= 14) return '🔥 2 tuần liên tiếp! Giữ vững nhé!';
    if (streak >= 7) {
      final daysTo14 = 14 - streak;
      return '🏅 1 tuần — giỏi lắm! Còn $daysTo14 ngày nữa là được huy hiệu 14!';
    }
    if (streak >= 3) {
      final daysTo7 = 7 - streak;
      return '🔥 Khởi đầu tốt! Cố gắng thêm $daysTo7 ngày nữa nhé!';
    }
    return null;
  }
}

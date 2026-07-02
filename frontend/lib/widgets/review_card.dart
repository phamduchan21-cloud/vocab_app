import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../app.dart';
import '../models/dashboard_data.dart';

class ReviewCard extends StatelessWidget {
  final TodayReviewData? data;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onTap;
  final VoidCallback? onRetry;

  const ReviewCard({
    super.key,
    this.data,
    this.isLoading = false,
    this.errorMessage,
    this.onTap,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildSkeleton();
    if (errorMessage != null) return _buildError();
    if (data == null || data!.total == 0) return _buildEmpty();
    return _buildContent();
  }

  Widget _buildSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: _boxDecoration(),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _skeletonLine(140, 20),
            const SizedBox(height: 12),
            _skeletonLine(double.infinity, 8),
            const SizedBox(height: 12),
            _skeletonLine(200, 44),
          ],
        ),
      ),
    );
  }

  Widget _skeletonLine(double w, double h) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(h / 2),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: _boxDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '😅 Không thể tải dữ liệu ôn tập',
              style: GoogleFonts.nunito(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: _boxDecoration(),
      child: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hôm nay bạn đã ôn xong!',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Quay lại vào ngày mai nhé!',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final d = data!;
    final progress = d.total > 0 ? d.completed / d.total : 0.0;
    final percent = (progress * 100).round();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📖', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(
                'Ôn tập hôm nay',
                style: GoogleFonts.nunito(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '🧠 ${d.remaining} từ cần ôn',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                'Đã ôn ${d.completed}/${d.total}',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.catLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$percent%',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: percent >= 80
                  ? AppColors.accent3
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(
                'Ôn tập ngay — ${d.remaining * 30 ~/ 60 + 1} phút',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../app.dart';

class NewWordsCard extends StatelessWidget {
  final String? topic;
  final int? newWordsCount;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onTap;
  final VoidCallback? onRetry;

  const NewWordsCard({
    super.key,
    this.topic,
    this.newWordsCount,
    this.isLoading = false,
    this.errorMessage,
    this.onTap,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildSkeleton();
    if (errorMessage != null) return _buildError();
    if (topic == null || newWordsCount == null || newWordsCount == 0) {
      return _buildEmpty();
    }
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
            const SizedBox(height: 8),
            _skeletonLine(100, 14),
            const SizedBox(height: 14),
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
              '😅 Không thể tải từ mới',
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
                  'Bạn đã học hết từ!',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Thêm từ vựng mới để tiếp tục.',
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: _boxDecoration(),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.catLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('📘', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Học từ mới',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '🌟 $topic · $newWordsCount từ mới',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Text(
              'Học →',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.bold,
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../app.dart';

class MockTestCard extends StatelessWidget {
  final int? beginnerCompleted;
  final int? beginnerTotal;
  final int? advancedCompleted;
  final int? advancedTotal;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onBeginnerTap;
  final VoidCallback? onAdvancedTap;

  const MockTestCard({
    super.key,
    this.beginnerCompleted,
    this.beginnerTotal,
    this.advancedCompleted,
    this.advancedTotal,
    this.isLoading = false,
    this.errorMessage,
    this.onBeginnerTap,
    this.onAdvancedTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildSkeleton();
    if (errorMessage != null) return const SizedBox.shrink();
    return _buildContent();
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _skeletonLine(140, 20),
            const SizedBox(height: 12),
            _skeletonLine(double.infinity, 80),
            const SizedBox(height: 10),
            _skeletonLine(double.infinity, 80),
          ],
        ),
      ),
    );
  }

  Widget _skeletonLine(double w, double h) => Container(
    width: w, height: h,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
  );

  Widget _buildContent() {
    final t1Progress = (beginnerTotal ?? 0) > 0
        ? ((beginnerCompleted ?? 0).toDouble() / (beginnerTotal ?? 1).toDouble() * 100).clamp(0.0, 100.0)
        : 0.0;
    final t2Progress = (advancedTotal ?? 0) > 0
        ? ((advancedCompleted ?? 0).toDouble() / (advancedTotal ?? 1).toDouble() * 100).clamp(0.0, 100.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              children: [
                const Text('📝', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  'Luyện đề thi',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          _buildTestCard(
            emoji: '🌱',
            title: 'Cơ bản',
            desc: '10 câu · 15 phút',
            progress: t1Progress,
            completed: beginnerCompleted ?? 0,
            total: beginnerTotal ?? 0,
            color: const Color(0xFF8B5CF6),
            onTap: onBeginnerTap,
          ),
          const SizedBox(height: 10),
          _buildTestCard(
            emoji: '🔥',
            title: 'Nâng cao',
            desc: '30 câu · 45 phút',
            progress: t2Progress,
            completed: advancedCompleted ?? 0,
            total: advancedTotal ?? 0,
            color: const Color(0xFFF472B6),
            onTap: onAdvancedTap,
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard({
    required String emoji,
    required String title,
    required String desc,
    required double progress,
    required int completed,
    required int total,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        desc,
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: AppColors.catLight,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${progress.toStringAsFixed(0)}% · Đã làm $completed/$total đề',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: AppColors.textHint, size: 24),
          ],
        ),
      ),
    );
  }
}

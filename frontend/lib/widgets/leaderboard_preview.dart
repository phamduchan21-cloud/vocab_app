import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../app.dart';
import '../models/dashboard_data.dart';

class LeaderboardPreview extends StatelessWidget {
  final List<LeaderboardEntry>? entries;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onSeeAll;

  const LeaderboardPreview({
    super.key,
    this.entries,
    this.isLoading = false,
    this.errorMessage,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildSkeleton();
    if (errorMessage != null || entries == null || entries!.isEmpty) {
      return const SizedBox.shrink();
    }
    return _buildContent();
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: [
            _skeletonLine(140, 20),
            const SizedBox(height: 12),
            ...List.generate(
              3,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _skeletonLine(double.infinity, 48),
              ),
            ),
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
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildContent() {
    final displayEntries = entries!.take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Bảng xếp hạng tuần này',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onSeeAll,
                child: const Text('Xem tất cả →'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
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
            child: Column(
              children: List.generate(displayEntries.length, (index) {
                final entry = displayEntries[index];
                final isMe = index == 0; // First entry is current user
                return _buildEntryRow(entry, index + 1, isMe);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryRow(LeaderboardEntry entry, int rank, bool isMe) {
    final rankEmoji = rank == 1
        ? '🥇'
        : rank == 2
            ? '🥈'
            : rank == 3
                ? '🥉'
                : '$rank.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.catLight : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            rankEmoji.toString(),
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isMe ? 'Bạn' : entry.username,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⭐', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                '${entry.xp}',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Shimmer.fromColors(
        baseColor: AppColors.surfaceSubtle,
        highlightColor: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 20, width: 200,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            ...List.generate(3, (_) => Container(
              height: 48, margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final displayEntries = entries!.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '🏆  Bảng xếp hạng',
              style: GoogleFonts.workSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            if (onSeeAll != null)
              GestureDetector(
                onTap: onSeeAll,
                child: Text(
                  'Xem tất cả →',
                  style: GoogleFonts.workSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blue,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.10)),
          ),
          child: Column(
            children: List.generate(displayEntries.length, (index) {
              final entry = displayEntries[index];
              final isMe = index == 0;
              return _buildEntryRow(entry, index + 1, isMe);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildEntryRow(LeaderboardEntry entry, int rank, bool isMe) {
    final rankStr = rank == 1
        ? '🥇'
        : rank == 2
            ? '🥈'
            : rank == 3
                ? '🥉'
                : '$rank.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.surfaceSubtle : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          bottom: BorderSide(color: AppColors.ink.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Text(
            rankStr,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isMe ? 'Bạn' : entry.username,
              style: GoogleFonts.workSans(
                fontSize: 14,
                fontWeight: isMe ? FontWeight.w600 : FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${entry.xp} XP',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

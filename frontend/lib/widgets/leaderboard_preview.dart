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
        baseColor: AppColors.luxuryBorder,
        highlightColor: AppColors.luxurySurface,
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
              'Bang xep hang',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.luxuryEspresso,
              ),
            ),
            if (onSeeAll != null)
              GestureDetector(
                onTap: onSeeAll,
                child: Text(
                  'Xem tat ca →',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.luxuryGold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppColors.luxurySurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.luxuryBorder, width: 1.5),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.luxuryBorder.withValues(alpha: 0.4), width: 0.5),
            ),
            child: Column(
              children: List.generate(displayEntries.length, (index) {
                final entry = displayEntries[index];
                final isMe = index == 0;
                return _buildEntryRow(entry, index + 1, isMe);
              }),
            ),
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
        color: isMe ? AppColors.luxuryBeige.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          bottom: BorderSide(color: AppColors.luxuryBorder.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Text(
            rankStr,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.luxuryEspresso,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isMe ? 'Ban' : entry.username,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: isMe ? FontWeight.w600 : FontWeight.w500,
                color: AppColors.luxuryEspresso,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${entry.xp} XP',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.luxuryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

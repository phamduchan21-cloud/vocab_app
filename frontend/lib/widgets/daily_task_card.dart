import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';

/// Editorial-luxury Bento task card for the dashboard.
/// Double-bezel framing with gold/green accent and playfair headings.
class DailyTaskCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? meta;
  final bool isDone;
  final Color accentColor;
  final double progress; // 0.0 - 1.0
  final VoidCallback onTap;

  const DailyTaskCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.meta,
    this.isDone = false,
    this.accentColor = AppColors.luxuryGold,
    this.progress = 0.0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = isDone ? AppColors.luxuryGreen : accentColor;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isDone ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppColors.luxurySurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDone
                  ? AppColors.luxuryGreen.withValues(alpha: 0.35)
                  : AppColors.luxuryBorder,
              width: 1.5,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDone
                    ? AppColors.luxuryGreen.withValues(alpha: 0.15)
                    : AppColors.luxuryBorder.withValues(alpha: 0.4),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon in colored bg
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.luxuryGreen.withValues(alpha: 0.12)
                        : _iconBg(effectiveAccent),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isDone ? Icons.check_circle : icon,
                    size: 20,
                    color: isDone ? AppColors.luxuryGreen : effectiveAccent,
                  ),
                ),
                const SizedBox(height: 12),
                // Title
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDone ? AppColors.luxuryGreen : AppColors.luxuryEspresso,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Description
                Text(
                  isDone ? 'Da hoan thanh ✓' : description,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: isDone
                        ? AppColors.luxuryGreen
                        : AppColors.luxuryText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isDone && progress > 0) ...[
                  const SizedBox(height: 12),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: AppColors.luxuryBorder,
                      valueColor: AlwaysStoppedAnimation<Color>(effectiveAccent),
                    ),
                  ),
                ],
                if (meta != null && !isDone) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      meta!,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: effectiveAccent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _iconBg(Color color) {
    if (color == AppColors.luxuryDanger) return color.withValues(alpha: 0.10);
    if (color == AppColors.luxuryGold) return color.withValues(alpha: 0.10);
    if (color == AppColors.luxuryGreen) return color.withValues(alpha: 0.10);
    return AppColors.luxuryGold.withValues(alpha: 0.10);
  }
}

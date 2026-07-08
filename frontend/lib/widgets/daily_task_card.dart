import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';

/// Stitch-style Bento task card for the dashboard.
/// Compact grid item with icon, title, subtitle, and optional progress.
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
    this.accentColor = AppColors.blue,
    this.progress = 0.0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isDone ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDone
                  ? AppColors.success.withValues(alpha: 0.25)
                  : AppColors.surfaceContainerHighest,
              width: 1,
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
                      ? AppColors.success.withValues(alpha: 0.12)
                      : _iconBg(accentColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDone ? Icons.check_circle : icon,
                  size: 20,
                  color: isDone ? AppColors.success : accentColor,
                ),
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                title,
                style: GoogleFonts.workSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDone ? AppColors.success : AppColors.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Description
              Text(
                isDone ? 'Đã hoàn thành ✓' : description,
                style: GoogleFonts.workSans(
                  fontSize: 12,
                  color: isDone
                      ? AppColors.success
                      : AppColors.inkSoft,
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
                    backgroundColor: AppColors.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
              ],
              if (meta != null && !isDone) ...[
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    meta!,
                    style: GoogleFonts.workSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _iconBg(Color color) {
    if (color == AppColors.danger) return AppColors.dangerBg;
    if (color == AppColors.warning) return AppColors.warningBg;
    if (color == AppColors.success) return AppColors.successBg;
    return AppColors.blueBg;
  }
}

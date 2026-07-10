import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';
import '../models/dashboard_data.dart';

/// Editorial-luxury weekly chart with double-bezel card and animated bars.
class WeeklyChart extends StatelessWidget {
  final List<WeeklyActivityDay> days;
  final int weeklyXpGoal;
  final int currentXp;

  const WeeklyChart({
    super.key,
    this.days = const [],
    this.weeklyXpGoal = 500,
    this.currentXp = 0,
  });

  @override
  Widget build(BuildContext context) {
    final displayDays = days.isEmpty
        ? List.generate(
            7,
            (index) => WeeklyActivityDay(
              date: '',
              xp: 0,
              quizzes: 0,
              learned: 0,
            ),
          )
        : days;
    final maxXp =
        displayDays.fold<int>(1, (max, day) => day.xp > max ? day.xp : max);
    final progress = (currentXp / weeklyXpGoal).clamp(0.0, 1.0);

    const dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final now = DateTime.now();
    final todayIdx = now.weekday - 1; // Monday=0

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.luxurySurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.luxuryBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.luxuryBrown.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: AppColors.luxuryBorder.withValues(alpha: 0.4), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tien do tuan nay',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.luxuryEspresso,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.luxuryGold.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$currentXp / $weeklyXpGoal XP',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.luxuryGold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Bar chart — editorial style with gold today highlight
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(displayDays.length, (i) {
                  final day = displayDays[i];
                  final height = maxXp == 0
                      ? 4.0
                      : 8.0 + (day.xp / maxXp) * 80;
                  final hasData = day.xp > 0;
                  final isToday = i == todayIdx;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (hasData)
                            Text(
                              '${day.xp}',
                              style: GoogleFonts.nunito(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: isToday
                                    ? AppColors.luxuryGold
                                    : AppColors.luxuryText,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            height: height,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                              gradient: hasData
                                  ? LinearGradient(
                                      colors: isToday
                                          ? [
                                              AppColors.luxuryGold,
                                              AppColors.luxuryBrownLight,
                                            ]
                                          : [
                                              AppColors.luxuryBrownPale,
                                              AppColors.luxuryBeige,
                                            ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    )
                                  : null,
                              color: hasData
                                  ? null
                                  : AppColors.luxuryBorder,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dayLabels[i],
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight:
                                  isToday ? FontWeight.w700 : FontWeight.w500,
                              color: isToday
                                  ? AppColors.luxuryGold
                                  : AppColors.luxuryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 18),

            // Weekly progress bar
            Row(
              children: [
                Text(
                  'Tuan',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.luxuryEspresso,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: AppColors.luxuryBorder,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.luxuryGold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(progress * 100).round()}%',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.luxuryGold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

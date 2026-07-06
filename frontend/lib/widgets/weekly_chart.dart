import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';
import '../models/dashboard_data.dart';

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

    // Day labels
    const dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('📊', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    'Tiến độ tuần này',
                    style: GoogleFonts.workSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              Text(
                '$currentXp / $weeklyXpGoal XP',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Bar chart
          SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(displayDays.length, (i) {
                final day = displayDays[i];
                final height = maxXp == 0
                    ? 4.0
                    : 8.0 + (day.xp / maxXp) * 58;
                final hasData = day.xp > 0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (hasData)
                          Text(
                            '${day.xp}',
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 9,
                              color: AppColors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: 3),
                        Container(
                          width: double.infinity,
                          height: height,
                          decoration: BoxDecoration(
                            gradient: hasData
                                ? const LinearGradient(
                                    colors: [AppColors.blueLight, AppColors.blue],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  )
                                : null,
                            color: hasData ? null : AppColors.surfaceSubtle,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dayLabels[i],
                          style: GoogleFonts.workSans(
                            fontSize: 10,
                            color: AppColors.inkSoft,
                            fontWeight: FontWeight.w500,
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
              const Text('🎯', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: AppColors.surfaceSubtle,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blue),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(progress * 100).round()}%',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';

class HeroStatsBar extends StatelessWidget {
  final String displayName;
  final int streak;
  final int xp;
  final int gems;
  final int level;
  final String levelTitle;
  final int dailyGoal;
  final int dailyProgress;
  final String? englishLevel;

  const HeroStatsBar({
    super.key,
    required this.displayName,
    this.streak = 0,
    this.xp = 0,
    this.gems = 0,
    this.level = 0,
    this.levelTitle = 'Mầm non',
    this.dailyGoal = 10,
    this.dailyProgress = 0,
    this.englishLevel,
  });

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 11) {
      greeting = 'Chào buổi sáng';
    } else if (hour < 13) {
      greeting = 'Chào buổi trưa';
    } else if (hour < 18) {
      greeting = 'Chào buổi chiều';
    } else {
      greeting = 'Chào buổi tối';
    }

    final avatarLetter =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'V';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          // Top row: Avatar + Greeting
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withValues(alpha: 0.20),
                child: Text(
                  avatarLetter,
                  style: GoogleFonts.workSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, $displayName',
                      style: GoogleFonts.workSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cấp $level - $levelTitle',
                      style: GoogleFonts.workSans(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Stats row
          Row(
            children: [
              _HeroPill(
                emoji: '🔥',
                value: '$streak',
                label: 'Streak',
                bgColor: Colors.white.withValues(alpha: 0.18),
              ),
              const SizedBox(width: 8),
              _HeroPill(
                emoji: '⚡',
                value: '$xp',
                label: 'XP',
                bgColor: Colors.white.withValues(alpha: 0.18),
              ),
              const SizedBox(width: 8),
              _HeroPill(
                emoji: '💎',
                value: '$gems',
                label: 'Gems',
                bgColor: Colors.white.withValues(alpha: 0.18),
              ),
              const SizedBox(width: 8),
              _HeroPill(
                emoji: '🌱',
                value: englishLevel ?? 'N/A',
                label: 'Trình độ',
                bgColor: Colors.white.withValues(alpha: 0.18),
              ),
            ],
          ),

          // Daily goal progress
          if (dailyGoal > 0) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (dailyProgress / dailyGoal).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.20),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '🎯 $dailyProgress/$dailyGoal từ hôm nay',
                  style: GoogleFonts.workSans(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String emoji, value, label;
  final Color bgColor;

  const _HeroPill({
    required this.emoji,
    required this.value,
    required this.label,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.workSans(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.88),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    this.levelTitle = 'Mam non',
    this.dailyGoal = 10,
    this.dailyProgress = 0,
    this.englishLevel,
  });

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 11 ? 'Chào buổi sáng' : hour < 13 ? 'Chào buổi trưa' : hour < 18 ? 'Chào buổi chiều' : 'Chào buổi tối';
    final avatarLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'V';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.luxuryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.luxuryBrown.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(top: -40, right: -40, child: Container(width: 128, height: 128,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.10)),
          )),
          Positioned(bottom: -24, left: -24, child: Container(width: 96, height: 96,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
          )),
          Column(children: [
            Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withValues(alpha: 0.20),
                child: Text(avatarLetter, style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$greeting!', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 2),
                Text(displayName, style: GoogleFonts.nunito(fontSize: 14, color: Colors.white.withValues(alpha: 0.85))),
              ])),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Row(children: [
                _StatItem(value: '$streak', emoji: '🔥', label: 'Streak'),
                _StatDivider(),
                _StatItem(value: '$xp', emoji: '⭐', label: 'XP'),
                _StatDivider(),
                _StatItem(value: '$gems', emoji: '💎', label: 'Gems'),
                _StatDivider(),
                _StatItem(value: englishLevel ?? 'N/A', emoji: '🌱', label: 'Level'),
              ]),
            ),
            if (dailyGoal > 0) ...[
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Muc tieu hom nay', style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.90))),
                Text('$dailyProgress/$dailyGoal tu', style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (dailyProgress / dailyGoal).clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: Colors.white.withValues(alpha: 0.20),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ]),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value, emoji, label;
  const _StatItem({required this.value, required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text('$value $emoji', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
    const SizedBox(height: 2),
    Text(label, style: GoogleFonts.nunito(fontSize: 10, color: Colors.white.withValues(alpha: 0.80))),
  ]));
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.20));
}

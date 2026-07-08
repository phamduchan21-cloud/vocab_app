import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';

class HeroStatsBar extends StatefulWidget {
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
  State<HeroStatsBar> createState() => _HeroStatsBarState();
}

class _HeroStatsBarState extends State<HeroStatsBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _floatController.repeat(reverse: true);
    });
    _floatAnim = Tween<double>(begin: 0, end: -5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

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
        widget.displayName.isNotEmpty ? widget.displayName[0].toUpperCase() : 'V';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative blur elements
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -24,
            left: -24,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            children: [
              // Top row: Avatar + Greeting
              Row(
                children: [
                  // Floating avatar (Stitch style)
                  AnimatedBuilder(
                    animation: _floatAnim,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _floatAnim.value),
                      child: child,
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withValues(alpha: 0.20),
                      child: Text(
                        avatarLetter,
                        style: GoogleFonts.workSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting! 👋',
                          style: GoogleFonts.workSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.displayName,
                          style: GoogleFonts.workSans(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stats grid with separators (Stitch style)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    _StatItem(value: '${widget.streak}', emoji: '🔥', label: 'Streak'),
                    _StatDivider(),
                    _StatItem(value: '${widget.xp}', emoji: '⭐', label: 'XP'),
                    _StatDivider(),
                    _StatItem(value: '${widget.gems}', emoji: '💎', label: 'Gems'),
                    _StatDivider(),
                    _StatItem(
                      value: widget.englishLevel ?? 'N/A',
                      emoji: '🌱',
                      label: 'Level',
                    ),
                  ],
                ),
              ),

              // Daily goal progress
              if (widget.dailyGoal > 0) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '🎯 Mục tiêu hôm nay',
                      style: GoogleFonts.workSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.90),
                      ),
                    ),
                    Text(
                      '${widget.dailyProgress}/${widget.dailyGoal} từ',
                      style: GoogleFonts.workSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (widget.dailyProgress / widget.dailyGoal)
                        .clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.20),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value, emoji, label;

  const _StatItem({
    required this.value,
    required this.emoji,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value $emoji',
            style: GoogleFonts.workSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.workSans(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.80),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withValues(alpha: 0.20),
    );
  }
}

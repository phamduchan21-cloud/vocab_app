import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';

enum StatsVariant { primary, secondary, accent, custom }

class StatsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? color;
  final StatsVariant variant;
  final bool hasGradient;

  const StatsCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.color,
    this.variant = StatsVariant.primary,
    this.hasGradient = false,
  });

  Color get _color {
    if (color != null) return color!;
    switch (variant) {
      case StatsVariant.primary:
        return AppColors.primary;
      case StatsVariant.secondary:
        return AppColors.secondary;
      case StatsVariant.accent:
        return AppColors.accent1;
      case StatsVariant.custom:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: hasGradient ? LinearGradient(
          colors: [_color, _color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ) : null,
        color: hasGradient ? null : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasGradient
                  ? Colors.white.withValues(alpha: 0.25)
                  : _color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: hasGradient ? Colors.white : _color, size: 26),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: hasGradient ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: hasGradient ? Colors.white.withValues(alpha: 0.85) : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

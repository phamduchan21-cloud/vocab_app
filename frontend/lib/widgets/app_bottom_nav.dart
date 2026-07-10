import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';

/// Editorial-luxury bottom navigation bar with gold accent and playfair headings.
class AppBottomNav extends StatelessWidget {
  final int selectedIndex;

  const AppBottomNav({super.key, required this.selectedIndex});

  static const List<_NavTab> _tabs = [
    _NavTab(Icons.home_rounded, 'Trang chủ', '/'),
    _NavTab(Icons.quiz_rounded, 'Quiz', '/quiz'),
    _NavTab(Icons.style_rounded, 'Flashcard', '/flashcard'),
    _NavTab(Icons.assignment_rounded, 'Test', '/mock-test'),
    _NavTab(Icons.person_rounded, 'Hồ sơ', '/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.luxurySurface,
        border: Border(
          top: BorderSide(color: AppColors.luxuryBorder.withValues(alpha: 0.6)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabs.length, (i) {
              final tab = _tabs[i];
              final isActive = i == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => context.go(tab.route),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.luxuryGold.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            tab.icon,
                            size: 22,
                            color: isActive
                                ? AppColors.luxuryGold
                                : AppColors.luxuryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tab.label,
                          style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w500,
                            color: isActive
                                ? AppColors.luxuryGold
                                : AppColors.luxuryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  final IconData icon;
  final String label;
  final String route;
  const _NavTab(this.icon, this.label, this.route);
}

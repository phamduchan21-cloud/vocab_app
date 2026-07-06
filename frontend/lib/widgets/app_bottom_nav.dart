import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';

/// Bottom navigation bar dÃ¹ng chung cho táº¥t cáº£ mÃ n hÃ¬nh (mobile).
class AppBottomNav extends StatelessWidget {
  final int selectedIndex;

  const AppBottomNav({super.key, required this.selectedIndex});

  static const List<_NavTab> _tabs = [
    _NavTab(Icons.home_outlined, 'Trang chủ', '/'),
    _NavTab(Icons.quiz_outlined, 'Quiz', '/quiz'),
    _NavTab(Icons.style_outlined, 'Flashcard', '/flashcard'),
    _NavTab(Icons.assignment_outlined, 'Test', '/mock-test'),
    _NavTab(Icons.person_outlined, 'Hồ sơ', '/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
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
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.icon,
                          size: 22,
                          color: isActive
                              ? AppColors.blue
                              : AppColors.inkSoft,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tab.label,
                          style: GoogleFonts.workSans(
                            fontSize: 10,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w500,
                            color: isActive
                                ? AppColors.blue
                                : AppColors.inkSoft,
                          ),
                        ),
                        if (isActive)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 16,
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: AppColors.blue,
                              borderRadius: BorderRadius.circular(1.5),
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

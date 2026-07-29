import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';
import '../motion/app_motion.dart';

/// Primary SolVocab navigation for compact layouts.
class AppBottomNav extends StatefulWidget {
  final int selectedIndex;

  const AppBottomNav({super.key, required this.selectedIndex});

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  static int _lastSelectedIndex = 0;

  late double _fromIndex;

  static const List<_NavTab> _tabs = [
    _NavTab(Icons.home_rounded, 'Hôm nay', '/'),
    _NavTab(Icons.quiz_rounded, 'Quiz', '/quiz'),
    _NavTab(Icons.style_rounded, 'Flashcard', '/flashcard'),
    _NavTab(Icons.assignment_rounded, 'Kiểm tra', '/mock-test'),
    _NavTab(Icons.person_rounded, 'Hồ sơ', '/profile'),
  ];

  @override
  void initState() {
    super.initState();
    _fromIndex = _lastSelectedIndex.toDouble();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lastSelectedIndex = widget.selectedIndex;
    });
  }

  @override
  void didUpdateWidget(covariant AppBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex == widget.selectedIndex) return;
    _fromIndex = oldWidget.selectedIndex.toDouble();
    _lastSelectedIndex = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.reduced(context)
        ? Duration.zero
        : const Duration(milliseconds: 210);

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / _tabs.length;
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: _fromIndex,
                      end: widget.selectedIndex.toDouble(),
                    ),
                    duration: duration,
                    curve: AppMotion.standardCurve,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(value * tabWidth + 6, 0),
                        child: child,
                      );
                    },
                    child: Container(
                      width: tabWidth - 12,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.luxuryGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.luxuryGold.withValues(alpha: 0.28),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(_tabs.length, (i) {
                      final tab = _tabs[i];
                      final isActive = i == widget.selectedIndex;
                      final wasActive = i == _fromIndex.round();
                      return Expanded(
                        child: Semantics(
                          button: true,
                          selected: isActive,
                          label: tab.label,
                          child: InkResponse(
                            onTap: () {
                              if (!isActive) context.go(tab.route);
                            },
                            radius: 30,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(
                                  begin: wasActive ? 1 : 0,
                                  end: isActive ? 1 : 0,
                                ),
                                duration: duration,
                                curve: AppMotion.standardCurve,
                                builder: (context, value, child) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Transform.scale(
                                        scale: 0.96 + (value * 0.10),
                                        child: Icon(
                                          tab.icon,
                                          size: 22,
                                          color: Color.lerp(
                                            AppColors.luxuryText,
                                            AppColors.luxuryGold,
                                            value,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        tab.label,
                                        style: GoogleFonts.nunito(
                                          fontSize: 10,
                                          fontWeight: isActive
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: Color.lerp(
                                            AppColors.luxuryText,
                                            AppColors.luxuryGold,
                                            value,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
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

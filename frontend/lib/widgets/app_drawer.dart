import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';
import '../providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final username =
        user?.userMetadata?['username'] as String? ?? user?.email ?? 'Người dùng';
    final email = user?.email ?? '';
    final avatarLetter =
        username.isNotEmpty ? username[0].toUpperCase() : 'V';

    return Drawer(
      child: Container(
        color: AppColors.luxurySurface,
        child: Column(
          children: [
            // ─── Header: Dark editorial sidebar ──────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
              decoration: const BoxDecoration(
                gradient: AppColors.luxuryGradientDark,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar circle
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.luxuryGold,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      avatarLetter,
                      style: GoogleFonts.playfairDisplay(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    username,
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFEDE6D3),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: GoogleFonts.nunito(
                        color: AppColors.luxuryBrownPale,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // ─── Menu items ────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                children: [
                  _buildMenuItem(
                    context,
                    Icons.home_outlined,
                    'Trang chủ',
                    '/',
                  ),
                  _buildMenuItem(
                    context,
                    Icons.style_outlined,
                    'Flashcard',
                    '/flashcard',
                  ),
                  _buildMenuItem(
                    context,
                    Icons.quiz_outlined,
                    'Quiz nhanh',
                    '/quiz',
                  ),
                  _buildMenuItem(
                    context,
                    Icons.assignment_outlined,
                    'Mini-test',
                    '/test',
                  ),
                  _buildMenuItem(
                    context,
                    Icons.bookmark_border,
                    'Đã lưu',
                    '/bookmark',
                  ),
                  _buildMenuItem(
                    context,
                    Icons.bar_chart_outlined,
                    'Tiến độ',
                    '/progress',
                  ),
                  _buildMenuItem(
                    context,
                    Icons.person_outlined,
                    'Hồ sơ',
                    '/profile',
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Divider(
                      height: 1,
                      color: AppColors.luxuryBorder.withValues(alpha: 0.6),
                    ),
                  ),
                  _buildLogoutItem(context),
                ],
              ),
            ),
            // ─── Version ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'SolVocab',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  color: AppColors.luxuryTextHint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    String? route,
  ) {
    final isActive =
        route != null && ModalRoute.of(context)?.settings.name == route;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1.5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            if (route != null) context.go(route);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? AppColors.luxuryBeige.withValues(alpha: 0.3) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive ? AppColors.luxuryEspresso : AppColors.luxuryText,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? AppColors.luxuryEspresso : AppColors.luxuryText,
                  ),
                ),
                const Spacer(),
                if (route != null)
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppColors.luxuryTextHint,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1.5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            context.read<AuthProvider>().logout();
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.logout_rounded,
                  size: 18,
                  color: AppColors.luxuryDanger,
                ),
                const SizedBox(width: 12),
                Text(
                  'Đăng xuất',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.luxuryDanger,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

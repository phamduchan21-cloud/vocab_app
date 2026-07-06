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
        color: AppColors.surface,
        child: Column(
          children: [
            // â”€â”€â”€ Header: Dark sidebar style â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
              decoration: const BoxDecoration(
                color: AppColors.ink,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar circle
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.blue,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      avatarLetter,
                      style: GoogleFonts.workSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    username,
                    style: GoogleFonts.workSans(
                      color: const Color(0xFFEDE6D3),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: GoogleFonts.workSans(
                        color: const Color(0xFF9AA3B8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // â”€â”€â”€ Menu items â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Divider(height: 1),
                  ),
                  _buildLogoutItem(context),
                ],
              ),
            ),
            // â”€â”€â”€ Version â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'VocaEng v1.0.0',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 11,
                  color: AppColors.textHint,
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
              color: isActive ? AppColors.surfaceSubtle : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive ? AppColors.ink : AppColors.inkSoft,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.workSans(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? AppColors.ink : AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                if (route != null)
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppColors.textHint,
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
                  color: AppColors.danger,
                ),
                const SizedBox(width: 12),
                Text(
                  'Đăng xuất',
                  style: GoogleFonts.workSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.danger,
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

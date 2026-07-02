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

    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header gradient với avatar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
              decoration: const BoxDecoration(
                gradient: AppTheme.catGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    auth.user?.email ?? 'Người dùng',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (auth.user?.email != null)
                    Text(
                      auth.user!.email!,
                      style: GoogleFonts.nunito(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            // Menu items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(
                    context,
                    Icons.dashboard_rounded,
                    'Dashboard',
                    '/',
                    AppColors.primary,
                  ),
                  _buildMenuItem(
                    context,
                    Icons.menu_book_rounded,
                    'Từ vựng',
                    '/vocabulary',
                    AppColors.primary,
                  ),
                  _buildMenuItem(
                    context,
                    Icons.quiz_rounded,
                    'Quiz',
                    '/quiz',
                    AppColors.secondary,
                  ),
                  _buildMenuItem(
                    context,
                    Icons.history_rounded,
                    'Lịch sử',
                    '/quiz/history',
                    AppColors.accent1,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(),
                  ),
                  _buildLogoutItem(context),
                ],
              ),
            ),
            // Version
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'MeuBeu v1.0.0',
                style: GoogleFonts.nunito(
                  fontSize: 12,
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
    Color color,
  ) {
    final isActive = route != null && ModalRoute.of(context)?.settings.name == route;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.catLight : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: isActive ? color : AppColors.textSecondary, size: 22),
          ),
          title: Text(
            title,
            style: GoogleFonts.nunito(
              color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              fontSize: 15,
            ),
          ),
          trailing: route != null
              ? Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20)
              : null,
          onTap: () {
            Navigator.pop(context);
            if (route != null) context.go(route);
          },
        ),
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent2.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.logout_rounded, color: AppColors.accent2, size: 22),
          ),
          title: Text(
            'Đăng xuất',
            style: GoogleFonts.nunito(
              color: AppColors.accent2,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            context.read<AuthProvider>().logout();
          },
        ),
      ),
    );
  }
}

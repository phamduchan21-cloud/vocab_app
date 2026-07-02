import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';
import 'cat_widget.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;
  final bool showCat;

  const EmptyStateWidget({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.onAction,
    this.showCat = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showCat)
              const CatWidget(size: 100, expression: CatExpression.sad)
            else if (icon != null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.catLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, size: 48, color: AppColors.primary),
              ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: AppTheme.primaryButtonGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(action!),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

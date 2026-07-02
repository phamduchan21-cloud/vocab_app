import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';
import 'cat_widget.dart';

class ErrorStateWidget extends StatelessWidget {
  final String message;
  final String? subtitle;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.subtitle,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CatWidget(size: 100, expression: CatExpression.sad),
            const SizedBox(height: 24),
            Text(
              'Rất tiếc!',
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.nunito(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 180,
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
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
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

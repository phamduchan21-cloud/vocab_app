import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';
import '../widgets/cat_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideUp = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: Stack(
          children: [
            // ─── Decorative blur elements (Stitch style) ───
            Positioned(
              top: -60,
              left: -60,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              right: -40,
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            // ─── Main content ────────────────────────
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // Cat avatar in container (Stitch style)
                  AnimatedBuilder(
                    animation: _fadeIn,
                    builder: (context, child) => Opacity(
                      opacity: _fadeIn.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideUp.value),
                        child: child,
                      ),
                    ),
                    child: Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const CatWidget(
                        size: 120,
                        expression: CatExpression.happy,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Brand name — Nunito (Stitch brand)
                  AnimatedBuilder(
                    animation: _fadeIn,
                    builder: (context, child) => Opacity(
                      opacity: _fadeIn.value,
                      child: child,
                    ),
                    child: Text(
                      'MeuBeu',
                      style: GoogleFonts.nunito(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.17,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Tagline
                  AnimatedBuilder(
                    animation: _fadeIn,
                    builder: (context, child) => Opacity(
                      opacity: (_fadeIn.value * 0.9).clamp(0.0, 1.0),
                      child: child,
                    ),
                    child: Text(
                      'Học miễn phí. Suốt đời.',
                      style: GoogleFonts.workSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.90),
                        height: 1.33,
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  // Buttons (Stitch style)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        // Primary: "Bắt đầu ngay"
                        AnimatedBuilder(
                          animation: _slideUp,
                          builder: (context, child) => Opacity(
                            opacity: _fadeIn.value,
                            child: child,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => context.go('/onboarding'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.surface,
                                foregroundColor: AppColors.primary,
                                elevation: 4,
                                shadowColor:
                                    AppColors.ink.withValues(alpha: 0.15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                textStyle: GoogleFonts.workSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('Bắt đầu ngay'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Outlined: "Tôi đã có tài khoản"
                        AnimatedBuilder(
                          animation: _fadeIn,
                          builder: (context, child) => Opacity(
                            opacity: (_fadeIn.value * 0.9).clamp(0.0, 1.0),
                            child: child,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: () => context.go('/login'),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.50),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                textStyle: GoogleFonts.workSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('Tôi đã có tài khoản'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

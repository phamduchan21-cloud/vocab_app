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

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
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
    _slideUp = Tween<double>(begin: 30.0, end: 0.0).animate(
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
          gradient: AppTheme.catGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Mèo tím
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) => Opacity(
                  opacity: _fadeIn.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideUp.value),
                    child: child,
                  ),
                ),
                child: const CatWidget(
                  size: 180,
                  expression: CatExpression.happy,
                ),
              ),
              const SizedBox(height: 24),
              // Tên app MeuBeu
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
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
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
                  opacity: (_fadeIn.value * 0.85).clamp(0.0, 1.0),
                  child: child,
                ),
                child: Text(
                  'Học miễn phí. Suốt đời.',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    color: Colors.white.withValues(alpha: 0.9),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const Spacer(flex: 2),
              // 2 nút bấm
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    // Nút Bắt đầu ngay
                    AnimatedBuilder(
                      animation: _slideUp,
                      builder: (context, child) => Opacity(
                        opacity: _fadeIn.value,
                        child: child,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () => context.go('/onboarding'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              textStyle: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: const Text('Bắt đầu ngay'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Nút Tôi đã có tài khoản
                    AnimatedBuilder(
                      animation: _fadeIn,
                      builder: (context, child) => Opacity(
                        opacity: (_fadeIn.value * 0.9).clamp(0.0, 1.0),
                        child: child,
                      ),
                      child: TextButton(
                        onPressed: () => context.go('/login'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          textStyle: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Tôi đã có tài khoản'),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}

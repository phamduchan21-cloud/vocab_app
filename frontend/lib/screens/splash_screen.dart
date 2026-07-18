import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app.dart';
import '../widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _entrance;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _entrance = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.luxuryBg,
      body: Stack(
        children: [
          const Positioned(top: -100, right: -80, child: _BotanicalOrb(size: 290)),
          const Positioned(bottom: -130, left: -90, child: _BotanicalOrb(size: 330, coral: true)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: FadeTransition(
                    opacity: _entrance,
                    child: Column(
                      children: [
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: AppColors.luxurySurface,
                            borderRadius: BorderRadius.circular(44),
                            border: Border.all(color: AppColors.luxuryBorder),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.luxuryBrown.withValues(alpha: 0.12),
                                blurRadius: 32,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: const Center(child: AppLogo(size: 126)),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'SolVocab',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 46,
                            fontWeight: FontWeight.w700,
                            color: AppColors.luxuryEspresso,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Mỗi ngày một chút, vốn từ vững vàng.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 17,
                            height: 1.5,
                            color: AppColors.luxuryText,
                          ),
                        ),
                        const SizedBox(height: 44),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () => context.go('/onboarding'),
                            iconAlignment: IconAlignment.end,
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: const Text('Bắt đầu hành trình'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton(
                            onPressed: () => context.go('/login'),
                            child: const Text('Tôi đã có tài khoản'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotanicalOrb extends StatelessWidget {
  const _BotanicalOrb({required this.size, this.coral = false});

  final double size;
  final bool coral;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              (coral ? AppColors.luxuryGold : AppColors.luxuryBrown)
                  .withValues(alpha: 0.13),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app.dart';
import 'app_logo.dart';
import 'cat_widget.dart';

class AuthPostcard extends StatelessWidget {
  const AuthPostcard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.heroTitle = 'Mỗi từ mới mở ra một quỹ đạo mới.',
    this.heroSubtitle =
        'Học đúng nhịp, ôn đúng lúc và tiến xa hơn mỗi ngày cùng Sol.',
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String heroTitle;
  final String heroSubtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.luxuryBg,
      body: CustomPaint(
        painter: const _AirmailBackgroundPainter(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 900;
              final form = SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: desktop ? 56 : 22,
                  vertical: desktop ? 38 : 22,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!desktop) ...[
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: AppLogoHero(size: 48, showName: true),
                          ),
                          const SizedBox(height: 22),
                        ],
                        Text(
                          title,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: desktop ? 38 : 32,
                            height: 1.12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.1,
                            color: AppColors.luxuryEspresso,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          subtitle,
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            height: 1.5,
                            color: AppColors.luxuryText,
                          ),
                        ),
                        const SizedBox(height: 24),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.luxurySurface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.luxuryBrown.withValues(
                                alpha: 0.28,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.luxuryEspresso.withValues(
                                  alpha: 0.09,
                                ),
                                blurRadius: 36,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: CustomPaint(
                            foregroundPainter: const _PostcardBorderPainter(),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: child,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              if (!desktop) return form;
              return Row(
                children: [
                  Expanded(
                    flex: 10,
                    child: Container(
                      margin: const EdgeInsets.all(22),
                      padding: const EdgeInsets.all(46),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF172B55),
                            Color(0xFF101B36),
                            Color(0xFF0B1226),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(34),
                        border: Border.all(
                          color: AppColors.blue.withValues(alpha: 0.28),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.blue.withValues(alpha: 0.10),
                            blurRadius: 44,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppLogoHero(
                            size: 58,
                            showName: true,
                            light: true,
                          ),
                          const Spacer(),
                          Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 236,
                                  height: 236,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.blue.withValues(
                                        alpha: 0.30,
                                      ),
                                    ),
                                  ),
                                ),
                                Transform.rotate(
                                  angle: -0.22,
                                  child: Container(
                                    width: 270,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: AppColors.lavender.withValues(
                                          alpha: 0.32,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    32,
                                    26,
                                    32,
                                    20,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface.withValues(
                                      alpha: 0.74,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.blue.withValues(
                                        alpha: 0.55,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                  child: const CatWidget(
                                    size: 146,
                                    expression: CatExpression.happy,
                                  ),
                                ),
                                Positioned(
                                  right: 12,
                                  top: 54,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: AppColors.sunny,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 34),
                          Text(
                            heroTitle,
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              height: 1.12,
                              fontSize: 38,
                              letterSpacing: -1.2,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            heroSubtitle,
                            style: GoogleFonts.manrope(
                              color: Colors.white.withValues(alpha: 0.82),
                              height: 1.55,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          const _AirmailRule(),
                        ],
                      ),
                    ),
                  ),
                  Expanded(flex: 11, child: form),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class StampSubmitButton extends StatelessWidget {
  const StampSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon = Icons.mark_email_read_outlined,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : Icon(icon),
        label: Text(isLoading ? 'Đang gửi...' : label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: AppColors.cosmicDeep,
          disabledBackgroundColor: AppColors.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
          shadowColor: AppColors.blue.withValues(alpha: 0.25),
          textStyle: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class AuthStatusBanner extends StatelessWidget {
  const AuthStatusBanner({
    super.key,
    required this.message,
    this.error = false,
  });

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final color = error ? AppColors.danger : AppColors.mint;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            Icon(
              error ? Icons.error_outline_rounded : Icons.outgoing_mail,
              color: color,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.nunito(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SocialAuthButtons extends StatelessWidget {
  const SocialAuthButtons({
    super.key,
    required this.onSelected,
    this.enabled = true,
    this.loadingProvider,
  });

  final ValueChanged<OAuthProvider> onSelected;
  final bool enabled;
  final OAuthProvider? loadingProvider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'HOẶC TIẾP TỤC VỚI',
                style: GoogleFonts.nunito(
                  color: AppColors.luxuryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                label: 'Google',
                mark: 'G',
                isLoading: loadingProvider == OAuthProvider.google,
                onPressed: enabled
                    ? () => onSelected(OAuthProvider.google)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SocialButton(
                label: 'Facebook',
                mark: 'f',
                isLoading: loadingProvider == OAuthProvider.facebook,
                onPressed: enabled
                    ? () => onSelected(OAuthProvider.facebook)
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'SolVocab không nhận hoặc lưu mật khẩu Google/Facebook của bạn.',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            color: AppColors.luxuryText,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.mark,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final String mark;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
        side: BorderSide(color: AppColors.luxuryBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Text(
              mark,
              style: const TextStyle(
                color: AppColors.luxuryEspresso,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                color: AppColors.luxuryEspresso,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  int get _score {
    var score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final score = _score;
    final labels = ['Chưa đủ', 'Yếu', 'Trung bình', 'Tốt', 'Rất mạnh'];
    final colors = [
      AppColors.luxuryBorder,
      AppColors.danger,
      const Color(0xFFD38B2D),
      const Color(0xFF38847E),
      AppColors.mint,
    ];
    return Semantics(
      label: 'Độ mạnh mật khẩu: ${labels[score]}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              4,
              (index) => Expanded(
                child: Container(
                  height: 5,
                  margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: index < score
                        ? colors[score]
                        : AppColors.luxuryBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${labels[score]} · Dùng 8+ ký tự, chữ hoa, số và ký hiệu',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: score == 0 ? AppColors.luxuryText : colors[score],
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class SuccessStampOverlay extends StatelessWidget {
  const SuccessStampOverlay({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xAAFFF8EC),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.8, end: 1),
          duration: const Duration(milliseconds: 520),
          curve: Curves.elasticOut,
          builder: (context, scale, child) => Transform.rotate(
            angle: -0.08,
            child: Transform.scale(scale: scale, child: child),
          ),
          child: Container(
            width: 210,
            height: 116,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.blue, width: 5),
              borderRadius: BorderRadius.circular(58),
            ),
            child: Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: AppColors.blue,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 19,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AirmailRule extends StatelessWidget {
  const _AirmailRule();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Row(
        children: List.generate(
          12,
          (index) => Expanded(
            child: Container(
              height: 7,
              color: index.isEven ? AppColors.blue : AppColors.lavender,
            ),
          ),
        ),
      ),
    );
  }
}

class _PostcardBorderPainter extends CustomPainter {
  const _PostcardBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.blue.withValues(alpha: 0.34)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    const dash = 5.0;
    const gap = 5.0;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AirmailBackgroundPainter extends CustomPainter {
  const _AirmailBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.blue.withValues(alpha: 0.045)
      ..strokeWidth = 1;
    for (double y = 28; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final accent = Paint()
      ..color = AppColors.lavender.withValues(alpha: 0.055)
      ..strokeWidth = 24;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.88, size.height * 0.08),
        width: size.width * 0.55,
        height: size.width * 0.20,
      ),
      0.1,
      3.0,
      false,
      accent,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

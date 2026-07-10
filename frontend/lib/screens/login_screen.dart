import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  late final AnimationController _animCtrl;
  late final Animation<double> _brandFade;
  late final Animation<Offset> _brandSlide;
  late final Animation<double> _formFade;
  late final Animation<Offset> _formSlide;

  static const _spring = Cubic(0.32, 0.72, 0, 1);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _brandFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: const Interval(0, 0.4, curve: _spring)),
    );
    _brandSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animCtrl, curve: const Interval(0, 0.4, curve: _spring)),
    );
    _formFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: const Interval(0.25, 0.7, curve: _spring)),
    );
    _formSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _animCtrl, curve: const Interval(0.25, 0.7, curve: _spring)),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (auth.isAuthenticated && mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0A1A),
              Color(0xFF151528),
              Color(0xFF1A1030),
            ],
          ),
        ),
        child: Stack(
          children: [
            // ponytail: ambient orbs via radial gradient, no image asset needed
            Positioned(
              top: -size.height * 0.15,
              right: -size.width * 0.25,
              child: Container(
                width: size.width * 0.7,
                height: size.width * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6C63FF).withValues(alpha: 0.18),
                      const Color(0xFF6C63FF).withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -size.height * 0.1,
              left: -size.width * 0.2,
              child: Container(
                width: size.width * 0.6,
                height: size.width * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF6B8A).withValues(alpha: 0.12),
                      const Color(0xFFFF6B8A).withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top + 8),

                    // -- Back button: Double-Bezel --
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedBuilder(
                        animation: _brandFade,
                        builder: (_, _) => Opacity(
                          opacity: _brandFade.value,
                          child: GestureDetector(
                            onTap: () => context.go('/splash'),
                            child: Container(
                              padding: const EdgeInsets.all(1.5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                              ),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: const Icon(Icons.arrow_back_rounded, color: Colors.white54, size: 18),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // -- Brand section with staggered entrance --
                    AnimatedBuilder(
                      animation: _animCtrl,
                      builder: (_, _) => Transform.translate(
                        offset: _brandSlide.value * 20,
                        child: Opacity(
                          opacity: _brandFade.value,
                          child: Column(
                            children: [
                              // Double-Bezel glass orb for logo
                              Container(
                                padding: const EdgeInsets.all(1.5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(40),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(37),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF6C63FF).withValues(alpha: 0.25),
                                        blurRadius: 24,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(37),
                                    child: Image.asset(
                                      'assets/logo.png',
                                      width: 72,
                                      height: 72,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'VocaEng',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Đăng nhập để tiếp tục hành trình',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.45),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // -- Form card: Double-Bezel (outer shell + inner core) --
                    AnimatedBuilder(
                      animation: _animCtrl,
                      builder: (_, _) => Transform.translate(
                        offset: _formSlide.value * 30,
                        child: Opacity(
                          opacity: _formFade.value,
                          child: Container(
                            padding: const EdgeInsets.all(1.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A2E).withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Email'),
                                    const SizedBox(height: 8),
                                    _buildGlassField(
                                      child: TextFormField(
                                        controller: _emailCtrl,
                                        keyboardType: TextInputType.emailAddress,
                                        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 15),
                                        decoration: _inputDeco(hint: 'your@email.com', icon: Icons.mail_outline_rounded),
                                        validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập email' : null,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    _buildLabel('Mật khẩu'),
                                    const SizedBox(height: 8),
                                    _buildGlassField(
                                      child: TextFormField(
                                        controller: _passCtrl,
                                        obscureText: _obscure,
                                        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 15),
                                        decoration: _inputDeco(
                                          hint: '••••••••',
                                          icon: _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                          onSuffixTap: () => setState(() => _obscure = !_obscure),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập mật khẩu' : null,
                                      ),
                                    ),

                                    if (auth.errorMessage != null) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF6B7A).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFFF6B7A).withValues(alpha: 0.2)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.error_outline_rounded, color: Color(0xFFFF6B7A), size: 18),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                auth.errorMessage!,
                                                style: GoogleFonts.plusJakartaSans(color: const Color(0xFFFF6B7A), fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 28),

                                    // -- CTA: Button-in-Button pattern --
                                    SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(27),
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF6C63FF), Color(0xFFFF6B8A)],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: auth.isLoading ? null : _login,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                                          ),
                                          child: auth.isLoading
                                              ? const SizedBox(
                                                  width: 22, height: 22,
                                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                                )
                                              : Padding(
                                                  padding: const EdgeInsets.only(right: 4),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text('Đăng nhập',
                                                        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      // Button-in-Button trailing icon island
                                                      Container(
                                                        width: 28, height: 28,
                                                        decoration: BoxDecoration(
                                                          color: Colors.white.withValues(alpha: 0.15),
                                                          borderRadius: BorderRadius.circular(14),
                                                        ),
                                                        child: const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // -- Register link --
                    AnimatedBuilder(
                      animation: _animCtrl,
                      builder: (_, _) => Opacity(
                        opacity: _formFade.value,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Chưa có tài khoản? ',
                              style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/register'),
                              child: Text('Đăng ký',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.45),
        letterSpacing: 0.5,
      ),
    );
  }

  // Double-Bezel glass input field
  Widget _buildGlassField({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(13),
        ),
        child: child,
      ),
    );
  }

  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
    VoidCallback? onSuffixTap,
  }) {
    return InputDecoration(
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 15),
      suffixIcon: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: GestureDetector(
          onTap: onSuffixTap,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white.withValues(alpha: 0.25), size: 18),
          ),
        ),
      ),
      suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 0),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';
import '../widgets/auth_postcard.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _showSuccessStamp = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_refreshStrength);
  }

  void _refreshStrength() => setState(() {});

  @override
  void dispose() {
    _passwordController.removeListener(_refreshStrength);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final canEnterApp = await auth.register(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
    );
    if (!mounted) return;
    if (!canEnterApp || !auth.isAuthenticated) return;

    setState(() => _showSuccessStamp = true);
    await Future<void>.delayed(const Duration(milliseconds: 720));
    if (mounted) context.go('/setup');
  }

  Future<void> _oauth(OAuthProvider provider) async {
    await context.read<AuthProvider>().signInWithOAuth(provider);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Stack(
      children: [
        AuthPostcard(
          title: 'Gửi lá thư đầu tiên',
          subtitle:
              'Chỉ cần ba thông tin. Trình độ và mục tiêu sẽ được chọn ở bước tiếp theo.',
          heroTitle: 'Bắt đầu nhẹ nhàng, tiến xa bền vững.',
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    enabled: !auth.isLoading,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    decoration: const InputDecoration(
                      labelText: 'Tên hiển thị',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) {
                      final name = value?.trim() ?? '';
                      if (name.length < 2) {
                        return 'Tên hiển thị cần ít nhất 2 ký tự.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _emailController,
                    enabled: !auth.isLoading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'ban@example.com',
                      prefixIcon: Icon(Icons.markunread_outlined),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) return 'Vui lòng nhập email.';
                      if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(email)) {
                        return 'Email chưa đúng định dạng.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _passwordController,
                    enabled: !auth.isLoading,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Hiện mật khẩu'
                            : 'Ẩn mật khẩu',
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 8) {
                        return 'Mật khẩu cần ít nhất 8 ký tự.';
                      }
                      if (!RegExp(r'[A-Za-z]').hasMatch(value) ||
                          !RegExp(r'[0-9]').hasMatch(value)) {
                        return 'Hãy kết hợp chữ và số để an toàn hơn.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 9),
                  PasswordStrengthMeter(password: _passwordController.text),
                  if (auth.errorMessage != null) ...[
                    const SizedBox(height: 14),
                    AuthStatusBanner(message: auth.errorMessage!, error: true),
                  ],
                  if (auth.noticeMessage != null) ...[
                    const SizedBox(height: 14),
                    AuthStatusBanner(message: auth.noticeMessage!),
                  ],
                  const SizedBox(height: 20),
                  StampSubmitButton(
                    label: 'Tạo tài khoản',
                    icon: Icons.outgoing_mail,
                    isLoading: auth.isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 22),
                  SocialAuthButtons(
                    enabled: !auth.isLoading,
                    loadingProvider: auth.oauthProvider,
                    onSelected: _oauth,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Đã có tài khoản?'),
                      TextButton(
                        onPressed: auth.isLoading
                            ? null
                            : () {
                                auth.clearMessages();
                                context.go('/login');
                              },
                        child: const Text('Đăng nhập'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_showSuccessStamp)
          const Positioned.fill(
            child: SuccessStampOverlay(label: 'Tài khoản đã sẵn sàng'),
          ),
      ],
    );
  }
}

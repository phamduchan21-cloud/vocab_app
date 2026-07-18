import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';
import '../widgets/auth_postcard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _rememberLogin = true;
  bool _showSuccessStamp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    await auth.login(_emailController.text.trim(), _passwordController.text);
    if (!mounted || !auth.isAuthenticated) return;
    setState(() => _showSuccessStamp = true);
    await Future<void>.delayed(const Duration(milliseconds: 680));
    if (mounted) context.go(auth.needsOnboarding ? '/setup' : '/');
  }

  Future<void> _oauth(OAuthProvider provider) async {
    await context.read<AuthProvider>().signInWithOAuth(provider);
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(
      text: _emailController.text.trim(),
    );
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Gửi magic link'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'Email tài khoản',
            prefixIcon: Icon(Icons.alternate_email_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Gửi liên kết'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted ||
        email == null ||
        !RegExp(r'^\S+@\S+\.\S+$').hasMatch(email)) {
      return;
    }
    await context.read<AuthProvider>().sendPasswordReset(email);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Stack(
      children: [
        AuthPostcard(
          title: 'Chào mừng trở lại',
          subtitle:
              'Mở lại hành trình từ vựng và tiếp tục từ đúng nơi bạn dừng.',
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                    autofillHints: const [AutofillHints.password],
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
                    validator: (value) => value == null || value.isEmpty
                        ? 'Vui lòng nhập mật khẩu.'
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Checkbox.adaptive(
                        value: _rememberLogin,
                        onChanged: auth.isLoading
                            ? null
                            : (value) => setState(
                                () => _rememberLogin = value ?? true,
                              ),
                      ),
                      const Expanded(child: Text('Ghi nhớ đăng nhập')),
                      TextButton(
                        onPressed: auth.isLoading ? null : _forgotPassword,
                        child: const Text('Quên mật khẩu?'),
                      ),
                    ],
                  ),
                  if (auth.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    AuthStatusBanner(message: auth.errorMessage!, error: true),
                  ],
                  if (auth.noticeMessage != null) ...[
                    const SizedBox(height: 8),
                    AuthStatusBanner(message: auth.noticeMessage!),
                  ],
                  const SizedBox(height: 18),
                  StampSubmitButton(
                    label: 'Đóng dấu đăng nhập',
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
                      const Text('Chưa có tài khoản?'),
                      TextButton(
                        onPressed: auth.isLoading
                            ? null
                            : () {
                                auth.clearMessages();
                                context.go('/register');
                              },
                        child: const Text('Đăng ký miễn phí'),
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
            child: SuccessStampOverlay(label: 'Đăng nhập thành công'),
          ),
      ],
    );
  }
}

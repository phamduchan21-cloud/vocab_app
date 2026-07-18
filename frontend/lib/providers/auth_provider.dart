import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/auth_config.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  Session? _session;
  StreamSubscription<AuthState>? _authSubscription;
  bool _isLoading = false;
  String? _errorMessage;
  String? _noticeMessage;
  bool _needsOnboarding = false;
  OAuthProvider? _oauthProvider;

  User? get user => _user;
  Session? get session => _session;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _session != null;
  String? get errorMessage => _errorMessage;
  String? get noticeMessage => _noticeMessage;
  bool get needsOnboarding => _needsOnboarding;
  OAuthProvider? get oauthProvider => _oauthProvider;

  AuthProvider() {
    _init();
  }

  void _init() {
    final auth = Supabase.instance.client.auth;
    _user = auth.currentUser;
    _session = auth.currentSession;
    _needsOnboarding = _shouldStartOnboarding(_user);

    _authSubscription = auth.onAuthStateChange.listen((data) {
      _session = data.session;
      _user = data.session?.user;
      _needsOnboarding = _shouldStartOnboarding(_user);
      if (data.event == AuthChangeEvent.signedIn) _oauthProvider = null;
      notifyListeners();
    });
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _noticeMessage = null;
    notifyListeners();

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session == null) {
        _errorMessage = 'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin.';
      } else {
        _session = response.session;
        _user = response.user ?? response.session?.user;
      }
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e.message);
    } catch (_) {
      _errorMessage = 'Đã xảy ra lỗi khi đăng nhập. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password, String username) async {
    _isLoading = true;
    _errorMessage = null;
    _noticeMessage = null;
    notifyListeners();

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username, 'onboarding_completed': false},
      );

      if (response.session == null) {
        _session = null;
        _user = null;
        _noticeMessage =
            'Đã tạo tài khoản. Vui lòng kiểm tra email để xác nhận trước khi đăng nhập.';
        return false;
      }

      _session = response.session;
      _user = response.user ?? response.session?.user;
      _needsOnboarding = true;
      return true;
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e.message);
      return false;
    } catch (_) {
      _errorMessage = 'Đã xảy ra lỗi khi đăng ký. Vui lòng thử lại.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithOAuth(OAuthProvider provider) async {
    _isLoading = true;
    _oauthProvider = provider;
    _errorMessage = null;
    _noticeMessage = null;
    notifyListeners();

    try {
      final launched = await Supabase.instance.client.auth.signInWithOAuth(
        provider,
        redirectTo: AuthConfig.oauthRedirectUrl,
        scopes: _oauthScopes(provider),
      );
      if (!launched) {
        _errorMessage =
            'Không thể mở cửa sổ đăng nhập. Vui lòng cho phép trình duyệt mở liên kết và thử lại.';
      }
      return launched;
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e.message);
      return false;
    } catch (_) {
      _errorMessage = 'Không thể mở đăng nhập mạng xã hội. Vui lòng thử lại.';
      return false;
    } finally {
      _isLoading = false;
      if (_session == null) _oauthProvider = null;
      notifyListeners();
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    _noticeMessage = null;
    notifyListeners();

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: AuthConfig.passwordRecoveryRedirectUrl,
      );
      _noticeMessage =
          'Liên kết đặt lại mật khẩu đã được gửi. Hãy kiểm tra hộp thư của bạn.';
      return true;
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e.message);
      return false;
    } catch (_) {
      _errorMessage = 'Không thể gửi email lúc này. Vui lòng thử lại sau.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeOnboarding() async {
    final response = await Supabase.instance.client.auth.updateUser(
      UserAttributes(data: {'onboarding_completed': true}),
    );
    _user = response.user ?? _user;
    _needsOnboarding = false;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _noticeMessage = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    _session = null;
    _user = null;
    _needsOnboarding = false;
    notifyListeners();
  }

  Future<String?> updatePassword(String password) async {
    if (password.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự.';
    }
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );
      return null;
    } on AuthException catch (e) {
      return _mapAuthError(e.message);
    } catch (_) {
      return 'Không thể đổi mật khẩu lúc này.';
    }
  }

  /// Set user từ bên ngoài, dùng khi cần đồng bộ profile.
  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  String _mapAuthError(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('provider is not enabled') ||
        normalized.contains('unsupported provider')) {
      return 'Nhà cung cấp đăng nhập này chưa được bật trên Supabase. Vui lòng kiểm tra cấu hình Google/Facebook.';
    }
    if (normalized.contains('oauth') && normalized.contains('cancel')) {
      return 'Bạn đã hủy đăng nhập. Hãy thử lại khi sẵn sàng.';
    }
    if (message.contains('Invalid login credentials')) {
      return 'Email hoặc mật khẩu không đúng.';
    }
    if (message.contains('Email not confirmed')) {
      return 'Email chưa được xác nhận. Vui lòng kiểm tra hộp thư.';
    }
    if (message.contains('User already registered')) {
      return 'Email này đã được đăng ký.';
    }
    if (message.contains('Password should be')) {
      return 'Mật khẩu phải có ít nhất 6 ký tự.';
    }
    return message;
  }

  bool _shouldStartOnboarding(User? user) {
    if (user == null) return false;
    final completed = user.userMetadata?['onboarding_completed'];
    if (completed is bool) return !completed;

    final provider = user.appMetadata['provider']?.toString();
    return provider == 'google' || provider == 'facebook';
  }

  String? _oauthScopes(OAuthProvider provider) {
    if (provider == OAuthProvider.google) return 'openid email profile';
    if (provider == OAuthProvider.facebook) return 'email public_profile';
    return null;
  }
}

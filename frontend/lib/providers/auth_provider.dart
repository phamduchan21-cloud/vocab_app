import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _init();
  }

  void _init() {
    _user = Supabase.instance.client.auth.currentUser;
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      notifyListeners();
    });
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        _errorMessage = 'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin.';
      }
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e.message);
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi khi đăng nhập. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password, String username) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );
      if (response.user == null) {
        _errorMessage = 'Đăng ký thất bại. Vui lòng thử lại.';
      } else {
        // Optionally sync user to backend
        try {
          // Backend will handle user sync on first request
        } catch (_) {}
      }
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e.message);
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi khi đăng ký. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    _user = null;
    notifyListeners();
  }

  String _mapAuthError(String message) {
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
}

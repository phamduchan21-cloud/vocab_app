import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/api_config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiAuthException implements Exception {
  final String message;
  ApiAuthException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  http.Client? _client;
  Timer? _refreshTimer;
  static const Duration _timeout = Duration(seconds: 30);
  static const Duration _refreshLeadTime = Duration(minutes: 5);

  http.Client get _http => _client ??= http.Client();

  ApiService() {
    _scheduleRefresh();
  }

  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    final session = Supabase.instance.client.auth.currentSession;
    if (session?.expiresAt == null) return;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(session!.expiresAt! * 1000);
    final delta = expiresAt.difference(DateTime.now()) - _refreshLeadTime;
    if (delta.isNegative) return;
    _refreshTimer = Timer(delta, () async {
      try {
        await Supabase.instance.client.auth.refreshSession();
      } catch (_) {}
      _scheduleRefresh(); // re-schedule for next cycle
    });
  }

  String? _getToken() {
    final session = Supabase.instance.client.auth.currentSession;
    return session?.accessToken;
  }

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    final token = _getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> _request(
    String method,
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint')
        .replace(queryParameters: queryParams);
    try {
      late http.Response response;
      switch (method) {
        case 'GET':
          response = await _http.get(uri, headers: _headers()).timeout(_timeout);
          break;
        case 'POST':
          response = await _http
              .post(uri, headers: _headers(), body: body != null ? jsonEncode(body) : null)
              .timeout(_timeout);
          break;
        case 'PUT':
          response = await _http
              .put(uri, headers: _headers(), body: body != null ? jsonEncode(body) : null)
              .timeout(_timeout);
          break;
        case 'DELETE':
          response = await _http.delete(uri, headers: _headers()).timeout(_timeout);
          break;
        default:
          throw ArgumentError('Unsupported method: $method');
      }
      return _handleResponse(response, method, endpoint, queryParams, body);
    } on SocketException {
      throw ApiException(0, 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.');
    } on TimeoutException {
      throw ApiException(0, 'Yêu cầu đã hết thời gian chờ. Vui lòng thử lại.');
    }
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) =>
      _request('GET', endpoint, queryParams: queryParams);

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) =>
      _request('POST', endpoint, body: body);

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) =>
      _request('PUT', endpoint, body: body);

  Future<dynamic> delete(String endpoint) =>
      _request('DELETE', endpoint);

  Future<dynamic> _handleResponse(
    http.Response response,
    String method,
    String endpoint,
    Map<String, String>? queryParams,
    Map<String, dynamic>? body,
  ) async {
    if (response.statusCode == 401) {
      // Attempt token refresh once
      try {
        final refreshed = await Supabase.instance.client.auth.refreshSession();
        if (refreshed.session != null) {
          // Retry with fresh token
          return _request(method, endpoint, queryParams: queryParams, body: body);
        }
      } catch (_) {
        // Refresh failed — sign out to trigger redirect to login
        await Supabase.instance.client.auth.signOut();
      }
      throw ApiAuthException('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    String message = 'Đã xảy ra lỗi không xác định.';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body.containsKey('detail')) {
        message = body['detail'].toString();
      }
    } catch (_) {}
    throw ApiException(response.statusCode, message);
  }

  void dispose() {
    _refreshTimer?.cancel();
    _client?.close();
    _client = null;
  }
}

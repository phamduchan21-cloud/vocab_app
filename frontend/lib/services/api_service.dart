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
  final http.Client _client = http.Client();
  static const Duration _timeout = Duration(seconds: 30);

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

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint')
          .replace(queryParameters: queryParams);
      final response = await _client
          .get(uri, headers: _headers())
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(0, 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.');
    } on TimeoutException {
      throw ApiException(0, 'Yêu cầu đã hết thời gian chờ. Vui lòng thử lại.');
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await _client
          .post(uri, headers: _headers(), body: body != null ? jsonEncode(body) : null)
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(0, 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.');
    } on TimeoutException {
      throw ApiException(0, 'Yêu cầu đã hết thời gian chờ. Vui lòng thử lại.');
    }
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await _client
          .put(uri, headers: _headers(), body: body != null ? jsonEncode(body) : null)
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(0, 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.');
    } on TimeoutException {
      throw ApiException(0, 'Yêu cầu đã hết thời gian chờ. Vui lòng thử lại.');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await _client
          .delete(uri, headers: _headers())
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(0, 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.');
    } on TimeoutException {
      throw ApiException(0, 'Yêu cầu đã hết thời gian chờ. Vui lòng thử lại.');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
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
    _client.close();
  }
}

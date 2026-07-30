import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/api_config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? code;
  final String? requestId;
  final Duration? retryAfter;

  ApiException(
    this.statusCode,
    this.message, {
    this.code,
    this.requestId,
    this.retryAfter,
  });

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
  static const Duration _timeout = Duration(seconds: 30);
  static int _requestSequence = 0;

  http.Client get _http => _client ??= http.Client();

  String? _getToken() {
    final session = Supabase.instance.client.auth.currentSession;
    return session?.accessToken;
  }

  Map<String, String> _headers() {
    final requestId =
        '${DateTime.now().microsecondsSinceEpoch}-${_requestSequence++}';
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'X-Request-ID': requestId,
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
    bool retryOnUnauthorized = true,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}$endpoint',
    ).replace(queryParameters: queryParams);
    try {
      late http.Response response;
      switch (method) {
        case 'GET':
          response = await _http
              .get(uri, headers: _headers())
              .timeout(_timeout);
          break;
        case 'POST':
          response = await _http
              .post(
                uri,
                headers: _headers(),
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(_timeout);
          break;
        case 'PUT':
          response = await _http
              .put(
                uri,
                headers: _headers(),
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(_timeout);
          break;
        case 'DELETE':
          response = await _http
              .delete(uri, headers: _headers())
              .timeout(_timeout);
          break;
        default:
          throw ArgumentError('Unsupported method: $method');
      }
      return _handleResponse(
        response,
        method,
        endpoint,
        queryParams,
        body,
        retryOnUnauthorized,
      );
    } on SocketException {
      throw ApiException(
        0,
        'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
        code: 'network_unavailable',
      );
    } on http.ClientException {
      throw ApiException(
        0,
        'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
        code: 'network_unavailable',
      );
    } on TimeoutException {
      throw ApiException(
        0,
        'Yêu cầu đã hết thời gian chờ. Vui lòng thử lại.',
        code: 'request_timeout',
      );
    }
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) =>
      _request('GET', endpoint, queryParams: queryParams);

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) =>
      _request('POST', endpoint, body: body);

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) =>
      _request('PUT', endpoint, body: body);

  Future<dynamic> delete(String endpoint) => _request('DELETE', endpoint);

  Future<dynamic> _handleResponse(
    http.Response response,
    String method,
    String endpoint,
    Map<String, String>? queryParams,
    Map<String, dynamic>? body,
    bool retryOnUnauthorized,
  ) async {
    if (response.statusCode == 401) {
      if (retryOnUnauthorized) {
        try {
          final refreshed = await Supabase.instance.client.auth
              .refreshSession();
          if (refreshed.session != null) {
            return _request(
              method,
              endpoint,
              queryParams: queryParams,
              body: body,
              retryOnUnauthorized: false,
            );
          }
        } catch (_) {
          // The shared sign-out below keeps auth state consistent.
        }
      }
      await Supabase.instance.client.auth.signOut();
      throw ApiAuthException(
        'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      );
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } on FormatException {
        throw ApiException(
          502,
          'Máy chủ trả về dữ liệu không hợp lệ. Vui lòng thử lại.',
          code: 'invalid_response',
          requestId: response.headers['x-request-id'],
        );
      }
    }
    String message = 'Đã xảy ra lỗi không xác định.';
    String? code;
    final requestId = response.headers['x-request-id'];
    Duration? retryAfter;
    final retryAfterValue = int.tryParse(response.headers['retry-after'] ?? '');
    if (retryAfterValue != null) {
      retryAfter = Duration(seconds: retryAfterValue);
    }
    try {
      final responseBody = jsonDecode(response.body);
      if (responseBody is Map && responseBody.containsKey('detail')) {
        final detail = responseBody['detail'];
        if (detail is Map) {
          message = detail['message']?.toString() ?? message;
          code = detail['code']?.toString();
        } else {
          message = detail.toString();
        }
      }
    } catch (_) {}
    code ??= response.headers['x-ai-error-code'];
    throw ApiException(
      response.statusCode,
      message,
      code: code,
      requestId: requestId,
      retryAfter: retryAfter,
    );
  }

  void dispose() {
    _client?.close();
    _client = null;
  }
}

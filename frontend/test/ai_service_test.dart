import 'package:flutter_test/flutter_test.dart';
import 'package:vocab_app/services/ai_service.dart';
import 'package:vocab_app/services/api_service.dart';

void main() {
  test('AI errors are translated into actionable Vietnamese messages', () {
    expect(
      friendlyAIErrorMessage(
        ApiException(0, 'raw', code: 'network_unavailable'),
      ),
      contains('kiểm tra mạng'),
    );
    expect(
      friendlyAIErrorMessage(ApiException(503, 'raw', code: 'ai_unavailable')),
      contains('tạm gián đoạn'),
    );
    expect(
      friendlyAIErrorMessage(ApiException(429, 'raw', code: 'rate_limited')),
      contains('gửi hơi nhanh'),
    );
  });

  test('unknown API errors preserve the safe backend message', () {
    expect(
      friendlyAIErrorMessage(
        ApiException(500, 'Thông báo an toàn', code: 'unknown'),
      ),
      'Thông báo an toàn',
    );
  });

  test('AI errors include request ID for production support', () {
    expect(
      friendlyAIErrorMessage(
        ApiException(
          503,
          'raw',
          code: 'ai_unavailable',
          requestId: 'request-123',
        ),
      ),
      contains('Mã hỗ trợ: request-123'),
    );
  });
}

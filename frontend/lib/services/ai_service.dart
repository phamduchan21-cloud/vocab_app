import 'api_service.dart';

String friendlyAIErrorMessage(Object error) {
  if (error is! ApiException) {
    return 'Sol gặp lỗi ngoài dự kiến. Vui lòng thử lại sau ít phút.';
  }
  final message = switch (error.code) {
    'network_unavailable' =>
      'Không thể kết nối máy chủ. Hãy kiểm tra mạng rồi thử lại.',
    'request_timeout' || 'provider_timeout' =>
      'Sol phản hồi chậm hơn bình thường. Bạn có thể thử gửi lại câu hỏi.',
    'rate_limited' =>
      'Bạn đang gửi hơi nhanh. Hãy chờ một lát rồi thử lại nhé.',
    'ai_unavailable' || 'quota_exhausted' =>
      'Sol đang tạm gián đoạn kết nối AI. Vui lòng thử lại sau ít phút.',
    _ => error.message,
  };
  final requestId = error.requestId;
  return requestId == null ? message : '$message\nMã hỗ trợ: $requestId';
}

/// Frontend service for AI features.
/// Calls backend /api/ai/ endpoints.
class AIService {
  final ApiService _api;

  AIService(this._api);

  /// Generate quiz questions using AI.
  Future<List<Map<String, dynamic>>> generateQuiz({
    int count = 10,
    String? topic,
    String level = 'intermediate',
  }) async {
    final body = <String, dynamic>{
      'count': count,
      'topic': topic ?? 'general',
      'level': level,
    };

    final response = await _api.post('/api/ai/generate-quiz', body: body);
    final data = response as Map<String, dynamic>;
    return (data['questions'] as List)
        .map((q) => q as Map<String, dynamic>)
        .toList();
  }

  /// Chat with AI Tutor.
  Future<Map<String, dynamic>> chat({
    required String message,
    Map<String, dynamic>? context,
  }) async {
    final body = <String, dynamic>{
      'message': message,
      'context': context ?? {},
    };

    final response = await _api.post('/api/ai/chat', body: body);
    return response as Map<String, dynamic>;
  }

  /// Explain a word in detail using AI.
  Future<Map<String, dynamic>> explainWord({
    required String word,
    String meaning = '',
    String context = '',
  }) async {
    final body = <String, dynamic>{
      'word': word,
      'meaning': meaning,
      'context': context,
    };

    final response = await _api.post('/api/ai/explain-word', body: body);
    return response as Map<String, dynamic>;
  }
}

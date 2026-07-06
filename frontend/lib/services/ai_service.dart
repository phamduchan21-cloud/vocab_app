import 'api_service.dart';

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

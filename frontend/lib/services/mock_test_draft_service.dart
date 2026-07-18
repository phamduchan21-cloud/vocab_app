// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html' as html;

import '../models/mock_test.dart';

class MockTestDraftService {
  static const _storageKey = 'solvocab_mock_test_draft_v1';

  static Map<String, dynamic>? load() {
    try {
      final raw = html.window.localStorage[_storageKey];
      if (raw == null || raw.isEmpty) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static void save({
    required MockTestConfig config,
    required String? testId,
    required List<MockTestQuestion> questions,
    required List<int?> answers,
    required Set<int> flagged,
    required int currentIndex,
    required int secondsRemaining,
  }) {
    try {
      html.window.localStorage[_storageKey] = jsonEncode({
        'level': config.level,
        'purpose': config.purpose,
        'topic': config.topic,
        'question_count': config.questionCount,
        'duration_minutes': config.durationMinutes,
        'test_id': testId,
        'questions': questions.map((q) => q.toJson()).toList(),
        'answers': answers,
        'flagged': flagged.toList(),
        'current_index': currentIndex,
        'seconds_remaining': secondsRemaining,
        'saved_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  static void clear() {
    try {
      html.window.localStorage.remove(_storageKey);
    } catch (_) {}
  }
}

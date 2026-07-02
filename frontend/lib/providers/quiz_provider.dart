import 'package:flutter/foundation.dart';
import '../models/quiz_category.dart';
import '../models/quiz_result.dart';
import '../services/quiz_service.dart';
import 'auth_provider.dart';

class QuizProvider extends ChangeNotifier {
  final QuizService _service;
  List<QuizCategory> _categories = [];
  List<Map<String, dynamic>> _currentQuestions = [];
  QuizResult? _lastResult;
  List<QuizResult> _history = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<QuizCategory> get categories => _categories;
  List<Map<String, dynamic>> get currentQuestions => _currentQuestions;
  QuizResult? get lastResult => _lastResult;
  List<QuizResult> get history => _history;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  QuizProvider(this._service);

  void updateAuth(AuthProvider auth) {
    // Auth state changed, no special handling needed
  }

  Future<void> fetchCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await _service.getCategories();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách bài quiz. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateQuiz({int count = 5}) async {
    _isLoading = true;
    _errorMessage = null;
    _currentQuestions = [];
    notifyListeners();

    try {
      _currentQuestions = await _service.generateQuiz(count: count);
    } catch (e) {
      _errorMessage = e.toString().contains('cần ít nhất')
          ? e.toString()
          : 'Không thể tạo câu hỏi. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitQuiz({
    required String quizType,
    required List<Map<String, dynamic>> answers,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _lastResult = await _service.submitQuiz(
        quizType: quizType,
        answers: answers,
      );
    } catch (e) {
      _errorMessage = 'Không thể nộp bài. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchHistory({int page = 1, int limit = 20}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.getHistory(page: page, limit: limit);
      _history = result['items'] as List<QuizResult>;
    } catch (e) {
      _errorMessage = 'Không thể tải lịch sử làm bài. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

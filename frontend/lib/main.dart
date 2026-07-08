import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/api_config.dart';
import 'services/api_service.dart';
import 'services/vocabulary_service.dart';
import 'services/quiz_service.dart';
import 'services/dashboard_service.dart';
import 'services/topic_service.dart';
import 'services/mock_test_service.dart';
import 'services/profile_service.dart';
import 'providers/auth_provider.dart';
import 'providers/vocabulary_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/flashcard_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/topic_provider.dart';
import 'providers/mock_test_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: ApiConfig.supabaseUrl,
    anonKey: ApiConfig.supabaseAnonKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Expose ApiService for screens that need it directly (e.g. AI Chat)
        Provider<ApiService>.value(value: _apiService),

        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, VocabularyProvider>(
          create: (_) => VocabularyProvider(VocabularyService(_apiService)),
          update: (_, auth, prev) => prev!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, QuizProvider>(
          create: (_) => QuizProvider(QuizService(_apiService)),
          update: (_, auth, prev) => prev!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, DashboardProvider>(
          create: (_) => DashboardProvider(DashboardService(_apiService)),
          update: (_, auth, prev) => prev!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, FlashcardProvider>(
          create: (_) => FlashcardProvider(VocabularyService(_apiService), TopicService(_apiService)),
          update: (_, auth, prev) => prev!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
          create: (_) => ProfileProvider(ProfileService(_apiService)),
          update: (_, auth, prev) => prev!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, TopicProvider>(
          create: (_) => TopicProvider(TopicService(_apiService)),
          update: (_, auth, prev) => prev!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, MockTestProvider>(
          create: (_) => MockTestProvider(MockTestService(_apiService)),
          update: (_, auth, prev) => prev!..updateAuth(auth),
        ),
      ],
      child: const VocabApp(),
    );
  }
}

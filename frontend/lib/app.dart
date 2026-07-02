import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/vocabulary_list_screen.dart';
import 'screens/vocabulary_form_screen.dart';
import 'screens/quiz_list_screen.dart';
import 'screens/quiz_play_screen.dart';
import 'screens/quiz_result_screen.dart';
import 'screens/quiz_history_screen.dart';
import 'screens/mock_test_screen.dart';
import 'screens/mock_test_play_screen.dart';
import 'screens/mock_test_result_screen.dart';
import 'models/mock_test.dart';
import 'screens/profile_screen.dart';

// ═══════════════════════════════════════════════════════
// 🎨 Brand: MeuBeu — Linh vật: Mèo tím
// Tagline: "Học miễn phí. Suốt đời."
// ═══════════════════════════════════════════════════════

class AppColors {
  // Primary — Tím (chủ đạo)
  static const primary = Color(0xFF8B5CF6);
  static const primaryLight = Color(0xFFA78BFA);
  static const primaryDark = Color(0xFF6D28D9);

  // Secondary — Hồng
  static const secondary = Color(0xFFF472B6);
  static const secondaryLight = Color(0xFFF9A8D4);

  // Accent
  static const accent1 = Color(0xFFFB923C); // Cam
  static const accent2 = Color(0xFFEF4444); // Đỏ
  static const accent3 = Color(0xFF34D399); // Xanh mint

  // Legacy aliases for backward compatibility
  static const orange = accent1;
  static const red = accent2;
  static const green = accent3;
  static const primaryColor = primary;

  // Mèo tím palette
  static const catPurple = Color(0xFF7C3AED);
  static const catPink = Color(0xFFEC4899);
  static const catLight = Color(0xFFEDE9FE);

  // Nền
  static const background = Color(0xFFFAFAFA);
  static const surface = Color(0xFFFFFFFF);

  // Text
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint = Color(0xFF9CA3AF);
}

class AppTheme {
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const secondaryGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [Color(0xFFF472B6), Color(0xFFFB923C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const catGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const primaryButtonGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class VocabApp extends StatefulWidget {
  const VocabApp({super.key});

  @override
  State<VocabApp> createState() => _VocabAppState();
}

class _VocabAppState extends State<VocabApp> {
  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final router = _buildRouter(auth);

    return MaterialApp.router(
      title: 'MeuBeu',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: router,
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.nunito().fontFamily,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.accent2,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.nunito(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: AppColors.surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accent2, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accent2, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIconColor: AppColors.textHint,
        labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.nunito(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 28,
        ),
        headlineMedium: GoogleFonts.nunito(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
        titleLarge: GoogleFonts.nunito(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleMedium: GoogleFonts.nunito(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyLarge: GoogleFonts.nunito(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.nunito(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),
    );
  }

  GoRouter _buildRouter(AuthProvider auth) {
    return GoRouter(
      refreshListenable: auth,
      initialLocation: '/splash',
      redirect: (context, state) {
        final authProv = context.read<AuthProvider>();
        final isLoggedIn = authProv.isAuthenticated;
        final location = state.matchedLocation;

        // Always allow splash and onboarding without auth
        if (location == '/splash' || location == '/onboarding') return null;

        // Auth routes
        final isAuthRoute = location == '/login' || location == '/register';
        if (!isLoggedIn && !isAuthRoute) return '/login';
        if (isLoggedIn && isAuthRoute) return '/';

        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
        GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
        GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
        GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
        GoRoute(
          path: '/vocabulary',
          builder: (_, _) => const VocabularyListScreen(),
          routes: [
            GoRoute(path: 'new', builder: (_, _) => const VocabularyFormScreen()),
            GoRoute(path: ':id/edit', builder: (_, state) {
              final id = state.pathParameters['id']!;
              return VocabularyFormScreen(id: id);
            }),
          ],
        ),
        GoRoute(
          path: '/quiz',
          builder: (_, _) => const QuizListScreen(),
          routes: [
            GoRoute(path: 'play', builder: (_, _) => const QuizPlayScreen()),
            GoRoute(path: 'result/:id', builder: (_, state) {
              final id = state.pathParameters['id']!;
              return QuizResultScreen(id: id);
            }),
            GoRoute(path: 'history', builder: (_, _) => const QuizHistoryScreen()),
          ],
        ),
        GoRoute(
          path: '/mock-test',
          builder: (_, _) => const MockTestScreen(),
          routes: [
            GoRoute(path: 'play/:level', builder: (_, state) {
              final level = state.pathParameters['level']!;
              return MockTestPlayScreen(level: level);
            }),
            GoRoute(path: 'result/:id', builder: (_, state) {
              final result = state.extra as MockTestResult?;
              if (result == null) {
                return const Scaffold(body: Center(child: Text('Không có dữ liệu kết quả')));
              }
              return MockTestResultScreen(result: result);
            }),
          ],
        ),
      ],
    );
  }
}

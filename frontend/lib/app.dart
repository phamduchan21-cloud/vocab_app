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
import 'screens/flashcard_screen.dart';
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
import 'screens/progress_screen.dart';
import 'screens/bookmark_screen.dart';
import 'screens/topic_browser_screen.dart';
import 'screens/topic_detail_screen.dart';
import 'screens/ai_chat_screen.dart';

// ═══════════════════════════════════════════════════════════
// 🔄 Custom Page Transitions
// ═══════════════════════════════════════════════════════════

Page<dynamic> _slideUpPage(Widget child) {
  return _CustomTransitionPage(
    key: ValueKey(child.hashCode),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        )),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
  );
}

Page<dynamic> _slideRightPage(Widget child) {
  return _CustomTransitionPage(
    key: ValueKey(child.hashCode),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.15, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        )),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
  );
}

Page<dynamic> _scaleFadePage(Widget child) {
  return _CustomTransitionPage(
    key: ValueKey(child.hashCode),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
  );
}

class _CustomTransitionPage extends CustomTransitionPage<dynamic> {
  const _CustomTransitionPage({
    required super.child,
    required super.transitionsBuilder,
    super.key,
  }) : super(
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
        );
}

// ═══════════════════════════════════════════════════════
// 🎨 VocaEng Design System — Taste-Skill compliant
// Cool cobalt palette, single accent, no beige/brass
// ═══════════════════════════════════════════════════════

class AppColors {
  // ─── Core tokens ────────────────────────────────────
  static const background = Color(0xFFF8F9FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSubtle = Color(0xFFF1F3F5);
  static const ink = Color(0xFF1A1D23);
  static const inkSoft = Color(0xFF6B7280);
  static const textHint = Color(0xFF9CA3AF);

  // ─── Single accent: Cobalt Blue ────────────────────
  static const blue = Color(0xFF2563EB);
  static const blueLight = Color(0xFF3B82F6);
  static const blueDark = Color(0xFF1D4ED8);
  static const blueBg = Color(0xFFEFF6FF);

  // ─── Semantic ──────────────────────────────────────
  static const success = Color(0xFF059669);
  static const successBg = Color(0xFFECFDF5);
  static const danger = Color(0xFFDC2626);
  static const dangerBg = Color(0xFFFEF2F2);
  static const warning = Color(0xFFD97706);
  static const warningBg = Color(0xFFFFFBEB);

  // ─── Backward-compatible aliases ────────────────────
  static const primary = blue;
  static const primaryLight = blueLight;
  static const primaryDark = blueDark;
  static const accent1 = blue;
  static const accent2 = danger;
  static const accent3 = success;
  static const textPrimary = ink;
  static const textSecondary = inkSoft;
}

// ─── Gradients ─────────────────────────────────────────
class AppTheme {
  static const primaryGradient = LinearGradient(
    colors: [AppColors.blue, AppColors.blueDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const secondaryGradient = LinearGradient(
    colors: [AppColors.blue, AppColors.blueLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [AppColors.blueLight, AppColors.blue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const primaryButtonGradient = LinearGradient(
    colors: [AppColors.blue, AppColors.blueDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ═══════════════════════════════════════════════════════
// 🚀 App
// ═══════════════════════════════════════════════════════

/// Taste-Skill compliant: cobalt accent, no serif, no beige palette.
class VocabApp extends StatefulWidget {
  const VocabApp({super.key});

  @override
  State<VocabApp> createState() => _VocabAppState();
}

class _VocabAppState extends State<VocabApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // GoRouter được tạo MỘT LẦN duy nhất — tránh rebuild loop
    _router = _buildRouter(context.read<AuthProvider>());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'VocaEng',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: _router,
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.workSans().fontFamily,
      colorScheme: ColorScheme.light(
        primary: AppColors.blue,
        secondary: AppColors.blueLight,
        surface: AppColors.surface,
        error: AppColors.danger,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,

      // ─── AppBar ──────────────────────────────────────
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.workSans(
          color: AppColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ─── Card ────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: AppColors.ink.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: AppColors.surface,
      ),

      // ─── Input ───────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.ink.withValues(alpha: 0.14)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.ink.withValues(alpha: 0.14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIconColor: AppColors.textHint,
        labelStyle: GoogleFonts.workSans(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.workSans(
          color: AppColors.textHint,
          fontSize: 14,
        ),
      ),

      // ─── Button ──────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.workSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.blue,
          textStyle: GoogleFonts.workSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.inkSoft,
          side: BorderSide(color: AppColors.ink.withValues(alpha: 0.14)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.workSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── Text — All Work Sans (no serif) ─────────────
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.workSans(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 28,
          letterSpacing: -0.3,
        ),
        headlineMedium: GoogleFonts.workSans(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 22,
          letterSpacing: -0.2,
        ),
        headlineSmall: GoogleFonts.workSans(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleLarge: GoogleFonts.workSans(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 17,
        ),
        titleMedium: GoogleFonts.workSans(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        titleSmall: GoogleFonts.workSans(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        bodyLarge: GoogleFonts.workSans(
          color: AppColors.ink,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.workSans(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        bodySmall: GoogleFonts.workSans(
          color: AppColors.textHint,
          fontSize: 12,
        ),
        labelLarge: GoogleFonts.workSans(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        labelMedium: GoogleFonts.ibmPlexMono(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        labelSmall: GoogleFonts.ibmPlexMono(
          color: AppColors.textHint,
          fontSize: 10,
        ),
      ),

      // ─── Divider & snack bar ─────────────────────────
      dividerTheme: DividerThemeData(
        color: AppColors.ink.withValues(alpha: 0.10),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: GoogleFonts.workSans(
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  GoRouter _buildRouter(AuthProvider auth) {
    return GoRouter(
      refreshListenable: auth,
      initialLocation: '/splash',
      redirect: (context, state) {
        final isLoggedIn = auth.isAuthenticated;
        final location = state.matchedLocation;

        // Cho phép splash + onboarding không cần auth
        if (location == '/splash' || location == '/onboarding') return null;

        final isAuthRoute = location == '/login' || location == '/register';
        // Chưa đăng nhập và không ở trang auth → redirect login
        if (!isLoggedIn && !isAuthRoute) return '/login';
        // Đã đăng nhập và đang ở trang auth → redirect dashboard
        if (isLoggedIn && isAuthRoute) return '/';

        return null;
      },
      routes: [
        // ─── Public ────────────────────────────────────
        GoRoute(
          path: '/splash',
          pageBuilder: (_, _) => _scaleFadePage(const SplashScreen()),
        ),
        GoRoute(
          path: '/onboarding',
          pageBuilder: (_, _) => _slideUpPage(const OnboardingScreen()),
        ),
        GoRoute(
          path: '/login',
          pageBuilder: (_, _) => _scaleFadePage(const LoginScreen()),
        ),
        GoRoute(
          path: '/register',
          pageBuilder: (_, _) => _scaleFadePage(const RegisterScreen()),
        ),

        // ─── Dashboard ─────────────────────────────────
        GoRoute(
          path: '/',
          pageBuilder: (_, _) => _slideUpPage(const DashboardScreen()),
        ),

        // ─── Flashcard ─────────────────────────────────
        GoRoute(
          path: '/flashcard',
          pageBuilder: (_, _) => _slideRightPage(const FlashcardScreen()),
        ),

        // ─── Quiz nhanh ────────────────────────────────
        GoRoute(
          path: '/quiz',
          pageBuilder: (_, _) => _slideRightPage(const QuizListScreen()),
          routes: [
            GoRoute(
              path: 'play',
              pageBuilder: (_, _) => _slideRightPage(const QuizPlayScreen()),
            ),
            GoRoute(
              path: 'result/:id',
              pageBuilder: (_, state) {
                final id = state.pathParameters['id']!;
                return _slideRightPage(QuizResultScreen(id: id));
              },
            ),
            GoRoute(
              path: 'history',
              pageBuilder: (_, _) => _slideRightPage(const QuizHistoryScreen()),
            ),
          ],
        ),

        // ─── AI Chat ─────────────────────────────────────
        GoRoute(
          path: '/ai-chat',
          pageBuilder: (_, _) => _slideRightPage(const AIChatScreen()),
        ),

        // ─── Mini-test ─────────────────────────────────
        GoRoute(
          path: '/test',
          pageBuilder: (_, _) => _slideRightPage(const MockTestScreen()),
        ),
        GoRoute(
          path: '/mock-test',
          pageBuilder: (_, _) => _slideRightPage(const MockTestScreen()),
          routes: [
            GoRoute(
              path: 'play/:level',
              pageBuilder: (_, state) {
                final level = state.pathParameters['level']!;
                final topic = state.uri.queryParameters['topic'];
                return _slideRightPage(MockTestPlayScreen(level: level, topic: topic));
              },
            ),
            GoRoute(
              path: 'result/:id',
              pageBuilder: (_, state) {
                final result = state.extra as MockTestResult?;
                if (result == null) {
                  return _slideRightPage(const Scaffold(
                    body: Center(
                      child: Text('Không có dữ liệu kết quả'),
                    ),
                  ));
                }
                return _slideRightPage(MockTestResultScreen(result: result));
              },
            ),
          ],
        ),

        // ─── Bookmark (Đã lưu) ─────────────────────────
        GoRoute(
          path: '/bookmark',
          pageBuilder: (_, _) => _slideRightPage(const BookmarkScreen()),
        ),

        // ─── Tiến độ ───────────────────────────────────
        GoRoute(
          path: '/progress',
          pageBuilder: (_, _) => _slideRightPage(const ProgressScreen()),
        ),

        // ─── Hồ sơ ─────────────────────────────────────
        GoRoute(
          path: '/profile',
          pageBuilder: (_, _) => _slideRightPage(const ProfileScreen()),
        ),

        // ─── Topic Browser (Kho từ vựng) ─────────────────
        GoRoute(
          path: '/topics',
          pageBuilder: (_, _) => _slideRightPage(const TopicBrowserScreen()),
          routes: [
            GoRoute(
              path: ':lessonId',
              pageBuilder: (_, state) {
                final lessonId = state.pathParameters['lessonId']!;
                return _slideRightPage(TopicDetailScreen(lessonId: lessonId));
              },
            ),
          ],
        ),

        // ─── Vocabulary (legacy) ───────────────────────
        GoRoute(
          path: '/vocabulary',
          pageBuilder: (_, _) => _slideRightPage(const VocabularyListScreen()),
          routes: [
            GoRoute(
              path: 'new',
              pageBuilder: (_, _) => _slideRightPage(const VocabularyFormScreen()),
            ),
            GoRoute(
              path: ':id/edit',
              pageBuilder: (_, state) {
                final id = state.pathParameters['id']!;
                return _slideRightPage(VocabularyFormScreen(id: id));
              },
            ),
          ],
        ),
      ],
    );
  }
}

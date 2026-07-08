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
  // ─── Stitch Material 3 Core tokens ─────────────────
  static const background = Color(0xFFF8F9FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFD9DADB);
  static const surfaceBright = Color(0xFFF8F9FA);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF3F4F5);
  static const surfaceContainer = Color(0xFFEDEEEF);
  static const surfaceContainerHigh = Color(0xFFE7E8E9);
  static const surfaceContainerHighest = Color(0xFFE1E3E4);
  static const surfaceVariant = Color(0xFFE1E3E4);
  static const surfaceSubtle = Color(0xFFF1F3F5);

  // ─── On-colors ─────────────────────────────────────
  static const onSurface = Color(0xFF191C1D);
  static const onSurfaceVariant = Color(0xFF434655);
  static const inverseSurface = Color(0xFF2E3132);
  static const inverseOnSurface = Color(0xFFF0F1F2);

  // ─── Ink (text) ────────────────────────────────────
  static const ink = Color(0xFF1A1D23);
  static const inkSoft = Color(0xFF6B7280);
  static const textHint = Color(0xFF9CA3AF);

  // ─── Accent: Cobalt Blue ──────────────────────────
  static const blue = Color(0xFF2563EB);
  static const blueDark = Color(0xFF004AC6);
  static const blueLight = Color(0xFF3B82F6);
  static const blueBg = Color(0xFFEFF6FF);
  static const blueContainer = Color(0xFF2170E4);

  // ─── Outline ───────────────────────────────────────
  static const outline = Color(0xFF737686);
  static const outlineVariant = Color(0xFFC3C6D7);

  // ─── Semantic ──────────────────────────────────────
  static const success = Color(0xFF059669);
  static const successBg = Color(0xFFECFDF5);
  static const danger = Color(0xFFDC2626);
  static const dangerBg = Color(0xFFFEF2F2);
  static const warning = Color(0xFFD97706);
  static const warningBg = Color(0xFFFFFBEB);
  static const tertiary = Color(0xFF824500);
  static const tertiaryContainer = Color(0xFFA65900);

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

// ─── Spacing & Radius tokens ──────────────────────────
class AppSpacing {
  static const double unit = 4;
  static const double gutter = 16;
  static const double marginMobile = 16;
  static const double marginDesktop = 24;
  static const double sidebarWidth = 230;
}

class AppRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 24;
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

  // ─── Stitch New Gradients ──────────────────────────
  static const heroGradient = LinearGradient(
    colors: [AppColors.blue, AppColors.blueContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const aiGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899)],
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
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.workSans().fontFamily,
      colorScheme: ColorScheme.light(
        primary: AppColors.blue,
        onPrimary: Colors.white,
        primaryContainer: AppColors.blueContainer,
        onPrimaryContainer: const Color(0xFFEEEFFF),
        secondary: const Color(0xFF0058BE),
        onSecondary: Colors.white,
        secondaryContainer: AppColors.blueContainer,
        onSecondaryContainer: const Color(0xFFFEFCFF),
        tertiary: AppColors.tertiary,
        onTertiary: Colors.white,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: const Color(0xFFFFEDE1),
        error: AppColors.danger,
        onError: Colors.white,
        errorContainer: const Color(0xFFFFDAD6),
        onErrorContainer: const Color(0xFF93000A),
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        surfaceContainerLowest: AppColors.surfaceContainerLowest,
        surfaceContainerLow: AppColors.surfaceContainerLow,
        surfaceContainer: AppColors.surfaceContainer,
        surfaceContainerHigh: AppColors.surfaceContainerHigh,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        inverseSurface: AppColors.inverseSurface,
        inversePrimary: const Color(0xFFB4C5FF),
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

      // ─── Text — Stitch Typography ───────────────────
      textTheme: TextTheme(
        // Nunito reserved for splash brand only
        headlineLarge: GoogleFonts.workSans(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 28,
          letterSpacing: -0.3,
          height: 1.29,
        ),
        headlineMedium: GoogleFonts.workSans(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 22,
          letterSpacing: -0.2,
          height: 1.27,
        ),
        headlineSmall: GoogleFonts.workSans(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 18,
          height: 1.33,
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
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.workSans(
          color: AppColors.onSurfaceVariant,
          fontSize: 14,
          height: 1.43,
        ),
        bodySmall: GoogleFonts.workSans(
          color: AppColors.textHint,
          fontSize: 12,
          height: 1.33,
        ),
        labelLarge: GoogleFonts.workSans(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        labelMedium: GoogleFonts.ibmPlexMono(
          color: AppColors.onSurfaceVariant,
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

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.workSans().fontFamily,
      colorScheme: ColorScheme.dark(
        primary: AppColors.blue,
        onPrimary: Colors.white,
        primaryContainer: AppColors.blueContainer,
        onPrimaryContainer: const Color(0xFFEEEFFF),
        secondary: const Color(0xFF0058BE),
        onSecondary: Colors.white,
        secondaryContainer: AppColors.blueContainer,
        onSecondaryContainer: const Color(0xFFFEFCFF),
        tertiary: AppColors.tertiary,
        onTertiary: Colors.white,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: const Color(0xFFFFEDE1),
        error: AppColors.danger,
        onError: Colors.white,
        errorContainer: const Color(0xFFFFDAD6),
        onErrorContainer: const Color(0xFF93000A),
        surface: const Color(0xFF1E1E1E),
        onSurface: const Color(0xFFE0E0E0),
        surfaceContainerLowest: const Color(0xFF121212),
        surfaceContainerLow: const Color(0xFF1E1E1E),
        surfaceContainer: const Color(0xFF2C2C2C),
        surfaceContainerHigh: const Color(0xFF3A3A3A),
        surfaceContainerHighest: const Color(0xFF484848),
        onSurfaceVariant: const Color(0xFFB0B0B0),
        outline: const Color(0xFF666666),
        outlineVariant: const Color(0xFF444444),
        inverseSurface: const Color(0xFFE0E0E0),
        inversePrimary: const Color(0xFFB4C5FF),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      canvasColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Color(0xFFE0E0E0),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        color: Color(0xFF1E1E1E),
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: AppColors.blue,
        unselectedItemColor: Color(0xFFB0B0B0),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF2C2C2C),
        contentTextStyle: TextStyle(color: Color(0xFFE0E0E0)),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF1E1E1E),
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

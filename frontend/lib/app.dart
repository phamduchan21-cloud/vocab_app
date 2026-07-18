import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/account_setup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/vocabulary_list_screen.dart';
import 'screens/flashcard_screen.dart';
import 'screens/vocabulary_form_screen.dart';
import 'screens/quiz_list_screen.dart';
import 'screens/quiz_play_screen.dart';
import 'screens/quiz_result_screen.dart';
import 'screens/quiz_history_screen.dart';
import 'screens/mock_test_screen.dart';
import 'screens/mock_test_history_screen.dart';
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
// 🔄 Custom Page Transitions — bouncy spring cubic
// ═══════════════════════════════════════════════════════════

const _springCurve = Cubic(0.34, 1.56, 0.64, 1);
const _slideCurve = Cubic(0.22, 1, 0.36, 1);

Page<dynamic> _slideUpPage(Widget child) {
  return _CustomTransitionPage(
    key: ValueKey(child.hashCode),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: animation,
                curve: _springCurve,
                reverseCurve: _slideCurve,
              ),
            ),
        child: FadeTransition(opacity: animation, child: child),
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
        position: Tween<Offset>(begin: const Offset(0.18, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: animation,
                curve: _slideCurve,
                reverseCurve: _slideCurve,
              ),
            ),
        child: FadeTransition(opacity: animation, child: child),
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
        scale: Tween<double>(
          begin: 0.88,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: _springCurve)),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}

Page<dynamic> _authSwitchPage(Widget child) {
  return _CustomTransitionPage(
    key: ValueKey(child.runtimeType),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: _slideCurve);
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.12, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
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
         transitionDuration: const Duration(milliseconds: 400),
         reverseTransitionDuration: const Duration(milliseconds: 300),
       );
}

// SolVocab design system: botanical focus with warm learning accents.

class AppBrand {
  static const name = 'SolVocab';
  static const assistantName = 'Sol';
  static const tagline = 'Từ mới vững vàng. Mỗi ngày tiến bộ.';
}

class AppColors {
  // ─── Warm candy background ──────────────────────────
  static const background = Color(0xFFF3F7F2);
  static const surface = Color(0xFFFFFDFC);
  static const surfaceDim = Color(0xFFE8F0EB);
  static const surfaceBright = Color(0xFFFFFDFC);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF7FAF7);
  static const surfaceContainer = Color(0xFFEDF4EF);
  static const surfaceContainerHigh = Color(0xFFE4EEE8);
  static const surfaceContainerHighest = Color(0xFFD8E7DE);
  static const surfaceVariant = Color(0xFFD8E7DE);
  static const surfaceSubtle = Color(0xFFEDF6F0);

  // ─── On-colors ─────────────────────────────────────────
  static const onSurface = Color(0xFF15251F);
  static const onSurfaceVariant = Color(0xFF536C63);
  static const inverseSurface = Color(0xFF17372E);
  static const inverseOnSurface = Color(0xFFF2F8F4);

  // ─── Ink (soft plum) ─────────────────────────────────
  static const ink = Color(0xFF15251F);
  static const inkSoft = Color(0xFF557168);
  static const textHint = Color(0xFF8AA098);

  // ─── Accent: Coral Pink (primary) ────────────────────
  static const blue = Color(0xFF0F766E);
  static const blueDark = Color(0xFF0A5A54);
  static const blueLight = Color(0xFF55A69E);
  static const blueBg = Color(0xFFE7F5F2);
  static const blueContainer = Color(0xFF0F766E);

  // ─── Playful accent colors ───────────────────────────
  static const rose = Color(0xFF0F766E);
  static const peach = Color(0xFFE76F51);
  static const mint = Color(0xFF4E9B68);
  static const mintDark = Color(0xFF36794D);
  static const mintBg = Color(0xFFEAF6ED);
  static const lavender = Color(0xFF3977A8);
  static const lavenderBg = Color(0xFFEBF3F8);
  static const sunny = Color(0xFFEAA544);
  static const sunnyBg = Color(0xFFFFF4DF);
  static const sky = Color(0xFF4C91C6);
  static const skyBg = Color(0xFFEAF4FA);

  // ─── Outline (soft) ─────────────────────────────────
  static const outline = Color(0xFF9DB2A9);
  static const outlineVariant = Color(0xFFD8E5DE);

  // ─── Semantic ──────────────────────────────────────────
  static const success = Color(0xFF3F8F5B);
  static const successBg = Color(0xFFEAF6ED);
  static const danger = Color(0xFFD94F4F);
  static const dangerBg = Color(0xFFFDECEC);
  static const warning = Color(0xFFE08B2E);
  static const warningBg = Color(0xFFFFF4DF);
  static const tertiary = Color(0xFF3977A8);
  static const tertiaryContainer = Color(0xFF2D648E);

  // Backward-compatible names used across existing screens.
  static const luxuryBg = background;
  static const luxurySurface = surface;
  static const luxuryBrown = Color(0xFF0F766E);
  static const luxuryBrownLight = Color(0xFF2A9187);
  static const luxuryBrownPale = Color(0xFF8AC0B7);
  static const luxuryBeige = Color(0xFFD9F0E8);
  static const luxuryEspresso = Color(0xFF102820);
  static const luxuryText = Color(0xFF557168);
  static const luxuryTextHint = Color(0xFF8AA098);
  static const luxuryBorder = Color(0xFFD8E5DE);
  static const luxuryGold = Color(0xFFE76F51);
  static const luxuryGreen = Color(0xFF4E9B68);
  static const luxuryDanger = danger;
  static const luxuryGradient = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF2A9187)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const luxuryGradientLight = LinearGradient(
    colors: [Color(0xFF55A69E), Color(0xFF0F766E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const luxuryGradientBeige = LinearGradient(
    colors: [Color(0xFFD9F0E8), Color(0xFF8AC0B7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const luxuryGradientDark = LinearGradient(
    colors: [Color(0xFF17372E), Color(0xFF102820)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Backward-compatible aliases ────────────────────
  static const primary = rose;
  static const primaryLight = Color(0xFF55A69E);
  static const primaryDark = rose;
  static const accent1 = rose;
  static const accent2 = mint;
  static const accent3 = lavender;
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
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
}

// Brand gradients are reserved for primary actions and hero surfaces.
class AppTheme {
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF2A9187)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const secondaryGradient = LinearGradient(
    colors: [Color(0xFF2A9187), Color(0xFF4E9B68)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [Color(0xFF3977A8), Color(0xFF4C91C6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const primaryButtonGradient = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF2A9187)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroGradient = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFFE76F51)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const aiGradient = LinearGradient(
    colors: [Color(0xFF3977A8), Color(0xFF0F766E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const mintGradient = LinearGradient(
    colors: [Color(0xFF4E9B68), Color(0xFF4C91C6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ═══════════════════════════════════════════════════════
// 🚀 App
// ═══════════════════════════════════════════════════════

class SolVocabApp extends StatefulWidget {
  const SolVocabApp({super.key});

  @override
  State<SolVocabApp> createState() => _SolVocabAppState();
}

class _SolVocabAppState extends State<SolVocabApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _buildRouter(context.read<AuthProvider>());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppBrand.name,
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.light,
      routerConfig: _router,
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.nunito().fontFamily,
      colorScheme: ColorScheme.light(
        primary: AppColors.rose,
        onPrimary: Colors.white,
        primaryContainer: AppColors.rose,
        onPrimaryContainer: Colors.white,
        secondary: AppColors.mint,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.mintBg,
        onSecondaryContainer: const Color(0xFF003325),
        tertiary: AppColors.lavender,
        onTertiary: Colors.white,
        tertiaryContainer: AppColors.lavender,
        onTertiaryContainer: Colors.white,
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
        inversePrimary: const Color(0xFFFFB0C0),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,

      // ─── AppBar ──────────────────────────────────────
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0.3,
        titleTextStyle: GoogleFonts.nunito(
          color: AppColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),

      // ─── Card ──────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: AppColors.outlineVariant),
        ),
        color: AppColors.surface,
        shadowColor: AppColors.rose.withValues(alpha: 0.08),
      ),

      // ─── Input ─────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: AppColors.rose, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: AppColors.danger, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        prefixIconColor: AppColors.textHint,
        labelStyle: GoogleFonts.nunito(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.nunito(color: AppColors.textHint, fontSize: 14),
      ),

      // ─── Button ──────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.rose,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
          shadowColor: AppColors.rose.withValues(alpha: 0.3),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.rose,
          textStyle: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.inkSoft,
          side: BorderSide(color: AppColors.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── Bottom Nav ─────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.rose,
        unselectedItemColor: AppColors.textHint,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ─── Typography ─────────────────────────────────
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.nunito(
          color: AppColors.ink,
          fontWeight: FontWeight.w800,
          fontSize: 28,
          height: 1.2,
        ),
        headlineMedium: GoogleFonts.nunito(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 22,
          height: 1.25,
        ),
        headlineSmall: GoogleFonts.nunito(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          height: 1.3,
        ),
        titleLarge: GoogleFonts.nunito(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
        titleMedium: GoogleFonts.nunito(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        titleSmall: GoogleFonts.nunito(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        bodyLarge: GoogleFonts.nunito(
          color: AppColors.ink,
          fontSize: 16,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.nunito(
          color: AppColors.onSurfaceVariant,
          fontSize: 14,
          height: 1.55,
        ),
        bodySmall: GoogleFonts.nunito(
          color: AppColors.textHint,
          fontSize: 12,
          height: 1.45,
        ),
        labelLarge: GoogleFonts.nunito(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
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
        color: AppColors.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: GoogleFonts.nunito(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),

      // ─── Progress Indicator ─────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.rose,
        linearTrackColor: AppColors.rose.withValues(alpha: 0.12),
        circularTrackColor: AppColors.rose.withValues(alpha: 0.12),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.nunito().fontFamily,
      colorScheme: ColorScheme.dark(
        primary: AppColors.rose,
        onPrimary: Colors.white,
        primaryContainer: AppColors.rose,
        onPrimaryContainer: Colors.white,
        secondary: AppColors.mint,
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFF003325),
        onSecondaryContainer: AppColors.mint,
        tertiary: AppColors.lavender,
        onTertiary: Colors.white,
        tertiaryContainer: AppColors.lavender,
        onTertiaryContainer: Colors.white,
        error: AppColors.danger,
        onError: Colors.white,
        errorContainer: const Color(0xFFFFDAD6),
        onErrorContainer: const Color(0xFF93000A),
        surface: const Color(0xFF1E1C2E),
        onSurface: const Color(0xFFE8E0F0),
        surfaceContainerLowest: const Color(0xFF141226),
        surfaceContainerLow: const Color(0xFF1E1C2E),
        surfaceContainer: const Color(0xFF2A2840),
        surfaceContainerHigh: const Color(0xFF363452),
        surfaceContainerHighest: const Color(0xFF424064),
        onSurfaceVariant: const Color(0xFFB8AEC8),
        outline: const Color(0xFF5A5270),
        outlineVariant: const Color(0xFF3A3858),
        inverseSurface: const Color(0xFFE8E0F0),
        inversePrimary: const Color(0xFFFFB0C0),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF141226),
      canvasColor: const Color(0xFF141226),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF1E1C2E),
        foregroundColor: Color(0xFFE8E0F0),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl)),
        ),
        color: const Color(0xFF1E1C2E),
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1C2E),
        selectedItemColor: AppColors.rose,
        unselectedItemColor: Color(0xFF7A7290),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF2A2840),
        contentTextStyle: TextStyle(color: Color(0xFFE8E0F0)),
      ),
      dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF1E1C2E)),
    );
  }

  GoRouter _buildRouter(AuthProvider auth) {
    return GoRouter(
      refreshListenable: auth,
      initialLocation: '/splash',
      redirect: (context, state) {
        final isLoggedIn = auth.isAuthenticated;
        final location = state.matchedLocation;
        final isAuthPreview = state.uri.queryParameters['preview'] == 'true';

        if (location == '/splash' || location == '/onboarding') return null;

        final isAuthRoute = location == '/login' || location == '/register';
        if (!isLoggedIn && !isAuthRoute) return '/login';
        if (isLoggedIn && isAuthRoute && !isAuthPreview) {
          return auth.needsOnboarding ? '/setup' : '/';
        }

        return null;
      },
      routes: [
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
          pageBuilder: (_, _) => _authSwitchPage(const LoginScreen()),
        ),
        GoRoute(
          path: '/register',
          pageBuilder: (_, _) => _authSwitchPage(const RegisterScreen()),
        ),
        GoRoute(
          path: '/setup',
          pageBuilder: (_, _) => _slideUpPage(const AccountSetupScreen()),
        ),
        GoRoute(
          path: '/',
          pageBuilder: (_, _) => _slideUpPage(const DashboardScreen()),
        ),
        GoRoute(
          path: '/flashcard',
          pageBuilder: (_, _) => _slideRightPage(const FlashcardScreen()),
        ),
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
        GoRoute(
          path: '/ai-chat',
          pageBuilder: (_, _) => _slideRightPage(const AIChatScreen()),
        ),
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
                final purpose =
                    state.uri.queryParameters['purpose'] ?? 'general';
                final count =
                    int.tryParse(state.uri.queryParameters['count'] ?? '') ??
                    10;
                final duration =
                    int.tryParse(state.uri.queryParameters['duration'] ?? '') ??
                    10;
                return _slideRightPage(
                  MockTestPlayScreen(
                    level: level,
                    topic: topic,
                    purpose: purpose,
                    questionCount: count,
                    durationMinutes: duration,
                  ),
                );
              },
            ),
            GoRoute(
              path: 'history',
              pageBuilder: (_, _) =>
                  _slideRightPage(const MockTestHistoryScreen()),
            ),
            GoRoute(
              path: 'result/:id',
              pageBuilder: (_, state) {
                final result = state.extra as MockTestResult?;
                if (result == null) {
                  return _slideRightPage(
                    const Scaffold(
                      body: Center(child: Text('Không có dữ liệu kết quả')),
                    ),
                  );
                }
                return _slideRightPage(MockTestResultScreen(result: result));
              },
            ),
          ],
        ),
        GoRoute(
          path: '/bookmark',
          pageBuilder: (_, _) => _slideRightPage(const BookmarkScreen()),
        ),
        GoRoute(
          path: '/progress',
          pageBuilder: (_, _) => _slideRightPage(const ProgressScreen()),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (_, _) => _slideRightPage(const ProfileScreen()),
        ),
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
        GoRoute(
          path: '/vocabulary',
          pageBuilder: (_, _) => _slideRightPage(const VocabularyListScreen()),
          routes: [
            GoRoute(
              path: 'new',
              pageBuilder: (_, _) =>
                  _slideRightPage(const VocabularyFormScreen()),
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

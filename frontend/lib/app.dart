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
import 'motion/app_motion.dart';
import 'widgets/cosmic_background.dart';
import 'widgets/sol_assistant_overlay.dart';

// SolVocab design system: a cosmic learning observatory.

class AppBrand {
  static const name = 'SolVocab';
  static const assistantName = 'Sol';
  static const tagline = 'Mở khóa từ mới. Mở rộng vũ trụ của bạn.';
}

class AppColors {
  // ─── Deep-space foundation ───────────────────────────
  static const background = Color(0xF70A0F1F);
  static const surface = Color(0xFF151D34);
  static const surfaceDim = Color(0xFF080D1B);
  static const surfaceBright = Color(0xFF222E50);
  static const surfaceContainerLowest = Color(0xFF0D1427);
  static const surfaceContainerLow = Color(0xFF121A30);
  static const surfaceContainer = Color(0xFF18223E);
  static const surfaceContainerHigh = Color(0xFF202C4C);
  static const surfaceContainerHighest = Color(0xFF29365B);
  static const surfaceVariant = Color(0xFF29365B);
  static const surfaceSubtle = Color(0xFF17213A);
  static const cosmicDeep = Color(0xFF091326);
  static const cosmicPanel = Color(0xFF121D35);
  static const cosmicGlow = Color(0xFF55D9EA);

  // ─── Starlight text ──────────────────────────────────
  static const onSurface = Color(0xFFF4F7FF);
  static const onSurfaceVariant = Color(0xFFB3BED9);
  static const inverseSurface = Color(0xFFEAF2FF);
  static const inverseOnSurface = Color(0xFF11182B);
  static const ink = Color(0xFFF4F7FF);
  static const inkSoft = Color(0xFFB6C1DC);
  static const textHint = Color(0xFF7F8CAB);

  // ─── Plasma cyan primary ─────────────────────────────
  static const blue = Color(0xFF55D9EA);
  static const blueDark = Color(0xFF159DB8);
  static const blueLight = Color(0xFF9DECF4);
  static const blueBg = Color(0xFF123746);
  static const blueContainer = Color(0xFF1CAAC2);

  // ─── Celestial accents ───────────────────────────────
  static const rose = Color(0xFF55D9EA);
  static const peach = Color(0xFFFF7A66);
  static const mint = Color(0xFF59E3B3);
  static const mintDark = Color(0xFF24B984);
  static const mintBg = Color(0xFF123A34);
  static const lavender = Color(0xFF7FA8FF);
  static const lavenderBg = Color(0xFF1A2A50);
  static const sunny = Color(0xFFFFC857);
  static const sunnyBg = Color(0xFF49391A);
  static const sky = Color(0xFF61B8FF);
  static const skyBg = Color(0xFF163451);

  // ─── Orbital outlines ────────────────────────────────
  static const outline = Color(0xFF536487);
  static const outlineVariant = Color(0xFF303E61);

  // ─── Semantic ──────────────────────────────────────────
  static const success = Color(0xFF59E3B3);
  static const successBg = Color(0xFF123A34);
  static const danger = Color(0xFFFF6B7A);
  static const dangerBg = Color(0xFF471D2A);
  static const warning = Color(0xFFFFC857);
  static const warningBg = Color(0xFF49391A);
  static const tertiary = Color(0xFF7FA8FF);
  static const tertiaryContainer = Color(0xFF233A72);

  // Backward-compatible names used across existing screens.
  static const luxuryBg = background;
  static const luxurySurface = surface;
  static const luxuryBrown = Color(0xFF55D9EA);
  static const luxuryBrownLight = Color(0xFF2EBAD1);
  static const luxuryBrownPale = Color(0xFF7FA8FF);
  static const luxuryBeige = Color(0xFF243A68);
  static const luxuryEspresso = Color(0xFFF4F7FF);
  static const luxuryText = Color(0xFFB6C1DC);
  static const luxuryTextHint = Color(0xFF7F8CAB);
  static const luxuryBorder = Color(0xFF303E61);
  static const luxuryGold = Color(0xFFFFC857);
  static const luxuryGreen = Color(0xFF59E3B3);
  static const luxuryDanger = danger;
  static const luxuryGradient = LinearGradient(
    colors: [Color(0xFF159DB8), Color(0xFF3156B8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const luxuryGradientLight = LinearGradient(
    colors: [Color(0xFF55D9EA), Color(0xFF5D79E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const luxuryGradientBeige = LinearGradient(
    colors: [Color(0xFF25385F), Color(0xFF314A7D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const luxuryGradientDark = LinearGradient(
    colors: [Color(0xFF17294B), Color(0xFF0A1022)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Backward-compatible aliases ────────────────────
  static const primary = rose;
  static const primaryLight = Color(0xFF9DECF4);
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
    colors: [Color(0xFF159DB8), Color(0xFF3156B8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const secondaryGradient = LinearGradient(
    colors: [Color(0xFF24B984), Color(0xFF159DB8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [Color(0xFF5D79E8), Color(0xFF159DB8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const primaryButtonGradient = LinearGradient(
    colors: [Color(0xFF55D9EA), Color(0xFF2DB8D0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroGradient = LinearGradient(
    colors: [Color(0xFF12294E), Color(0xFF273B77), Color(0xFF214E68)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const aiGradient = LinearGradient(
    colors: [Color(0xFF5D79E8), Color(0xFF159DB8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const mintGradient = LinearGradient(
    colors: [Color(0xFF24B984), Color(0xFF159DB8)],
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
      builder: (context, child) => CosmicBackground(
        child: SolAssistantOverlay(
          routeInformation: _router.routeInformationProvider,
          onOpenChat: () async {
            final from = _router.routeInformationProvider.value.uri.path;
            await _router.push(
              Uri(path: '/ai-chat', queryParameters: {'from': from}).toString(),
            );
          },
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.manrope().fontFamily,
      colorScheme: ColorScheme.dark(
        primary: AppColors.rose,
        onPrimary: AppColors.cosmicDeep,
        primaryContainer: AppColors.blueBg,
        onPrimaryContainer: AppColors.blueLight,
        secondary: AppColors.mint,
        onSecondary: AppColors.cosmicDeep,
        secondaryContainer: AppColors.mintBg,
        onSecondaryContainer: AppColors.mint,
        tertiary: AppColors.lavender,
        onTertiary: AppColors.cosmicDeep,
        tertiaryContainer: AppColors.lavenderBg,
        onTertiaryContainer: AppColors.lavender,
        error: AppColors.danger,
        onError: AppColors.cosmicDeep,
        errorContainer: AppColors.dangerBg,
        onErrorContainer: AppColors.danger,
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
        inversePrimary: AppColors.blueDark,
        brightness: Brightness.dark,
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
        titleTextStyle: GoogleFonts.spaceGrotesk(
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
        labelStyle: GoogleFonts.manrope(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.manrope(color: AppColors.textHint, fontSize: 14),
      ),

      // ─── Button ──────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.rose,
          foregroundColor: AppColors.cosmicDeep,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
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
          textStyle: GoogleFonts.manrope(
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
          textStyle: GoogleFonts.manrope(
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
        selectedLabelStyle: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ─── Typography ─────────────────────────────────
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.spaceGrotesk(
          color: AppColors.ink,
          fontWeight: FontWeight.w800,
          fontSize: 28,
          height: 1.2,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 22,
          height: 1.25,
        ),
        headlineSmall: GoogleFonts.spaceGrotesk(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          height: 1.3,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
        titleMedium: GoogleFonts.spaceGrotesk(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        titleSmall: GoogleFonts.spaceGrotesk(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        bodyLarge: GoogleFonts.manrope(
          color: AppColors.ink,
          fontSize: 16,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.manrope(
          color: AppColors.onSurfaceVariant,
          fontSize: 14,
          height: 1.55,
        ),
        bodySmall: GoogleFonts.manrope(
          color: AppColors.textHint,
          fontSize: 12,
          height: 1.45,
        ),
        labelLarge: GoogleFonts.manrope(
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
        backgroundColor: AppColors.surfaceBright,
        contentTextStyle: GoogleFonts.manrope(
          color: AppColors.onSurface,
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
    return _buildLightTheme();
  }

  GoRouter _buildRouter(AuthProvider auth) {
    return GoRouter(
      refreshListenable: auth,
      initialLocation: '/splash',
      redirect: (context, state) {
        final isLoggedIn = auth.isAuthenticated;
        final location = state.matchedLocation;
        final isAuthPreview = state.uri.queryParameters['preview'] == 'true';

        if (location == '/splash') {
          if (!isLoggedIn) return null;
          return auth.needsOnboarding ? '/setup' : '/';
        }
        if (location == '/onboarding') return null;

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
          pageBuilder: (_, state) => AppMotion.page(
            state: state,
            child: const SplashScreen(),
            kind: MotionPageKind.auth,
          ),
        ),
        GoRoute(
          path: '/onboarding',
          pageBuilder: (_, state) => AppMotion.page(
            state: state,
            child: const OnboardingScreen(),
            kind: MotionPageKind.modal,
          ),
        ),
        GoRoute(
          path: '/login',
          pageBuilder: (_, state) => AppMotion.page(
            state: state,
            child: const LoginScreen(),
            kind: MotionPageKind.auth,
          ),
        ),
        GoRoute(
          path: '/register',
          pageBuilder: (_, state) => AppMotion.page(
            state: state,
            child: const RegisterScreen(),
            kind: MotionPageKind.auth,
          ),
        ),
        GoRoute(
          path: '/setup',
          pageBuilder: (_, state) => AppMotion.page(
            state: state,
            child: const AccountSetupScreen(),
            kind: MotionPageKind.modal,
          ),
        ),
        GoRoute(
          path: '/',
          pageBuilder: (_, state) => AppMotion.page(
            state: state,
            child: const DashboardScreen(),
            kind: MotionPageKind.mainTab,
          ),
        ),
        GoRoute(
          path: '/flashcard',
          pageBuilder: (_, state) => AppMotion.page(
            state: state,
            child: const FlashcardScreen(),
            kind: MotionPageKind.mainTab,
          ),
        ),
        GoRoute(
          path: '/quiz',
          pageBuilder: (_, state) => AppMotion.page(
            state: state,
            child: const QuizListScreen(),
            kind: MotionPageKind.mainTab,
          ),
          routes: [
            GoRoute(
              path: 'play',
              pageBuilder: (_, state) => AppMotion.page(
                state: state,
                child: const QuizPlayScreen(),
                kind: MotionPageKind.detail,
              ),
            ),
            GoRoute(
              path: 'result/:id',
              pageBuilder: (_, state) {
                final id = state.pathParameters['id']!;
                return AppMotion.page(
                  state: state,
                  child: QuizResultScreen(id: id),
                  kind: MotionPageKind.result,
                );
              },
            ),
            GoRoute(
              path: 'history',
              pageBuilder: (_, state) => AppMotion.page(
                state: state,
                child: const QuizHistoryScreen(),
                kind: MotionPageKind.detail,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/ai-chat',
          pageBuilder: (_, state) => AppMotion.page(
            state: state,
            child: const AIChatScreen(),
            kind: MotionPageKind.detail,
          ),
        ),
        GoRoute(
          path: '/test',
          pageBuilder: (_, state) => AppMotion.page(
            state: state,
            child: const MockTestScreen(),
            kind: MotionPageKind.mainTab,
          ),
        ),
        GoRoute(
          path: '/mock-test',
          pageBuilder: (_, state) => AppMotion.page(
            state: state,
            child: const MockTestScreen(),
            kind: MotionPageKind.mainTab,
          ),
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
                return AppMotion.page(
                  state: state,
                  child: MockTestPlayScreen(
                    level: level,
                    topic: topic,
                    purpose: purpose,
                    questionCount: count,
                    durationMinutes: duration,
                  ),
                  kind: MotionPageKind.detail,
                );
              },
            ),
            GoRoute(
              path: 'history',
              pageBuilder: (_, state) => AppMotion.page(
                state: state,
                child: const MockTestHistoryScreen(),
                kind: MotionPageKind.detail,
              ),
            ),
            GoRoute(
              path: 'result/:id',
              pageBuilder: (_, state) {
                final result = state.extra as MockTestResult?;
                if (result == null) {
                  return AppMotion.page(
                    state: state,
                    child: const Scaffold(
                      body: Center(child: Text('Không có dữ liệu kết quả')),
                    ),
                    kind: MotionPageKind.result,
                  );
                }
                return AppMotion.page(
                  state: state,
                  child: MockTestResultScreen(result: result),
                  kind: MotionPageKind.result,
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: '/bookmark',
          pageBuilder: (_, state) => AppMotion.page(
            state: state,
            child: const BookmarkScreen(),
            kind: MotionPageKind.detail,
          ),
        ),
        GoRoute(
          path: '/progress',
          pageBuilder: (_, state) => AppMotion.page(
            state: state,
            child: const ProgressScreen(),
            kind: MotionPageKind.detail,
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (_, state) => AppMotion.page(
            state: state,
            child: const ProfileScreen(),
            kind: MotionPageKind.mainTab,
          ),
        ),
        GoRoute(
          path: '/topics',
          pageBuilder: (_, state) => AppMotion.page(
            state: state,
            child: const TopicBrowserScreen(),
            kind: MotionPageKind.detail,
          ),
          routes: [
            GoRoute(
              path: ':lessonId',
              pageBuilder: (_, state) {
                final lessonId = state.pathParameters['lessonId']!;
                return AppMotion.page(
                  state: state,
                  child: TopicDetailScreen(lessonId: lessonId),
                  kind: MotionPageKind.detail,
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: '/vocabulary',
          pageBuilder: (_, state) => AppMotion.page(
            state: state,
            child: const VocabularyListScreen(),
            kind: MotionPageKind.detail,
          ),
          routes: [
            GoRoute(
              path: 'new',
              pageBuilder: (_, state) => AppMotion.page(
                state: state,
                child: const VocabularyFormScreen(),
                kind: MotionPageKind.modal,
              ),
            ),
            GoRoute(
              path: ':id/edit',
              pageBuilder: (_, state) {
                final id = state.pathParameters['id']!;
                return AppMotion.page(
                  state: state,
                  child: VocabularyFormScreen(id: id),
                  kind: MotionPageKind.modal,
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

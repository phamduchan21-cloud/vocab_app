import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vocab_app/widgets/cat_widget.dart';
import 'package:vocab_app/widgets/sol_assistant_overlay.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('assistant can be dragged and opens chat when tapped', (
    tester,
  ) async {
    final route = ValueNotifier(RouteInformation(uri: Uri.parse('/flashcard')));
    var openCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: SolAssistantOverlay(
          routeInformation: route,
          onOpenChat: () async => openCount++,
          child: const Scaffold(body: Text('Flashcard')),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Đang vướng ở đâu?'), findsOneWidget);
    expect(find.byType(CatWidget), findsOneWidget);

    final before = tester.getTopLeft(find.byType(CatWidget));
    await tester.drag(find.byType(CatWidget), const Offset(-120, -80));
    await tester.pump();
    final after = tester.getTopLeft(find.byType(CatWidget));

    expect(after.dx, lessThan(before.dx));
    expect(after.dy, lessThan(before.dy));

    await tester.tap(find.byType(CatWidget));
    await tester.pump();
    expect(openCount, 1);

    route.dispose();
  });

  testWidgets('assistant hint stays compact on desktop', (tester) async {
    tester.view.physicalSize = const Size(1100, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final route = ValueNotifier(RouteInformation(uri: Uri.parse('/quiz')));
    addTearDown(route.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: SolAssistantOverlay(
          routeInformation: route,
          onOpenChat: () async {},
          child: const Scaffold(body: Text('Quiz')),
        ),
      ),
    );
    await tester.pump();

    final hint = find.byKey(const ValueKey('sol-assistant-hint'));
    expect(hint, findsOneWidget);
    expect(tester.getSize(hint).width, lessThanOrEqualTo(330));
    expect(tester.getSize(hint).height, 122);
  });

  testWidgets('assistant stays hidden on auth and chat routes', (tester) async {
    final route = ValueNotifier(RouteInformation(uri: Uri.parse('/login')));

    await tester.pumpWidget(
      MaterialApp(
        home: SolAssistantOverlay(
          routeInformation: route,
          onOpenChat: () async {},
          child: const Scaffold(body: Text('Nội dung')),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CatWidget), findsNothing);

    route.value = RouteInformation(uri: Uri.parse('/ai-chat'));
    await tester.pump();
    expect(find.byType(CatWidget), findsNothing);

    route.value = RouteInformation(uri: Uri.parse('/profile'));
    await tester.pump();
    expect(find.byType(CatWidget), findsOneWidget);

    route.dispose();
  });

  testWidgets('assistant returns after closing a pushed chat route', (
    tester,
  ) async {
    late final GoRouter router;
    router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (_, _) => const Scaffold(body: Text('Profile')),
        ),
        GoRoute(
          path: '/ai-chat',
          builder: (context, _) => Scaffold(
            appBar: AppBar(
              leading: IconButton(
                tooltip: 'Close chat',
                onPressed: context.pop,
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            body: const Text('AI Chat'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => SolAssistantOverlay(
          routeInformation: router.routeInformationProvider,
          onOpenChat: () => router.push('/ai-chat?from=/profile'),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Profile'), findsOneWidget);
    expect(find.byType(CatWidget), findsOneWidget);

    await tester.tap(find.byType(CatWidget));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('AI Chat'), findsOneWidget);
    expect(find.byType(CatWidget), findsNothing);

    await tester.tap(find.byTooltip('Close chat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Profile'), findsOneWidget);
    expect(find.byType(CatWidget), findsOneWidget);
  });
}

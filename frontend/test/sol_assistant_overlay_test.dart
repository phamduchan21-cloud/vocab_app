import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
          onOpenChat: () => openCount++,
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

  testWidgets('assistant stays hidden on auth and chat routes', (tester) async {
    final route = ValueNotifier(RouteInformation(uri: Uri.parse('/login')));

    await tester.pumpWidget(
      MaterialApp(
        home: SolAssistantOverlay(
          routeInformation: route,
          onOpenChat: () {},
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
}

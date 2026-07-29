import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocab_app/motion/app_motion.dart';

void main() {
  Widget motionHarness(MotionPageKind kind, {bool reduceMotion = false}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          disableAnimations: reduceMotion,
          accessibleNavigation: reduceMotion,
        ),
        child: AppMotionTransition(
          animation: const AlwaysStoppedAnimation(0.5),
          secondaryAnimation: const AlwaysStoppedAnimation(0.25),
          kind: kind,
          child: const Text('Nội dung'),
        ),
      ),
    );
  }

  testWidgets('main tab uses fade-through and scale', (tester) async {
    await tester.pumpWidget(motionHarness(MotionPageKind.mainTab));

    expect(find.byType(FadeTransition), findsWidgets);
    expect(find.byType(ScaleTransition), findsWidgets);
    expect(find.text('Nội dung'), findsOneWidget);
  });

  testWidgets('detail and auth routes use directional slide', (tester) async {
    await tester.pumpWidget(motionHarness(MotionPageKind.detail));
    expect(find.byType(SlideTransition), findsWidgets);

    await tester.pumpWidget(motionHarness(MotionPageKind.auth));
    expect(find.byType(SlideTransition), findsWidgets);
  });

  testWidgets('modal rises and result receives stamp-like scale', (
    tester,
  ) async {
    await tester.pumpWidget(motionHarness(MotionPageKind.modal));
    expect(find.byType(SlideTransition), findsWidgets);

    await tester.pumpWidget(motionHarness(MotionPageKind.result));
    expect(find.byType(ScaleTransition), findsWidgets);
  });

  testWidgets('reduced motion renders content without transforms', (
    tester,
  ) async {
    for (final kind in MotionPageKind.values) {
      await tester.pumpWidget(motionHarness(kind, reduceMotion: true));

      final motion = find.byType(AppMotionTransition);
      expect(find.text('Nội dung'), findsOneWidget);
      expect(
        find.descendant(of: motion, matching: find.byType(SlideTransition)),
        findsNothing,
      );
      expect(
        find.descendant(of: motion, matching: find.byType(ScaleTransition)),
        findsNothing,
      );
      expect(
        find.descendant(of: motion, matching: find.byType(FadeTransition)),
        findsNothing,
      );
    }
  });

  testWidgets('stamp reveal completes immediately with reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            disableAnimations: true,
            accessibleNavigation: true,
          ),
          child: AirmailStampReveal(child: Text('Dấu điểm')),
        ),
      ),
    );

    await tester.pump();
    final reveal = find.byType(AirmailStampReveal);
    final fade = tester.widget<FadeTransition>(
      find.descendant(of: reveal, matching: find.byType(FadeTransition)),
    );
    expect(fade.opacity.value, 1);
    expect(find.text('Dấu điểm'), findsOneWidget);
  });
}

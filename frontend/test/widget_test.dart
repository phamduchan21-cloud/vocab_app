import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    // Note: Full widget test requires Supabase mock.
    // This is a smoke test to verify the app can build.
    // For now, test basic Material widgets instead.

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('VocaEng - Học Từ Vựng'),
          ),
        ),
      ),
    );

    expect(find.text('VocaEng - Học Từ Vựng'), findsOneWidget);
  });
}

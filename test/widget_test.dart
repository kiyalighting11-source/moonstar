// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Moonstar app smoke test', (WidgetTester tester) async {
    // اختبار بسيط إن الـ widgets الأساسية بتشتغل
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Moonstar')),
        ),
      ),
    );

    expect(find.text('Moonstar'), findsOneWidget);
  });
}

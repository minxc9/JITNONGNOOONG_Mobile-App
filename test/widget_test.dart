import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('smoke test widget renders expected text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Smoke Test')),
        ),
      ),
    );

    expect(find.text('Smoke Test'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('test environment smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('SPIT Canteen')));

    expect(find.text('SPIT Canteen'), findsOneWidget);
  });
}

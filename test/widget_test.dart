// SmartQuail Widget Test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartquail_app/main.dart';

void main() {
  testWidgets('SmartQuail app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartQuailApp());

    // Verify that SmartQuail title appears
    expect(find.text('SmartQuail'), findsOneWidget);

    // Verify that Dashboard tab exists
    expect(find.text('Dashboard'), findsOneWidget);
  });
}

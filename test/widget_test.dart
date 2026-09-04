import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nchat/main.dart';

void main() {
  testWidgets('NChat app smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MyApp(
        themeMode: ThemeMode.light,
      ),
    );

    await tester.pump();

    expect(find.byType(MyApp), findsOneWidget);
  });
}
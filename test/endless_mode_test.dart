import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flame_game/main.dart';

void main() {
  testWidgets('endless mode runs without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const FlameGameApp());
    await tester.pump();

    await tester.tap(find.text('Endless Mode'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Spawn'), findsOneWidget);
  });
}

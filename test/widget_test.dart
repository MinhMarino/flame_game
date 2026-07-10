import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flame_game/main.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('App boots and renders MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const FlameGameApp());
    await pumpUntilFound(tester, find.text('Endless Mode'));
    await tester.pumpAndSettle(); // let the page transition finish.

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Ant Smasher'), findsOneWidget);
  });
}

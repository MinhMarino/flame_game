import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flame_game/main.dart';

void main() {
  testWidgets('App boots and renders MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const FlameGameApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

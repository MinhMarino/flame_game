import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class HeartsHud extends TextComponent {
  HeartsHud({
    required this.maxLives,
    required this._lives,
    required super.position,
  }) : super(
         anchor: Anchor.topLeft,
         priority: 10,
         textRenderer: TextPaint(
           style: const TextStyle(fontSize: 22, height: 1.2),
         ),
       ) {
    _refreshText();
  }

  final int maxLives;
  int _lives;

  int get lives => _lives;

  set lives(int value) {
    _lives = value.clamp(0, maxLives);
    _refreshText();
  }

  void _refreshText() {
    text = List.generate(
      maxLives,
      (index) => index < _lives ? '❤️' : '🖤',
    ).join();
  }
}

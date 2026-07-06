import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class GameOverLabel extends TextComponent with HasVisibility {
  GameOverLabel({required super.position})
    : super(
        text: 'Game Over\nTap to restart',
        anchor: Anchor.center,
        priority: 20,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Color(0xFFDC2626),
            fontSize: 36,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ),
      ) {
    isVisible = false;
  }
}

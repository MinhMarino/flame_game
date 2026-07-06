import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class FloatingText extends TextComponent {
  FloatingText({required super.text, required super.position})
    : super(
        anchor: Anchor.center,
        priority: 20,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Color(0xFFDC2626),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  double _lifetime = 0;

  @override
  void update(double dt) {
    super.update(dt);

    _lifetime += dt;
    position.y -= 40 * dt;

    if (_lifetime > 0.45) {
      removeFromParent();
    }
  }
}

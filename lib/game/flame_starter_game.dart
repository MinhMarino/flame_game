import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class FlameStarterGame extends FlameGame {
  @override
  Color backgroundColor() => const Color(0xFF1B263B);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(
      TextComponent(
        text: 'Flame Game',
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        anchor: Anchor.center,
        position: size / 2,
      ),
    );
  }
}

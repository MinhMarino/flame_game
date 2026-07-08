import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../../game/ant_smasher_game.dart';

/// Fly swatter pickup — simple labeled box placeholder.
class FlySwatterPickup extends PositionComponent with TapCallbacks {
  FlySwatterPickup({required this.onActivated, required this.radius})
    : super(size: Vector2(72, 40), anchor: Anchor.center, priority: 50);

  final VoidCallback onActivated;
  final double radius;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(
      RectangleComponent(
        size: size,
        paint: Paint()..color = const Color(0xFF6366F1),
        anchor: Anchor.center,
        position: size / 2,
        children: [
          TextComponent(
            text: 'Swatter',
            anchor: Anchor.center,
            position: size / 2,
            textRenderer: TextPaint(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    add(
      ScaleEffect.by(
        Vector2.all(0.06),
        EffectController(duration: 0.6, alternate: true, infinite: true),
      ),
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    final game = findGame();
    if (game is! AntSmasherGame || !game.acceptsGameplayInput) {
      return;
    }
    onActivated();
    removeFromParent();
  }
}

/// Visual splash for fly swatter area attack.
class FlySwatterSplash extends CircleComponent {
  FlySwatterSplash({
    required super.radius,
    required super.position,
    required this.onComplete,
  }) : super(
         anchor: Anchor.center,
         paint: Paint()..color = Colors.white.withValues(alpha: 0.35),
         priority: 40,
       );

  final VoidCallback onComplete;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(ScaleEffect.to(Vector2.all(1.6), EffectController(duration: 0.25)));
    add(
      OpacityEffect.fadeOut(
        EffectController(duration: 0.35),
        onComplete: () {
          onComplete();
          removeFromParent();
        },
      ),
    );
  }
}

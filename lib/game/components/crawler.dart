import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../ant_smasher_game.dart';

class Crawler extends SpriteAnimationComponent with TapCallbacks {
  Crawler({
    required super.animation,
    required this.velocity,
    required this.points,
    required Vector2 displaySize,
  }) : super(
          size: displaySize,
          anchor: Anchor.center,
        );

  final Vector2 velocity;
  final int points;

  @override
  void update(double dt) {
    super.update(dt);

    position += velocity * dt;
    angle = atan2(velocity.y, velocity.x) + pi / 2;

    final game = findGame();
    if (game == null) {
      return;
    }

    final margin = size.x;
    final outOfBounds = position.x < -margin ||
        position.x > game.size.x + margin ||
        position.y < -margin ||
        position.y > game.size.y + margin;

    if (outOfBounds) {
      removeFromParent();
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    final game = findGame();
    if (game is AntSmasherGame) {
      game.registerHit(this);
    }
    removeFromParent();
  }
}

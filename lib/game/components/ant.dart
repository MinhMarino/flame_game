import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../ant_smasher_game.dart';

class Ant extends SpriteAnimationComponent with TapCallbacks {
  Ant({
    required super.animation,
    required this.speed,
    required Vector2 displaySize,
  }) : super(size: displaySize, anchor: Anchor.center);

  final double speed;

  int get points => 1;

  @override
  void update(double dt) {
    super.update(dt);

    position.y += speed * dt;
    angle = pi;

    final game = findGame();
    if (game == null || game is! AntSmasherGame) {
      return;
    }

    if (position.y > game.size.y + size.y * 0.5) {
      game.onCrawlerEscaped(this);
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

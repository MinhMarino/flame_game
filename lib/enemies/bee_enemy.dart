import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../game/ant_smasher_game.dart';

class BeeEnemy extends SpriteAnimationComponent with TapCallbacks {
  BeeEnemy({
    required super.animation,
    required Vector2 orbitCenter,
    required this.orbitRadius,
    required this.angularSpeed,
    required this.driftSpeed,
    required Vector2 displaySize,
    double initialOrbitAngle = 0,
    this.isBoss = false,
  }) : _orbitCenter = orbitCenter.clone(),
       _orbitAngle = initialOrbitAngle,
       super(size: displaySize, anchor: Anchor.center);

  final Vector2 _orbitCenter;
  double _orbitAngle;
  final double orbitRadius;
  final double angularSpeed;
  final double driftSpeed;
  final bool isBoss;

  int get points => isBoss ? 5 : 3;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _syncPosition();
  }

  void _syncPosition() {
    position =
        _orbitCenter +
        Vector2(cos(_orbitAngle) * orbitRadius, sin(_orbitAngle) * orbitRadius);
    angle = _orbitAngle + pi;
  }

  @override
  void update(double dt) {
    super.update(dt);

    _orbitAngle += angularSpeed * dt;
    _orbitCenter.y += driftSpeed * dt;
    _syncPosition();

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
    if (game is! AntSmasherGame || !game.acceptsGameplayInput) {
      return;
    }

    game.registerHit(this);
    removeFromParent();
  }
}

import 'dart:math';

import 'level_enemy.dart';

/// House Fly — zigzag descent; weave scales with level difficulty.
class HouseFlyEnemy extends LevelEnemy {
  HouseFlyEnemy({
    required super.stats,
    required super.random,
    required super.startPosition,
    required this.weaveIntensity,
    super.speedScale,
  }) : _centerX = startPosition.x,
       _weavePhase = random.nextDouble() * pi * 2;

  final double weaveIntensity;
  double _centerX;
  final double _weavePhase;
  double _weaveTime = 0;
  double _burstTimer = 0;
  double _burstDrift = 0;

  @override
  void update(double dt) {
    _weaveTime += dt;
    _burstTimer -= dt;

    if (_burstTimer <= 0) {
      _burstDrift = (random.nextDouble() * 2 - 1) * 90 * weaveIntensity;
      _burstTimer = max(0.35, 0.9 - weaveIntensity * 0.25);
    }

    final frequency = 3.5 + weaveIntensity * 5.5;
    final amplitude = 28 + weaveIntensity * 52;
    final wobble =
        sin(_weaveTime * frequency * 1.7 + _weavePhase) * amplitude * 0.35;

    _centerX += _burstDrift * dt;
    _centerX += sin(_weaveTime * frequency + _weavePhase) * amplitude * dt;
    _centerX = _centerX.clamp(size.x * 0.5, gameRef.size.x - size.x * 0.5);

    position.x = _centerX + wobble;
    position.y += moveSpeed * dt;

    if (position.y > gameRef.size.y + size.y * 0.5) {
      gameRef.onSpawnedEnemyEscaped(this);
      removeFromParent();
    }
  }
}

/// Cockroach with near-miss angry state (same top-down movement).
class CockroachEnemy extends LevelEnemy {
  CockroachEnemy({
    required super.stats,
    required super.random,
    required super.startPosition,
    super.speedScale,
  });
}

/// Baby spider — faster top-down movement.
class BabySpiderEnemy extends LevelEnemy {
  BabySpiderEnemy({
    required super.stats,
    required super.random,
    required super.startPosition,
    super.speedScale,
  });
}

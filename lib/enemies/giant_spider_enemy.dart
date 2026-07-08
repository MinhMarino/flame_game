import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import 'level_enemy.dart';

/// Giant Spider boss — colored box placeholder, crawls slowly top to bottom.
class GiantSpiderEnemy extends LevelEnemy {
  GiantSpiderEnemy({
    required super.stats,
    required super.random,
    required super.startPosition,
    required this.onBossDefeated,
    super.speedScale,
  });

  final VoidCallback onBossDefeated;
  int _hitCount = 0;
  double _speedMultiplier = 1;

  @override
  double get moveSpeed => stats.speed * _speedMultiplier * speedScale;

  @override
  void takeDamage(int damage) {
    if (!isAlive) {
      return;
    }

    currentHp = max(0, currentHp - damage);
    _hitCount++;
    refreshHpLabel();

    add(
      MoveEffect.by(
        Vector2(6, 0),
        EffectController(duration: 0.05, alternate: true, repeatCount: 2),
      ),
    );

    gameRef.playBossHitFeedback();

    if (_hitCount % 5 == 0) {
      _speedMultiplier += 0.08;
    }

    if (currentHp <= 0) {
      gameRef.triggerScreenShake();
      gameRef.playSmashSound();
      onBossDefeated();
      gameRef.onSpawnedEnemyDefeated(this);
      removeFromParent();
    }
  }
}

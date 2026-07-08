import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/ant_smasher_game.dart';
import 'ant_enemy.dart';
import 'bee_enemy.dart';
import 'data/enemy_data.dart';
import 'enemy_assets.dart';
import 'giant_spider_enemy.dart';
import 'level_enemy.dart';
import 'level_enemy_variants.dart';
import 'models/enemy_kind.dart';
import 'models/enemy_stats.dart';
import 'spawned_enemy.dart';

/// Central factory for every enemy type in the game.
class EnemyFactory {
  EnemyFactory({
    required this.game,
    required this.random,
    required this.antWalkAnimation,
    required this.beeFlyAnimation,
  });

  final AntSmasherGame game;
  final Random random;
  final SpriteAnimation antWalkAnimation;
  final SpriteAnimation beeFlyAnimation;

  /// Shared ant spawn used by Endless mode and Level mode.
  AntEnemy createAnt({
    required double speed,
    required Vector2 startPosition,
    double weaveIntensity = 0,
    double speedScale = 1,
  }) {
    final stats = EnemyData.forKind(EnemyKind.blackAnt);

    return AntEnemy(
      animation: antWalkAnimation.clone(),
      displaySize: Vector2.all(stats.boxWidth),
      stats: stats,
      speed: speed,
      random: random,
      weaveIntensity: weaveIntensity,
      speedScale: speedScale,
      startPosition: startPosition,
    );
  }

  BeeEnemy createBee({
    required bool isBoss,
    required Vector2 startPosition,
    double speedMultiplier = 1,
  }) {
    final beeScale = isBoss
        ? EnemyAssets.bossBeeDisplayScale
        : EnemyAssets.beeDisplayScale;

    return BeeEnemy(
      animation: beeFlyAnimation.clone(),
      orbitCenter: Vector2(startPosition.x, -40),
      orbitRadius: (isBoss ? 40 : 28) + random.nextDouble() * 24,
      angularSpeed: (2.2 + random.nextDouble() * 1.4) * speedMultiplier,
      driftSpeed: (28 + random.nextDouble() * 18) * speedMultiplier,
      displaySize: Vector2.all(EnemyAssets.frameSize * beeScale),
      initialOrbitAngle: random.nextDouble() * pi * 2,
      isBoss: isBoss,
    );
  }

  Vector2 spawnPositionFor(EnemyStats stats) {
    return Vector2(
      stats.boxWidth * 0.5 +
          random.nextDouble() * (game.size.x - stats.boxWidth),
      -stats.boxHeight * 0.5,
    );
  }

  SpawnedEnemy createLevelEnemy({
    required EnemyKind kind,
    required double antWeaveIntensity,
    required double flyWeaveIntensity,
    double speedScale = 1,
    VoidCallback? onBossDefeated,
  }) {
    final stats = EnemyData.forKind(kind);
    final startPosition = spawnPositionFor(stats);

    return switch (kind) {
      EnemyKind.blackAnt => createAnt(
        speed: stats.speed,
        startPosition: startPosition,
        weaveIntensity: antWeaveIntensity,
        speedScale: speedScale,
      ),
      EnemyKind.houseFly => HouseFlyEnemy(
        stats: stats,
        random: random,
        startPosition: startPosition,
        weaveIntensity: flyWeaveIntensity,
        speedScale: speedScale,
      ),
      EnemyKind.cockroach => CockroachEnemy(
        stats: stats,
        random: random,
        startPosition: startPosition,
        speedScale: speedScale,
      ),
      EnemyKind.babySpider => BabySpiderEnemy(
        stats: stats,
        random: random,
        startPosition: startPosition,
        speedScale: speedScale * 1.1,
      ),
      EnemyKind.giantSpider => GiantSpiderEnemy(
        stats: stats,
        random: random,
        startPosition: startPosition,
        onBossDefeated: onBossDefeated ?? () {},
        speedScale: speedScale,
      ),
      _ => LevelEnemy(
        stats: stats,
        random: random,
        startPosition: startPosition,
        speedScale: speedScale,
      ),
    };
  }
}

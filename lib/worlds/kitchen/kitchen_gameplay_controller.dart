import 'dart:math';

import 'package:flame/components.dart';

import '../../../game/ant_smasher_game.dart';
import '../../../game/level_session.dart';
import 'components/fly_swatter.dart';
import 'data/kitchen_enemy_data.dart';
import 'enemies/giant_spider.dart';
import 'enemies/kitchen_enemies.dart';
import 'models/kitchen_enemy_kind.dart';
import 'models/kitchen_enemy_stats.dart';
import 'models/kitchen_level_config.dart';

/// Handles World 1 spawning, boss phases, and fly swatter logic.
class KitchenGameplayController {
  KitchenGameplayController({
    required this.game,
    required this.config,
    required this.random,
    required this.session,
  });

  final AntSmasherGame game;
  final KitchenLevelConfig config;
  final Random random;
  LevelSession session;

  double _spawnTimer = 0;
  int _spawnedCount = 0;
  bool _bossSpawned = false;
  bool _bossDefeated = false;
  int _babySpidersToSpawn = 0;
  int _babySpidersDefeated = 0;
  double _flySwatterCooldown = 8;
  double _flySwatterSpawnTimer = 6;
  FlySwatterPickup? _activePickup;
  double _screenShakeTimer = 0;
  Vector2 _shakeOffset = Vector2.zero();

  bool get isBossLevel => config.isBossLevel;
  bool get bossAlive => _bossSpawned && !_bossDefeated;

  int get _activeBabyCount => game.kitchenEnemies
      .where((e) => e.kind == KitchenEnemyKind.babySpider)
      .length;

  int get activeEnemyCount => game.kitchenEnemies.length;

  Vector2 get shakeOffset => _shakeOffset;

  void onLoad() {
    if (isBossLevel) {
      _spawnBoss();
      return;
    }

    // Level 1: instant action so the first taps feel rewarding.
    if (config.levelInWorld == 1) {
      for (var i = 0; i < 3; i++) {
        Future.delayed(Duration(milliseconds: i * 300), () {
          if (game.isLoaded &&
              !game.isLevelEnded &&
              session.status == LevelSessionStatus.playing) {
            _spawnWeightedEnemy();
          }
        });
      }
    }
  }

  void onGameResize() {}

  void update(double dt) {
    if (session.status != LevelSessionStatus.playing) {
      return;
    }

    if (_screenShakeTimer > 0) {
      _screenShakeTimer -= dt;
      _shakeOffset = Vector2(
        (random.nextDouble() - 0.5) * 8,
        (random.nextDouble() - 0.5) * 8,
      );
      if (_screenShakeTimer <= 0) {
        _shakeOffset = Vector2.zero();
      }
    }

    if (isBossLevel && bossAlive) {
      return;
    }

    if (!isBossLevel || _bossDefeated) {
      _spawnTimer += dt;
      if (_spawnTimer >= config.spawnInterval &&
          activeEnemyCount < config.maxSimultaneousEnemies &&
          _canSpawnMore()) {
        _spawnTimer = 0;
        _spawnWeightedEnemy();
      }
    }

    if (config.enableFlySwatter && !isBossLevel) {
      _updateFlySwatter(dt);
    }
  }

  bool _canSpawnMore() {
    if (isBossLevel && !_bossDefeated) {
      return false;
    }
    final cap = config.totalSpawnCap;
    if (cap != null && _spawnedCount >= cap) {
      return false;
    }
    return true;
  }

  void _updateFlySwatter(double dt) {
    if (_activePickup != null && _activePickup!.isMounted) {
      return;
    }

    if (_flySwatterCooldown > 0) {
      _flySwatterCooldown -= dt;
      return;
    }

    _flySwatterSpawnTimer -= dt;
    if (_flySwatterSpawnTimer <= 0) {
      _spawnFlySwatterPickup();
      _flySwatterSpawnTimer = 10 + random.nextDouble() * 8;
    }
  }

  void _spawnFlySwatterPickup() {
    if (game.size.x <= 0 || game.size.y <= 0) {
      return;
    }

    _activePickup =
        FlySwatterPickup(
            radius: KitchenEnemyData.flySwatterRadius.toDouble(),
            onActivated: _activateFlySwatter,
          )
          ..position = Vector2(
            60 + random.nextDouble() * (game.size.x - 120),
            80 + random.nextDouble() * (game.size.y * 0.5),
          );
    game.add(_activePickup!);
  }

  void _activateFlySwatter() {
    final center = _activePickup?.position ?? game.size / 2;
    _activePickup = null;
    _flySwatterCooldown = config.flySwatterCooldownSeconds;

    game.add(
      FlySwatterSplash(
        radius: KitchenEnemyData.flySwatterRadius.toDouble(),
        position: center.clone(),
        onComplete: () {},
      ),
    );

    game.playSmashSound();

    for (final enemy in game.kitchenEnemies.toList()) {
      final distance = enemy.position.distanceTo(center);
      if (distance <= KitchenEnemyData.flySwatterRadius) {
        if (enemy.isBoss) {
          enemy.takeDamage(KitchenEnemyData.flySwatterBossDamage);
        } else {
          enemy.takeDamage(enemy.currentHp);
        }
      }
    }
  }

  void _spawnWeightedEnemy() {
    if (config.spawnTable.isEmpty) {
      return;
    }

    final kind = _pickSpawnKind();
    _spawnEnemy(kind);
    _spawnedCount++;
  }

  KitchenEnemyKind _pickSpawnKind() {
    final totalWeight = config.spawnTable.fold<double>(
      0,
      (sum, entry) => sum + entry.weight,
    );
    var roll = random.nextDouble() * totalWeight;

    for (final entry in config.spawnTable) {
      roll -= entry.weight;
      if (roll <= 0) {
        return entry.kind;
      }
    }
    return config.spawnTable.last.kind;
  }

  Vector2 _spawnPositionFor(KitchenEnemyStats stats) {
    return Vector2(
      stats.boxWidth * 0.5 +
          random.nextDouble() * (game.size.x - stats.boxWidth),
      -stats.boxHeight * 0.5,
    );
  }

  void _spawnEnemy(KitchenEnemyKind kind) {
    if (game.size.x <= 0) {
      return;
    }

    final stats = KitchenEnemyData.forKind(kind);
    final startPosition = _spawnPositionFor(stats);

    final speedScale = config.enemySpeedMultiplier;

    final KitchenEnemy enemy = switch (kind) {
      KitchenEnemyKind.blackAnt => BlackAntEnemy(
        stats: stats,
        random: random,
        startPosition: startPosition,
        weaveIntensity: config.antWeaveIntensity,
        speedScale: speedScale,
      ),
      KitchenEnemyKind.houseFly => HouseFlyEnemy(
        stats: stats,
        random: random,
        startPosition: startPosition,
        weaveIntensity: config.flyWeaveIntensity,
        speedScale: speedScale,
      ),
      KitchenEnemyKind.cockroach => CockroachEnemy(
        stats: stats,
        random: random,
        startPosition: startPosition,
        speedScale: speedScale,
      ),
      KitchenEnemyKind.babySpider => BabySpiderEnemy(
        stats: stats,
        random: random,
        startPosition: startPosition,
        speedScale: speedScale * 1.1,
      ),
      KitchenEnemyKind.giantSpider => throw StateError(
        'Use _spawnBoss for giant spider',
      ),
      _ => KitchenEnemy(
        stats: stats,
        random: random,
        startPosition: startPosition,
        speedScale: speedScale,
      ),
    };

    game.add(enemy);
  }

  void _spawnBoss() {
    if (_bossSpawned || game.size.x <= 0) {
      return;
    }

    _bossSpawned = true;
    final stats = KitchenEnemyData.forKind(KitchenEnemyKind.giantSpider);

    game.add(
      GiantSpider(
        stats: stats,
        random: random,
        startPosition: Vector2(game.size.x / 2, -stats.boxHeight * 0.5),
        onBossDefeated: _onBossDefeated,
        speedScale: config.enemySpeedMultiplier,
      ),
    );
  }

  void _onBossDefeated() {
    _bossDefeated = true;
    _babySpidersToSpawn = KitchenEnemyData.babySpiderSpawnCount;
    _babySpidersDefeated = 0;
    triggerScreenShake();

    for (var i = 0; i < KitchenEnemyData.babySpiderSpawnCount; i++) {
      Future.delayed(Duration(milliseconds: i * 120), () {
        if (game.isLoaded && !game.isLevelEnded) {
          _spawnEnemy(KitchenEnemyKind.babySpider);
        }
      });
    }
  }

  void triggerScreenShake() {
    _screenShakeTimer = 0.45;
  }

  void handleNearMiss(Vector2 tapPosition) {
    for (final enemy in game.kitchenEnemies) {
      if (enemy is CockroachEnemy &&
          enemy.position.distanceTo(tapPosition) <=
              enemy.stats.nearMissRadius) {
        enemy.triggerNearMiss();
      }
    }
  }

  void onEnemyDefeated(KitchenEnemy enemy, {bool skipScore = false}) {
    if (!skipScore) {
      session.onKitchenEnemyDefeated(enemy.stats.scoreValue);
    }

    if (enemy.kind == KitchenEnemyKind.babySpider) {
      _babySpidersDefeated++;
    }

    _checkWinCondition();
  }

  void onEnemyEscaped(KitchenEnemy enemy) {
    game.onCrawlerEscaped(enemy);
  }

  void _checkWinCondition() {
    if (isBossLevel) {
      if (_bossDefeated &&
          _babySpidersDefeated >= _babySpidersToSpawn &&
          _activeBabyCount == 0) {
        session.markBossDefeated();
        session.checkObjective();
      }
    }
  }

  void restart() {
    _spawnTimer = 0;
    _spawnedCount = 0;
    _bossSpawned = false;
    _bossDefeated = false;
    _babySpidersToSpawn = 0;
    _babySpidersDefeated = 0;
    _flySwatterCooldown = 8;
    _flySwatterSpawnTimer = 6;
    _activePickup?.removeFromParent();
    _activePickup = null;

    for (final enemy in game.kitchenEnemies.toList()) {
      enemy.removeFromParent();
    }

    if (isBossLevel) {
      _spawnBoss();
    }
  }
}

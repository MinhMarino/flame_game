import 'dart:math';

import 'package:flame/components.dart';

import '../../../enemies/data/enemy_data.dart';
import '../../../enemies/enemy_factory.dart';
import '../../../enemies/level_enemy_variants.dart';
import '../../../enemies/models/enemy_kind.dart';
import '../../../enemies/spawned_enemy.dart';
import '../../../game/ant_smasher_game.dart';
import '../../../game/level_session.dart';
import 'components/fly_swatter.dart';
import 'models/kitchen_level_config.dart';

/// Handles World 1 spawning, boss phases, and fly swatter logic.
class KitchenGameplayController {
  KitchenGameplayController({
    required this.game,
    required this.config,
    required this.random,
    required this.session,
    required this.enemyFactory,
  });

  final AntSmasherGame game;
  final KitchenLevelConfig config;
  final Random random;
  final EnemyFactory enemyFactory;
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

  int get _activeBabyCount =>
      game.spawnedEnemies.where((e) => e.kind == EnemyKind.babySpider).length;

  int get activeEnemyCount => game.spawnedEnemies.length;

  Vector2 get shakeOffset => _shakeOffset;

  void onLoad() {
    if (isBossLevel) {
      _spawnBoss();
      return;
    }

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
            radius: EnemyData.flySwatterRadius.toDouble(),
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
        radius: EnemyData.flySwatterRadius.toDouble(),
        position: center.clone(),
        onComplete: () {},
      ),
    );

    game.playSmashSound();

    for (final enemy in game.spawnedEnemies.toList()) {
      final component = enemy as PositionComponent;
      final distance = component.position.distanceTo(center);
      if (distance <= EnemyData.flySwatterRadius) {
        if (enemy.isBoss) {
          enemy.takeDamage(EnemyData.flySwatterBossDamage);
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

  EnemyKind _pickSpawnKind() {
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

  void _spawnEnemy(EnemyKind kind) {
    if (game.size.x <= 0) {
      return;
    }

    if (kind == EnemyKind.giantSpider) {
      throw StateError('Use _spawnBoss for giant spider');
    }

    final enemy = enemyFactory.createLevelEnemy(
      kind: kind,
      antWeaveIntensity: config.antWeaveIntensity,
      flyWeaveIntensity: config.flyWeaveIntensity,
      speedScale: config.enemySpeedMultiplier,
    );

    game.add(enemy as Component);
  }

  void _spawnBoss() {
    if (_bossSpawned || game.size.x <= 0) {
      return;
    }

    _bossSpawned = true;
    final stats = EnemyData.forKind(EnemyKind.giantSpider);

    final enemy = enemyFactory.createLevelEnemy(
      kind: EnemyKind.giantSpider,
      antWeaveIntensity: config.antWeaveIntensity,
      flyWeaveIntensity: config.flyWeaveIntensity,
      speedScale: config.enemySpeedMultiplier,
      onBossDefeated: _onBossDefeated,
    );

    (enemy as PositionComponent).position = Vector2(
      game.size.x / 2,
      -stats.boxHeight * 0.5,
    );
    game.add(enemy as Component);
  }

  void _onBossDefeated() {
    _bossDefeated = true;
    _babySpidersToSpawn = EnemyData.babySpiderSpawnCount;
    _babySpidersDefeated = 0;
    triggerScreenShake();

    for (var i = 0; i < EnemyData.babySpiderSpawnCount; i++) {
      Future.delayed(Duration(milliseconds: i * 120), () {
        if (game.isLoaded && !game.isLevelEnded) {
          _spawnEnemy(EnemyKind.babySpider);
        }
      });
    }
  }

  void triggerScreenShake() {
    _screenShakeTimer = 0.45;
  }

  void handleNearMiss(Vector2 tapPosition) {
    for (final enemy in game.spawnedEnemies) {
      if (enemy is CockroachEnemy) {
        final component = enemy as PositionComponent;
        if (component.position.distanceTo(tapPosition) <=
            enemy.stats.nearMissRadius) {
          enemy.triggerNearMiss();
        }
      }
    }
  }

  void onEnemyDefeated(SpawnedEnemy enemy, {bool skipScore = false}) {
    if (!skipScore) {
      session.onKitchenEnemyDefeated(enemy.stats.scoreValue);
    }

    if (enemy.kind == EnemyKind.babySpider) {
      _babySpidersDefeated++;
    }

    _checkWinCondition();
  }

  void onEnemyEscaped(SpawnedEnemy enemy) {
    game.onCrawlerEscaped(enemy as PositionComponent);
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

    for (final enemy in game.spawnedEnemies.toList()) {
      (enemy as PositionComponent).removeFromParent();
    }

    if (isBossLevel) {
      _spawnBoss();
    }
  }
}

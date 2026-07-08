import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../game/ant_smasher_game.dart';
import 'models/enemy_kind.dart';
import 'models/enemy_stats.dart';
import 'smashed_ant.dart';
import 'spawned_enemy.dart';

/// Sprite ant used in endless mode and kitchen levels.
class AntEnemy extends SpriteAnimationComponent
    with TapCallbacks
    implements SpawnedEnemy {
  AntEnemy({
    required super.animation,
    required Vector2 displaySize,
    required this.stats,
    required this.speed,
    required Random random,
    this.weaveIntensity = 0,
    this.speedScale = 1,
    this.useLevelCallbacks = false,
    Vector2? startPosition,
  }) : _random = random,
       _currentHp = stats.maxHp,
       _centerX = startPosition?.x ?? 0,
       _weavePhase = random.nextDouble() * pi * 2,
       _turnIntervalScale = 0.55 + random.nextDouble() * 0.9,
       _frequencyScale = 0.75 + random.nextDouble() * 0.5,
       super(size: displaySize, anchor: Anchor.center, position: startPosition) {
    _turnTimer = random.nextDouble() * (0.2 + 0.35 * _turnIntervalScale);
  }

  static const _weaveScale = 0.5;

  static final EnemyStats endlessStats = EnemyStats(
    kind: EnemyKind.blackAnt,
    displayName: 'Ant',
    maxHp: 1,
    speed: 0,
    scoreValue: 1,
    displayScale: 0,
    boxWidth: 0,
    boxHeight: 0,
    tint: Color(0xFF000000),
  );

  @override
  final EnemyStats stats;
  final double speed;
  final double speedScale;
  final double weaveIntensity;
  final bool useLevelCallbacks;
  final Random _random;

  final double _turnIntervalScale;
  final double _frequencyScale;
  double _centerX;
  final double _weavePhase;
  double _weaveTime = 0;
  double _turnTimer = 0;
  double _laneDrift = 0;
  double _jitterX = 0;
  int _currentHp;

  @override
  EnemyKind get kind => stats.kind;

  @override
  int get currentHp => _currentHp;

  @override
  bool get isAlive => _currentHp > 0;

  @override
  bool get isBoss => stats.isBoss;

  int get points => stats.scoreValue;

  AntSmasherGame get _game => findGame()! as AntSmasherGame;

  double get _moveSpeed =>
      (useLevelCallbacks ? stats.speed : speed) * speedScale;

  double get _baseTurnInterval =>
      max(0.18, 0.42 - weaveIntensity * 0.12) * _turnIntervalScale;

  @override
  void update(double dt) {
    super.update(dt);

    if (weaveIntensity > 0) {
      _updateWeave(dt);
    } else {
      position.y += _moveSpeed * dt;
    }

    angle = pi;
    _checkEscaped();
  }

  void _updateWeave(double dt) {
    _weaveTime += dt;
    _turnTimer -= dt;

    if (_turnTimer <= 0) {
      _laneDrift =
          (_random.nextDouble() * 2 - 1) *
          (110 + weaveIntensity * 90) *
          _weaveScale;
      _jitterX =
          (_random.nextDouble() * 2 - 1) *
          (18 + weaveIntensity * 22) *
          _weaveScale;
      _turnTimer = _baseTurnInterval;
    }

    final frequency = (2.8 + weaveIntensity * 4.2) * _frequencyScale;
    final amplitude = (34 + weaveIntensity * 58) * _weaveScale;
    final zigzag =
        sin(_weaveTime * frequency + _weavePhase) * amplitude * dt * 9;
    final wobble =
        sin(_weaveTime * frequency * 2.3 + _weavePhase + 1.2) *
        amplitude *
        0.28;

    _centerX += _laneDrift * dt;
    _centerX += zigzag;
    _centerX = _centerX.clamp(size.x * 0.5, _game.size.x - size.x * 0.5);

    position.x = _centerX + wobble + _jitterX * 0.15;
    position.y += _moveSpeed * dt;
  }

  void _checkEscaped() {
    if (position.y > _game.size.y + size.y * 0.5) {
      if (useLevelCallbacks) {
        _game.onSpawnedEnemyEscaped(this);
      } else {
        _game.onCrawlerEscaped(this);
      }
      removeFromParent();
    }
  }

  @override
  void takeDamage(int damage) {
    if (!isAlive) {
      return;
    }

    _currentHp = max(0, _currentHp - damage);
    if (_currentHp <= 0) {
      _defeat();
    }
  }

  void _defeat() {
    if (useLevelCallbacks) {
      _game.onSpawnedEnemyDefeated(this);
    } else {
      _game.add(SmashedAnt(position: position.clone(), size: size.clone()));
      _game.registerHit(this);
    }
    removeFromParent();
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!_game.acceptsGameplayInput) {
      return;
    }
    takeDamage(1);
  }
}

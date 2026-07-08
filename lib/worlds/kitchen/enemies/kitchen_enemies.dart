import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../../game/ant_smasher_game.dart';
import '../models/kitchen_enemy_kind.dart';
import '../models/kitchen_enemy_stats.dart';

/// Placeholder enemy: colored box + label, crawls from top to bottom.
class KitchenEnemy extends PositionComponent with TapCallbacks {
  KitchenEnemy({
    required this.stats,
    required this.random,
    required Vector2 startPosition,
    this.speedScale = 1,
    this.showLabel = true,
  }) : currentHp = stats.maxHp,
       super(
         size: Vector2(stats.boxWidth, stats.boxHeight),
         anchor: Anchor.center,
         position: startPosition,
       );

  final KitchenEnemyStats stats;
  final Random random;
  final double speedScale;
  final bool showLabel;
  int currentHp;

  double _angryTimer = 0;
  bool _isAngry = false;

  KitchenEnemyKind get kind => stats.kind;
  bool get isAlive => currentHp > 0;
  bool get isBoss => stats.isBoss;

  AntSmasherGame get gameRef => findGame()! as AntSmasherGame;

  double get _currentSpeed =>
      stats.speed * (_isAngry ? stats.angrySpeedMultiplier : 1);

  double get moveSpeed => _currentSpeed * speedScale;

  TextComponent? _hpLabel;
  RectangleComponent? _body;
  TextComponent? _nameLabel;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _applyDamageVisual(initial: true);
  }

  void _applyDamageVisual({bool initial = false}) {
    final stage = stats.visualForHp(currentHp);

    if (_body == null) {
      _body = RectangleComponent(
        size: size,
        paint: Paint()..color = stage.tint,
        anchor: Anchor.center,
        position: size / 2,
      );
      if (showLabel) {
        _nameLabel = TextComponent(
          text: stage.label,
          anchor: Anchor.center,
          position: size / 2,
          textRenderer: TextPaint(
            style: TextStyle(
              color: Colors.white,
              fontSize: stats.damageStages != null ? 10 : 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        _body!.add(_nameLabel!);
      }
      add(_body!);
    } else {
      _body!.paint.color = stage.tint;
      _nameLabel?.text = stage.label;
    }

    if (stats.maxHp > 1 && _hpLabel == null) {
      _hpLabel = TextComponent(
        text: '$currentHp',
        anchor: Anchor.bottomRight,
        position: size - Vector2(6, 4),
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      add(_hpLabel!);
    } else if (!initial) {
      refreshHpLabel();
    }
  }

  void triggerNearMiss() {
    if (stats.kind != KitchenEnemyKind.cockroach || _isAngry) {
      return;
    }
    _isAngry = true;
    _angryTimer = stats.angryDurationSeconds;
  }

  void takeDamage(int damage) {
    if (!isAlive) {
      return;
    }

    currentHp = max(0, currentHp - damage);
    _applyDamageVisual();
    _flashHit();

    if (currentHp <= 0) {
      gameRef.onKitchenEnemyDefeated(this);
      removeFromParent();
    }
  }

  void refreshHpLabel() {
    _hpLabel?.text = '$currentHp';
  }

  void _flashHit() {
    add(
      ScaleEffect.by(
        Vector2.all(0.08),
        EffectController(duration: 0.06, alternate: true, repeatCount: 1),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isAngry) {
      _angryTimer -= dt;
      if (_angryTimer <= 0) {
        _isAngry = false;
      }
    }

    position.y += moveSpeed * dt;

    if (position.y > gameRef.size.y + size.y * 0.5) {
      gameRef.onKitchenEnemyEscaped(this);
      removeFromParent();
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!gameRef.acceptsGameplayInput) {
      return;
    }
    takeDamage(1);
  }
}

/// Black Ant — winding crawl with sharp lane changes.
class BlackAntEnemy extends KitchenEnemy {
  BlackAntEnemy({
    required super.stats,
    required super.random,
    required super.startPosition,
    required this.weaveIntensity,
    super.speedScale,
    super.showLabel = false,
  }) : _centerX = startPosition.x,
       _weavePhase = random.nextDouble() * pi * 2,
       _turnIntervalScale = 0.55 + random.nextDouble() * 0.9,
       _frequencyScale = 0.75 + random.nextDouble() * 0.5 {
    _turnTimer = random.nextDouble() * (0.2 + 0.35 * _turnIntervalScale);
  }

  static const _weaveScale = 0.5;

  final double weaveIntensity;
  final double _turnIntervalScale;
  final double _frequencyScale;
  double _centerX;
  final double _weavePhase;
  double _weaveTime = 0;
  double _turnTimer = 0;
  double _laneDrift = 0;
  double _jitterX = 0;

  double get _baseTurnInterval =>
      max(0.18, 0.42 - weaveIntensity * 0.12) * _turnIntervalScale;

  @override
  void update(double dt) {
    _weaveTime += dt;
    _turnTimer -= dt;

    if (_turnTimer <= 0) {
      _laneDrift =
          (random.nextDouble() * 2 - 1) *
          (110 + weaveIntensity * 90) *
          _weaveScale;
      _jitterX =
          (random.nextDouble() * 2 - 1) *
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
    _centerX = _centerX.clamp(size.x * 0.5, gameRef.size.x - size.x * 0.5);

    position.x = _centerX + wobble + _jitterX * 0.15;
    position.y += moveSpeed * dt;

    if (position.y > gameRef.size.y + size.y * 0.5) {
      gameRef.onKitchenEnemyEscaped(this);
      removeFromParent();
    }
  }
}

/// House Fly — zigzag descent; weave scales with level difficulty.
class HouseFlyEnemy extends KitchenEnemy {
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

    // Primary zigzag + secondary wobble for harder levels
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
      gameRef.onKitchenEnemyEscaped(this);
      removeFromParent();
    }
  }
}

/// Cockroach with near-miss angry state (same top-down movement).
class CockroachEnemy extends KitchenEnemy {
  CockroachEnemy({
    required super.stats,
    required super.random,
    required super.startPosition,
    super.speedScale,
  });
}

/// Baby spider — faster top-down movement.
class BabySpiderEnemy extends KitchenEnemy {
  BabySpiderEnemy({
    required super.stats,
    required super.random,
    required super.startPosition,
    super.speedScale,
  });
}

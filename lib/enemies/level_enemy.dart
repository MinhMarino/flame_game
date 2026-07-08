import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../game/ant_smasher_game.dart';
import 'models/enemy_kind.dart';
import 'models/enemy_stats.dart';
import 'spawned_enemy.dart';

/// Placeholder enemy: colored box + label, crawls from top to bottom.
class LevelEnemy extends PositionComponent
    with TapCallbacks
    implements SpawnedEnemy {
  LevelEnemy({
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

  @override
  final EnemyStats stats;
  final Random random;
  final double speedScale;
  final bool showLabel;
  @override
  int currentHp;

  double _angryTimer = 0;
  bool _isAngry = false;

  @override
  EnemyKind get kind => stats.kind;

  @override
  bool get isAlive => currentHp > 0;

  @override
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
    if (stats.kind != EnemyKind.cockroach || _isAngry) {
      return;
    }
    _isAngry = true;
    _angryTimer = stats.angryDurationSeconds;
  }

  @override
  void takeDamage(int damage) {
    if (!isAlive) {
      return;
    }

    currentHp = max(0, currentHp - damage);
    _applyDamageVisual();
    _flashHit();

    if (currentHp <= 0) {
      gameRef.onSpawnedEnemyDefeated(this);
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
      gameRef.onSpawnedEnemyEscaped(this);
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

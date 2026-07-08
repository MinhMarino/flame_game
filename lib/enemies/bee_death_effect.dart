import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../game/ant_smasher_game.dart';

/// Death sequence: damaged bee, debris, green splatter, fall, fade.
class BeeDeathEffect extends PositionComponent {
  BeeDeathEffect({
    required Vector2 startPosition,
    required Vector2 bodySize,
    required this.bodyAngle,
    required this.deathAnimation,
    required Random random,
  }) : _random = random,
       _rotationVelocity = (random.nextDouble() - 0.5) * 4.5,
       super(
         position: startPosition,
         size: bodySize,
         anchor: Anchor.center,
         angle: bodyAngle,
         priority: 6,
       );

  static const _gravity = 520.0;
  static const _fadeDelay = 0.55;
  static const _fadeDuration = 0.9;

  final double bodyAngle;
  final SpriteAnimation deathAnimation;
  final Random _random;

  late final SpriteAnimationComponent _body;
  double _verticalVelocity = 0;
  double _horizontalVelocity = 0;
  double _rotationVelocity = 0;
  bool _landed = false;
  bool _splatterSpawned = false;
  bool _fadeStarted = false;
  double _groundY = 0;
  double _landedTimer = 0;

  AntSmasherGame get _game => findGame()! as AntSmasherGame;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _groundY = _game.size.y - size.y * 0.35;
    _horizontalVelocity = ( _random.nextDouble() - 0.5) * 40;
    _verticalVelocity = -20 - _random.nextDouble() * 30;

    _body = SpriteAnimationComponent(
      animation: deathAnimation.clone(),
      size: size,
      anchor: Anchor.center,
      position: size / 2,
    )..playing = true;
    add(_body);

    _spawnDebris();
  }

  void _spawnDebris() {
    final wingPaint = Paint()..color = const Color(0xCCFFFFFF);
    final legPaint = Paint()..color = const Color(0xFF111827);

    add(
      RectangleComponent(
        size: Vector2(size.x * 0.22, size.y * 0.08),
        paint: wingPaint,
        anchor: Anchor.center,
        position: size / 2 + Vector2(size.x * 0.2, -size.y * 0.12),
        angle: 0.8,
      )..add(
        MoveEffect.by(
          Vector2(26, 18),
          EffectController(duration: 0.45, curve: Curves.easeOut),
        ),
      ),
    );

    for (var i = 0; i < 3; i++) {
      final offset = Vector2(
        (i - 1) * size.x * 0.12,
        size.y * 0.18,
      );
      add(
        RectangleComponent(
          size: Vector2(size.x * 0.05, size.y * 0.16),
          paint: legPaint,
          anchor: Anchor.topCenter,
          position: size / 2 + offset,
          angle: (i - 1) * 0.35,
        )..add(
          MoveEffect.by(
            Vector2((i - 1) * 10, 24 + i * 4),
            EffectController(duration: 0.5, curve: Curves.easeIn),
          ),
        ),
      );
    }
  }

  void _spawnSplatter() {
    if (_splatterSpawned) {
      return;
    }
    _splatterSpawned = true;
    _body.playing = false;

    final splatter = PositionComponent(
      position: Vector2(position.x, _groundY + size.y * 0.2),
      anchor: Anchor.center,
      priority: 4,
    );

    final green = const Color(0xFF65A30D);
    for (var i = 0; i < 6; i++) {
      final blob = CircleComponent(
        radius: 4 + _random.nextDouble() * 7,
        paint: Paint()..color = green.withValues(alpha: 0.75),
        position: Vector2(
          (_random.nextDouble() - 0.5) * size.x * 0.9,
          (_random.nextDouble() - 0.5) * 10,
        ),
      );
      splatter.add(blob);
    }

    _game.add(splatter);
    splatter.add(
      OpacityEffect.fadeOut(
        EffectController(duration: _fadeDuration + 0.2),
        onComplete: splatter.removeFromParent,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_landed) {
      _verticalVelocity += _gravity * dt;
      position.y += _verticalVelocity * dt;
      position.x += _horizontalVelocity * dt;
      angle += _rotationVelocity * dt;

      if (position.y >= _groundY) {
        position.y = _groundY;
        _landed = true;
        _rotationVelocity = 0;
        _horizontalVelocity = 0;
        _verticalVelocity = 0;
        _spawnSplatter();
      }
      return;
    }

    _landedTimer += dt;
    if (_landedTimer >= _fadeDelay && !_fadeStarted) {
      _fadeStarted = true;
      _body.add(
        OpacityEffect.fadeOut(
          EffectController(duration: _fadeDuration),
          onComplete: removeFromParent,
        ),
      );
    }
  }
}

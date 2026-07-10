import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../services/audio_manager.dart';
import '../ant_smasher_game.dart';

/// Classic flat fly-swatter sprite that plays a cartoony "swing & slam" at
/// the player's tap location and then vanishes.
///
/// The sprite's bottom half is the handle (grip) and the top half is the
/// mesh head. The motion is built around a fixed pivot point that stands in
/// for the player's hand: during the wind-up the whole swatter rotates
/// around that pivot like a real swing (handle whips back, head arcs up and
/// away), then it swings forward and down so the head lands exactly on the
/// tap point, squashes on impact, and deals real wide-area damage to every
/// enemy inside a wide circular hit zone (telegraphed before impact, then
/// flashed as an impact ring), then lifts away and fades out.
class FlySwatterCursor extends SpriteComponent
    with HasGameReference<AntSmasherGame>, HasVisibility {
  FlySwatterCursor()
    : super(
        size: Vector2(204, 300),
        anchor: const Anchor(0.50, 0.16),
        priority: 100,
      );

  /// Horizontal flip factor. Set to -1 to mirror the sprite so the handle
  /// rests on the opposite side. Baked into the x scale/offsets every frame
  /// so it survives squash and the swing arc.
  ///
  /// -1 mirrors the whole swing to the right-hand side (handle winds up on
  /// the right, head sweeps in from the right), matching a right-handed
  /// swing instead of the default left-handed one.
  static const double _flipX = -1;

  /// Neutral display tilt of the sprite (radians) when idle.
  static const double _restAngle = -0.18;

  /// Distance (px) from the pivot (the "hand") to the head. Drives how wide
  /// the swing arc reads on screen.
  static const double _armLength = 230;

  /// Angle (radians) at the top of the backswing, before the head slams
  /// down. More negative = a bigger, more readable wind-up of the handle.
  static const double _backAngle = -1.2;

  /// Angle (radians) at the exact moment the head lands on the tap point.
  static const double _impactAngle = 0.55;

  /// Angle the swatter eases toward right after impact, before lifting away.
  static const double _settledAngle = -0.02;

  /// Radius (px) of the wide-area damage/impact zone shown and applied when
  /// the head lands. Sized generously (~1.3x an ant's width) so a single
  /// swing reads as a real area attack, not a single-target poke.
  static const double _impactRingRadius = 108;

  /// How far (px) the head overshoots past the target on impact before
  /// settling, purely for squash feel.
  static const double _overshoot = 10;

  static const double _totalDuration = 0.5;

  // Phase boundaries as fractions of the total timeline.
  static const double _windupEnd = 0.30;
  static const double _slamEnd = 0.52;
  static const double _impactEnd = 0.70;

  final Vector2 _targetPosition = Vector2.zero();
  final Vector2 _pivot = Vector2.zero();
  bool _armed = false;
  bool _impactTriggered = false;
  double _elapsed = 0;

  bool get isArmed => _armed;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = Sprite(game.images.fromCache('fly_swatter.png'));
    isVisible = false;
    _applyPose(
      offset: Vector2.zero(),
      angle: _restAngle,
      scaleX: 1,
      scaleY: 1,
      opacity: 1,
    );
  }

  /// Positions the swatter over [target] and plays a single swing-and-smack,
  /// after which it hides itself again.
  void smackAt(Vector2 target) {
    _targetPosition.setFrom(target);
    // Fix the pivot ("hand") so that at `_impactAngle` the head lands exactly
    // on the target. All other angles trace an arc around this same pivot,
    // producing a genuine swing rather than a straight up/down poke.
    final armAtImpact = _armVector(_impactAngle);
    _pivot
      ..setFrom(_targetPosition)
      ..x -= armAtImpact.x
      ..y -= armAtImpact.y;
    _armed = true;
    _impactTriggered = false;
    _elapsed = 0;
    isVisible = true;

    // Whoosh plays right as the swing kicks off (wind-up + slam) so it
    // reads as the sound of the swatter cutting through the air.
    AudioManager.instance.playSfx('swing');

    // Telegraph the landing zone immediately so the wide hit area reads
    // clearly before the head actually arrives, timed to finish exactly as
    // the slam lands.
    game.add(
      SwatTelegraphRing(
        position: _targetPosition.clone(),
        radius: _impactRingRadius,
        duration: _totalDuration * _slamEnd,
      ),
    );
  }

  void reset() {
    _armed = false;
    _impactTriggered = false;
    _elapsed = 0;
    isVisible = false;
    _applyPose(
      offset: Vector2.zero(),
      angle: _restAngle,
      scaleX: 1,
      scaleY: 1,
      opacity: 1,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_armed) {
      return;
    }

    _elapsed += dt;
    if (_elapsed >= _totalDuration) {
      reset();
      return;
    }

    final t = _elapsed / _totalDuration;

    Vector2 offset;
    double angle;
    double scaleX;
    double scaleY;
    double opacity = 1;
    double shakeX = 0;

    if (t < _windupEnd) {
      // Swing back: the whole swatter rotates around the hand pivot, so the
      // head arcs up and away like a real backswing while fading in.
      final p = _easeOut(t / _windupEnd);
      angle = _lerp(_restAngle, _backAngle, p);
      offset = _headOffsetFromTarget(angle);
      scaleX = 1;
      scaleY = 1;
      opacity = (t / _windupEnd * 1.6).clamp(0.0, 1.0);
    } else if (t < _slamEnd) {
      // Slam: keep rotating around the same pivot, accelerating forward and
      // down until the head lands exactly on the tap point.
      final p = _easeIn((t - _windupEnd) / (_slamEnd - _windupEnd));
      angle = _lerp(_backAngle, _impactAngle, p);
      offset = _headOffsetFromTarget(angle);
      scaleX = _lerp(1, 1.08, p);
      scaleY = _lerp(1, 0.92, p);
    } else if (t < _impactEnd) {
      // Impact: pin the head to the tap point and squash flat, then spawn
      // the wide-area impact ring exactly once as we enter this phase.
      if (!_impactTriggered) {
        _impactTriggered = true;
        _spawnImpactRing();
      }
      final p = (t - _slamEnd) / (_impactEnd - _slamEnd);
      final pulse = sin(p * pi);
      final wobble = sin(p * pi * 4) * 0.16 * (1 - p);
      final settle = _easeOut(p);
      offset = Vector2(0, _lerp(_overshoot, 0, settle));
      angle = _lerp(_impactAngle, _settledAngle, settle) + wobble;
      scaleX = 1 + 0.26 * pulse;
      scaleY = 1 - 0.24 * pulse;
      shakeX = sin(p * pi * 3) * 4 * (1 - p);
    } else {
      // Recover & vanish: lift the head away from the target while the
      // swatter settles back toward rest, then fade out.
      final p = _easeIn((t - _impactEnd) / (1 - _impactEnd));
      final settleWobble = sin(p * pi * 2.4) * 0.1 * (1 - p);
      offset = Vector2(0, _lerp(0, -_armLength * 0.4, p));
      angle = _lerp(_settledAngle, _restAngle, p) + settleWobble;
      scaleX = 1;
      scaleY = 1;
      opacity = (1 - p).clamp(0.0, 1.0);
    }

    _applyPose(
      offset: offset,
      angle: angle,
      scaleX: scaleX,
      scaleY: scaleY,
      opacity: opacity,
      shakeX: shakeX,
    );
  }

  /// Vector from the pivot to the head at rotation [theta], assuming the
  /// head points straight up from the pivot when theta is 0.
  static Vector2 _armVector(double theta) =>
      Vector2(sin(theta) * _armLength, -cos(theta) * _armLength);

  /// Where the head should sit (relative to `_targetPosition`) when the
  /// swatter is rotated to [angle] around the fixed pivot.
  Vector2 _headOffsetFromTarget(double angle) {
    final arm = _armVector(angle);
    return Vector2(
      _pivot.x + arm.x - _targetPosition.x,
      _pivot.y + arm.y - _targetPosition.y,
    );
  }

  void _spawnImpactRing() {
    game.add(
      SwatImpactRing(
        position: _targetPosition.clone(),
        radius: _impactRingRadius,
      ),
    );
    // Thud plays the instant the head actually lands, matching the visual
    // flash and the real area damage below.
    AudioManager.instance.playSfx('swat_impact');
    // The flash is purely visual; this is what actually smashes every enemy
    // caught inside the wide hit zone, not just the one under the tap.
    game.applySwatterAreaDamage(_targetPosition, _impactRingRadius);
  }

  void _applyPose({
    required Vector2 offset,
    required double angle,
    required double scaleX,
    required double scaleY,
    required double opacity,
    double shakeX = 0,
  }) {
    // Mirroring the sprite reverses perceived rotation and swing direction,
    // so negate the angle and every horizontal offset to keep the head
    // slamming and arcing the same way.
    this.angle = _flipX * angle;
    scale.setValues(_flipX * scaleX, scaleY);
    this.opacity = opacity;
    position
      ..setFrom(_targetPosition)
      ..x += _flipX * (offset.x + shakeX)
      ..y += offset.y;
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  static double _easeIn(double t) => t * t * t;

  static double _easeOut(double t) {
    final inv = 1 - t;
    return 1 - inv * inv * inv;
  }
}

/// Dashed circular preview that grows at the swatter's landing spot while it
/// swings in, telegraphing the wide hit zone before the head actually lands
/// so the area-of-effect reads clearly ahead of impact.
class SwatTelegraphRing extends PositionComponent {
  SwatTelegraphRing({
    required Vector2 position,
    required this.radius,
    required this.duration,
  }) : super(position: position, anchor: Anchor.center, priority: 89);

  final double radius;
  final double duration;
  double _elapsed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final p = (_elapsed / duration).clamp(0.0, 1.0);
    final ringRadius = radius * _lerp(0.45, 1.0, _easeOut(p));
    final opacity = _lerp(0.15, 0.6, p);

    final fillPaint = Paint()
      ..color = const Color(0xFFFF5252).withValues(alpha: opacity * 0.16);
    canvas.drawCircle(Offset.zero, ringRadius, fillPaint);

    const dashCount = 14;
    final dashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFF5252).withValues(alpha: opacity);
    // Spin the dashes slightly as the ring grows so it reads as an
    // energetic "locking on" telegraph rather than a static outline.
    final spin = p * pi * 0.6;
    for (var i = 0; i < dashCount; i++) {
      final start = spin + (i / dashCount) * pi * 2;
      const sweep = (pi * 2 / dashCount) * 0.55;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: ringRadius),
        start,
        sweep,
        false,
        dashPaint,
      );
    }
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  static double _easeOut(double t) {
    final inv = 1 - t;
    return 1 - inv * inv * inv;
  }
}

/// Wide-area impact ring that flashes at the fly-swatter's landing spot,
/// visually communicating a generous circular hit zone rather than a single
/// pixel-precise tap.
class SwatImpactRing extends PositionComponent {
  SwatImpactRing({required Vector2 position, required this.radius})
    : super(position: position, anchor: Anchor.center, priority: 90);

  final double radius;

  static const double _duration = 0.34;
  double _elapsed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= _duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final p = (_elapsed / _duration).clamp(0.0, 1.0);
    final grow = 1 - (1 - p) * (1 - p);
    final ringRadius = radius * _lerp(0.35, 1.0, grow);
    final fade = 1 - p;

    final flashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28 * fade * fade);
    canvas.drawCircle(Offset.zero, ringRadius * 0.7, flashPaint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _lerp(9, 1.5, p)
      ..color = const Color(0xFFFF5252).withValues(alpha: 0.85 * fade);
    canvas.drawCircle(Offset.zero, ringRadius, ringPaint);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}

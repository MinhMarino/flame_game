import 'dart:math';

import 'package:flame/components.dart';

import '../ant_smasher_game.dart';

/// Classic flat fly-swatter sprite that plays a cartoony "raise & slam" at the
/// player's tap location and then vanishes.
///
/// The anchor sits on the mesh head so the head is what drives down onto the
/// tap point. The motion is: quick wind-up (head lifts back), fast slam down,
/// a squash-on-impact, then a small lift and fade-out.
class FlySwatterCursor extends SpriteComponent
    with HasGameReference<AntSmasherGame>, HasVisibility {
  FlySwatterCursor()
    : super(
        size: Vector2(135, 265),
        anchor: const Anchor(0.36, 0.16),
        priority: 100,
      );

  /// Horizontal flip factor. Set to -1 to mirror the sprite so the handle
  /// rests on the opposite side. Baked into the x scale every frame so it
  /// survives squash.
  static const double _flipX = 1;

  /// Neutral display tilt of the sprite (radians).
  static const double _restAngle = -0.30;

  /// How high (px) the head lifts during the wind-up before slamming down.
  static const double _raiseHeight = 90;

  /// How far (px) the head drives past the target on impact.
  static const double _overshoot = 14;

  static const double _totalDuration = 0.46;

  // Phase boundaries as fractions of the total timeline.
  static const double _windupEnd = 0.26;
  static const double _slamEnd = 0.50;
  static const double _impactEnd = 0.66;

  final Vector2 _targetPosition = Vector2.zero();
  bool _armed = false;
  double _elapsed = 0;

  bool get isArmed => _armed;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = Sprite(game.images.fromCache('fly_swatter.png'));
    isVisible = false;
    _applyPose(offsetY: 0, angle: _restAngle, scaleX: 1, scaleY: 1, opacity: 1);
  }

  /// Positions the swatter over [target] and plays a single smack, after which
  /// it hides itself again.
  void smackAt(Vector2 target) {
    _targetPosition.setFrom(target);
    _armed = true;
    _elapsed = 0;
    isVisible = true;
  }

  void reset() {
    _armed = false;
    _elapsed = 0;
    isVisible = false;
    _applyPose(offsetY: 0, angle: _restAngle, scaleX: 1, scaleY: 1, opacity: 1);
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

    double offsetY;
    double angle;
    double scaleX;
    double scaleY;
    double opacity = 1;
    double shakeX = 0;

    if (t < _windupEnd) {
      // Wind-up: fade in while the head arcs back and the handle swings up.
      final p = _easeOut(t / _windupEnd);
      offsetY = _lerp(-_raiseHeight * 0.45, -_raiseHeight, p);
      angle = _lerp(_restAngle - 0.18, _restAngle - 0.75, p);
      scaleX = 1;
      scaleY = 1;
      opacity = (t / _windupEnd * 1.6).clamp(0.0, 1.0);
    } else if (t < _slamEnd) {
      // Slam: accelerate the head straight down while the handle whips past.
      final p = _easeIn((t - _windupEnd) / (_slamEnd - _windupEnd));
      offsetY = _lerp(-_raiseHeight, _overshoot, p);
      angle = _lerp(_restAngle - 0.75, _restAngle + 0.34, p);
      scaleX = _lerp(1, 1.06, p);
      scaleY = _lerp(1, 0.94, p);
    } else if (t < _impactEnd) {
      // Impact: squash the head flat while the handle wobbles from the recoil.
      final p = (t - _slamEnd) / (_impactEnd - _slamEnd);
      final pulse = sin(p * pi);
      final wobble = sin(p * pi * 4) * 0.18 * (1 - p);
      offsetY = _lerp(_overshoot, 0, _easeOut(p));
      angle = _restAngle + 0.34 * (1 - p) + wobble;
      scaleX = 1 + 0.26 * pulse;
      scaleY = 1 - 0.24 * pulse;
      shakeX = sin(p * pi * 3) * 4 * (1 - p);
    } else {
      // Recover & vanish: handle keeps swinging slightly while the head lifts.
      final p = _easeIn((t - _impactEnd) / (1 - _impactEnd));
      final settle = sin(p * pi * 2.4) * 0.12 * (1 - p);
      offsetY = _lerp(0, -_raiseHeight * 0.7, p);
      angle = _restAngle - 0.18 * p + settle;
      scaleX = 1;
      scaleY = 1;
      opacity = (1 - p).clamp(0.0, 1.0);
    }

    _applyPose(
      offsetY: offsetY,
      angle: angle,
      scaleX: scaleX,
      scaleY: scaleY,
      opacity: opacity,
      shakeX: shakeX,
    );
  }

  void _applyPose({
    required double offsetY,
    required double angle,
    required double scaleX,
    required double scaleY,
    required double opacity,
    double shakeX = 0,
  }) {
    // Mirroring the sprite reverses perceived rotation, so negate the angle
    // (and the horizontal shake) to keep the head slamming the same way.
    this.angle = _flipX * angle;
    scale.setValues(_flipX * scaleX, scaleY);
    this.opacity = opacity;
    position
      ..setFrom(_targetPosition)
      ..x += _flipX * shakeX
      ..y += offsetY;
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  static double _easeIn(double t) => t * t * t;

  static double _easeOut(double t) {
    final inv = 1 - t;
    return 1 - inv * inv * inv;
  }
}

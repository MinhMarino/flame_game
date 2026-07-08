import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../game/ant_smasher_game.dart';
import 'bee_lifecycle.dart';
import 'enemy_assets.dart';

/// Flying bee with curved flight, wing flap, and hover bob.
class BeeEnemy extends SpriteAnimationComponent with TapCallbacks {
  BeeEnemy({
    required super.animation,
    required this.random,
    required Vector2 startPosition,
    required this.isBoss,
    this.speedMultiplier = 1,
  }) : _heading = _initialHeading(random),
       _targetHeading = _initialHeading(random),
       _baseSpeed = _initialSpeed(isBoss, speedMultiplier),
       _turnRate = pi * (2.2 + random.nextDouble() * 1.4),
       _swayPhase = random.nextDouble() * pi * 2,
       _zigzagPhase = random.nextDouble() * pi * 2,
       super(
         size: Vector2.all(EnemyAssets.beeDisplaySize(isBoss: isBoss)),
         anchor: Anchor.center,
         position: startPosition,
       ) {
    _pickNextCourseChange();
    angle = _heading + _spriteAngleOffset;
    _currentSpeed = _baseSpeed;
  }

  static const _spriteAngleOffset = pi / 2;

  final Random random;
  final bool isBoss;
  final double speedMultiplier;

  double _heading;
  double _targetHeading;
  final double _baseSpeed;
  final double _turnRate;
  final double _swayPhase;
  final double _zigzagPhase;
  double _currentSpeed = 0;
  double _desiredSpeed = 0;
  double _courseTimer = 0;
  double _burstTimer = 0;
  double _aliveTime = 0;
  double _bobOffset = 0;
  double _flapSpeed = 1;

  int get points => isBoss ? 5 : 3;

  /// Vertical draw offset applied in [render]; used when spawning death sprite.
  double get bobOffset => _bobOffset;

  AntSmasherGame? get optionalGameRef => findGame() as AntSmasherGame?;

  AntSmasherGame get gameRef => optionalGameRef!;

  static double _initialHeading(Random random) {
    return pi / 2 + (random.nextDouble() - 0.5) * 0.9;
  }

  static double _initialSpeed(bool isBoss, double speedMultiplier) {
    final base = isBoss ? 250.0 : 205.0;
    return base * speedMultiplier;
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(0, _bobOffset);
    super.render(canvas);
    canvas.restore();
  }

  @override
  void update(double dt) {
    if (!isMounted) {
      return;
    }

    final game = optionalGameRef;
    if (game == null || !game.hasLayout) {
      return;
    }

    _aliveTime += dt;
    _updateBurst(dt);
    _updateCourse(dt);
    _updateSteering(dt);
    _rotateTowardTarget(dt);
    _updateSpeed(dt);
    _moveForward(dt);
    _updateBob(dt);
    _enforceBounds(game);
    _checkEscaped(game);
    super.update(dt * _flapSpeed);
  }

  void _updateBurst(double dt) {
    _burstTimer -= dt;
    if (_burstTimer <= 0 && random.nextDouble() < 0.012) {
      _burstTimer = 0.35 + random.nextDouble() * 0.45;
    }
    final bursting = _burstTimer > 0;
    _desiredSpeed = _baseSpeed * (bursting ? 1.38 : 1);
    _flapSpeed = bursting ? 1.75 : 1;
  }

  void _updateCourse(double dt) {
    _courseTimer -= dt;
    if (_courseTimer <= 0) {
      _pickNextCourseChange();
    }
  }

  void _pickNextCourseChange() {
    final jitter = (random.nextDouble() - 0.5) * 1.1;
    _targetHeading = pi / 2 + jitter;
    _courseTimer = 0.5 + random.nextDouble() * 1.5;
  }

  void _updateSteering(double dt) {
    final downPull = 0.55;
    var steerX = sin(_aliveTime * 1.8 + _swayPhase) * 0.42;
    final zigzag = sin(_aliveTime * 3.6 + _zigzagPhase) * 0.18;
    steerX += zigzag;

    final steer = Vector2(steerX, downPull)..normalize();
    var desiredHeading = atan2(steer.y, steer.x);

    final targetDelta = _shortestAngleDelta(_targetHeading, desiredHeading);
    desiredHeading = _normalizeAngle(_targetHeading + targetDelta * 0.45);

    final blend = (dt * 2.4).clamp(0.0, 1.0);
    final smoothDelta = _shortestAngleDelta(_targetHeading, desiredHeading);
    _targetHeading = _normalizeAngle(_targetHeading + smoothDelta * blend);
  }

  void _rotateTowardTarget(double dt) {
    final maxTurn = _turnRate * dt;
    _heading = _rotateToward(_heading, _targetHeading, maxTurn);
    angle = _heading + _spriteAngleOffset;
  }

  void _updateSpeed(double dt) {
    final blend = (dt * 3.5).clamp(0.0, 1.0);
    _currentSpeed += (_desiredSpeed - _currentSpeed) * blend;
  }

  void _moveForward(double dt) {
    final direction = Vector2(cos(_heading), sin(_heading));
    position += direction * (_currentSpeed * dt);
  }

  void _updateBob(double dt) {
    final bobAmount = 2.5 + sin(_aliveTime * 9 + _swayPhase).abs() * 1.5;
    _bobOffset = sin(_aliveTime * 11 + _zigzagPhase) * bobAmount;
  }

  void _enforceBounds(AntSmasherGame game) {
    final halfW = size.x * 0.5;
    final minX = halfW;
    final maxX = max(halfW, game.size.x - halfW);

    if (position.x < minX + 20) {
      _targetHeading = _rotateToward(_targetHeading, pi / 2 - 0.5, 0.4);
    } else if (position.x > maxX - 20) {
      _targetHeading = _rotateToward(_targetHeading, pi / 2 + 0.5, 0.4);
    }

    position.x = position.x.clamp(minX, maxX);
  }

  void _checkEscaped(AntSmasherGame game) {
    if (position.y > game.size.y + size.y * 0.5) {
      BeeLifecycle.escape(this);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    final game = optionalGameRef;
    if (game == null || !game.acceptsGameplayInput) {
      return;
    }
    BeeLifecycle.defeat(this);
  }

  static double _normalizeAngle(double angle) {
    var result = angle;
    while (result > pi) {
      result -= 2 * pi;
    }
    while (result < -pi) {
      result += 2 * pi;
    }
    return result;
  }

  static double _shortestAngleDelta(double from, double to) {
    return _normalizeAngle(to - from);
  }

  static double _rotateToward(double current, double target, double maxDelta) {
    final delta = _shortestAngleDelta(current, target);
    if (delta.abs() <= maxDelta) {
      return target;
    }
    return current + delta.sign * maxDelta;
  }
}

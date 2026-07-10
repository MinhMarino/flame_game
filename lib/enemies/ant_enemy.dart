import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../game/ant_smasher_game.dart';
import 'ant_lifecycle.dart';
import 'models/enemy_kind.dart';
import 'models/enemy_stats.dart';
import 'spawned_enemy.dart';

/// Sprite ant with forward-only locomotion: turn first, then walk.
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
    Vector2? startPosition,
  }) : _random = random,
       _currentHp = stats.maxHp,
       _heading = _initialHeading(random),
       _targetHeading = _initialHeading(random),
       _wanderPhase = random.nextDouble() * pi * 2,
       _zigzagPhase = random.nextDouble() * pi * 2,
       _turnRate = _initialTurnRate(random, weaveIntensity),
       _wanderRate = 0.7 + random.nextDouble() * 0.8,
       super(
         size: displaySize,
         anchor: Anchor.center,
         position: startPosition,
       ) {
    _pickNextWanderTarget();
    angle = _heading + _spriteAngleOffset;
  }

  /// Sprite sheet faces upward at rotation 0; offset aligns art with heading.
  static const _spriteAngleOffset = pi / 2;

  @override
  final EnemyStats stats;
  final double speed;
  final double speedScale;
  final double weaveIntensity;
  final Random _random;

  double _heading;
  double _targetHeading;
  final double _wanderPhase;
  final double _zigzagPhase;
  final double _turnRate;
  final double _wanderRate;
  double _wanderTimer = 0;
  double _aliveTime = 0;
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

  AntSmasherGame? get optionalGameRef => findGame() as AntSmasherGame?;

  AntSmasherGame get gameRef => optionalGameRef!;

  double get _moveSpeed => speed * speedScale;

  double get _wanderStrength => 0.12 + weaveIntensity * 0.34;

  double get _zigzagStrength => 0.04 + weaveIntensity * 0.11;

  static double _initialHeading(Random random) {
    return pi / 2 + (random.nextDouble() - 0.5) * 0.5;
  }

  static double _initialTurnRate(Random random, double weaveIntensity) {
    final minRate = pi;
    final maxRate = pi * 2;
    final t = random.nextDouble();
    return minRate + (maxRate - minRate) * t * (0.85 + weaveIntensity * 0.15);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!isMounted) {
      return;
    }

    final game = optionalGameRef;
    if (game == null || !game.hasLayout) {
      return;
    }

    _aliveTime += dt;
    _updateSteering(dt, game);
    _rotateTowardTarget(dt);
    _moveForward(dt);
    _enforceBounds(game);
    _checkEscaped(game);
  }

  void _updateSteering(double dt, AntSmasherGame game) {
    _wanderTimer -= dt;
    if (_wanderTimer <= 0) {
      _pickNextWanderTarget();
    }

    final steering = _computeSteeringVector(game);
    var desiredHeading = atan2(steering.y, steering.x);

    final zigzag = sin(
      _aliveTime * (2.4 + weaveIntensity * 1.8) + _zigzagPhase,
    );
    desiredHeading += zigzag * _zigzagStrength;

    _targetHeading = _smoothHeading(desiredHeading, dt);
  }

  Vector2 _computeSteeringVector(AntSmasherGame game) {
    final downBias = 0.75 + weaveIntensity * 0.1;
    var steerX = 0.0;
    var steerY = downBias;

    final halfW = size.x * 0.5;
    final margin = max(40.0, size.x * 1.6);
    final left = halfW + margin;
    final right = game.size.x - halfW - margin;

    if (position.x < left) {
      final urgency = 1 - (position.x / left).clamp(0.0, 1.0);
      steerX += urgency * (1.1 + weaveIntensity * 0.4);
    } else if (position.x > right) {
      final urgency =
          1 -
          ((game.size.x - position.x) / (game.size.x - right)).clamp(0.0, 1.0);
      steerX -= urgency * (1.1 + weaveIntensity * 0.4);
    }

    final wander =
        sin(_aliveTime * _wanderRate + _wanderPhase) * _wanderStrength;
    steerX += wander;

    final blended = Vector2(steerX, steerY);
    if (blended.length2 < 0.0001) {
      return Vector2(0, 1);
    }
    return blended..normalize();
  }

  void _pickNextWanderTarget() {
    final jitter = (_random.nextDouble() - 0.5) * _wanderStrength * 1.6;
    _targetHeading = pi / 2 + jitter;
    _wanderTimer = 0.35 + _random.nextDouble() * (0.9 - weaveIntensity * 0.2);
  }

  double _smoothHeading(double desiredHeading, double dt) {
    final blend = (dt * (1.6 + weaveIntensity * 0.8)).clamp(0.0, 1.0);
    final delta = _shortestAngleDelta(_targetHeading, desiredHeading);
    return _normalizeAngle(_targetHeading + delta * blend);
  }

  void _rotateTowardTarget(double dt) {
    final maxTurn = _turnRate * dt;
    _heading = _rotateToward(_heading, _targetHeading, maxTurn);
    angle = _heading + _spriteAngleOffset;
  }

  void _moveForward(double dt) {
    final direction = Vector2(cos(_heading), sin(_heading));
    position += direction * (_moveSpeed * dt);
  }

  void _enforceBounds(AntSmasherGame game) {
    final halfW = size.x * 0.5;
    final minX = halfW;
    final maxX = max(halfW, game.size.x - halfW);
    position.x = position.x.clamp(minX, maxX);
  }

  void _checkEscaped(AntSmasherGame game) {
    if (position.y > game.size.y + size.y * 0.5) {
      AntLifecycle.escape(this);
    }
  }

  @override
  void takeDamage(int damage) {
    if (!isAlive) {
      return;
    }

    _currentHp = max(0, _currentHp - damage);
    if (_currentHp <= 0) {
      AntLifecycle.defeat(this);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    final game = optionalGameRef;
    if (game == null || !game.acceptsGameplayInput) {
      return;
    }
    game.triggerSwatterAt(position);
    // With the swatter equipped, the tap only winds up the swing; the ant
    // shouldn't die until the head actually lands (handled by
    // `applySwatterAreaDamage` at impact). Without the swatter, a bare tap
    // still smashes instantly like before.
    if (!game.swatterEnabled) {
      takeDamage(1);
    }
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

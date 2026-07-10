import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

/// Purely cosmetic "attraction aura" for bait/decoy style items (the
/// Lollipop today, future bait/decoy items tomorrow).
///
/// It has zero effect on gameplay, damage, HP, or AI targeting — it only
/// exists to give players an at-a-glance read of how far an item's
/// attraction/pull radius reaches, dressed up as a pleasant candy smell
/// (soft pastel wisps + sugar sparkles) rather than a combat AoE, magic, or
/// poison effect.
///
/// Add it as a child of the host component, positioned at the host's own
/// center (`hostSize / 2`, since the host is anchored at its center too):
///
/// ```dart
/// add(
///   AttractionAuraComponent(radius: detectionRadius)..position = size / 2,
/// );
/// ```
///
/// Because it is a normal child component it automatically follows the
/// host's position every frame, and it is torn down (along with every
/// particle/effect it owns) the instant the host is removed from the
/// component tree — no manual start/stop/dispose wiring required.
class AttractionAuraComponent extends PositionComponent {
  AttractionAuraComponent({
    required double radius,
    this.scentColors = _defaultScentColors,
    this.candyColors = _defaultCandyColors,
    this.showCandyParticles = true,
  }) : _radius = radius,
       super(size: Vector2.all(radius * 2), anchor: Anchor.center);

  final double _radius;

  /// Soft pastel palette for the breathing ring and the drifting smell
  /// wisps/sparkles. Kept intentionally light so it reads as "sweet smell",
  /// not a magic/poison effect.
  final List<Color> scentColors;

  /// Palette used for the optional tiny candy-shaped bits.
  final List<Color> candyColors;

  /// Whether to also spawn the tiny candy-shaped particles (extra visual
  /// polish, safe to disable for a leaner effect).
  final bool showCandyParticles;

  static const List<Color> _defaultScentColors = [
    Color(0xFFFFB3DE), // pink
    Color(0xFFFFF3B0), // yellow
    Color(0xFFD8B4FE), // light purple
    Color(0xFFA6EFFF), // cyan
  ];

  static const List<Color> _defaultCandyColors = [
    Color(0xFFFF8FB1), // strawberry pink
    Color(0xFFFFD98E), // lemon yellow
    Color(0xFFC3AAFF), // grape purple
  ];

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Every sub-effect lives in the same local coordinate space, centered
    // on this component's own bounding box (which is centered on the host).
    final center = Vector2.all(_radius);

    add(_BreathingRadiusRing(radius: _radius)..position = center);
    add(
      _SweetSmellEmitter(radius: _radius, colors: scentColors)
        ..position = center,
    );
    if (showCandyParticles) {
      add(
        _CandyBitsEmitter(radius: _radius, colors: candyColors)
          ..position = center,
      );
    }
  }
}

/// Subtle, continuously "breathing" circle that communicates the host's
/// attraction range without ever reading as a combat area-of-effect: low
/// opacity, soft pastel color, no hard edges, no pulsing red/orange.
class _BreathingRadiusRing extends PositionComponent {
  _BreathingRadiusRing({required double radius})
    : _radius = radius,
      super(size: Vector2.all(radius * 2), anchor: Anchor.center);

  final double _radius;
  double _time = 0;

  /// One direction of the breathe (grow or shrink) takes this long, so a
  /// full inhale+exhale cycle takes twice this.
  static const double _halfCycleDuration = 1.2;
  static const double _minScale = 0.95;
  static const double _maxScale = 1.05;
  static const double _minOpacity = 0.05;
  static const double _maxOpacity = 0.20;

  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;

  double _breatheEase = 0;

  @override
  void onMount() {
    super.onMount();
    scale.setAll(_minScale);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    final phase = (_time / _halfCycleDuration) % 2;
    final triangleWave = phase <= 1 ? phase : 2 - phase;
    _breatheEase = Curves.easeInOut.transform(triangleWave);
    scale.setAll(_minScale + (_maxScale - _minScale) * _breatheEase);
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(_radius, _radius);
    final opacity = _maxOpacity - (_maxOpacity - _minOpacity) * _breatheEase;

    _fillPaint.color = const Color(0xFFFFF6E9).withValues(alpha: opacity * 0.5);
    _ringPaint.color = const Color(
      0xFFFFD9EC,
    ).withValues(alpha: (opacity * 1.3).clamp(0.0, 1.0));

    canvas.drawCircle(center, _radius, _fillPaint);
    canvas.drawCircle(center, _radius, _ringPaint);
  }
}

/// Continuously emits two flavors of low-cost, self-expiring particles:
///  - soft blurred pastel "scent wisps" that float up and drift outward,
///  - tiny four-point "sugar sparkle" glints that pop in and fade out.
///
/// Both spawn on independent timers but share a single active-particle
/// budget, keeping the total on-screen particle count low and predictable
/// on mobile. Each particle is a self-contained [ParticleSystemComponent]
/// that removes itself once its lifespan ends — nothing is ever allocated
/// or retained beyond what is currently visible.
class _SweetSmellEmitter extends PositionComponent {
  _SweetSmellEmitter({required this._radius, required this._colors});

  final double _radius;
  final List<Color> _colors;
  final Random _random = Random();

  /// Hard cap on concurrently-alive particles owned by this emitter, across
  /// both wisps and sparkles, so cost stays flat no matter how long the
  /// Lollipop has been alive.
  static const int _maxActiveParticles = 10;

  double _wispCooldown = 0;
  double _sparkleCooldown = 0;

  @override
  void update(double dt) {
    super.update(dt);

    _wispCooldown -= dt;
    if (_wispCooldown <= 0 && children.length < _maxActiveParticles) {
      _wispCooldown = 0.7 + _random.nextDouble() * 0.6;
      _spawnScentWisp();
    }

    _sparkleCooldown -= dt;
    if (_sparkleCooldown <= 0 && children.length < _maxActiveParticles) {
      _sparkleCooldown = 0.22 + _random.nextDouble() * 0.28;
      _spawnSugarSparkle();
    }
  }

  Vector2 _randomOffsetWithin(double maxFraction) {
    final angle = _random.nextDouble() * pi * 2;
    final dist = _radius * maxFraction * _random.nextDouble();
    return Vector2(cos(angle), sin(angle)) * dist;
  }

  void _spawnScentWisp() {
    final start = _randomOffsetWithin(0.45);
    final outward = start.length > 0.5 ? start.normalized() : Vector2(0, -1);
    final riseDistance = 44 + _random.nextDouble() * 30;
    final driftDistance = 12 + _random.nextDouble() * 16;
    final end = Vector2(
      start.x + outward.x * driftDistance,
      start.y + outward.y * driftDistance - riseDistance,
    );
    final color = _colors[_random.nextInt(_colors.length)];
    final maxRadius = 8.0 + _random.nextDouble() * 6;
    final lifespan = 2.3 + _random.nextDouble() * 1.3;

    final particle = ComputedParticle(
      lifespan: lifespan,
      renderer: (canvas, particle) {
        final t = particle.progress;
        final fade = sin(pi * t);
        if (fade <= 0.01) {
          return;
        }
        final paint = Paint()
          ..color = color.withValues(alpha: 0.16 * fade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(Offset.zero, maxRadius * (0.55 + 0.45 * t), paint);
      },
    ).moving(from: start, to: end, curve: Curves.easeOut);

    add(ParticleSystemComponent(particle: particle));
  }

  void _spawnSugarSparkle() {
    final start = _randomOffsetWithin(0.85);
    final drift = Vector2(
      (_random.nextDouble() - 0.5) * 18,
      -(16 + _random.nextDouble() * 18),
    );
    final color = _colors[_random.nextInt(_colors.length)];
    final maxRadius = 1.6 + _random.nextDouble() * 1.6;
    final lifespan = 0.9 + _random.nextDouble() * 0.6;

    final particle = ComputedParticle(
      lifespan: lifespan,
      renderer: (canvas, particle) {
        final t = particle.progress;
        final fade = sin(pi * t).clamp(0.0, 1.0);
        if (fade <= 0.02) {
          return;
        }
        final paint = Paint()..color = color.withValues(alpha: 0.85 * fade);
        _drawSparkle(canvas, paint, maxRadius * (0.4 + 0.6 * fade));
      },
    ).moving(from: start, to: start + drift, curve: Curves.easeOut);

    add(ParticleSystemComponent(particle: particle));
  }

  static void _drawSparkle(Canvas canvas, Paint paint, double r) {
    final path = Path()
      ..moveTo(0, -r)
      ..lineTo(r * 0.32, 0)
      ..lineTo(0, r)
      ..lineTo(-r * 0.32, 0)
      ..close()
      ..moveTo(-r, 0)
      ..lineTo(0, -r * 0.32)
      ..lineTo(r, 0)
      ..lineTo(0, r * 0.32)
      ..close();
    canvas.drawPath(path, paint);
  }
}

/// Optional extra polish: a handful of tiny candy-shaped bits that tumble
/// gently up and away, far less frequent than the sparkles so they read as
/// a bonus flourish rather than the main effect.
class _CandyBitsEmitter extends PositionComponent {
  _CandyBitsEmitter({required this._radius, required this._colors});

  final double _radius;
  final List<Color> _colors;
  final Random _random = Random();

  static const int _maxActiveCandies = 2;
  double _cooldown = 1.2;

  @override
  void update(double dt) {
    super.update(dt);
    _cooldown -= dt;
    if (_cooldown <= 0 && children.length < _maxActiveCandies) {
      _cooldown = 2.6 + _random.nextDouble() * 1.8;
      _spawnCandyBit();
    }
  }

  void _spawnCandyBit() {
    final angle = _random.nextDouble() * pi * 2;
    final start =
        Vector2(cos(angle), sin(angle)) *
        (_radius * 0.3 * _random.nextDouble());
    final end =
        start +
        Vector2(
          (_random.nextDouble() - 0.5) * 20,
          -60 - _random.nextDouble() * 20,
        );
    final color = _colors[_random.nextInt(_colors.length)];
    final lifespan = 2.0 + _random.nextDouble() * 0.8;
    final startAngle = _random.nextDouble() * pi * 2;
    const size = 3.4;

    final particle =
        ComputedParticle(
              lifespan: lifespan,
              renderer: (canvas, particle) {
                final t = particle.progress;
                final fade = sin(pi * t).clamp(0.0, 1.0);
                if (fade <= 0.02) {
                  return;
                }
                final bodyPaint = Paint()
                  ..color = color.withValues(alpha: 0.9 * fade);
                final highlightPaint = Paint()
                  ..color = Colors.white.withValues(alpha: 0.6 * fade);
                final rect = RRect.fromRectAndRadius(
                  Rect.fromCenter(
                    center: Offset.zero,
                    width: size * 2,
                    height: size,
                  ),
                  const Radius.circular(1.6),
                );
                canvas.drawRRect(rect, bodyPaint);
                canvas.drawCircle(
                  Offset(-size * 0.4, -size * 0.15),
                  size * 0.28,
                  highlightPaint,
                );
              },
            )
            .rotating(from: startAngle, to: startAngle + pi * 1.5)
            .moving(from: start, to: end, curve: Curves.easeOut);

    add(ParticleSystemComponent(particle: particle));
  }
}

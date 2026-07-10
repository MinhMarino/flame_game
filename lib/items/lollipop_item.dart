import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

import '../game/ant_smasher_game.dart';

/// A single HP-gated sprite swap threshold for [LollipopItem].
class _LollipopStage {
  const _LollipopStage({required this.minFraction, required this.asset});

  final double minFraction;
  final String asset;
}

/// Player-placed decoy that lures nearby Ants and Bees away from the level
/// exit. Enemies within [LollipopItem.detectionRadius] beeline for it and
/// chip away at its HP instead of marching toward the bottom of the screen.
///
/// Once HP reaches zero the Lollipop plays a short destroy animation and
/// removes itself, at which point every enemy that was attacking it
/// automatically resumes normal behavior (there is simply nothing left to
/// target).
class LollipopItem extends SpriteComponent
    with HasGameReference<AntSmasherGame> {
  LollipopItem({required Vector2 position})
    : _currentHp = maxHp,
      super(
        position: position,
        size: Vector2.all(displaySize),
        anchor: Anchor.center,
        priority: 6,
      );

  /// Total hit points; matches the 30 HP called out in the design.
  static const double maxHp = 30;

  /// Shared canvas size used by every static sprite in the game (see
  /// `EnemyAssets.frameSize`), kept in sync so scaling stays consistent.
  static const double frameSize = 313;
  static const double displayScale = 0.42;
  static const double displaySize = frameSize * displayScale;

  /// How far away an Ant/Bee can sense this Lollipop and start beelining for
  /// it instead of continuing toward the end of the level.
  static const double detectionRadius = 260;

  static const double _destroyPopDuration = 0.18;
  static const double _destroyFadeDuration = 0.6;

  /// Ordered brightest-to-darkest so the first matching stage wins.
  static const List<_LollipopStage> _stages = [
    _LollipopStage(minFraction: 0.75, asset: 'lollipop_100.png'),
    _LollipopStage(minFraction: 0.50, asset: 'lollipop_75.png'),
    _LollipopStage(minFraction: 0.25, asset: 'lollipop_50.png'),
    _LollipopStage(minFraction: 0.0, asset: 'lollipop_25.png'),
    _LollipopStage(minFraction: -1, asset: 'lollipop_0.png'),
  ];

  double _currentHp;
  bool _destroyed = false;
  String? _currentAsset;

  double get currentHp => _currentHp;

  double get hpFraction => (_currentHp / maxHp).clamp(0, 1);

  /// False as soon as HP hits zero, even while the destroy animation is
  /// still playing out — this is what lets enemies resume normal AI
  /// immediately rather than waiting for the fade-out to finish.
  bool get isAlive => !_destroyed;

  /// Distance from center that counts as "in melee range" for an attacker.
  double get attackRadius => size.x * 0.32;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _applySpriteForHp();
  }

  /// Applies [amount] HP of damage (fractional, since damage is expressed
  /// per-second and applied every frame). Triggers the destroy sequence the
  /// moment HP reaches zero.
  void takeDamage(double amount) {
    if (_destroyed || amount <= 0) {
      return;
    }

    _currentHp = (_currentHp - amount).clamp(0, maxHp);
    _applySpriteForHp();

    if (_currentHp <= 0) {
      _destroy();
    }
  }

  void _applySpriteForHp() {
    final asset = _assetForFraction(hpFraction);
    if (asset == _currentAsset) {
      return;
    }
    _currentAsset = asset;
    sprite = Sprite(game.images.fromCache(asset));
  }

  static String _assetForFraction(double fraction) {
    for (final stage in _stages) {
      if (fraction >= stage.minFraction) {
        return stage.asset;
      }
    }
    return 'lollipop_0.png';
  }

  void _destroy() {
    if (_destroyed) {
      return;
    }
    _destroyed = true;
    _currentAsset = 'lollipop_0.png';
    sprite = Sprite(game.images.fromCache('lollipop_0.png'));

    add(
      ScaleEffect.by(
        Vector2.all(1.2),
        EffectController(
          duration: _destroyPopDuration,
          curve: Curves.easeOut,
          alternate: true,
        ),
      ),
    );
    add(
      OpacityEffect.fadeOut(
        EffectController(
          duration: _destroyFadeDuration,
          startDelay: _destroyPopDuration,
        ),
        onComplete: removeFromParent,
      ),
    );
  }
}

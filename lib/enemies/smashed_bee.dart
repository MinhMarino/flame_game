import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../game/ant_smasher_game.dart';

class SmashedBee extends SpriteComponent with HasGameReference<AntSmasherGame> {
  /// Death art faces opposite the fly sprite at rotation 0.
  static const _spriteAngleOffset = pi;

  SmashedBee({
    required super.position,
    required super.size,
    required double liveAngle,
  }) : super(
         anchor: Anchor.center,
         angle: liveAngle + _spriteAngleOffset,
         priority: 5,
       );

  static const double _fadeDuration = 0.9;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    sprite = Sprite(game.images.fromCache('bee_smashed.png'));

    add(
      OpacityEffect.fadeOut(
        EffectController(duration: _fadeDuration),
        onComplete: removeFromParent,
      ),
    );
  }
}

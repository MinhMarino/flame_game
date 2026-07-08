import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../game/ant_smasher_game.dart';

class SmashedBee extends SpriteComponent with HasGameReference<AntSmasherGame> {
  SmashedBee({required super.position, required super.size})
    : super(anchor: Anchor.center, priority: 5);

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

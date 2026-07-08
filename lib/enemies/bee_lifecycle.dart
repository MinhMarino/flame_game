import 'bee_enemy.dart';
import 'bee_death_effect.dart';

/// Single source of truth for bee defeat and escape handling.
abstract final class BeeLifecycle {
  BeeLifecycle._();

  static void defeat(BeeEnemy bee) {
    final game = bee.gameRef;
    if (game.isGameOver || game.isLevelEnded) {
      return;
    }

    game.add(
      BeeDeathEffect(
        startPosition: bee.position.clone(),
        bodySize: bee.size.clone(),
        bodyAngle: bee.angle,
        deathAnimation: game.beeDeathAnimation,
        random: bee.random,
      ),
    );
    game.registerBeeHit(bee);
    bee.removeFromParent();
  }

  static void escape(BeeEnemy bee) {
    final game = bee.gameRef;
    if (game.isGameOver || game.isLevelEnded) {
      bee.removeFromParent();
      return;
    }

    game.onBeeEscaped(bee);
    bee.removeFromParent();
  }
}

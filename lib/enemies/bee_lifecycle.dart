import 'bee_enemy.dart';
import 'smashed_bee.dart';

/// Single source of truth for bee defeat and escape handling.
abstract final class BeeLifecycle {
  BeeLifecycle._();

  static void defeat(BeeEnemy bee) {
    final game = bee.gameRef;
    if (game.isGameOver || game.isLevelEnded) {
      return;
    }

    game.add(
      SmashedBee(
        position: bee.position.clone(),
        size: bee.size.clone(),
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

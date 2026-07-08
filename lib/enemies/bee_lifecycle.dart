import 'package:flame/components.dart';

import 'bee_enemy.dart';
import 'enemy_assets.dart';
import 'smashed_bee.dart';

/// Single source of truth for bee defeat and escape handling.
abstract final class BeeLifecycle {
  BeeLifecycle._();

  static void defeat(BeeEnemy bee) {
    final game = bee.optionalGameRef;
    if (game == null) {
      bee.removeFromParent();
      return;
    }
    if (!game.isLoaded || game.isGameOver || game.isLevelEnded) {
      return;
    }

    game.add(
      SmashedBee(
        position: bee.position.clone(),
        size: Vector2.all(
          EnemyAssets.beeSmashedDisplaySize(isBoss: bee.isBoss),
        ),
      ),
    );
    game.registerBeeHit(bee);
    bee.removeFromParent();
  }

  static void escape(BeeEnemy bee) {
    final game = bee.optionalGameRef;
    if (game == null) {
      bee.removeFromParent();
      return;
    }
    if (game.isGameOver || game.isLevelEnded) {
      bee.removeFromParent();
      return;
    }

    game.onBeeEscaped(bee);
    bee.removeFromParent();
  }
}

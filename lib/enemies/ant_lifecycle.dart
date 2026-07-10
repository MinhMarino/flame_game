import 'smashed_ant.dart';
import 'ant_enemy.dart';

/// Single source of truth for ant defeat and escape handling.
abstract final class AntLifecycle {
  AntLifecycle._();

  static void defeat(AntEnemy ant) {
    final game = ant.optionalGameRef;
    if (game == null) {
      ant.removeFromParent();
      return;
    }
    if (!game.isLoaded || game.isGameOver || game.isLevelEnded) {
      return;
    }

    game.add(
      SmashedAnt(position: ant.position.clone(), size: ant.size.clone()),
    );
    game.registerAntHit(ant);
    ant.removeFromParent();
  }

  static void escape(AntEnemy ant) {
    final game = ant.optionalGameRef;
    if (game == null) {
      ant.removeFromParent();
      return;
    }
    if (game.isGameOver || game.isLevelEnded) {
      ant.removeFromParent();
      return;
    }

    game.onAntEscaped(ant);
    ant.removeFromParent();
  }
}

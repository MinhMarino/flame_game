import 'models/enemy_kind.dart';
import 'models/enemy_stats.dart';

/// Shared contract for enemies spawned in level/world gameplay.
abstract interface class SpawnedEnemy {
  EnemyKind get kind;
  EnemyStats get stats;
  int get currentHp;
  bool get isAlive;
  bool get isBoss;
  void takeDamage(int damage);
}

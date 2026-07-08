import '../../../level_data/models/level_models.dart';
import 'kitchen_enemy_stats.dart';

class KitchenLevelConfig {
  const KitchenLevelConfig({
    required this.levelInWorld,
    required this.name,
    required this.objective,
    required this.spawnInterval,
    required this.maxSimultaneousEnemies,
    required this.lives,
    required this.spawnTable,
    required this.starRequirements,
    this.totalSpawnCap,
    this.isBossLevel = false,
    this.enableFlySwatter = false,
    this.flySwatterCooldownSeconds = 25,
    this.flyWeaveIntensity = 0,
    this.antWeaveIntensity = 0.65,
    this.enemySpeedMultiplier = 1,
    this.countdownSeconds,
  });

  final int levelInWorld;
  final String name;
  final LevelObjective objective;
  final double spawnInterval;
  final int maxSimultaneousEnemies;
  final int lives;
  final List<KitchenSpawnEntry> spawnTable;
  final StarRequirements starRequirements;
  final int? totalSpawnCap;
  final bool isBossLevel;
  final bool enableFlySwatter;
  final double flySwatterCooldownSeconds;

  /// 0 = no weave. Scales House Fly zigzag difficulty per level.
  final double flyWeaveIntensity;

  /// Scales Black Ant winding path per level.
  final double antWeaveIntensity;

  /// Scales all enemy movement speed for this level.
  final double enemySpeedMultiplier;

  /// Round duration for tower-defense levels (seconds).
  final double? countdownSeconds;

  int get levelId => levelInWorld;
}

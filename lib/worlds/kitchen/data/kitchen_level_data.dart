import '../../../level_data/models/level_models.dart';
import '../models/kitchen_enemy_kind.dart';
import '../models/kitchen_enemy_stats.dart';
import '../models/kitchen_level_config.dart';

/// Handcrafted World 1 (Kitchen) — tower defense rounds with countdown timer.
class KitchenLevelData {
  KitchenLevelData._();

  static const List<KitchenLevelConfig> levels = [
    // L1: Black Ant — busy opener, tighter base HP
    KitchenLevelConfig(
      levelInWorld: 1,
      name: 'First Swat',
      objective: LevelObjective(
        type: LevelObjectiveType.defendBase,
        description: 'Defend the kitchen for 60 seconds',
      ),
      countdownSeconds: 60,
      spawnInterval: 0.8,
      maxSimultaneousEnemies: 8,
      lives: 8,
      enemySpeedMultiplier: 0.9,
      antWeaveIntensity: 0.55,
      spawnTable: [
        KitchenSpawnEntry(kind: KitchenEnemyKind.blackAnt, weight: 1),
      ],
      starRequirements: StarRequirements(
        oneStarScore: 0,
        twoStarScore: 0,
        threeStarScore: 0,
      ),
    ),
    // L2: Ant swarm ramps up
    KitchenLevelConfig(
      levelInWorld: 2,
      name: 'Counter Patrol',
      objective: LevelObjective(
        type: LevelObjectiveType.defendBase,
        description: 'Defend the kitchen for 60 seconds',
      ),
      countdownSeconds: 60,
      spawnInterval: 0.72,
      maxSimultaneousEnemies: 9,
      lives: 8,
      enemySpeedMultiplier: 1.0,
      antWeaveIntensity: 0.62,
      spawnTable: [
        KitchenSpawnEntry(kind: KitchenEnemyKind.blackAnt, weight: 1),
      ],
      starRequirements: StarRequirements(
        oneStarScore: 0,
        twoStarScore: 0,
        threeStarScore: 0,
      ),
    ),
    // L3: House Fly introduced
    KitchenLevelConfig(
      levelInWorld: 3,
      name: 'Fly Invasion',
      objective: LevelObjective(
        type: LevelObjectiveType.defendBase,
        description: 'Defend the kitchen for 55 seconds',
      ),
      countdownSeconds: 55,
      spawnInterval: 0.65,
      maxSimultaneousEnemies: 9,
      lives: 7,
      enemySpeedMultiplier: 1.08,
      flyWeaveIntensity: 0.5,
      antWeaveIntensity: 0.68,
      spawnTable: [
        KitchenSpawnEntry(kind: KitchenEnemyKind.blackAnt, weight: 0.55),
        KitchenSpawnEntry(kind: KitchenEnemyKind.houseFly, weight: 0.45),
      ],
      starRequirements: StarRequirements(
        oneStarScore: 0,
        twoStarScore: 0,
        threeStarScore: 0,
      ),
    ),
    // L4: Fly-heavy pressure
    KitchenLevelConfig(
      levelInWorld: 4,
      name: 'Buzz Off',
      objective: LevelObjective(
        type: LevelObjectiveType.defendBase,
        description: 'Defend the kitchen for 55 seconds',
      ),
      countdownSeconds: 55,
      spawnInterval: 0.58,
      maxSimultaneousEnemies: 10,
      lives: 7,
      enemySpeedMultiplier: 1.16,
      flyWeaveIntensity: 0.72,
      antWeaveIntensity: 0.74,
      spawnTable: [
        KitchenSpawnEntry(kind: KitchenEnemyKind.blackAnt, weight: 0.3),
        KitchenSpawnEntry(kind: KitchenEnemyKind.houseFly, weight: 0.7),
      ],
      starRequirements: StarRequirements(
        oneStarScore: 0,
        twoStarScore: 0,
        threeStarScore: 0,
      ),
    ),
    // L5: Cockroach + Fly Swatter unlock
    KitchenLevelConfig(
      levelInWorld: 5,
      name: 'Roach Rush',
      objective: LevelObjective(
        type: LevelObjectiveType.defendBase,
        description: 'Defend the kitchen for 50 seconds',
      ),
      countdownSeconds: 50,
      spawnInterval: 0.52,
      maxSimultaneousEnemies: 10,
      lives: 6,
      enemySpeedMultiplier: 1.24,
      flyWeaveIntensity: 0.88,
      antWeaveIntensity: 0.8,
      enableFlySwatter: true,
      flySwatterCooldownSeconds: 28,
      spawnTable: [
        KitchenSpawnEntry(kind: KitchenEnemyKind.blackAnt, weight: 0.25),
        KitchenSpawnEntry(kind: KitchenEnemyKind.houseFly, weight: 0.35),
        KitchenSpawnEntry(kind: KitchenEnemyKind.cockroach, weight: 0.4),
      ],
      starRequirements: StarRequirements(
        oneStarScore: 0,
        twoStarScore: 0,
        threeStarScore: 0,
      ),
    ),
    // L6: Roach + fly chaos
    KitchenLevelConfig(
      levelInWorld: 6,
      name: 'Kitchen Chaos',
      objective: LevelObjective(
        type: LevelObjectiveType.defendBase,
        description: 'Defend the kitchen for 50 seconds',
      ),
      countdownSeconds: 50,
      spawnInterval: 0.46,
      maxSimultaneousEnemies: 11,
      lives: 6,
      enemySpeedMultiplier: 1.32,
      flyWeaveIntensity: 1.05,
      antWeaveIntensity: 0.86,
      enableFlySwatter: true,
      flySwatterCooldownSeconds: 30,
      spawnTable: [
        KitchenSpawnEntry(kind: KitchenEnemyKind.blackAnt, weight: 0.15),
        KitchenSpawnEntry(kind: KitchenEnemyKind.houseFly, weight: 0.4),
        KitchenSpawnEntry(kind: KitchenEnemyKind.cockroach, weight: 0.45),
      ],
      starRequirements: StarRequirements(
        oneStarScore: 0,
        twoStarScore: 0,
        threeStarScore: 0,
      ),
    ),
    // L7: Small Beetle introduced
    KitchenLevelConfig(
      levelInWorld: 7,
      name: 'Beetle Blockade',
      objective: LevelObjective(
        type: LevelObjectiveType.defendBase,
        description: 'Defend the kitchen for 45 seconds',
      ),
      countdownSeconds: 45,
      spawnInterval: 0.42,
      maxSimultaneousEnemies: 11,
      lives: 5,
      enemySpeedMultiplier: 1.4,
      flyWeaveIntensity: 1.2,
      antWeaveIntensity: 0.92,
      enableFlySwatter: true,
      flySwatterCooldownSeconds: 32,
      spawnTable: [
        KitchenSpawnEntry(kind: KitchenEnemyKind.blackAnt, weight: 0.1),
        KitchenSpawnEntry(kind: KitchenEnemyKind.houseFly, weight: 0.3),
        KitchenSpawnEntry(kind: KitchenEnemyKind.cockroach, weight: 0.25),
        KitchenSpawnEntry(kind: KitchenEnemyKind.smallBeetle, weight: 0.35),
      ],
      starRequirements: StarRequirements(
        oneStarScore: 0,
        twoStarScore: 0,
        threeStarScore: 0,
      ),
    ),
    // L8: Full mix, heavy screen
    KitchenLevelConfig(
      levelInWorld: 8,
      name: 'Full Mix',
      objective: LevelObjective(
        type: LevelObjectiveType.defendBase,
        description: 'Defend the kitchen for 45 seconds',
      ),
      countdownSeconds: 45,
      spawnInterval: 0.38,
      maxSimultaneousEnemies: 12,
      lives: 5,
      enemySpeedMultiplier: 1.48,
      flyWeaveIntensity: 1.35,
      antWeaveIntensity: 0.96,
      enableFlySwatter: true,
      flySwatterCooldownSeconds: 34,
      spawnTable: [
        KitchenSpawnEntry(kind: KitchenEnemyKind.blackAnt, weight: 0.1),
        KitchenSpawnEntry(kind: KitchenEnemyKind.houseFly, weight: 0.25),
        KitchenSpawnEntry(kind: KitchenEnemyKind.cockroach, weight: 0.3),
        KitchenSpawnEntry(kind: KitchenEnemyKind.smallBeetle, weight: 0.35),
      ],
      starRequirements: StarRequirements(
        oneStarScore: 0,
        twoStarScore: 0,
        threeStarScore: 0,
      ),
    ),
    // L9: Peak swarm before boss
    KitchenLevelConfig(
      levelInWorld: 9,
      name: 'Pre-Boss Swarm',
      objective: LevelObjective(
        type: LevelObjectiveType.defendBase,
        description: 'Defend the kitchen for 40 seconds',
      ),
      countdownSeconds: 40,
      spawnInterval: 0.34,
      maxSimultaneousEnemies: 13,
      lives: 4,
      enemySpeedMultiplier: 1.56,
      flyWeaveIntensity: 1.55,
      antWeaveIntensity: 1.0,
      enableFlySwatter: true,
      flySwatterCooldownSeconds: 36,
      spawnTable: [
        KitchenSpawnEntry(kind: KitchenEnemyKind.blackAnt, weight: 0.08),
        KitchenSpawnEntry(kind: KitchenEnemyKind.houseFly, weight: 0.27),
        KitchenSpawnEntry(kind: KitchenEnemyKind.cockroach, weight: 0.3),
        KitchenSpawnEntry(kind: KitchenEnemyKind.smallBeetle, weight: 0.35),
      ],
      starRequirements: StarRequirements(
        oneStarScore: 0,
        twoStarScore: 0,
        threeStarScore: 0,
      ),
    ),
    // L10: Giant Spider boss
    KitchenLevelConfig(
      levelInWorld: 10,
      name: 'Giant Spider',
      objective: LevelObjective(
        type: LevelObjectiveType.defeatBoss,
        description: 'Defeat the Giant Spider and all Baby Spiders',
      ),
      spawnInterval: 999,
      maxSimultaneousEnemies: 14,
      lives: 4,
      enemySpeedMultiplier: 1.35,
      spawnTable: [],
      starRequirements: StarRequirements(
        oneStarScore: 0,
        twoStarScore: 20,
        threeStarScore: 40,
      ),
      isBossLevel: true,
    ),
  ];

  static KitchenLevelConfig forLevel(int levelInWorld) =>
      levels[levelInWorld - 1];
}

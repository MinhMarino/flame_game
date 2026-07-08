import '../worlds/kitchen/data/kitchen_level_data.dart';
import 'models/level_models.dart';
import 'level_blueprints.dart';
import 'world_registry.dart';

/// Central catalog of all worlds and levels. Extend by adding to registries only.
class LevelCatalog {
  LevelCatalog._();

  static final List<WorldDefinition> worlds = WorldRegistry.worlds;
  static final List<LevelDefinition> levels = _buildAllLevels();
  static final Map<int, LevelDefinition> _byId = {
    for (final level in levels) level.levelId: level,
  };

  static int get totalLevels => levels.length;
  static int get totalWorlds => worlds.length;

  static LevelDefinition levelById(int levelId) {
    final level = _byId[levelId];
    if (level == null) {
      throw ArgumentError('Unknown level id: $levelId');
    }
    return level;
  }

  static WorldDefinition worldForLevel(int levelId) =>
      WorldRegistry.forLevel(levelId);

  static List<LevelDefinition> levelsForWorld(int worldId) {
    return levels.where((level) => level.worldId == worldId).toList();
  }

  static List<LevelDefinition> _buildAllLevels() {
    final built = <LevelDefinition>[];

    for (final world in worlds) {
      if (world.id == 1) {
        built.addAll(_buildKitchenLevels(world));
        continue;
      }

      final blueprints = LevelBlueprintRegistry.byWorld[world.id];
      if (blueprints == null || blueprints.length != 10) {
        throw StateError('World ${world.id} must define exactly 10 levels.');
      }

      for (var index = 0; index < blueprints.length; index++) {
        final blueprint = blueprints[index];
        final levelInWorld = index + 1;
        final levelId = world.firstLevel + index;
        final isBoss = blueprint.isBossLevel;

        built.add(
          LevelDefinition(
            worldId: world.id,
            levelId: levelId,
            levelInWorld: levelInWorld,
            name: blueprint.name,
            objective: isBoss
                ? blueprint.objective
                : LevelObjective(
                    type: LevelObjectiveType.defendBase,
                    description:
                        'Defend for ${_defenseCountdownSeconds(levelInWorld, blueprint.countdownSeconds).toInt()} seconds',
                  ),
            enemyTypes: blueprint.enemyTypes,
            spawnInterval: blueprint.spawnInterval,
            antSpeedMin: blueprint.antSpeedMin,
            antSpeedMax: blueprint.antSpeedMax,
            beeSpawnChance: blueprint.beeSpawnChance,
            maxSimultaneousEnemies: blueprint.maxSimultaneousEnemies,
            lives: blueprint.lives,
            starRequirements: StarRequirements(
              oneStarScore: blueprint.oneStar,
              twoStarScore: blueprint.twoStar,
              threeStarScore: blueprint.threeStar,
            ),
            countdownSeconds: isBoss
                ? blueprint.countdownSeconds
                : _defenseCountdownSeconds(
                    levelInWorld,
                    blueprint.countdownSeconds,
                  ),
            isBossLevel: isBoss,
          ),
        );
      }
    }

    return built;
  }

  static double _defenseCountdownSeconds(
    int levelInWorld,
    double? blueprintCountdown,
  ) {
    if (blueprintCountdown != null) {
      return blueprintCountdown;
    }

    return switch (levelInWorld) {
      1 || 2 => 60,
      3 || 4 => 55,
      5 || 6 => 50,
      7 || 8 => 45,
      9 => 40,
      _ => 60,
    };
  }

  static List<LevelDefinition> _buildKitchenLevels(WorldDefinition world) {
    return KitchenLevelData.levels.map((config) {
      return LevelDefinition(
        worldId: world.id,
        levelId: world.firstLevel + config.levelInWorld - 1,
        levelInWorld: config.levelInWorld,
        name: config.name,
        objective: config.objective,
        enemyTypes: const [EnemyType.ant],
        spawnInterval: config.spawnInterval,
        antSpeedMin: 100,
        antSpeedMax: 160,
        beeSpawnChance: 0,
        maxSimultaneousEnemies: config.maxSimultaneousEnemies,
        lives: config.lives,
        starRequirements: config.starRequirements,
        countdownSeconds: config.countdownSeconds,
        isBossLevel: config.isBossLevel,
      );
    }).toList();
  }
}

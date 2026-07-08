import 'package:flutter/material.dart';

enum EnemyType { ant, bee, boss }

enum LevelObjectiveType {
  smashCount,
  targetScore,
  eliminateAnts,
  eliminateBees,
  eliminateMixed,
  surviveTime,
  countdownComplete,
  defeatBoss,
  defendBase,
}

class LevelObjective {
  const LevelObjective({
    required this.type,
    this.targetCount,
    this.targetScore,
    this.targetAnts,
    this.targetBees,
    this.surviveSeconds,
    this.countdownSeconds,
    this.description,
  });

  final LevelObjectiveType type;
  final int? targetCount;
  final int? targetScore;
  final int? targetAnts;
  final int? targetBees;
  final double? surviveSeconds;
  final double? countdownSeconds;
  final String? description;

  String get displayText {
    if (description != null) {
      return description!;
    }

    return switch (type) {
      LevelObjectiveType.smashCount => 'Smash ${targetCount ?? 0} bugs',
      LevelObjectiveType.targetScore => 'Reach ${targetScore ?? 0} points',
      LevelObjectiveType.eliminateAnts => 'Eliminate ${targetAnts ?? 0} ants',
      LevelObjectiveType.eliminateBees => 'Eliminate ${targetBees ?? 0} bees',
      LevelObjectiveType.eliminateMixed =>
        'Smash ${targetAnts ?? 0} ants & ${targetBees ?? 0} bees',
      LevelObjectiveType.surviveTime =>
        'Survive for ${surviveSeconds?.toInt() ?? 0} seconds',
      LevelObjectiveType.countdownComplete =>
        'Complete the objective before time runs out',
      LevelObjectiveType.defeatBoss => 'Defeat the boss and all baby spiders',
      LevelObjectiveType.defendBase =>
        'Defend the base until the timer runs out',
    };
  }
}

class StarRequirements {
  const StarRequirements({
    required this.oneStarScore,
    required this.twoStarScore,
    required this.threeStarScore,
  });

  final int oneStarScore;
  final int twoStarScore;
  final int threeStarScore;

  int starsForScore(int score) {
    if (score >= threeStarScore) {
      return 3;
    }
    if (score >= twoStarScore) {
      return 2;
    }
    if (score >= oneStarScore) {
      return 1;
    }
    return 0;
  }

  int starsForCompletion({
    required int score,
    required LevelObjectiveType objectiveType,
    int? livesRemaining,
    int? maxLives,
  }) {
    if (objectiveType == LevelObjectiveType.defendBase &&
        livesRemaining != null &&
        maxLives != null &&
        maxLives > 0) {
      if (livesRemaining >= maxLives) {
        return 3;
      }
      if (livesRemaining >= (maxLives * 0.7).ceil()) {
        return 2;
      }
      if (livesRemaining > 0) {
        return 1;
      }
      return 0;
    }
    return starsForScore(score);
  }
}

class LevelRewards {
  const LevelRewards({this.bonusLives = 0});

  final int bonusLives;
}

class LevelDefinition {
  const LevelDefinition({
    required this.worldId,
    required this.levelId,
    required this.levelInWorld,
    required this.name,
    required this.objective,
    required this.enemyTypes,
    required this.spawnInterval,
    required this.antSpeedMin,
    required this.antSpeedMax,
    required this.beeSpawnChance,
    required this.maxSimultaneousEnemies,
    required this.lives,
    required this.starRequirements,
    this.rewards = const LevelRewards(),
    this.countdownSeconds,
    this.isBossLevel = false,
  });

  final int worldId;
  final int levelId;
  final int levelInWorld;
  final String name;
  final LevelObjective objective;
  final List<EnemyType> enemyTypes;
  final double spawnInterval;
  final double antSpeedMin;
  final double antSpeedMax;
  final double beeSpawnChance;
  final int maxSimultaneousEnemies;
  final int lives;
  final StarRequirements starRequirements;
  final LevelRewards rewards;
  final double? countdownSeconds;
  final bool isBossLevel;
}

class WorldDefinition {
  const WorldDefinition({
    required this.id,
    required this.name,
    required this.theme,
    required this.backgroundColor,
    required this.accentColor,
    required this.surfaceColor,
    required this.musicTrackId,
    required this.firstLevel,
    required this.lastLevel,
    required this.description,
  });

  final int id;
  final String name;
  final String theme;
  final Color backgroundColor;
  final Color accentColor;
  final Color surfaceColor;
  final String musicTrackId;
  final int firstLevel;
  final int lastLevel;
  final String description;

  bool containsLevel(int levelId) =>
      levelId >= firstLevel && levelId <= lastLevel;
}

class LevelResult {
  const LevelResult({
    required this.levelId,
    required this.score,
    required this.completionTimeSeconds,
    required this.stars,
    required this.isNewBest,
    required this.previousBestScore,
    required this.isNewBestTime,
    required this.previousBestTime,
    required this.smashCount,
    required this.antsEliminated,
    required this.beesEliminated,
  });

  final int levelId;
  final int score;
  final double completionTimeSeconds;
  final int stars;
  final bool isNewBest;
  final int previousBestScore;
  final bool isNewBestTime;
  final double? previousBestTime;
  final int smashCount;
  final int antsEliminated;
  final int beesEliminated;
}

class LevelProgressSnapshot {
  const LevelProgressSnapshot({
    required this.highestUnlockedLevel,
    required this.highestUnlockedWorld,
    required this.completedLevels,
    required this.starRatings,
    required this.bestScores,
    required this.bestTimes,
    required this.completionPercentage,
  });

  final int highestUnlockedLevel;
  final int highestUnlockedWorld;
  final Set<int> completedLevels;
  final Map<int, int> starRatings;
  final Map<int, int> bestScores;
  final Map<int, double> bestTimes;
  final double completionPercentage;

  bool isLevelUnlocked(int levelId) => levelId <= highestUnlockedLevel;

  bool isLevelCompleted(int levelId) => completedLevels.contains(levelId);

  bool isWorldUnlocked(int worldId) => worldId <= highestUnlockedWorld;

  int starsFor(int levelId) => starRatings[levelId] ?? 0;

  int bestScoreFor(int levelId) => bestScores[levelId] ?? 0;

  double? bestTimeFor(int levelId) => bestTimes[levelId];
}

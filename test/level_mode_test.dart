import 'package:flutter_test/flutter_test.dart';
import 'package:flame_game/game/level_session.dart';
import 'package:flame_game/level_data/level_catalog.dart';
import 'package:flame_game/level_data/level_blueprints.dart';
import 'package:flame_game/level_data/models/level_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flame_game/services/level_progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LevelCatalog', () {
    test('contains 6 worlds and 60 levels', () {
      expect(LevelCatalog.totalWorlds, 6);
      expect(LevelCatalog.totalLevels, 60);
    });

    test('each world has exactly 10 handcrafted levels', () {
      for (var worldId = 1; worldId <= 6; worldId++) {
        final levels = LevelCatalog.levelsForWorld(worldId);
        expect(levels.length, 10);
        expect(LevelBlueprintRegistry.byWorld[worldId]?.length, 10);
      }
    });

    test('level ids map to correct worlds', () {
      expect(LevelCatalog.levelById(1).worldId, 1);
      expect(LevelCatalog.levelById(10).worldId, 1);
      expect(LevelCatalog.levelById(11).worldId, 2);
      expect(LevelCatalog.levelById(60).worldId, 6);
    });

    test('non-boss levels use tower defense objectives', () {
      expect(LevelCatalog.levelById(1).objective.type, LevelObjectiveType.defendBase);
      expect(LevelCatalog.levelById(9).objective.type, LevelObjectiveType.defendBase);
      expect(LevelCatalog.levelById(11).objective.type, LevelObjectiveType.defendBase);
      expect(LevelCatalog.levelById(1).countdownSeconds, 60);
    });

    test('defendBase does not complete early when smashing bugs', () {
      final level = LevelCatalog.levelById(1);
      final session = LevelSession(level)..start();
      session.syncLives(lives: 10, max: 10);

      session.onKitchenEnemyDefeated(1);
      session.checkObjective();

      expect(session.status, LevelSessionStatus.playing);
      expect(session.countdownRemaining, greaterThan(0));

      session.tick(session.countdownRemaining! + 0.1);

      expect(session.status, LevelSessionStatus.won);
      expect(session.countdownRemaining, 0);
    });

    test('star requirements calculate correctly', () {
      final level = LevelCatalog.levelById(1);
      expect(level.objective.type, LevelObjectiveType.defendBase);
      expect(
        level.starRequirements.starsForCompletion(
          score: 0,
          objectiveType: level.objective.type,
          livesRemaining: 10,
          maxLives: 10,
        ),
        3,
      );
      expect(
        level.starRequirements.starsForCompletion(
          score: 0,
          objectiveType: level.objective.type,
          livesRemaining: 7,
          maxLives: 10,
        ),
        2,
      );
      expect(
        level.starRequirements.starsForCompletion(
          score: 0,
          objectiveType: level.objective.type,
          livesRemaining: 1,
          maxLives: 10,
        ),
        1,
      );
    });
  });

  group('LevelProgressService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LevelProgressService.instance.resetForTesting();
    });

    test('level 1 is unlocked by default', () {
      final snapshot = LevelProgressService.instance.snapshot();
      expect(snapshot.highestUnlockedLevel, 1);
      expect(snapshot.isLevelUnlocked(1), isTrue);
      expect(snapshot.isLevelUnlocked(2), isFalse);
    });

    test('completing a level unlocks the next level and world', () async {
      final level10 = LevelCatalog.levelById(10);

      await LevelProgressService.instance.recordCompletion(
        level: level10,
        score: 50,
        completionTimeSeconds: 30,
        smashCount: 22,
        antsEliminated: 20,
        beesEliminated: 2,
      );

      final snapshot = LevelProgressService.instance.snapshot();
      expect(snapshot.isLevelUnlocked(11), isTrue);
      expect(snapshot.isWorldUnlocked(2), isTrue);
      expect(snapshot.isLevelCompleted(10), isTrue);
      expect(snapshot.starsFor(10), greaterThan(0));
    });
  });
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../level_data/level_catalog.dart';
import '../level_data/models/level_models.dart';

class LevelProgressService extends ChangeNotifier {
  LevelProgressService._();

  static final LevelProgressService instance = LevelProgressService._();

  static const _highestUnlockedLevelKey = 'highest_unlocked_level';
  static const _highestUnlockedWorldKey = 'highest_unlocked_world';
  static const _completedLevelsKey = 'completed_levels';
  static const _starRatingsKey = 'star_ratings';
  static const _bestScoresKey = 'best_scores';
  static const _bestTimesKey = 'best_times';

  SharedPreferences? _prefs;
  bool _loaded = false;

  int _highestUnlockedLevel = 1;
  int _highestUnlockedWorld = 1;
  final Set<int> _completedLevels = {};
  final Map<int, int> _starRatings = {};
  final Map<int, int> _bestScores = {};
  final Map<int, double> _bestTimes = {};

  bool get isLoaded => _loaded;
  int get highestUnlockedLevel => _highestUnlockedLevel;
  int get highestUnlockedWorld => _highestUnlockedWorld;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();

    _highestUnlockedLevel = _prefs!.getInt(_highestUnlockedLevelKey) ?? 1;
    _highestUnlockedWorld = _prefs!.getInt(_highestUnlockedWorldKey) ?? 1;

    final completed = _prefs!.getStringList(_completedLevelsKey) ?? [];
    _completedLevels
      ..clear()
      ..addAll(completed.map(int.parse));

    _starRatings
      ..clear()
      ..addAll(_decodeIntMap(_prefs!.getString(_starRatingsKey)));

    _bestScores
      ..clear()
      ..addAll(_decodeIntMap(_prefs!.getString(_bestScoresKey)));

    _bestTimes
      ..clear()
      ..addAll(_decodeDoubleMap(_prefs!.getString(_bestTimesKey)));

    _loaded = true;
    notifyListeners();
  }

  LevelProgressSnapshot snapshot() {
    return LevelProgressSnapshot(
      highestUnlockedLevel: _highestUnlockedLevel,
      highestUnlockedWorld: _highestUnlockedWorld,
      completedLevels: Set.unmodifiable(_completedLevels),
      starRatings: Map.unmodifiable(_starRatings),
      bestScores: Map.unmodifiable(_bestScores),
      bestTimes: Map.unmodifiable(_bestTimes),
      completionPercentage: _completionPercentage(),
    );
  }

  bool isLevelUnlocked(int levelId) => levelId <= _highestUnlockedLevel;

  bool isLevelCompleted(int levelId) => _completedLevels.contains(levelId);

  bool isWorldUnlocked(int worldId) => worldId <= _highestUnlockedWorld;

  int starsFor(int levelId) => _starRatings[levelId] ?? 0;

  int bestScoreFor(int levelId) => _bestScores[levelId] ?? 0;

  double? bestTimeFor(int levelId) => _bestTimes[levelId];

  Future<LevelResult> recordCompletion({
    required LevelDefinition level,
    required int score,
    required double completionTimeSeconds,
    required int smashCount,
    required int antsEliminated,
    required int beesEliminated,
    int? livesRemaining,
    int? maxLives,
  }) async {
    await _ensureLoaded();

    final stars = level.starRequirements.starsForCompletion(
      score: score,
      objectiveType: level.objective.type,
      livesRemaining: livesRemaining,
      maxLives: maxLives,
    );
    final previousBest = _bestScores[level.levelId] ?? 0;
    final isNewBest = score > previousBest;
    final previousTime = _bestTimes[level.levelId];
    final isNewBestTime =
        previousTime == null || completionTimeSeconds < previousTime;

    if (isNewBest) {
      _bestScores[level.levelId] = score;
    }

    if (isNewBestTime) {
      _bestTimes[level.levelId] = completionTimeSeconds;
    }

    final previousStars = _starRatings[level.levelId] ?? 0;
    if (stars > previousStars) {
      _starRatings[level.levelId] = stars;
    }

    _completedLevels.add(level.levelId);

    if (level.levelId >= _highestUnlockedLevel &&
        level.levelId < LevelCatalog.totalLevels) {
      _highestUnlockedLevel = level.levelId + 1;
      final nextWorld = LevelCatalog.worldForLevel(_highestUnlockedLevel);
      if (nextWorld.id > _highestUnlockedWorld) {
        _highestUnlockedWorld = nextWorld.id;
      }
    }

    await _persist();
    notifyListeners();

    return LevelResult(
      levelId: level.levelId,
      score: score,
      completionTimeSeconds: completionTimeSeconds,
      stars: stars,
      isNewBest: isNewBest,
      previousBestScore: previousBest,
      isNewBestTime: isNewBestTime,
      previousBestTime: previousTime,
      smashCount: smashCount,
      antsEliminated: antsEliminated,
      beesEliminated: beesEliminated,
    );
  }

  Future<void> _persist() async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }

    await prefs.setInt(_highestUnlockedLevelKey, _highestUnlockedLevel);
    await prefs.setInt(_highestUnlockedWorldKey, _highestUnlockedWorld);
    await prefs.setStringList(
      _completedLevelsKey,
      _completedLevels.map((level) => level.toString()).toList(),
    );
    await prefs.setString(
      _starRatingsKey,
      jsonEncode(_starRatings.map((k, v) => MapEntry(k.toString(), v))),
    );
    await prefs.setString(
      _bestScoresKey,
      jsonEncode(_bestScores.map((k, v) => MapEntry(k.toString(), v))),
    );
    await prefs.setString(
      _bestTimesKey,
      jsonEncode(_bestTimes.map((k, v) => MapEntry(k.toString(), v))),
    );
  }

  Future<void> _ensureLoaded() async {
    if (!_loaded) {
      await load();
    }
  }

  double _completionPercentage() {
    if (LevelCatalog.totalLevels == 0) {
      return 0;
    }
    return (_completedLevels.length / LevelCatalog.totalLevels) * 100;
  }

  Map<int, int> _decodeIntMap(String? raw) {
    if (raw == null || raw.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(int.parse(key), value as int));
  }

  Map<int, double> _decodeDoubleMap(String? raw) {
    if (raw == null || raw.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(int.parse(key), (value as num).toDouble()),
    );
  }

  @visibleForTesting
  Future<void> resetForTesting() async {
    await _ensureLoaded();
    _highestUnlockedLevel = 1;
    _highestUnlockedWorld = 1;
    _completedLevels.clear();
    _starRatings.clear();
    _bestScores.clear();
    _bestTimes.clear();
    await _persist();
    notifyListeners();
  }
}

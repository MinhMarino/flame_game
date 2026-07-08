import '../level_data/models/level_models.dart';

enum LevelSessionStatus { playing, won, lost }

class LevelSession {
  LevelSession(this.level);

  final LevelDefinition level;

  int score = 0;
  int smashCount = 0;
  int antsEliminated = 0;
  int beesEliminated = 0;
  bool bossDefeated = false;
  double elapsedSeconds = 0;
  double? countdownRemaining;
  int livesRemaining = 0;
  int maxLives = 0;
  LevelSessionStatus status = LevelSessionStatus.playing;

  void start() {
    if (level.countdownSeconds != null) {
      countdownRemaining = level.countdownSeconds;
    }
  }

  void syncLives({required int lives, required int max}) {
    livesRemaining = lives;
    maxLives = max;
  }

  void onAntEliminated({required int points}) {
    antsEliminated++;
    smashCount++;
    score += points;
  }

  void onBeeEliminated({required int points}) {
    beesEliminated++;
    smashCount++;
    score += points;
  }

  void onKitchenEnemyDefeated(int points) {
    smashCount++;
    score += points;
  }

  void markBossDefeated() {
    bossDefeated = true;
  }

  void tick(double dt) {
    if (status != LevelSessionStatus.playing) {
      return;
    }

    elapsedSeconds += dt;

    if (countdownRemaining != null) {
      countdownRemaining = countdownRemaining! - dt;
      if (countdownRemaining! <= 0) {
        countdownRemaining = 0;
        if (level.objective.type == LevelObjectiveType.defendBase) {
          status = livesRemaining > 0
              ? LevelSessionStatus.won
              : LevelSessionStatus.lost;
        } else {
          status = _isObjectiveMet()
              ? LevelSessionStatus.won
              : LevelSessionStatus.lost;
        }
        return;
      }
    }

    if (level.objective.type == LevelObjectiveType.surviveTime &&
        _isObjectiveMet()) {
      status = LevelSessionStatus.won;
    }
  }

  void checkObjective() {
    if (status != LevelSessionStatus.playing) {
      return;
    }

    // Tower defense: win only when the countdown ends (handled in tick).
    if (level.objective.type == LevelObjectiveType.defendBase) {
      return;
    }

    if (_isObjectiveMet()) {
      status = LevelSessionStatus.won;
    }
  }

  bool _isObjectiveMet() {
    final objective = level.objective;

    return switch (objective.type) {
      LevelObjectiveType.smashCount =>
        smashCount >= (objective.targetCount ?? 0),
      LevelObjectiveType.targetScore => score >= (objective.targetScore ?? 0),
      LevelObjectiveType.eliminateAnts =>
        antsEliminated >= (objective.targetAnts ?? 0),
      LevelObjectiveType.eliminateBees =>
        beesEliminated >= (objective.targetBees ?? 0),
      LevelObjectiveType.eliminateMixed =>
        antsEliminated >= (objective.targetAnts ?? 0) &&
            beesEliminated >= (objective.targetBees ?? 0),
      LevelObjectiveType.surviveTime =>
        elapsedSeconds >= (objective.surviveSeconds ?? 0),
      LevelObjectiveType.countdownComplete => _countdownObjectiveMet(objective),
      LevelObjectiveType.defeatBoss => bossDefeated,
      LevelObjectiveType.defendBase => false,
    };
  }

  bool _countdownObjectiveMet(LevelObjective objective) {
    if (objective.targetCount != null) {
      return smashCount >= objective.targetCount!;
    }
    if (objective.targetScore != null) {
      return score >= objective.targetScore!;
    }
    if (objective.targetAnts != null && objective.targetBees != null) {
      return antsEliminated >= objective.targetAnts! &&
          beesEliminated >= objective.targetBees!;
    }
    return false;
  }

  String get objectiveProgressText {
    final objective = level.objective;

    return switch (objective.type) {
      LevelObjectiveType.smashCount =>
        'Smashed: $smashCount / ${objective.targetCount}',
      LevelObjectiveType.targetScore =>
        'Score: $score / ${objective.targetScore}',
      LevelObjectiveType.eliminateAnts =>
        'Ants: $antsEliminated / ${objective.targetAnts}',
      LevelObjectiveType.eliminateBees =>
        'Bees: $beesEliminated / ${objective.targetBees}',
      LevelObjectiveType.eliminateMixed =>
        'Ants: $antsEliminated/${objective.targetAnts} Bees: $beesEliminated/${objective.targetBees}',
      LevelObjectiveType.surviveTime =>
        'Survive: ${elapsedSeconds.toInt()}s / ${objective.surviveSeconds?.toInt()}s',
      LevelObjectiveType.countdownComplete =>
        objective.targetCount != null
            ? 'Smashed: $smashCount / ${objective.targetCount}'
            : 'Score: $score / ${objective.targetScore}',
      LevelObjectiveType.defeatBoss =>
        bossDefeated
            ? 'All spiders defeated!'
            : 'Defeat the Giant Spider and baby spiders',
      LevelObjectiveType.defendBase =>
        'Base HP: $livesRemaining / $maxLives',
    };
  }

  String get countdownDisplayText {
    if (countdownRemaining == null) {
      return '';
    }
    final totalSeconds = countdownRemaining!.ceil().clamp(0, 9999);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return '${seconds}s';
  }
}

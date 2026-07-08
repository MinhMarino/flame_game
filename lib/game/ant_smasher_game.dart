import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../enemies/ant_enemy.dart';
import '../enemies/bee_enemy.dart';
import '../enemies/enemy_assets.dart';
import '../enemies/enemy_factory.dart';
import '../enemies/spawned_enemy.dart';
import '../level_data/models/level_models.dart';
import '../level_data/world_registry.dart';
import '../services/audio_manager.dart';
import '../worlds/kitchen/data/kitchen_level_data.dart';
import '../worlds/kitchen/kitchen_gameplay_controller.dart';
import 'components/floating_text.dart';
import 'components/game_over_label.dart';
import 'components/hearts_hud.dart';
import 'level_session.dart';
import 'mixins/pausable_game_mixin.dart';

typedef LevelCompleteCallback = void Function(LevelSession session);
typedef LevelFailedCallback = void Function(LevelSession session);

class AntSmasherGame extends FlameGame
    with TapCallbacks, PausableGameMixin, ChangeNotifier {
  AntSmasherGame({
    Random? random,
    this.level,
    this.onLevelComplete,
    this.onLevelFailed,
  }) : _random = random ?? Random();

  final LevelDefinition? level;
  final LevelCompleteCallback? onLevelComplete;
  final LevelFailedCallback? onLevelFailed;

  static const int endlessMaxLives = 10;

  final Random _random;
  late final EnemyFactory _enemyFactory;
  late final SpriteAnimation _antWalkAnimation;
  late final SpriteAnimation _beeFlyAnimation;
  late final TextComponent _scoreText;
  late final TextComponent _hintText;
  late final GameOverLabel _gameOverText;
  late final HeartsHud _heartsHud;

  KitchenGameplayController? _kitchenController;
  LevelSession? _levelSession;
  int _maxLives = endlessMaxLives;
  int _score = 0;
  int _lives = endlessMaxLives;
  double _spawnTimer = 0;
  double _spawnInterval = 1.6;
  double _gameTime = 0;
  bool _gameOver = false;
  bool _levelEnded = false;

  bool get isLevelMode => level != null;
  bool get isKitchenWorld => level?.worldId == 1;
  KitchenGameplayController? get kitchenController => _kitchenController;
  LevelSession? get levelSession => _levelSession;
  int get score => _score;
  int get lives => _lives;
  bool get isGameOver => _gameOver;
  bool get isLevelEnded => _levelEnded;

  EnemyFactory get enemyFactory => _enemyFactory;

  Iterable<SpawnedEnemy> get spawnedEnemies =>
      children.whereType<SpawnedEnemy>();

  @override
  bool get canPause => !_gameOver && !_levelEnded;

  @override
  void pauseGame() {
    super.pauseGame();
    notifyListeners();
  }

  @override
  void resumeGame() {
    super.resumeGame();
    notifyListeners();
  }

  @override
  Color backgroundColor() {
    if (isKitchenWorld) {
      return const Color(0xFFD8D8D8);
    }
    if (level != null) {
      return WorldRegistry.forLevel(level!.levelId).backgroundColor;
    }
    return const Color(0xFFD8D8D8);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    if (level != null) {
      _maxLives = level!.lives;
      _lives = level!.lives;
      _spawnInterval = level!.spawnInterval;
      _levelSession = LevelSession(level!)..start();
      _levelSession!.syncLives(lives: _lives, max: _maxLives);
    }

    await images.loadAll([
      'ant_walk_sheet.png',
      'bee_fly_sheet.png',
      'ant_smashed.png',
    ]);

    _antWalkAnimation = _loadWalkAnimation('ant_walk_sheet.png');
    _beeFlyAnimation = _loadWalkAnimation('bee_fly_sheet.png');

    _enemyFactory = EnemyFactory(
      game: this,
      random: _random,
      antWalkAnimation: _antWalkAnimation,
      beeFlyAnimation: _beeFlyAnimation,
    );

    if (isKitchenWorld && level != null && _levelSession != null) {
      final kitchenConfig = KitchenLevelData.forLevel(level!.levelInWorld);
      _kitchenController = KitchenGameplayController(
        game: this,
        config: kitchenConfig,
        random: _random,
        session: _levelSession!,
        enemyFactory: _enemyFactory,
      );
      _kitchenController!.onLoad();
    }

    _heartsHud = HeartsHud(
      maxLives: _maxLives,
      lives: _lives,
      position: Vector2(16, 16),
    );

    _scoreText = TextComponent(
      text: level?.objective.type == LevelObjectiveType.defendBase
          ? '60s'
          : 'Score: 0',
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 20),
      priority: 10,
      textRenderer: TextPaint(
        style: TextStyle(
          color: const Color(0xFF1F2937),
          fontSize: level?.objective.type == LevelObjectiveType.defendBase
              ? 34
              : 26,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    _hintText = TextComponent(
      text: _initialHintText(),
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 52),
      priority: 10,
      textRenderer: TextPaint(
        style: TextStyle(
          color: const Color(0xFF1F2937).withValues(alpha: 0.75),
          fontSize: 15,
        ),
      ),
    );

    _gameOverText = GameOverLabel(position: size / 2);

    addAll([_heartsHud, _scoreText, _hintText, _gameOverText]);
  }

  String _initialHintText() {
    if (level != null) {
      return level!.objective.displayText;
    }
    return 'Tap to smash! 10 hearts = 10 lives';
  }

  SpriteAnimation _loadWalkAnimation(String asset) {
    final sheet = images.fromCache(asset);
    return SpriteAnimation.fromFrameData(
      sheet,
      SpriteAnimationData.sequenced(
        amount: EnemyAssets.frameCount,
        stepTime: 0.07,
        textureSize: Vector2(EnemyAssets.frameSize, EnemyAssets.frameSize),
      ),
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!isLoaded) {
      return;
    }
    _scoreText.position = Vector2(size.x / 2, 20);
    _hintText.position = Vector2(size.x / 2, 52);
    _gameOverText.position = size / 2;
    _kitchenController?.onGameResize();
  }

  @override
  void render(Canvas canvas) {
    if (_kitchenController != null &&
        _kitchenController!.shakeOffset != Vector2.zero()) {
      canvas.save();
      canvas.translate(
        _kitchenController!.shakeOffset.x,
        _kitchenController!.shakeOffset.y,
      );
      super.render(canvas);
      canvas.restore();
      return;
    }
    super.render(canvas);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_gameOver || _levelEnded) {
      return;
    }

    _gameTime += dt;
    _levelSession?.syncLives(lives: _lives, max: _maxLives);
    _levelSession?.tick(dt);

    if (_levelSession != null) {
      _score = _levelSession!.score;
      _updateLevelHud();

      if (_levelSession!.status == LevelSessionStatus.won) {
        _completeLevel();
        return;
      }
      if (_levelSession!.status == LevelSessionStatus.lost) {
        _failLevel();
        return;
      }
    }

    if (isKitchenWorld && _kitchenController != null) {
      _kitchenController!.update(dt);
      return;
    }

    _spawnTimer += dt;

    if (!isLevelMode) {
      _spawnInterval = max(0.55, 1.6 - (_gameTime * 0.015));
    }

    if (_spawnTimer >= _spawnInterval && _canSpawnMore()) {
      _spawnTimer = 0;
      _spawnEnemy();
    }
  }

  void _updateLevelHud() {
    final session = _levelSession!;
    final isDefend = session.level.objective.type == LevelObjectiveType.defendBase;

    if (isDefend) {
      _scoreText.text = session.countdownDisplayText;
      _hintText.text = session.objectiveProgressText;
      return;
    }

    _scoreText.text = 'Score: $_score';
    _hintText.text = _buildLevelHudText();
  }

  String _buildLevelHudText() {
    final session = _levelSession!;
    final buffer = StringBuffer(session.objectiveProgressText);

    if (session.countdownRemaining != null) {
      buffer.write(' | Time: ${session.countdownDisplayText}');
    }

    return buffer.toString();
  }

  bool _canSpawnMore() {
    if (size.x <= 0 || size.y <= 0) {
      return false;
    }

    final activeEnemies =
        children.where((c) => c is AntEnemy || c is BeeEnemy).length;
    if (isLevelMode) {
      return activeEnemies < level!.maxSimultaneousEnemies;
    }
    return true;
  }

  void _spawnEnemy() {
    if (isLevelMode) {
      _spawnLevelEnemy();
      return;
    }

    final spawnBee = _random.nextDouble() < min(0.22, 0.08 + _gameTime * 0.004);
    if (spawnBee) {
      _spawnBee(isBoss: false);
    } else {
      _spawnAnt();
    }
  }

  void _spawnLevelEnemy() {
    final config = level!;
    final roll = _random.nextDouble();
    final hasBoss = config.enemyTypes.contains(EnemyType.boss);
    final hasBee = config.enemyTypes.contains(EnemyType.bee);

    if (hasBoss && roll < 0.08) {
      _spawnBossBee();
    } else if (hasBee && roll < config.beeSpawnChance) {
      _spawnBee(isBoss: false);
    } else {
      _spawnAnt(speedMin: config.antSpeedMin, speedMax: config.antSpeedMax);
    }
  }

  void _spawnAnt({double? speedMin, double? speedMax}) {
    final minSpeed = speedMin ?? (140 + _gameTime * 0.6);
    final maxSpeed = speedMax ?? (200 + _gameTime * 0.6);
    final speed = minSpeed + _random.nextDouble() * (maxSpeed - minSpeed);
    final antSize = EnemyAssets.antDisplaySize();

    add(
      _enemyFactory.createAnt(
        speed: speed,
        startPosition: Vector2(
          _random.nextDouble() * size.x,
          -antSize * 0.5,
        ),
      ),
    );
  }

  void _spawnBee({required bool isBoss}) {
    final startX = _random.nextDouble() * size.x;
    final speedMultiplier = isBoss ? 1.5 : 1.0;

    add(
      _enemyFactory.createBee(
        isBoss: isBoss,
        startPosition: Vector2(startX, 0),
        speedMultiplier: speedMultiplier,
      ),
    );
  }

  void _spawnBossBee() => _spawnBee(isBoss: true);

  void onSpawnedEnemyDefeated(SpawnedEnemy enemy, {bool skipScore = false}) {
    if (enemy is AntEnemy) {
      return;
    }

    _kitchenController?.onEnemyDefeated(enemy, skipScore: skipScore);
    add(
      FloatingText(
        text: '+${enemy.stats.scoreValue}',
        position: (enemy as PositionComponent).position.clone(),
      ),
    );
    notifyListeners();
  }

  void onSpawnedEnemyEscaped(SpawnedEnemy enemy) {
    if (enemy is AntEnemy) {
      return;
    }

    _kitchenController?.onEnemyEscaped(enemy);
  }

  /// Unified ant hit handling used by every game mode.
  void registerAntHit(AntEnemy ant) {
    registerHit(ant);
  }

  /// Unified ant escape handling used by every game mode.
  void onAntEscaped(AntEnemy ant) {
    onCrawlerEscaped(ant);
  }

  void onCrawlerEscaped(PositionComponent crawler) {
    if (_gameOver || _levelEnded) {
      return;
    }

    _lives--;
    _heartsHud.lives = _lives;
    _levelSession?.syncLives(lives: _lives, max: _maxLives);

    if (_lives <= 0) {
      if (isLevelMode) {
        _failLevel();
      } else {
        _triggerGameOver();
      }
    }
  }

  void registerHit(PositionComponent crawler) {
    if (_gameOver || _levelEnded) {
      return;
    }

    final points = switch (crawler) {
      AntEnemy ant => ant.points,
      BeeEnemy bee => bee.isBoss ? 5 : 3,
      _ => 0,
    };

    _score += points;
    _scoreText.text = 'Score: $_score';

    if (crawler is AntEnemy) {
      _levelSession?.onAntEliminated(points: points);
    } else if (crawler is BeeEnemy) {
      _levelSession?.onBeeEliminated(points: points);
    }

    _levelSession?.checkObjective();

    add(FloatingText(text: '+$points', position: crawler.position.clone()));

    notifyListeners();
  }

  void triggerScreenShake() {
    _kitchenController?.triggerScreenShake();
  }

  void playBossHitFeedback() {
    AudioManager.instance.playSfx('boss_hit');
  }

  void playSmashSound() {
    AudioManager.instance.playSfx('smash');
  }

  void _completeLevel() {
    if (_levelEnded) {
      return;
    }

    _levelEnded = true;
    _clearEnemies();
    onLevelComplete?.call(_levelSession!);
    notifyListeners();
  }

  void _failLevel() {
    if (_levelEnded) {
      return;
    }

    if (isPaused) {
      resumeGame();
    }

    _levelEnded = true;
    _gameOver = true;
    _clearEnemies();
    onLevelFailed?.call(_levelSession!);
    notifyListeners();
  }

  void _triggerGameOver() {
    if (isPaused) {
      resumeGame();
    }

    _gameOver = true;
    _gameOverText.isVisible = true;
    _hintText.text = 'Final score: $_score';
    _clearEnemies();
    notifyListeners();
  }

  void _clearEnemies() {
    for (final enemy
        in children.where((c) => c is SpawnedEnemy || c is BeeEnemy).toList()) {
      enemy.removeFromParent();
    }
  }

  void restartGame() {
    _score = 0;
    _lives = _maxLives;
    _gameTime = 0;
    _spawnTimer = 0;
    _spawnInterval = isLevelMode ? level!.spawnInterval : 1.6;
    _gameOver = false;
    _levelEnded = false;

    if (level != null) {
      _levelSession = LevelSession(level!)..start();
      _levelSession!.syncLives(lives: _lives, max: _maxLives);
      if (_kitchenController != null) {
        _kitchenController!.session = _levelSession!;
        _kitchenController!.restart();
      }
    }

    _updateLevelHud();
    _heartsHud.lives = _lives;
    _gameOverText.isVisible = false;
    _clearEnemies();
    notifyListeners();
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isPaused) {
      return;
    }

    if (isKitchenWorld) {
      _kitchenController?.handleNearMiss(event.localPosition);
      return;
    }

    if (isLevelMode) {
      return;
    }

    if (_gameOver) {
      restartGame();
    }
  }
}

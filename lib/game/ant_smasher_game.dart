import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'components/ant.dart';
import 'components/bee.dart';
import 'components/floating_text.dart';
import 'components/game_over_label.dart';
import 'components/hearts_hud.dart';

class AntSmasherGame extends FlameGame with TapCallbacks {
  AntSmasherGame({Random? random}) : _random = random ?? Random();

  static const int _frameCount = 16;
  static const double _frameSize = 313;
  static const int maxLives = 10;

  final Random _random;
  late final SpriteAnimation _antWalkAnimation;
  late final SpriteAnimation _beeFlyAnimation;
  late final TextComponent _scoreText;
  late final TextComponent _hintText;
  late final GameOverLabel _gameOverText;
  late final HeartsHud _heartsHud;

  int _score = 0;
  int _lives = maxLives;
  double _spawnTimer = 0;
  double _spawnInterval = 1.6;
  double _gameTime = 0;
  bool _gameOver = false;

  int get score => _score;
  int get lives => _lives;
  bool get isGameOver => _gameOver;

  @override
  Color backgroundColor() => const Color(0xFFD8D8D8);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await images.loadAll(['ant_walk_sheet.png', 'bee_fly_sheet.png']);

    _antWalkAnimation = _loadWalkAnimation('ant_walk_sheet.png');
    _beeFlyAnimation = _loadWalkAnimation('bee_fly_sheet.png');

    _heartsHud = HeartsHud(
      maxLives: maxLives,
      lives: _lives,
      position: Vector2(16, 16),
    );

    _scoreText = TextComponent(
      text: 'Score: 0',
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 20),
      priority: 10,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF1F2937),
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    _hintText = TextComponent(
      text: 'Tap to smash! 10 hearts = 10 lives',
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

  SpriteAnimation _loadWalkAnimation(String asset) {
    final sheet = images.fromCache(asset);
    return SpriteAnimation.fromFrameData(
      sheet,
      SpriteAnimationData.sequenced(
        amount: _frameCount,
        stepTime: 0.07,
        textureSize: Vector2(_frameSize, _frameSize),
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
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_gameOver) {
      return;
    }

    _gameTime += dt;
    _spawnTimer += dt;

    _spawnInterval = max(0.55, 1.6 - (_gameTime * 0.015));

    if (_spawnTimer >= _spawnInterval) {
      _spawnTimer = 0;
      _spawnEnemy();
    }
  }

  void _spawnEnemy() {
    if (size.x <= 0 || size.y <= 0) {
      return;
    }

    final spawnBee = _random.nextDouble() < min(0.22, 0.08 + _gameTime * 0.004);

    if (spawnBee) {
      _spawnBee();
    } else {
      _spawnAnt();
    }
  }

  void _spawnAnt() {
    const antScale = 0.42;
    final speed = 70 + _random.nextDouble() * 40 + _gameTime * 0.35;

    add(
      Ant(
          animation: _antWalkAnimation.clone(),
          speed: speed,
          displaySize: Vector2.all(_frameSize * antScale),
        )
        ..position = Vector2(
          _random.nextDouble() * size.x,
          -_frameSize * antScale * 0.5,
        ),
    );
  }

  void _spawnBee() {
    const beeScale = 0.45;
    final startX = _random.nextDouble() * size.x;

    add(
      Bee(
        animation: _beeFlyAnimation.clone(),
        orbitCenter: Vector2(startX, -40),
        orbitRadius: 28 + _random.nextDouble() * 24,
        angularSpeed: 2.2 + _random.nextDouble() * 1.4,
        driftSpeed: 28 + _random.nextDouble() * 18,
        displaySize: Vector2.all(_frameSize * beeScale),
        initialOrbitAngle: _random.nextDouble() * pi * 2,
      ),
    );
  }

  void onCrawlerEscaped(PositionComponent crawler) {
    if (_gameOver) {
      return;
    }

    _lives--;
    _heartsHud.lives = _lives;

    if (_lives <= 0) {
      _triggerGameOver();
    }
  }

  void registerHit(PositionComponent crawler) {
    if (_gameOver) {
      return;
    }

    final points = switch (crawler) {
      Ant _ => 1,
      Bee _ => 3,
      _ => 0,
    };

    _score += points;
    _scoreText.text = 'Score: $_score';

    add(
      FloatingText(
        text: points > 1 ? '+$points' : '+1',
        position: crawler.position.clone(),
      ),
    );
  }

  void _triggerGameOver() {
    _gameOver = true;
    _gameOverText.isVisible = true;
    _hintText.text = 'Final score: $_score';

    for (final enemy in children.where((c) => c is Ant || c is Bee).toList()) {
      enemy.removeFromParent();
    }
  }

  void restartGame() {
    _score = 0;
    _lives = maxLives;
    _gameTime = 0;
    _spawnTimer = 0;
    _spawnInterval = 1.6;
    _gameOver = false;

    _scoreText.text = 'Score: 0';
    _heartsHud.lives = _lives;
    _hintText.text = 'Tap to smash! 10 hearts = 10 lives';
    _gameOverText.isVisible = false;

    for (final enemy in children.where((c) => c is Ant || c is Bee).toList()) {
      enemy.removeFromParent();
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_gameOver) {
      restartGame();
    }
  }
}

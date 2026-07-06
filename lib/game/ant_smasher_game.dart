import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'components/crawler.dart';
import 'components/floating_text.dart';

class AntSmasherGame extends FlameGame {
  AntSmasherGame({Random? random}) : _random = random ?? Random();

  static const int _frameCount = 16;
  static const double _frameSize = 313;

  final Random _random;
  late final SpriteAnimation _antWalkAnimation;
  late final SpriteAnimation _beeFlyAnimation;
  late final TextComponent _scoreText;
  late final TextComponent _hintText;

  int _score = 0;
  double _spawnTimer = 0;
  double _spawnInterval = 1.6;
  double _gameTime = 0;

  int get score => _score;

  @override
  Color backgroundColor() => const Color(0xFFD8D8D8);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await images.loadAll(['ant_walk_sheet.png', 'bee_fly_sheet.png']);

    _antWalkAnimation = _loadWalkAnimation('ant_walk_sheet.png');
    _beeFlyAnimation = _loadWalkAnimation('bee_fly_sheet.png');

    _scoreText = TextComponent(
      text: 'Score: 0',
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 24),
      priority: 10,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF1F2937),
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    _hintText = TextComponent(
      text: 'Tap the ants before they escape!',
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 62),
      priority: 10,
      textRenderer: TextPaint(
        style: TextStyle(
          color: const Color(0xFF1F2937).withValues(alpha: 0.75),
          fontSize: 16,
        ),
      ),
    );

    addAll([_scoreText, _hintText]);
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
    _scoreText.position = Vector2(size.x / 2, 24);
    _hintText.position = Vector2(size.x / 2, 62);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _gameTime += dt;
    _spawnTimer += dt;

    _spawnInterval = max(0.55, 1.6 - (_gameTime * 0.015));

    if (_spawnTimer >= _spawnInterval) {
      _spawnTimer = 0;
      _spawnCrawler();
    }
  }

  void _spawnCrawler() {
    if (size.x <= 0 || size.y <= 0) {
      return;
    }

    final spawnBee = _random.nextDouble() < min(0.22, 0.08 + _gameTime * 0.004);
    final animation = spawnBee ? _beeFlyAnimation.clone() : _antWalkAnimation.clone();
    final speed = spawnBee
        ? 95 + _random.nextDouble() * 45
        : 55 + _random.nextDouble() * 35 + _gameTime * 0.4;
    final points = spawnBee ? 3 : 1;
    final scale = spawnBee ? 0.78 : 0.72;

    final start = _randomEdgePosition();
    final target = _randomInteriorPosition();
    final direction = (target - start).normalized();
    if (direction.length2 == 0) {
      return;
    }

    add(
      Crawler(
        animation: animation,
        velocity: direction * speed,
        points: points,
        displaySize: Vector2.all(_frameSize * scale),
      )..position = start,
    );
  }

  Vector2 _randomEdgePosition() {
    final edge = _random.nextInt(4);
    final padding = 40.0;

    return switch (edge) {
      0 => Vector2(_random.nextDouble() * size.x, -padding),
      1 => Vector2(size.x + padding, _random.nextDouble() * size.y),
      2 => Vector2(_random.nextDouble() * size.x, size.y + padding),
      _ => Vector2(-padding, _random.nextDouble() * size.y),
    };
  }

  Vector2 _randomInteriorPosition() {
    return Vector2(
      size.x * (0.15 + _random.nextDouble() * 0.7),
      size.y * (0.2 + _random.nextDouble() * 0.65),
    );
  }

  void registerHit(Crawler crawler) {
    _score += crawler.points;
    _scoreText.text = 'Score: $_score';

    add(
      FloatingText(
        text: crawler.points > 1 ? '+${crawler.points}' : '+1',
        position: crawler.position.clone(),
      ),
    );
  }
}

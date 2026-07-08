import 'package:flame/game.dart';

import '../../services/audio_manager.dart';

/// Shared pause/resume behavior for Endless Mode and Level Mode games.
mixin PausableGameMixin on FlameGame {
  bool _isPaused = false;

  bool get isPaused => _isPaused;

  /// Whether the game can be paused right now (e.g. not during game over).
  bool get canPause => true;

  /// Whether gameplay taps and interactions should be processed.
  bool get acceptsGameplayInput => !isPaused;

  void pauseGame() {
    if (_isPaused || !canPause) {
      return;
    }

    _isPaused = true;
    pauseEngine();
    overlays.add('pause');
    AudioManager.instance.pauseMusic();
  }

  void resumeGame() {
    if (!_isPaused) {
      return;
    }

    _isPaused = false;
    resumeEngine();
    overlays.remove('pause');
    AudioManager.instance.resumeMusic();
  }

  void togglePause() {
    if (_isPaused) {
      resumeGame();
    } else {
      pauseGame();
    }
  }
}

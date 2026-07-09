import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/ant_smasher_game.dart';
import '../game/mixins/pausable_game_mixin.dart';
import '../game/level_session.dart';
import '../level_data/models/level_models.dart';
import '../level_data/world_registry.dart';
import '../services/audio_manager.dart';
import '../services/level_progress_service.dart';
import '../widgets/endless_spawn_test_bar.dart';
import '../widgets/pause_menu_overlay.dart';
import '../widgets/swatter_toggle_button.dart';
import 'home_screen.dart';
import 'level_complete_screen.dart';
import 'level_failed_screen.dart';

enum GameMode { endless, level }

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key, this.mode = GameMode.endless, this.level})
    : assert(
        mode != GameMode.level || level != null,
        'Level mode requires a level definition.',
      );

  final GameMode mode;
  final LevelDefinition? level;

  bool get isLevelMode => level != null;

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen>
    with WidgetsBindingObserver {
  late final AntSmasherGame _game;
  bool _navigatedAway = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _game = AntSmasherGame(
      level: widget.level,
      onLevelComplete: _onLevelComplete,
      onLevelFailed: _onLevelFailed,
    );

    if (widget.isLevelMode) {
      final world = WorldRegistry.forLevel(widget.level!.levelId);
      AudioManager.instance.startMusic(trackId: world.musicTrackId);
    } else {
      AudioManager.instance.startMusic();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _game.pauseEngine();
    _game.dispose();
    AudioManager.instance.stopMusic();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_game.canPause) {
      return;
    }

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _game.pauseGame();
      case AppLifecycleState.resumed:
        break;
    }
  }

  Future<void> _onLevelComplete(LevelSession session) async {
    if (_navigatedAway || !mounted || widget.level == null) {
      return;
    }
    _navigatedAway = true;

    final result = await LevelProgressService.instance.recordCompletion(
      level: widget.level!,
      score: session.score,
      completionTimeSeconds: session.elapsedSeconds,
      smashCount: session.smashCount,
      antsEliminated: session.antsEliminated,
      beesEliminated: session.beesEliminated,
      livesRemaining: session.livesRemaining,
      maxLives: session.maxLives,
    );

    if (!mounted) {
      return;
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            LevelCompleteScreen(level: widget.level!, result: result),
      ),
    );
  }

  void _onLevelFailed(LevelSession session) {
    if (_navigatedAway || !mounted || widget.level == null) {
      return;
    }
    _navigatedAway = true;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            LevelFailedScreen(level: widget.level!, session: session),
      ),
    );
  }

  void _onRestart() {
    _game.restartGame();
    _game.resumeGame();
  }

  void _onHome() {
    AudioManager.instance.stopMusic();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: Stack(
        children: [
          GameWidget(
            game: _game,
            loadingBuilder: (context) =>
                const Center(child: CircularProgressIndicator()),
            overlayBuilderMap: {
              'pause': (context, game) => PauseMenuOverlay(
                game: game as PausableGameMixin,
                onRestart: _onRestart,
                onHome: _onHome,
              ),
            },
          ),
          Positioned(
            top: topPadding + 8,
            right: 12,
            child: ListenableBuilder(
              listenable: _game,
              builder: (context, _) => PauseButton(
                visible: _game.canPause,
                onPressed: _game.pauseGame,
              ),
            ),
          ),
          if (widget.isLevelMode)
            Positioned(
              top: topPadding + 8,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Lv ${widget.level!.levelId}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (!widget.isLevelMode)
            Positioned(
              top: topPadding + 8,
              left: 12,
              child: EndlessSpawnTestBar(game: _game),
            ),
          if (!widget.isLevelMode)
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: ListenableBuilder(
                  listenable: _game,
                  builder: (context, _) => SwatterToggleButton(
                    enabled: _game.canToggleSwatter,
                    active: _game.swatterEnabled,
                    onPressed: () =>
                        _game.setSwatterEnabled(!_game.swatterEnabled),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

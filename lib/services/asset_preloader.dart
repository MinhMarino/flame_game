import 'package:flame/flame.dart';

import 'audio_manager.dart';

/// Single source of truth for every image asset the game needs, and the
/// entry point for warming up the whole asset pipeline (images + sfx) before
/// gameplay ever starts.
///
/// Assets are decoded into the shared [Flame.images] cache once, up front,
/// on a dedicated loading screen. [AntSmasherGame] no longer has to decode
/// them the first time it loads (or re-decode them every time the player
/// re-enters gameplay), which is what caused the visible hitches/lag.
abstract final class AssetPreloader {
  AssetPreloader._();

  /// Every sprite sheet/image used anywhere in the game.
  static const List<String> images = [
    'ant_walk_sheet.png',
    'bee_fly_sheet.png',
    'bee_smashed.png',
    'ant_smashed.png',
    'fly_swatter.png',
  ];

  static bool _preloaded = false;

  /// True once [preloadAll] has finished successfully at least once.
  static bool get isPreloaded => _preloaded;

  /// Decodes every image and audio asset into their caches.
  ///
  /// Safe to call more than once: after the first successful run this is an
  /// instant no-op, so it can be called both from the dedicated loading
  /// screen (with progress reporting) and defensively from
  /// [AntSmasherGame.onLoad] without ever double-loading.
  static Future<void> preloadAll({
    void Function(double progress)? onProgress,
  }) async {
    if (_preloaded) {
      onProgress?.call(1);
      return;
    }

    final totalSteps = images.length + 1; // +1 for the sfx batch.
    var completedSteps = 0;
    void reportStep() {
      completedSteps++;
      onProgress?.call(completedSteps / totalSteps);
    }

    for (final image in images) {
      await Flame.images.load(image);
      reportStep();
    }

    await AudioManager.instance.preloadSfx();
    reportStep();

    _preloaded = true;
  }
}

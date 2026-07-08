/// Shared sprite sizing used by every enemy in the game.
class EnemyAssets {
  EnemyAssets._();

  static const int frameCount = 16;
  static const double frameSize = 313;

  static const double antDisplayScale = 0.28;

  /// Reduced bee scale for clearer gameplay and easier tapping.
  static const double beeDisplayScale = 0.24;
  static const double bossBeeDisplayScale = 0.32;

  static const int beeFlyFrameCount = 8;
  static const double beeFlapStepTime = 0.055;

  static double antDisplaySize() => frameSize * antDisplayScale;

  static double beeDisplaySize({required bool isBoss}) =>
      frameSize * (isBoss ? bossBeeDisplayScale : beeDisplayScale);
}

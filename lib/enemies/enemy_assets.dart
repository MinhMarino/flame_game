/// Shared sprite sizing used by every enemy in the game.
class EnemyAssets {
  EnemyAssets._();

  static const int frameCount = 16;
  static const double frameSize = 313;

  static const double antDisplayScale = 0.28;

  /// Reduced to ~70% of the previous bee scale (0.45 -> 0.315).
  static const double beeDisplayScale = 0.315;
  static const double bossBeeDisplayScale = 0.42;

  static const int beeFlyFrameCount = 8;
  static const int beeDeathFrameStart = 8;
  static const int beeDeathFrameCount = 8;
  static const double beeFlapStepTime = 0.055;

  static double antDisplaySize() => frameSize * antDisplayScale;

  static double beeDisplaySize({required bool isBoss}) =>
      frameSize * (isBoss ? bossBeeDisplayScale : beeDisplayScale);
}

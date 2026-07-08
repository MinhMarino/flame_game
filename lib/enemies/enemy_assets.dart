/// Shared sprite sizing used by every enemy in the game.
class EnemyAssets {
  EnemyAssets._();

  static const int frameCount = 16;
  static const double frameSize = 313;
  static const double antDisplayScale = 0.28;
  static const double beeDisplayScale = 0.45;
  static const double bossBeeDisplayScale = 0.6;

  static double antDisplaySize() => frameSize * antDisplayScale;
}

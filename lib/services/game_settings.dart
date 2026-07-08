import 'package:flutter/foundation.dart';

/// Global gameplay audio preferences shared across all game modes.
class GameSettings extends ChangeNotifier {
  GameSettings._();

  static final GameSettings instance = GameSettings._();

  bool _musicEnabled = true;
  bool _sfxEnabled = true;

  bool get musicEnabled => _musicEnabled;
  bool get sfxEnabled => _sfxEnabled;

  void setMusicEnabled(bool enabled) {
    if (_musicEnabled == enabled) {
      return;
    }
    _musicEnabled = enabled;
    notifyListeners();
  }

  void setSfxEnabled(bool enabled) {
    if (_sfxEnabled == enabled) {
      return;
    }
    _sfxEnabled = enabled;
    notifyListeners();
  }
}

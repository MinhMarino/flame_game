import 'game_settings.dart';

/// Central audio controller. Pauses and resumes music with the game pause state.
class AudioManager {
  AudioManager._();

  static final AudioManager instance = AudioManager._();

  bool _musicPlaying = false;
  bool _pausedByGame = false;

  bool get isMusicPlaying => _musicPlaying;

  /// Starts background music when assets are available.
  void startMusic({String trackId = 'music_endless'}) {
    if (!GameSettings.instance.musicEnabled) {
      return;
    }
    _musicPlaying = true;
    _currentTrackId = trackId;
  }

  String _currentTrackId = 'music_endless';
  String get currentTrackId => _currentTrackId;

  void stopMusic() {
    _musicPlaying = false;
    _pausedByGame = false;
  }

  void pauseMusic() {
    if (!_musicPlaying) {
      return;
    }
    _pausedByGame = true;
  }

  void resumeMusic() {
    if (!_musicPlaying || !_pausedByGame) {
      return;
    }
    if (!GameSettings.instance.musicEnabled) {
      return;
    }
    _pausedByGame = false;
  }

  void playSfx(String id) {
    if (!GameSettings.instance.sfxEnabled) {
      return;
    }
  }

  void onMusicSettingChanged(bool enabled) {
    if (!enabled) {
      _pausedByGame = _musicPlaying;
      return;
    }
    if (_musicPlaying && !_pausedByGame) {
      resumeMusic();
    }
  }
}

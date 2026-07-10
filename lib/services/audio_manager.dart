import 'dart:async';

import 'package:flame_audio/flame_audio.dart';

import 'game_settings.dart';

/// Central audio controller. Pauses and resumes music with the game pause state.
class AudioManager {
  AudioManager._();

  static final AudioManager instance = AudioManager._();

  /// Maps logical sfx ids to the audio file under `assets/audio/`.
  static const Map<String, String> _sfxFiles = {
    'swing': 'swing_whoosh.mp3',
    'swat_impact': 'swat_impact.mp3',
  };

  /// Preloads every known sfx file so `playSfx` has zero latency on first
  /// use. Safe to call multiple times; failures (e.g. missing asset on a
  /// platform without audio support) are swallowed so gameplay never blocks
  /// on sound.
  Future<void> preloadSfx() async {
    try {
      await FlameAudio.audioCache.loadAll(_sfxFiles.values.toList());
    } catch (_) {
      // Missing/unsupported audio must never break gameplay.
    }
  }

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
    final file = _sfxFiles[id];
    if (file == null) {
      return;
    }
    // Fire-and-forget: never let an audio hiccup interrupt gameplay.
    unawaited(_playSafely(file));
  }

  Future<void> _playSafely(String file) async {
    try {
      await FlameAudio.play(file);
    } catch (_) {
      // Missing/unsupported audio must never break gameplay.
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

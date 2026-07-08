import 'package:flutter/material.dart';

import '../services/audio_manager.dart';
import '../services/game_settings.dart';
import '../game/mixins/pausable_game_mixin.dart';

class PauseMenuOverlay extends StatefulWidget {
  const PauseMenuOverlay({
    super.key,
    required this.game,
    required this.onRestart,
    required this.onHome,
  });

  final PausableGameMixin game;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  @override
  State<PauseMenuOverlay> createState() => _PauseMenuOverlayState();
}

class _PauseMenuOverlayState extends State<PauseMenuOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          color: Colors.black.withValues(alpha: 0.6),
          alignment: Alignment.center,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: _showSettings ? _buildSettingsPanel() : _buildMainMenu(),
          ),
        ),
      ),
    );
  }

  Widget _buildMainMenu() {
    return Container(
      width: 280,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Paused',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _MenuButton(
            label: 'Resume',
            icon: Icons.play_arrow_rounded,
            onPressed: widget.game.resumeGame,
          ),
          const SizedBox(height: 12),
          _MenuButton(
            label: 'Restart',
            icon: Icons.refresh_rounded,
            onPressed: widget.onRestart,
          ),
          const SizedBox(height: 12),
          _MenuButton(
            label: 'Home',
            icon: Icons.home_rounded,
            onPressed: widget.onHome,
          ),
          const SizedBox(height: 12),
          _MenuButton(
            label: 'Settings',
            icon: Icons.settings_rounded,
            onPressed: () => setState(() => _showSettings = true),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return ListenableBuilder(
      listenable: GameSettings.instance,
      builder: (context, _) {
        final settings = GameSettings.instance;
        return Container(
          width: 280,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _SettingsToggle(
                label: 'Music',
                value: settings.musicEnabled,
                onChanged: (value) {
                  settings.setMusicEnabled(value);
                  AudioManager.instance.onMusicSettingChanged(value);
                },
              ),
              const SizedBox(height: 12),
              _SettingsToggle(
                label: 'Sound Effects',
                value: settings.sfxEnabled,
                onChanged: settings.setSfxEnabled,
              ),
              const SizedBox(height: 20),
              _MenuButton(
                label: 'Back',
                icon: Icons.arrow_back_rounded,
                onPressed: () => setState(() => _showSettings = false),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF374151),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }
}

class PauseButton extends StatelessWidget {
  const PauseButton({
    super.key,
    required this.onPressed,
    required this.visible,
  });

  final VoidCallback onPressed;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: const Icon(Icons.pause_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

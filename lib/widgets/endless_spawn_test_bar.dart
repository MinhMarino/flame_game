import 'package:flutter/material.dart';

import '../game/ant_smasher_game.dart';

class EndlessSpawnTestBar extends StatelessWidget {
  const EndlessSpawnTestBar({super.key, required this.game});

  final AntSmasherGame game;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final enabled = game.canSpawnTestEnemies;

        return Row(
          children: [
            _SpawnTestButton(
              label: 'Ant',
              enabled: enabled,
              onPressed: game.spawnTestAnt,
            ),
            const SizedBox(width: 8),
            _SpawnTestButton(
              label: 'Bee',
              enabled: enabled,
              onPressed: () => game.spawnTestBee(),
            ),
            const SizedBox(width: 8),
            _SpawnTestButton(
              label: 'Boss',
              enabled: enabled,
              onPressed: () => game.spawnTestBee(isBoss: true),
            ),
          ],
        );
      },
    );
  }
}

class _SpawnTestButton extends StatelessWidget {
  const _SpawnTestButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: enabled ? 0.5 : 0.25),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: enabled ? 0.3 : 0.12),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: enabled ? 1 : 0.45),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

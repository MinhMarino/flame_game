import 'package:flutter/material.dart';

import '../game/ant_smasher_game.dart';

class EndlessSpawnTestBar extends StatefulWidget {
  const EndlessSpawnTestBar({super.key, required this.game});

  final AntSmasherGame game;

  @override
  State<EndlessSpawnTestBar> createState() => _EndlessSpawnTestBarState();
}

class _EndlessSpawnTestBarState extends State<EndlessSpawnTestBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.game,
      builder: (context, _) {
        final enabled = widget.game.canSelectEndlessEnemyFilter;
        final selected = widget.game.endlessEnemyFilter;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SpawnTestButton(
              label: _expanded ? 'Hide' : 'Spawn',
              enabled: true,
              selected: false,
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
            if (_expanded) ...[
              const SizedBox(width: 6),
              _SpawnTestButton(
                label: 'All',
                enabled: enabled,
                selected: selected == EndlessEnemyFilter.mixed,
                onPressed: () =>
                    widget.game.setEndlessEnemyFilter(EndlessEnemyFilter.mixed),
              ),
              const SizedBox(width: 6),
              _SpawnTestButton(
                label: 'Ant',
                enabled: enabled,
                selected: selected == EndlessEnemyFilter.ant,
                onPressed: () =>
                    widget.game.setEndlessEnemyFilter(EndlessEnemyFilter.ant),
              ),
              const SizedBox(width: 6),
              _SpawnTestButton(
                label: 'Bee',
                enabled: enabled,
                selected: selected == EndlessEnemyFilter.bee,
                onPressed: () =>
                    widget.game.setEndlessEnemyFilter(EndlessEnemyFilter.bee),
              ),
              const SizedBox(width: 6),
              _SpawnTestButton(
                label: 'Boss',
                enabled: enabled,
                selected: selected == EndlessEnemyFilter.boss,
                onPressed: () =>
                    widget.game.setEndlessEnemyFilter(EndlessEnemyFilter.boss),
              ),
            ],
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
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final active = enabled && (selected || label == 'Hide' || label == 'Spawn');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled || label == 'Hide' || label == 'Spawn'
            ? onPressed
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.22)
                : Colors.black.withValues(alpha: active ? 0.45 : 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: active ? 0.25 : 0.1),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: active ? 1 : 0.45),
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

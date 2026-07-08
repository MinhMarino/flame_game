import 'package:flutter/material.dart';

import '../level_data/level_catalog.dart';
import '../level_data/models/level_models.dart';
import '../game/level_session.dart';
import 'gameplay_screen.dart';
import 'home_screen.dart';
import 'level_selection_screen.dart';

class LevelFailedScreen extends StatelessWidget {
  const LevelFailedScreen({
    super.key,
    required this.level,
    required this.session,
  });

  final LevelDefinition level;
  final LevelSession session;

  @override
  Widget build(BuildContext context) {
    final world = LevelCatalog.worldForLevel(level.levelId);

    return Scaffold(
      backgroundColor: const Color(0xFF1F2937),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEF4444), width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.close_rounded,
                    size: 56,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Game Over',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Level ${level.levelId}: ${level.name}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _StatRow(label: 'Score', value: '${session.score}'),
                  _StatRow(
                    label: 'Bugs Smashed',
                    value: '${session.smashCount}',
                  ),
                  const SizedBox(height: 28),
                  _ActionButton(
                    label: 'Retry',
                    color: world.accentColor,
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => GameplayScreen(level: level),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _ActionButton(
                    label: 'Back to Level Selection',
                    color: const Color(0xFF374151),
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute<void>(
                          builder: (_) => const LevelSelectionScreen(),
                        ),
                        (route) => route.isFirst,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _ActionButton(
                    label: 'Home',
                    color: const Color(0xFF4B5563),
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute<void>(
                          builder: (_) => const HomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF9CA3AF))),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

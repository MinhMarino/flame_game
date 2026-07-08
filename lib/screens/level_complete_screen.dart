import 'package:flutter/material.dart';

import '../level_data/level_catalog.dart';
import '../level_data/models/level_models.dart';
import '../services/level_progress_service.dart';
import 'gameplay_screen.dart';
import 'home_screen.dart';
import 'level_selection_screen.dart';

class LevelCompleteScreen extends StatelessWidget {
  const LevelCompleteScreen({
    super.key,
    required this.level,
    required this.result,
  });

  final LevelDefinition level;
  final LevelResult result;

  @override
  Widget build(BuildContext context) {
    final nextLevelId = level.levelId + 1;
    final hasNextLevel = nextLevelId <= LevelCatalog.totalLevels;
    final nextUnlocked = LevelProgressService.instance.isLevelUnlocked(
      nextLevelId,
    );
    final world = LevelCatalog.worldForLevel(level.levelId);

    return Scaffold(
      backgroundColor: world.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    size: 56,
                    color: world.accentColor,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Level Complete!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Level ${level.levelId}: ${level.name}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _StatRow(label: 'Final Score', value: '${result.score}'),
                  _StatRow(
                    label: 'Completion Time',
                    value:
                        '${result.completionTimeSeconds.toStringAsFixed(1)}s',
                  ),
                  _StatRow(
                    label: 'Best Time',
                    value: result.isNewBestTime
                        ? '${result.completionTimeSeconds.toStringAsFixed(1)}s (New!)'
                        : result.previousBestTime != null
                        ? '${result.previousBestTime!.toStringAsFixed(1)}s'
                        : '${result.completionTimeSeconds.toStringAsFixed(1)}s',
                  ),
                  _StatRow(
                    label: 'Best Score',
                    value: result.isNewBest
                        ? '${result.score} (New!)'
                        : '${LevelProgressService.instance.bestScoreFor(level.levelId)}',
                  ),
                  const SizedBox(height: 12),
                  _StarRow(stars: result.stars),
                  const SizedBox(height: 28),
                  if (hasNextLevel && nextUnlocked)
                    _ActionButton(
                      label: 'Next Level',
                      color: world.accentColor,
                      onPressed: () {
                        final next = LevelCatalog.levelById(nextLevelId);
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => GameplayScreen(level: next),
                          ),
                        );
                      },
                    ),
                  if (hasNextLevel && nextUnlocked) const SizedBox(height: 10),
                  _ActionButton(
                    label: 'Replay',
                    color: const Color(0xFF374151),
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
                    color: const Color(0xFF4B5563),
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
                    color: const Color(0xFF6B7280),
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
          Text(label, style: const TextStyle(color: Color(0xFF6B7280))),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final filled = index < stars;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 36,
          color: filled ? const Color(0xFFFBBF24) : Colors.grey.shade300,
        );
      }),
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

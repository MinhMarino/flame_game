import 'package:flutter/material.dart';

import '../level_data/level_catalog.dart';
import '../level_data/models/level_models.dart';
import '../services/level_progress_service.dart';
import 'gameplay_screen.dart';

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  final _progress = LevelProgressService.instance;

  @override
  void initState() {
    super.initState();
    _progress.load();
    _progress.addListener(_onProgressChanged);
  }

  @override
  void dispose() {
    _progress.removeListener(_onProgressChanged);
    super.dispose();
  }

  void _onProgressChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _progress.snapshot();

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2937),
        foregroundColor: Colors.white,
        title: const Text('Level Mode'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${snapshot.completionPercentage.toStringAsFixed(0)}% Complete',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: LevelCatalog.totalWorlds,
        itemBuilder: (context, index) {
          final world = LevelCatalog.worlds[index];
          final worldUnlocked = snapshot.isWorldUnlocked(world.id);
          final worldLevels = LevelCatalog.levelsForWorld(world.id);

          return _WorldSection(
            world: world,
            levels: worldLevels,
            snapshot: snapshot,
            worldUnlocked: worldUnlocked,
            onLevelTap: _onLevelTap,
          );
        },
      ),
    );
  }

  void _onLevelTap(LevelDefinition level, bool unlocked) {
    if (!unlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete the previous level to unlock this level.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => GameplayScreen(level: level)),
    );
  }
}

class _WorldSection extends StatelessWidget {
  const _WorldSection({
    required this.world,
    required this.levels,
    required this.snapshot,
    required this.worldUnlocked,
    required this.onLevelTap,
  });

  final WorldDefinition world;
  final List<LevelDefinition> levels;
  final LevelProgressSnapshot snapshot;
  final bool worldUnlocked;
  final void Function(LevelDefinition level, bool unlocked) onLevelTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: worldUnlocked ? world.surfaceColor : Colors.grey.shade800,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: worldUnlocked
                    ? world.accentColor.withValues(alpha: 0.5)
                    : Colors.grey.shade600,
              ),
            ),
            child: Row(
              children: [
                if (!worldUnlocked)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.lock, color: Colors.white54),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'World ${world.id}: ${world.name}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: worldUnlocked
                              ? const Color(0xFF1F2937)
                              : Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        world.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: worldUnlocked
                              ? const Color(0xFF4B5563)
                              : Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: levels.length,
            itemBuilder: (context, index) {
              final level = levels[index];
              final unlocked = snapshot.isLevelUnlocked(level.levelId);
              final completed = snapshot.isLevelCompleted(level.levelId);
              final stars = snapshot.starsFor(level.levelId);
              final bestScore = snapshot.bestScoreFor(level.levelId);

              return _LevelCard(
                level: level,
                world: world,
                unlocked: unlocked && worldUnlocked,
                completed: completed,
                stars: stars,
                bestScore: bestScore,
                onTap: () => onLevelTap(level, unlocked && worldUnlocked),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.world,
    required this.unlocked,
    required this.completed,
    required this.stars,
    required this.bestScore,
    required this.onTap,
  });

  final LevelDefinition level;
  final WorldDefinition world;
  final bool unlocked;
  final bool completed;
  final int stars;
  final int bestScore;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = unlocked ? world.backgroundColor : Colors.grey.shade700;
    final textColor = unlocked ? const Color(0xFF1F2937) : Colors.white38;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: completed
                  ? world.accentColor
                  : unlocked
                  ? world.accentColor.withValues(alpha: 0.3)
                  : Colors.grey.shade600,
              width: completed ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!unlocked)
                const Icon(Icons.lock, size: 18, color: Colors.white38)
              else
                Text(
                  '${level.levelId}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              const SizedBox(height: 4),
              _StarRow(stars: unlocked ? stars : 0),
              if (completed && bestScore > 0) ...[
                const SizedBox(height: 2),
                Text(
                  '$bestScore',
                  style: TextStyle(fontSize: 10, color: textColor),
                ),
              ],
            ],
          ),
        ),
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
          size: 12,
          color: filled ? const Color(0xFFFBBF24) : Colors.grey,
        );
      }),
    );
  }
}

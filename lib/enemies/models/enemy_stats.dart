import 'package:flutter/material.dart';

import 'enemy_kind.dart';

/// Visual state for multi-hit enemies. Replace tint/label with sprites later.
class EnemyVisualStage {
  const EnemyVisualStage({
    required this.tint,
    required this.label,
    this.spriteAsset,
  });

  final Color tint;
  final String label;
  final String? spriteAsset;
}

class EnemyStats {
  const EnemyStats({
    required this.kind,
    required this.displayName,
    required this.maxHp,
    required this.speed,
    required this.scoreValue,
    required this.displayScale,
    required this.boxWidth,
    required this.boxHeight,
    required this.tint,
    this.angrySpeedMultiplier = 1.5,
    this.angryDurationSeconds = 2,
    this.nearMissRadius = 48,
    this.isBoss = false,
    this.damageStages,
  });

  final EnemyKind kind;
  final String displayName;
  final int maxHp;
  final double speed;
  final int scoreValue;
  final double displayScale;
  final double boxWidth;
  final double boxHeight;
  final Color tint;
  final double angrySpeedMultiplier;
  final double angryDurationSeconds;
  final double nearMissRadius;
  final bool isBoss;
  final List<EnemyVisualStage>? damageStages;

  EnemyVisualStage visualForHp(int currentHp) {
    final stages = damageStages;
    if (stages == null || stages.isEmpty) {
      return EnemyVisualStage(tint: tint, label: displayName);
    }
    final index = (maxHp - currentHp).clamp(0, stages.length - 1);
    return stages[index];
  }
}

class EnemySpawnEntry {
  const EnemySpawnEntry({required this.kind, required this.weight});

  final EnemyKind kind;
  final double weight;
}

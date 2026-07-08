import 'package:flutter/material.dart';

import '../models/kitchen_enemy_kind.dart';
import '../models/kitchen_enemy_stats.dart';

/// Configurable enemy stats for World 1. Tune values here — not in gameplay code.
class KitchenEnemyData {
  KitchenEnemyData._();

  static const double baseAntSpeed = 115;

  static const Map<KitchenEnemyKind, KitchenEnemyStats> stats = {
    KitchenEnemyKind.blackAnt: KitchenEnemyStats(
      kind: KitchenEnemyKind.blackAnt,
      displayName: 'Black Ant',
      maxHp: 1,
      speed: baseAntSpeed,
      scoreValue: 1,
      displayScale: 0.28,
      boxWidth: 24,
      boxHeight: 60,
      tint: Color(0xFF000000),
    ),
    KitchenEnemyKind.houseFly: KitchenEnemyStats(
      kind: KitchenEnemyKind.houseFly,
      displayName: 'House Fly',
      maxHp: 1,
      speed: baseAntSpeed * 1.6,
      scoreValue: 2,
      displayScale: 0.24,
      boxWidth: 68,
      boxHeight: 36,
      tint: Color(0xFF6B7280),
    ),
    KitchenEnemyKind.cockroach: KitchenEnemyStats(
      kind: KitchenEnemyKind.cockroach,
      displayName: 'Cockroach',
      maxHp: 3,
      speed: baseAntSpeed * 1.4,
      scoreValue: 3,
      displayScale: 0.32,
      boxWidth: 80,
      boxHeight: 44,
      tint: Color(0xFF78350F),
      angrySpeedMultiplier: 1.5,
      angryDurationSeconds: 2,
      nearMissRadius: 52,
      damageStages: [
        EnemyVisualStage(
          tint: Color(0xFF78350F),
          label: 'Cockroach',
          spriteAsset: 'cockroach_full.png',
        ),
        EnemyVisualStage(
          tint: Color(0xFF92400E),
          label: 'Cockroach (hurt)',
          spriteAsset: 'cockroach_hurt.png',
        ),
        EnemyVisualStage(
          tint: Color(0xFFDC2626),
          label: 'Cockroach (critical)',
          spriteAsset: 'cockroach_critical.png',
        ),
      ],
    ),
    KitchenEnemyKind.smallBeetle: KitchenEnemyStats(
      kind: KitchenEnemyKind.smallBeetle,
      displayName: 'Small Beetle',
      maxHp: 5,
      speed: baseAntSpeed * 0.6,
      scoreValue: 5,
      displayScale: 0.38,
      boxWidth: 88,
      boxHeight: 48,
      tint: Color(0xFF065F46),
    ),
    KitchenEnemyKind.giantSpider: KitchenEnemyStats(
      kind: KitchenEnemyKind.giantSpider,
      displayName: 'Giant Spider',
      maxHp: 25,
      speed: baseAntSpeed * 0.4,
      scoreValue: 10,
      displayScale: 0.72,
      boxWidth: 120,
      boxHeight: 72,
      tint: Color(0xFF7F1D1D),
      isBoss: true,
    ),
    KitchenEnemyKind.babySpider: KitchenEnemyStats(
      kind: KitchenEnemyKind.babySpider,
      displayName: 'Baby Spider',
      maxHp: 1,
      speed: baseAntSpeed * 2.0,
      scoreValue: 2,
      displayScale: 0.18,
      boxWidth: 56,
      boxHeight: 32,
      tint: Color(0xFF991B1B),
    ),
  };

  static KitchenEnemyStats forKind(KitchenEnemyKind kind) => stats[kind]!;

  static const int flySwatterRadius = 120;
  static const int flySwatterBossDamage = 5;
  static const int babySpiderSpawnCount = 14;
}

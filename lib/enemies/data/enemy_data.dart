import 'package:flutter/material.dart';

import '../enemy_assets.dart';
import '../models/enemy_kind.dart';
import '../models/enemy_stats.dart';

/// Configurable enemy stats. Tune values here — not in gameplay code.
class EnemyData {
  EnemyData._();

  static const double baseAntSpeed = 115;
  static const double _antSize =
      EnemyAssets.frameSize * EnemyAssets.antDisplayScale;

  static const Map<EnemyKind, EnemyStats> stats = {
    EnemyKind.blackAnt: EnemyStats(
      kind: EnemyKind.blackAnt,
      displayName: 'Black Ant',
      maxHp: 1,
      speed: baseAntSpeed,
      scoreValue: 1,
      displayScale: EnemyAssets.antDisplayScale,
      boxWidth: _antSize,
      boxHeight: _antSize,
      tint: Color(0xFF000000),
    ),
    EnemyKind.houseFly: EnemyStats(
      kind: EnemyKind.houseFly,
      displayName: 'House Fly',
      maxHp: 1,
      speed: baseAntSpeed * 1.6,
      scoreValue: 2,
      displayScale: 0.24,
      boxWidth: 68,
      boxHeight: 36,
      tint: Color(0xFF6B7280),
    ),
    EnemyKind.cockroach: EnemyStats(
      kind: EnemyKind.cockroach,
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
    EnemyKind.smallBeetle: EnemyStats(
      kind: EnemyKind.smallBeetle,
      displayName: 'Small Beetle',
      maxHp: 5,
      speed: baseAntSpeed * 0.6,
      scoreValue: 5,
      displayScale: 0.38,
      boxWidth: 88,
      boxHeight: 48,
      tint: Color(0xFF065F46),
    ),
    EnemyKind.giantSpider: EnemyStats(
      kind: EnemyKind.giantSpider,
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
    EnemyKind.babySpider: EnemyStats(
      kind: EnemyKind.babySpider,
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

  static EnemyStats forKind(EnemyKind kind) => stats[kind]!;

  static const int flySwatterRadius = 120;
  static const int flySwatterBossDamage = 5;
  static const int babySpiderSpawnCount = 14;
}

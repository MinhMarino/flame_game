import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Bright cartoon kitchen background with wooden table surface.
class KitchenBackground extends Component with HasGameReference {
  KitchenBackground({required this.gameSize});

  Vector2 gameSize;

  @override
  void render(Canvas canvas) {
    final wallRect = Rect.fromLTWH(0, 0, gameSize.x, gameSize.y * 0.55);
    final wallPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFF7ED), Color(0xFFFDE68A)],
      ).createShader(wallRect);
    canvas.drawRect(wallRect, wallPaint);

    final tableRect = Rect.fromLTWH(
      0,
      gameSize.y * 0.55,
      gameSize.x,
      gameSize.y * 0.45,
    );
    final tablePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFD97706), Color(0xFF92400E)],
      ).createShader(tableRect);
    canvas.drawRect(tableRect, tablePaint);

    final linePaint = Paint()
      ..color = const Color(0xFF78350F).withValues(alpha: 0.25)
      ..strokeWidth = 2;
    for (var i = 0; i < 6; i++) {
      final y = gameSize.y * 0.58 + i * (gameSize.y * 0.06);
      canvas.drawLine(Offset(0, y), Offset(gameSize.x, y), linePaint);
    }
  }
}

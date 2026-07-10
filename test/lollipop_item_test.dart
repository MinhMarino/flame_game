import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flame_game/game/ant_smasher_game.dart';
import 'package:flame_game/items/lollipop_item.dart';
import 'package:flame_game/main.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('lollipop decoy can be placed, damaged, and destroyed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FlameGameApp());
    await pumpUntilFound(tester, find.text('Endless Mode'));

    await tester.tap(find.text('Endless Mode'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final gameWidget = tester.widget<GameWidget<AntSmasherGame>>(
      find.byType(GameWidget<AntSmasherGame>),
    );
    final game = gameWidget.game!;

    // Only one Lollipop may be active at a time.
    expect(game.canPlaceLollipop, isTrue);
    expect(game.placeLollipopAt(Vector2(200, 300)), isTrue);
    expect(game.hasActiveLollipop, isTrue);
    expect(game.canPlaceLollipop, isFalse);
    expect(game.placeLollipopAt(Vector2(50, 50)), isFalse);

    final lollipop = game.activeLollipop!;
    expect(lollipop.currentHp, LollipopItem.maxHp);
    expect(lollipop.isAlive, isTrue);

    // 75% HP threshold -> stage 2 sprite.
    lollipop.takeDamage(LollipopItem.maxHp * 0.30);
    expect(lollipop.hpFraction, closeTo(0.70, 0.001));

    // Fully destroy it: HP hits 0 immediately frees up placement again even
    // though the fade-out/pop destroy animation is still playing.
    lollipop.takeDamage(LollipopItem.maxHp);
    expect(lollipop.currentHp, 0);
    expect(lollipop.isAlive, isFalse);
    expect(game.activeLollipop, isNull);
    expect(game.hasActiveLollipop, isFalse);
    expect(game.canPlaceLollipop, isTrue);

    // Let the destroy animation finish; the component removes itself.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(lollipop.isMounted, isFalse);

    // Placement is available again for a brand new decoy.
    expect(game.placeLollipopAt(Vector2(120, 220)), isTrue);
    expect(game.activeLollipop!.currentHp, LollipopItem.maxHp);
  });
}

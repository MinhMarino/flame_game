import 'package:flutter_test/flutter_test.dart';

/// Pumps [tester] until [finder] matches something, or [maxTicks] is
/// exhausted.
///
/// The app's `LoadingScreen` decodes real images/audio via `dart:ui`, which
/// needs a real engine frame to actually deliver each decode result -
/// `pump()`'s fake clock alone never resolves it. Interleaving a short
/// `runAsync` (real time) with a `pump` (fake time) on every tick lets each
/// pending decode complete before moving on to the next one.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxTicks = 30,
  Duration tickDuration = const Duration(milliseconds: 100),
}) async {
  for (var i = 0; i < maxTicks; i++) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.runAsync(() => Future<void>.delayed(tickDuration));
    await tester.pump(tickDuration);
  }
}

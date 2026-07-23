import 'package:balok_kosong/game_engine.dart';
import 'package:balok_kosong/native_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('100-piece board renders and rebuilds within budget', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final pieces = generateLevel(23, 100);
    final engine = PuzzleEngine(pieces);
    final stopwatch = Stopwatch()..start();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PuzzleCanvas(
            engine: engine,
            boardColor: const Color(0xff35215e),
            showGrid: true,
            disabled: false,
            hintedPieceId: pieces.first.id,
            onHintConsumed: () {},
            onExit: (_) {},
            onMove: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    stopwatch.stop();

    expect(tester.takeException(), isNull);
    expect(find.byType(PuzzleCanvas), findsOneWidget);
    expect(
      stopwatch.elapsed,
      lessThan(const Duration(seconds: 3)),
      reason: 'Render 100 balok terlalu lambat: ${stopwatch.elapsed}',
    );
  });
}

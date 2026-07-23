import 'package:balok_kosong/how_to_play.dart';
import 'package:balok_kosong/mode_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tutorial completes and opens mode selection', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => HowToPlayScreen(
            onFinished: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => ModeSelectionScreen(
                    onRelaxed: () {},
                    onChallenge: () {},
                    onCancel: () {},
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('CARA BERMAIN · 1/4'), findsOneWidget);
    for (var page = 1; page < 4; page++) {
      await tester.tap(find.text('Berikutnya'));
      await tester.pumpAndSettle();
      expect(find.text('CARA BERMAIN · ${page + 1}/4'), findsOneWidget);
    }

    await tester.tap(find.text('Mulai bermain'));
    await tester.pumpAndSettle();

    expect(find.text('PILIH MODE'), findsOneWidget);
    expect(find.text('Santai'), findsOneWidget);
    expect(find.text('Tantangan · 1 ⚡'), findsOneWidget);
  });

  testWidgets('tutorial back button returns to prior page', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HowToPlayScreen(onFinished: () {})),
    );

    await tester.tap(find.text('Berikutnya'));
    await tester.pumpAndSettle();
    expect(find.text('CARA BERMAIN · 2/4'), findsOneWidget);

    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('CARA BERMAIN · 1/4'), findsOneWidget);
  });
}

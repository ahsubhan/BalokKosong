import 'package:balok_kosong/how_to_play.dart';
import 'package:balok_kosong/main.dart';
import 'package:balok_kosong/mode_selection.dart';
import 'package:balok_kosong/native_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    await tester.tap(find.text('Lanjut'));
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

  testWidgets('progress buttons start the selected mode and level', (
    tester,
  ) async {
    bool? relaxedFromLevelOne;
    bool? challengeFromLevelOne;
    await tester.pumpWidget(
      MaterialApp(
        home: ModeSelectionScreen(
          hasProgress: true,
          onRelaxed: () {},
          onChallenge: () {},
          onCancel: () {},
          onRelaxedSelected: (value) => relaxedFromLevelOne = value,
          onChallengeSelected: (value) => challengeFromLevelOne = value,
        ),
      ),
    );

    await tester.tap(find.text('Lanjutkan'));
    expect(relaxedFromLevelOne, isFalse);

    await tester.tap(find.text('Tantangan · 1 ⚡'));
    expect(challengeFromLevelOne, isFalse);

    await tester.tap(find.text('Dari Level 1'));
    expect(relaxedFromLevelOne, isTrue);
  });

  testWidgets('fresh player starts by tapping a mode', (tester) async {
    var relaxedStarted = false;
    var challengeStarted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ModeSelectionScreen(
          onRelaxed: () => relaxedStarted = true,
          onChallenge: () => challengeStarted = true,
          onCancel: () {},
          onSettings: () {},
        ),
      ),
    );

    final continueChoice = tester.widget<InkWell>(
      find.ancestor(of: find.text('Lanjutkan'), matching: find.byType(InkWell)),
    );
    final levelOneChoice = tester.widget<InkWell>(
      find.ancestor(
        of: find.text('Dari Level 1'),
        matching: find.byType(InkWell),
      ),
    );
    expect(continueChoice.onTap, isNull);
    expect(levelOneChoice.onTap, isNull);
    expect(find.byTooltip('Pengaturan'), findsOneWidget);

    await tester.tap(find.text('Santai'));
    expect(relaxedStarted, isTrue);

    relaxedStarted = false;
    await tester.tap(find.text('Tantangan · 1 ⚡'));
    expect(challengeStarted, isTrue);
  });

  testWidgets('mode cards immediately start a saved game', (tester) async {
    bool? relaxedFromLevelOne;
    bool? challengeFromLevelOne;
    await tester.pumpWidget(
      MaterialApp(
        home: ModeSelectionScreen(
          hasProgress: true,
          onRelaxed: () {},
          onChallenge: () {},
          onCancel: () {},
          onRelaxedSelected: (value) => relaxedFromLevelOne = value,
          onChallengeSelected: (value) => challengeFromLevelOne = value,
        ),
      ),
    );

    await tester.tap(find.text('Santai'));
    expect(relaxedFromLevelOne, isFalse);

    await tester.tap(find.text('Tantangan · 1 ⚡'));
    expect(challengeFromLevelOne, isFalse);
  });

  testWidgets('main menu opened from settings shows a back button', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: NativeGameScreen(
          settingsOnly: true,
          homeBuilder: (_) => const HomeScreen(showBackButton: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kembali ke halaman utama'));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Kembali'), findsOneWidget);
  });
}

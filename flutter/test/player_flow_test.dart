import 'package:balok_kosong/how_to_play.dart';
import 'package:balok_kosong/main.dart';
import 'package:balok_kosong/mode_selection.dart';
import 'package:balok_kosong/native_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _testHomeBuilder(BuildContext context) => const SizedBox.shrink();

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'BalokKosong',
      packageName: 'id.ahmadss.balokkosong',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  test('new game screen defaults to Level 1 instead of saved progress', () {
    const screen = NativeGameScreen(homeBuilder: _testHomeBuilder);
    expect(screen.startFromLevelOne, isTrue);
  });

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

    expect(find.text('Kembali'), findsOneWidget);
    await tester.tap(find.text('Berikutnya'));
    await tester.pumpAndSettle();
    expect(find.text('CARA BERMAIN · 2/4'), findsOneWidget);

    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('CARA BERMAIN · 1/4'), findsOneWidget);
  });

  testWidgets('progress buttons and mode cards can both start a game', (
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
    expect(challengeFromLevelOne, isTrue);
  });

  testWidgets('fresh player starts by tapping a mode', (tester) async {
    var relaxedStarted = false;
    var challengeStarted = false;
    bool? relaxedFromLevelOne;
    bool? challengeFromLevelOne;
    await tester.pumpWidget(
      MaterialApp(
        home: ModeSelectionScreen(
          onRelaxed: () => relaxedStarted = true,
          onChallenge: () => challengeStarted = true,
          onCancel: () {},
          onSettings: () {},
          onRelaxedSelected: (value) => relaxedFromLevelOne = value,
          onChallengeSelected: (value) => challengeFromLevelOne = value,
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
    expect(relaxedStarted, isFalse);
    expect(relaxedFromLevelOne, isTrue);

    await tester.tap(find.text('Tantangan · 1 ⚡'));
    expect(challengeStarted, isFalse);
    expect(challengeFromLevelOne, isTrue);
  });

  testWidgets('returning player can start from either action group', (
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
    expect(challengeFromLevelOne, isTrue);
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

    expect(find.textContaining('Versi 1.0.0 · Build 1'), findsOneWidget);
    await tester.tap(find.text('Kembali ke halaman utama'));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Kembali'), findsOneWidget);
  });

  testWidgets('game header shows metrics and footer shows controls', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: NativeGameScreen(homeBuilder: (_) => const HomeScreen()),
      ),
    );
    await tester.pump();

    expect(find.byTooltip('Aturan'), findsOneWidget);
    expect(find.text('SCORE'), findsOneWidget);
    expect(find.text('LEVEL'), findsOneWidget);
    expect(find.text('WAKTU'), findsOneWidget);
    expect(find.text('SISA SALAH'), findsOneWidget);
    expect(
      tester.getCenter(find.text('SCORE')).dy,
      lessThan(tester.getCenter(find.byTooltip('Pause')).dy),
    );
    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    expect(find.text('Aturan'), findsNothing);
    expect(find.text('Toko &\nHadiah'), findsOneWidget);
  });

  testWidgets('logout replaces all routes with a fresh sign-in home', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (rootContext) => FilledButton(
            onPressed: () => Navigator.of(rootContext).push(
              MaterialPageRoute(
                builder: (routeContext) => Scaffold(
                  body: FilledButton(
                    onPressed: () => replaceWithSignedOutHome(
                      routeContext,
                      (_) => const HomeScreen(),
                    ),
                    child: const Text('Selesaikan logout'),
                  ),
                ),
              ),
            ),
            child: const Text('Buka sesi akun'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka sesi akun'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selesaikan logout'));
    await tester.pumpAndSettle();

    expect(find.text('MASUK DENGAN GOOGLE'), findsOneWidget);
    expect(find.text('MAIN SEBAGAI TAMU'), findsOneWidget);
    expect(find.byTooltip('Kembali'), findsNothing);
  });
}

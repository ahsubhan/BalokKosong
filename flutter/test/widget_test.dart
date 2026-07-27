import 'package:balok_kosong/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _initializeForTest() async {}

void main() {
  testWidgets('shows the Balok Kosong home screen', (tester) async {
    await tester.pumpWidget(const BalokKosongApp(showSplash: false));

    expect(find.text('BALOK'), findsOneWidget);
    expect(find.text('KOSONG'), findsOneWidget);
    expect(find.text('MASUK DENGAN EMAIL'), findsOneWidget);
    expect(find.text('MASUK DENGAN GOOGLE'), findsOneWidget);
    expect(find.text('MAIN SEBAGAI TAMU'), findsOneWidget);
    expect(find.text('Mendaftar'), findsOneWidget);
    expect(find.textContaining('APPLE'), findsNothing);
    expect(find.textContaining('FACEBOOK'), findsNothing);
    expect(find.byTooltip('Cara bermain'), findsOneWidget);
  });

  testWidgets('home help button opens the four-page guide', (tester) async {
    await tester.pumpWidget(const BalokKosongApp(showSplash: false));

    await tester.tap(find.byTooltip('Cara bermain'));
    await tester.pumpAndSettle();

    expect(find.text('CARA BERMAIN · 1/4'), findsOneWidget);
    expect(find.text('Kosongkan papan'), findsOneWidget);
    expect(find.text('Kembali'), findsOneWidget);
  });

  testWidgets('opens email registration form', (tester) async {
    await tester.pumpWidget(const BalokKosongApp(showSplash: false));

    await tester.tap(find.text('Mendaftar'));
    await tester.pumpAndSettle();

    expect(find.text('MENDAFTAR'), findsOneWidget);
    expect(find.text('Nama'), findsOneWidget);
    expect(find.text('Alamat email'), findsOneWidget);
    expect(find.text('Password (minimal 6 karakter)'), findsOneWidget);
    expect(find.text('KIRIM VERIFIKASI'), findsOneWidget);
    expect(find.textContaining('folder Junk/Spam'), findsOneWidget);
  });

  testWidgets('guest play warns about temporary progress and login bonus', (
    tester,
  ) async {
    await tester.pumpWidget(const BalokKosongApp(showSplash: false));

    await tester.tap(find.text('MAIN SEBAGAI TAMU'));
    await tester.pumpAndSettle();

    expect(find.text('MAIN SEBAGAI TAMU?'), findsOneWidget);
    expect(find.textContaining('dimulai lagi dari Level 1'), findsOneWidget);
    expect(find.textContaining('+3 token awal'), findsOneWidget);
    expect(find.text('LOGIN & DAPATKAN +10 TOKEN'), findsOneWidget);
    expect(find.text('LANJUT'), findsOneWidget);
    expect(find.text('KEMBALI'), findsOneWidget);

    await tester.tap(find.text('KEMBALI'));
    await tester.pumpAndSettle();
    expect(find.text('MAIN SEBAGAI TAMU?'), findsNothing);
    expect(find.text('MAIN SEBAGAI TAMU'), findsOneWidget);
  });

  testWidgets('shows opening animation before the home screen', (tester) async {
    await tester.pumpWidget(
      const BalokKosongApp(startupInitializer: _initializeForTest),
    );

    expect(find.byType(OpeningSplashScreen), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('MASUK DENGAN EMAIL'), findsNothing);

    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pumpAndSettle();

    expect(find.byType(OpeningSplashScreen), findsNothing);
    expect(find.text('MASUK DENGAN EMAIL'), findsOneWidget);
  });

  test('returning player name prefers profile name then email address', () {
    expect(
      returningPlayerName(
        displayName: 'Ahmad Subhan',
        email: 'ah.subhan@gmail.com',
      ),
      'Ahmad Subhan',
    );
    expect(
      returningPlayerName(displayName: ' ', email: 'ah.subhan@gmail.com'),
      'ah.subhan',
    );
  });

  testWidgets('returning player sees a welcome screen briefly', (tester) async {
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ReturningPlayerWelcomeScreen(
          playerName: 'ah.subhan',
          onFinished: () => finished = true,
        ),
      ),
    );

    expect(find.text('Welcome, ah.subhan'), findsOneWidget);
    expect(find.textContaining('Menyiapkan progres'), findsOneWidget);
    expect(finished, isFalse);

    await tester.pump(const Duration(milliseconds: 4100));
    expect(finished, isTrue);
  });

  testWidgets('shows back button when home is opened from settings', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: HomeScreen(showBackButton: true)),
    );

    expect(find.byTooltip('Kembali'), findsOneWidget);
  });

  testWidgets('shows back button when home is pushed from another page', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const HomeScreen())),
            child: const Text('Buka halaman utama'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka halaman utama'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Kembali'), findsOneWidget);
  });

  testWidgets('disables sign-in actions when an account is already active', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: HomeScreen(accountSignedIn: true)),
    );

    for (final label in [
      'MASUK DENGAN EMAIL',
      'MASUK DENGAN GOOGLE',
      'MAIN SEBAGAI TAMU',
    ]) {
      final button = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(button.onPressed, isNull);
    }
  });
}

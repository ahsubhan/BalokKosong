import 'package:balok_kosong/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the Balok Kosong home screen', (tester) async {
    await tester.pumpWidget(const BalokKosongApp());

    expect(find.text('BALOK'), findsOneWidget);
    expect(find.text('KOSONG'), findsOneWidget);
    expect(find.text('MASUK DENGAN EMAIL'), findsOneWidget);
    expect(find.text('MASUK DENGAN GOOGLE'), findsOneWidget);
    expect(find.text('MAIN SEBAGAI TAMU'), findsOneWidget);
    expect(find.text('Mendaftar'), findsOneWidget);
    expect(find.textContaining('APPLE'), findsNothing);
    expect(find.textContaining('FACEBOOK'), findsNothing);
  });

  testWidgets('opens email registration form', (tester) async {
    await tester.pumpWidget(const BalokKosongApp());

    await tester.tap(find.text('Mendaftar'));
    await tester.pumpAndSettle();

    expect(find.text('MENDAFTAR'), findsOneWidget);
    expect(find.text('Nama'), findsOneWidget);
    expect(find.text('Alamat email'), findsOneWidget);
    expect(find.text('Password (minimal 6 karakter)'), findsOneWidget);
    expect(find.text('KIRIM VERIFIKASI'), findsOneWidget);
  });

  testWidgets('shows back button when home is opened from settings', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: HomeScreen(showBackButton: true)),
    );

    expect(find.byTooltip('Kembali ke permainan'), findsOneWidget);
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

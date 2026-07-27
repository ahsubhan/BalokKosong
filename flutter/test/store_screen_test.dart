import 'package:balok_kosong/store_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('store shows token purchase and rewarded ad actions', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: StoreScreen()));
    await tester.pumpAndSettle();

    expect(find.text('BELI 30 TOKEN'), findsOneWidget);
    expect(
      find.textContaining('Main sebagai Tamu: +3 token awal'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Daftar/Login Email atau Google: +10 token'),
      findsOneWidget,
    );
    expect(find.text('+3 Token Petunjuk'), findsOneWidget);
    expect(find.text('Tonton iklan berhadiah'), findsOneWidget);

    await tester.ensureVisible(find.text('BELI 30 TOKEN'));
    await tester.tap(find.text('BELI 30 TOKEN'));
    await tester.pump();
    expect(find.textContaining('Produk token belum tersedia'), findsOneWidget);
  });
}

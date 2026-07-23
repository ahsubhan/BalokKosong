import 'package:balok_kosong/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the Balok Kosong home screen', (tester) async {
    await tester.pumpWidget(const BalokKosongApp());

    expect(find.text('BALOK'), findsOneWidget);
    expect(find.text('KOSONG'), findsOneWidget);
    expect(find.text('MAIN SEBAGAI TAMU'), findsOneWidget);

    await tester.tap(find.text('MAIN SEBAGAI TAMU'));
    await tester.pumpAndSettle();
    expect(find.text('SCORE'), findsOneWidget);
    expect(find.text('LEVEL'), findsOneWidget);
  });
}

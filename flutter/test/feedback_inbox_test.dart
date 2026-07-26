import 'package:balok_kosong/feedback_inbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('feedback card shows readable sender and app details', (
    tester,
  ) async {
    const item = FeedbackItem(
      id: 'feedback-1',
      senderName: 'Rina',
      email: 'rina@example.com',
      message: 'Balok pendek sulit digeret.',
      platform: 'ios',
      appVersion: '1.0.0',
      buildNumber: '1',
      status: 'new',
      category: 'feedback',
      createdAt: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeedbackInboxCard(item: item, onStatusChanged: (_) {}),
        ),
      ),
    );

    expect(find.text('Rina'), findsOneWidget);
    expect(find.text('rina@example.com'), findsOneWidget);
    expect(find.text('Balok pendek sulit digeret.'), findsOneWidget);
    expect(find.text('ios'), findsOneWidget);
    expect(find.text('v1.0.0 (1)'), findsOneWidget);
    expect(find.text('Baru'), findsOneWidget);
    expect(find.text('Sudah dibaca'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
  });
}

import 'package:balok_kosong/help_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('guest can fill feedback and add an attachment', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HelpFeedbackScreen()));

    await tester.scrollUntilVisible(
      find.text('Kirim feedback'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields, hasLength(1));
    expect(fields.every((field) => field.enabled != false), isTrue);
    expect(find.byKey(const Key('addFeedbackAttachment')), findsOneWidget);

    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Kirim feedback'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNotNull);
  });
}

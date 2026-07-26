import 'package:balok_kosong/help_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('guest cannot fill or submit feedback', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HelpFeedbackScreen(onOpenGuide: () {})),
    );

    expect(
      find.text('Masuk dengan Email atau Google untuk mengirim feedback.'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Login diperlukan'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields, hasLength(2));
    expect(fields.every((field) => field.enabled == false), isTrue);

    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Login diperlukan'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
  });
}

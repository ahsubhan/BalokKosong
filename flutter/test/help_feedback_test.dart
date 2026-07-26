import 'package:balok_kosong/help_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('guest cannot fill or submit feedback', (tester) async {
    var loginOpened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: HelpFeedbackScreen(
          onOpenGuide: () {},
          onLoginRequired: () async => loginOpened = true,
        ),
      ),
    );

    expect(find.text('Masuk dengan Email atau Google'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -220));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('feedbackLoginPrompt')));
    await tester.pump();
    expect(loginOpened, isTrue);

    await tester.scrollUntilVisible(
      find.text('Masuk untuk mengirim'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields, hasLength(1));
    expect(fields.every((field) => field.enabled == false), isTrue);

    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Masuk untuk mengirim'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNotNull);
  });
}

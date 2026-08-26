import 'package:flutter_test/flutter_test.dart';

import 'package:questionable_decisions/app.dart';

void main() {
  testWidgets('Questionable Decisions app loads', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const QuestionableDecisionsApp(),
    );

    expect(
      find.byType(QuestionableDecisionsApp),
      findsOneWidget,
    );
  });
}
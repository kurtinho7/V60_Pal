import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v60pal/BrewScreen.dart';
import 'package:v60pal/Theme.dart';

void main() {
  testWidgets('Brew screen renders recipe choices and primary action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: COLOR_SCHEME,
          scaffoldBackgroundColor: BACKGROUND_COLOR,
        ),
        home: const BrewScreen(),
      ),
    );

    expect(find.text('Choose a recipe'), findsOneWidget);
    expect(find.text('4:6 Method'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Start brew'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Start brew'), findsOneWidget);
  });
}

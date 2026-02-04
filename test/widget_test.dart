// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:easzygoo/features/rider/app.dart';

void main() {
  testWidgets('Rider app shows splash then login', (WidgetTester tester) async {
    await tester.pumpWidget(const RiderApp());

    // Splash
    expect(find.text('EaszyGoo Rider'), findsOneWidget);

    // RiderRoot transitions from splash -> login after a short delay.
    await tester.pump(const Duration(milliseconds: 950));
    await tester.pumpAndSettle();

    // Login
    expect(find.text('Welcome, Rider'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
  });
}

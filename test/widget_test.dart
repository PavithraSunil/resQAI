// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:resqai/dashboard_page.dart';

void main() {
<<<<<<< HEAD
  testWidgets('admin dashboard renders command center overview', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardPage()));

    expect(find.text('Good morning, Admin'), findsOneWidget);
    expect(find.text('Current risk summary'), findsOneWidget);
    expect(find.text('Priority SOS requests'), findsOneWidget);
    expect(find.text('Environmental conditions'), findsOneWidget);
=======
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ResQAIApp());

    expect(find.text('ResQAI'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
>>>>>>> anjaly
  });
}

// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

<<<<<<< HEAD
import 'package:flutter_test/flutter_test.dart';

import 'package:resqai/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ResQAIApp());

    expect(find.text('ResQAI'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
=======
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resqai/admin_dashboard.dart';

void main() {
  testWidgets('admin dashboard renders command center overview',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminDashboardPage(),
      ),
    );

    expect(find.text('Good morning, Admin'), findsOneWidget);
    expect(find.text('Current risk summary'), findsOneWidget);
    expect(find.text('Priority SOS requests'), findsOneWidget);
    expect(find.text('Environmental conditions'), findsOneWidget);
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
  });
}
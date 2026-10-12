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
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_tutor_app/main.dart';

void main() {
  testWidgets('renders the GramNet splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('GRAMNET AI'), findsOneWidget);
    expect(find.text('SMART VILLAGE TUTOR'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
  });
}

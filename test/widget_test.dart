// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:voos_baratos_app/app/app.dart';

void main() {
  testWidgets('home renders search button', (WidgetTester tester) async {
    await tester.pumpWidget(const FlightDealsApp());

    await tester.pump();

    expect(find.text('Buscar passagens'), findsOneWidget);
    expect(find.text('Minhas viagens'), findsOneWidget);
  });
}

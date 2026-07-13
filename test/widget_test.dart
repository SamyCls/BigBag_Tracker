// Basic Flutter widget test for Big Bag Manager.

import 'package:flutter_test/flutter_test.dart';

import 'package:big_bag_manager/main.dart';

void main() {
  testWidgets('App launches and shows Production screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BigBagManagerApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Production'), findsWidgets);
  });
}

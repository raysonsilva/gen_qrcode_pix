import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qrpix/app.dart';
import 'package:qrpix/controllers/theme_controller.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(App(themeController: ThemeController()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

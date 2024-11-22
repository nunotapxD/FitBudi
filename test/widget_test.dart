import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbudi_1/login_page.dart'; // Verifique o caminho do seu arquivo
import 'package:fitbudi_1/home_page.dart';  // Verifique o caminho do seu arquivo

void main() {
  testWidgets('Test if HomePage is rendered after login', (WidgetTester tester) async {
    // Build the LoginPage widget
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    // Tap the login button
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();  // Wait for the navigation to complete

    // Verify that HomePage is displayed
    expect(find.byType(HomePage), findsOneWidget); // Verifica se o HomePage foi exibido
  });
}

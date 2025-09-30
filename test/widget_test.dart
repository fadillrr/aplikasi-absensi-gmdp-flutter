// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Import ScreenUtilInit

import 'package:flutter_application_2/screens/login_page.dart'; // Import LoginPage

void main() {
  testWidgets('Verify LoginPage is rendered initially', (WidgetTester tester) async {
    // Build our app's initial widget tree.
    // We're wrapping LoginPage with ScreenUtilInit and MaterialApp,
    // just like how it's set up in main.dart's runApp.
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844), // Match the designSize from your main.dart
        builder: (context, child) {
          return MaterialApp(
            home: const LoginPage(), // Your application starts with LoginPage
          );
        },
      ),
    );

    // Verify that elements from your LoginPage are present.
    // For example, let's check for the "Email" text field and the "LOGIN" button.
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'LOGIN'), findsOneWidget);

    // If your LoginPage has a title or specific text, you can test for that too.
    // For instance, if your LoginPage has an AppBar with "Login_GMDP" as a title:
    // expect(find.text('Login_GMDP'), findsOneWidget);

    // You can add more specific tests here for your LoginPage's functionality,
    // like entering text into fields or tapping buttons.
    // For example, to enter text:
    // await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
    // await tester.enterText(find.byKey(const Key('password_field')), 'password123');
    // await tester.tap(find.widgetWithText(ElevatedButton, 'LOGIN'));
    // await tester.pumpAndSettle(); // Wait for navigation or other animations to complete

    // Then, verify what happens after login (e.g., if you navigate to HomePage)
    // expect(find.byType(HomePage), findsOneWidget);
  });
}
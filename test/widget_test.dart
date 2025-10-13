// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flirtfix/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}

// whi8le trying to login I get the error Sep 22 20:46:34  Login error: type object 'Token' has no attribute 'objects'
// Sep 22 20:46:34  Traceback (most recent call last):
// Sep 22 20:46:34    File "/workspace/src/mobileapi/views.py", line 94, in login
// Sep 22 20:46:34      token, created = Token.objects.get_or_create(user=user)
// Sep 22 20:46:34                       ^^^^^^^^^^^^^
// Sep 22 20:46:34  AttributeError: type object 'Token' has no attribute 'objects'
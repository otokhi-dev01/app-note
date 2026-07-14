import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes/app.dart';

void main() {
  testWidgets('App splash screen test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NoteApp());

    // Verify that SplashView is shown initially (it has a CupertinoActivityIndicator)
    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);

    // Let the splash timer finish
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}

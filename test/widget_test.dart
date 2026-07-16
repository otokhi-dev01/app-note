import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes/app.dart';
import 'package:notes/presentation/modules/auth/login_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App splash screen test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(const NoteApp());

    // Verify that SplashView is shown initially (it has a CupertinoActivityIndicator)
    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);

    // Let the splash timer finish
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(LoginView), findsOneWidget);
  });
}

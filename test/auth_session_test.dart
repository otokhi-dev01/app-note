import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes/data/models/user_model.dart';
import 'package:notes/data/services/auth_service.dart';
import 'package:notes/data/services/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('corrupted stored auth JSON is discarded', () async {
    SharedPreferences.setMockInitialValues({'auth_user': '{not-json'});
    final storage = LocalStorage();

    expect(await storage.getAuthUser(), isNull);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey('auth_user'), isFalse);
  });

  test('a stored auth value with the wrong type is discarded', () async {
    SharedPreferences.setMockInitialValues({'auth_user': true});
    final storage = LocalStorage();

    expect(await storage.getAuthUser(), isNull);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey('auth_user'), isFalse);
  });

  test('an expired JWT is not restored as an authenticated session', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage();
    await storage.saveAuthUser(
      UserModel(
        id: 'user-1',
        phone: '012345678',
        token: _jwtWithExpiration(DateTime.utc(2000)),
      ),
    );

    final authService = AuthService(storage);
    await authService.ready;

    expect(authService.isLoggedIn, isFalse);
    expect(authService.user, isNull);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey('auth_user'), isFalse);
  });

  test('a valid legacy session is migrated to secure storage', () async {
    final user = UserModel(
      id: 'user-1',
      phone: '012345678',
      token: 'opaque-token',
    );
    SharedPreferences.setMockInitialValues({
      'auth_user': jsonEncode(user.toJson()),
    });

    final restored = await LocalStorage().getAuthUser();

    expect(restored?.id, user.id);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey('auth_user'), isFalse);
    expect(await LocalStorage().getAuthUser(), isNotNull);
  });

  test(
    'an explicit sign-out marker suppresses a stale secure session',
    () async {
      final user = UserModel(
        id: 'user-1',
        phone: '012345678',
        token: 'opaque-token',
      );
      FlutterSecureStorage.setMockInitialValues({
        'auth_user': jsonEncode(user.toJson()),
      });
      SharedPreferences.setMockInitialValues({'auth_signed_out': true});

      expect(await LocalStorage().getAuthUser(), isNull);

      SharedPreferences.setMockInitialValues({});
      expect(await LocalStorage().getAuthUser(), isNull);
    },
  );
}

String _jwtWithExpiration(DateTime expiration) {
  String encodePart(Map<String, Object> value) {
    return base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  }

  final header = encodePart({'alg': 'none', 'typ': 'JWT'});
  final payload = encodePart({
    'exp': expiration.millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond,
  });
  return '$header.$payload.unsigned';
}

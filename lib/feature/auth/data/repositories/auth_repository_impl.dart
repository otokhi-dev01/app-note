import 'dart:convert';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_parser.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/validation/auth_input_validator.dart';
import '../datasources/auth_session_storage.dart';
import '../models/auth_session_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient apiClient;
  final TokenStorage tokenStorage;
  final AuthSessionStorage sessionStorage;

  AuthRepositoryImpl({
    required this.apiClient,
    required this.tokenStorage,
    AuthSessionStorage? sessionStorage,
  }) : sessionStorage = sessionStorage ?? const AuthSessionStorage();

  @override
  Future<void> login({required String phone, required String password}) async {
    final String cleanPhone = AuthInputValidator.normalizePhone(phone);

    final String? phoneError = AuthInputValidator.validatePhone(cleanPhone);
    if (phoneError != null) {
      throw ApiException(message: phoneError);
    }

    final String? passwordError = AuthInputValidator.validatePassword(password);
    if (passwordError != null) {
      throw ApiException(message: passwordError);
    }

    final dynamic rawResponse = await apiClient.post(
      ApiEndpoints.login,
      requiresAuth: false,
      useAuthBaseUrl: true,
      body: <String, dynamic>{'phone': cleanPhone, 'password': password},
    );
    final dynamic response = ApiParser.decodeResponse(rawResponse);

    ApiParser.ensureSuccess(response, fallbackMessage: 'Login failed.');

    final String? token = _extractToken(response);

    if (token == null) {
      throw const ApiException(
        message: 'The login response does not contain an authentication token.',
      );
    }

    if (!_isTokenUsable(token)) {
      throw const ApiException(
        message: 'The login response contains an invalid or expired token.',
      );
    }

    await _saveAuthenticatedSession(
      response: response,
      phone: cleanPhone,
      token: token,
    );
  }

  @override
  Future<bool> register({
    required String phone,
    required String password,
  }) async {
    final String cleanPhone = AuthInputValidator.normalizePhone(phone);

    final String? phoneError = AuthInputValidator.validatePhone(cleanPhone);
    if (phoneError != null) {
      throw ApiException(message: phoneError);
    }

    final String? passwordError = AuthInputValidator.validatePassword(password);
    if (passwordError != null) {
      throw ApiException(message: passwordError);
    }

    final dynamic rawResponse = await apiClient.post(
      ApiEndpoints.register,
      requiresAuth: false,
      useAuthBaseUrl: true,
      body: <String, dynamic>{'phone': cleanPhone, 'password': password},
    );
    final dynamic response = ApiParser.decodeResponse(rawResponse);

    ApiParser.ensureSuccess(response, fallbackMessage: 'Registration failed.');

    final String? token = _extractToken(response);

    if (token == null || !_isTokenUsable(token)) {
      return false;
    }

    await _saveAuthenticatedSession(
      response: response,
      phone: cleanPhone,
      token: token,
    );
    return true;
  }

  @override
  Future<void> logout() async {
    await Future.wait<void>(<Future<void>>[
      tokenStorage.deleteToken(),
      sessionStorage.clearSession(),
    ]);
  }

  @override
  Future<bool> isLoggedIn() async {
    final String? storedToken = await tokenStorage.readToken();
    final String? token = _normalizeToken(storedToken);

    if (token == null || !_isTokenUsable(token)) {
      await Future.wait<void>(<Future<void>>[
        tokenStorage.deleteToken(),
        sessionStorage.clearSession(),
      ]);
      return false;
    }

    if (token != storedToken) {
      await tokenStorage.saveToken(token);
    }

    return true;
  }

  @override
  Future<AuthSession?> getSession() async {
    if (!await isLoggedIn()) {
      return null;
    }

    final AuthSession? session = await sessionStorage.readSession();
    if (session != null) {
      return session;
    }

    final String? token = _normalizeToken(await tokenStorage.readToken());
    final Map<String, dynamic>? claims = token == null
        ? null
        : _decodeJwtPayload(token);

    if (claims == null) {
      return null;
    }

    final AuthSessionModel restoredSession = AuthSessionModel.fromAuthResponse(
      claims,
      fallbackPhone: '',
    );
    await sessionStorage.saveSession(restoredSession);
    return restoredSession;
  }

  String? _extractToken(dynamic response) {
    for (final String key in const <String>['accessToken', 'token']) {
      final String? token = _normalizeToken(_findScalarValue(response, key));

      if (token != null) {
        return token;
      }
    }

    return null;
  }

  String? _normalizeToken(Object? value) {
    if (value is Map || value is Iterable) {
      return null;
    }

    String token = value?.toString().trim() ?? '';

    if (token.toLowerCase().startsWith('bearer ')) {
      token = token.substring(7).trim();
    }

    return token.isEmpty ? null : token;
  }

  dynamic _findScalarValue(dynamic value, String key) {
    final String normalizedKey = _normalizeKey(key);

    if (value is Map) {
      for (final MapEntry<dynamic, dynamic> entry in value.entries) {
        if (_normalizeKey(entry.key.toString()) == normalizedKey &&
            entry.value is! Map &&
            entry.value is! Iterable) {
          return entry.value;
        }
      }

      for (final dynamic nestedValue in value.values) {
        final dynamic result = _findScalarValue(nestedValue, key);
        if (result != null) {
          return result;
        }
      }
    } else if (value is Iterable) {
      for (final dynamic nestedValue in value) {
        final dynamic result = _findScalarValue(nestedValue, key);
        if (result != null) {
          return result;
        }
      }
    }

    return null;
  }

  String _normalizeKey(String key) {
    return key.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
  }

  bool _isTokenUsable(String token) {
    final List<String> parts = token.split('.');

    if (parts.length != 3) {
      return true;
    }

    final Map<String, dynamic>? payload = _decodeJwtPayload(token);
    if (payload == null) {
      return false;
    }

    try {
      final dynamic expiration = payload['exp'];
      final int? expirationSeconds = switch (expiration) {
        num value => value.toInt(),
        String value => num.tryParse(value.trim())?.toInt(),
        _ => null,
      };

      if (expirationSeconds == null) {
        return false;
      }

      final DateTime expiresAt = DateTime.fromMillisecondsSinceEpoch(
        expirationSeconds * Duration.millisecondsPerSecond,
        isUtc: true,
      );

      return expiresAt.isAfter(DateTime.now().toUtc());
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic>? _decodeJwtPayload(String token) {
    final List<String> parts = token.split('.');
    if (parts.length != 3) {
      return null;
    }

    try {
      final dynamic payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      if (payload is! Map) {
        return null;
      }

      return Map<String, dynamic>.from(payload);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveAuthenticatedSession({
    required dynamic response,
    required String phone,
    required String token,
  }) async {
    final AuthSessionModel session = AuthSessionModel.fromAuthResponse(
      response,
      fallbackPhone: phone,
    );

    await sessionStorage.saveSession(session);

    try {
      await tokenStorage.saveToken(token);
    } catch (_) {
      await sessionStorage.clearSession();
      rethrow;
    }
  }
}

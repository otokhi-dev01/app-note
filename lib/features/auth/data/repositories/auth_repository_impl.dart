import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:notes/core/network/api_endpoints.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../datasources/local_storage.dart';

class AuthService extends GetxService implements AuthRepository {
  AuthService(this._localStorage) {
    _client.timeout = const Duration(seconds: 20);
    ready = _restoreSession();
  }

  final LocalStorage _localStorage;
  final GetConnect _client = GetConnect();
  final _user = Rxn<UserModel>();
  @override
  late final Future<void> ready;

  @override
  UserModel? get user => _user.value;

  @override
  bool get isLoggedIn => _normalizeToken(_user.value?.token) != null;

  @override
  String? get accountScopeId {
    final currentUser = _user.value;
    if (currentUser == null) return null;

    final id = currentUser.id.trim();
    if (id.isNotEmpty) return 'user:$id';

    final phone = currentUser.phone?.trim();
    if (phone != null && phone.isNotEmpty) return 'phone:$phone';

    final email = currentUser.email?.trim().toLowerCase();
    if (email != null && email.isNotEmpty) return 'email:$email';
    return null;
  }

  @override
  String? lastError;

  Future<void> _restoreSession() async {
    try {
      final savedUser = await _localStorage.getAuthUser();
      final token = _normalizeToken(savedUser?.token);
      if (savedUser != null && token != null && _isTokenUsable(token)) {
        _user.value = token == savedUser.token
            ? savedUser
            : UserModel(
                id: savedUser.id,
                email: savedUser.email,
                phone: savedUser.phone,
                name: savedUser.name,
                avatar: savedUser.avatar,
                token: token,
              );
        return;
      }
    } catch (_) {
      // A storage failure must never leave the splash screen waiting forever.
    }

    _user.value = null;
    try {
      await _localStorage.clearAuthUser();
    } catch (_) {}
  }

  @override
  Future<bool> login(String phone, String password) async {
    lastError = null;

    try {
      if (kDebugMode) {
        debugPrint(
          '[Auth] Logging in with phone=$phone to ${ApiEndpoints.login}',
        );
      }
      final response = await _client.post<dynamic>(
        ApiEndpoints.login,
        {'phone': phone, 'password': password},
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('[Auth] Login response status: ${response.statusCode}');
      debugPrint('[Auth] Login response body: ${response.body}');

      final body = response.body;
      if (!response.isOk) {
        lastError =
            _errorMessage(body) ??
            'Login failed (${response.statusCode ?? 'network error'}).';
        debugPrint('[Auth] Login failed: $lastError');
        return false;
      }

      final payload = _asMap(body);
      if (payload == null) {
        lastError = 'The server returned an invalid response.';
        debugPrint('[Auth] Login failed: could not parse response body as map');
        return false;
      }

      debugPrint('[Auth] Parsed payload keys: ${payload.keys.toList()}');

      final data = _asMap(payload['data']);
      debugPrint('[Auth] data keys: ${data?.keys.toList()}');

      final userJson =
          _asMap(data?['user']) ?? _asMap(payload['user']) ?? data ?? payload;
      debugPrint('[Auth] userJson keys: ${userJson.keys.toList()}');

      final token =
          _readToken(data) ?? _readToken(payload) ?? _readToken(userJson);
      if (kDebugMode) {
        debugPrint(
          '[Auth] token resolved: ${token != null ? '${token.substring(0, token.length.clamp(0, 20))}...' : 'null'}',
        );
      }

      if (token == null || token.isEmpty) {
        lastError = 'The login response did not include an access token.';
        debugPrint('[Auth] Login failed: no token in response');
        return false;
      }

      final authenticatedUser = UserModel(
        id:
            (userJson['id'] ??
                    userJson['_id'] ??
                    userJson['userId'] ??
                    userJson['UserId'] ??
                    '')
                .toString(),
        email: userJson['email']?.toString(),
        phone:
            (userJson['phone'] ??
                    userJson['phoneNumber'] ??
                    userJson['Phone'] ??
                    phone)
                .toString(),
        name: (userJson['name'] ?? userJson['fullName'] ?? userJson['FullName'])
            ?.toString(),
        avatar:
            (userJson['avatar'] ??
                    userJson['avatar_url'] ??
                    userJson['avatarUrl'])
                ?.toString(),
        token: token,
      );

      if (kDebugMode) {
        debugPrint(
          '[Auth] Authenticated user: id=${authenticatedUser.id}, name=${authenticatedUser.name}, phone=${authenticatedUser.phone}',
        );
      }

      await _localStorage.saveAuthUser(authenticatedUser);
      _user.value = authenticatedUser;
      debugPrint('[Auth] Login successful!');
      return true;
    } on FormatException catch (error) {
      lastError = error.message;
      debugPrint('[Auth] Login FormatException: ${error.message}');
      return false;
    } catch (error, stackTrace) {
      lastError = 'Unable to connect to the server. Please try again.';
      debugPrint('[Auth] Login unexpected error: $error');
      debugPrint('[Auth] Stack trace: $stackTrace');
      return false;
    }
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    if (value is String && value.isNotEmpty) {
      try {
        return _asMap(jsonDecode(value));
      } on FormatException {
        return null;
      }
    }
    return null;
  }

  String? _readToken(Map<String, dynamic>? json) {
    if (json == null) return null;
    return _normalizeToken(
      json['access_token'] ?? json['accessToken'] ?? json['token'],
    );
  }

  String? _normalizeToken(Object? value) {
    if (value == null) return null;
    final token = value.toString().trim();
    return token.isEmpty ? null : token;
  }

  bool _isTokenUsable(String? token) {
    final normalizedToken = _normalizeToken(token);
    if (normalizedToken == null) return false;

    final parts = normalizedToken.split('.');
    if (parts.length != 3) return true; // The API may use an opaque token.

    try {
      final payload = _asMap(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final expiration = payload?['exp'];
      final expirationSeconds = switch (expiration) {
        num value => value.toInt(),
        String value => num.tryParse(value.trim())?.toInt(),
        _ => null,
      };
      if (expirationSeconds == null) return false;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        expirationSeconds * 1000,
        isUtc: true,
      );
      return expiresAt.isAfter(DateTime.now().toUtc());
    } catch (_) {
      return false;
    }
  }

  String? _errorMessage(dynamic body) {
    final json = _asMap(body);
    if (json == null) return null;

    final errors = json['errors'] ?? json['data'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      return first.toString();
    }

    final message = json['message'] ?? json['error'] ?? json['detail'];
    if (message is String && message.trim().isNotEmpty) return message;
    return null;
  }

  @override
  Future<bool> signup(String phone, String password) async {
    lastError = null;

    try {
      final response = await _client.post<dynamic>(
        ApiEndpoints.register,
        {'phone': phone, 'password': password},
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (!response.isOk) {
        lastError =
            _errorMessage(response.body) ??
            'Registration failed (${response.statusCode ?? 'network error'}).';
        return false;
      }

      return true;
    } on FormatException catch (error) {
      lastError = error.message;
      return false;
    } catch (_) {
      lastError = 'Unable to connect to the server. Please try again.';
      return false;
    }
  }

  @override
  Future<void> logout() async {
    _user.value = null;
    try {
      await _localStorage.clearAuthUser();
    } catch (_) {
      lastError = 'The local session could not be fully cleared.';
    }
  }
}

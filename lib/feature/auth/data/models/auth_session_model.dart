import '../../domain/entities/auth_session.dart';

class AuthSessionModel extends AuthSession {
  const AuthSessionModel({
    super.id,
    super.phone,
    super.fullName,
    super.email,
    super.avatarUrl,
  });

  factory AuthSessionModel.fromAuthResponse(
    dynamic response, {
    required String fallbackPhone,
  }) {
    final Map<String, dynamic> payload =
        _asMap(response) ?? <String, dynamic>{'phone': fallbackPhone};
    final Map<String, dynamic>? data = _asMap(_read(payload, <String>['data']));
    final Map<String, dynamic> user =
        _asMap(_read(data, <String>['user'])) ??
        _asMap(_read(payload, <String>['user'])) ??
        data ??
        payload;

    return AuthSessionModel(
      id: _text(_read(user, <String>['id', '_id', 'userId', 'sub'])),
      phone:
          _text(_read(user, <String>['phone', 'phoneNumber'])) ?? fallbackPhone,
      fullName: _text(_read(user, <String>['name', 'fullName'])),
      email: _text(_read(user, <String>['email'])),
      avatarUrl: _text(
        _read(user, <String>['avatar', 'avatarUrl', 'avatar_url', 'picture']),
      ),
    );
  }

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      id: _text(json['id']),
      phone: _text(json['phone']),
      fullName: _text(json['fullName']),
      email: _text(json['email']),
      avatarUrl: _text(json['avatarUrl']),
    );
  }

  factory AuthSessionModel.fromSession(AuthSession session) {
    return AuthSessionModel(
      id: session.id,
      phone: session.phone,
      fullName: session.fullName,
      email: session.email,
      avatarUrl: session.avatarUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'phone': phone,
      'fullName': fullName,
      'email': email,
      'avatarUrl': avatarUrl,
    };
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is! Map) {
      return null;
    }

    return value.map(
      (dynamic key, dynamic item) =>
          MapEntry<String, dynamic>(key.toString(), item),
    );
  }

  static dynamic _read(Map<String, dynamic>? source, List<String> keys) {
    if (source == null) {
      return null;
    }

    final Set<String> normalizedKeys = keys.map(_normalizeKey).toSet();

    for (final MapEntry<String, dynamic> entry in source.entries) {
      if (normalizedKeys.contains(_normalizeKey(entry.key))) {
        return entry.value;
      }
    }

    return null;
  }

  static String? _text(dynamic value) {
    final String text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static String _normalizeKey(String key) {
    return key.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
  }
}

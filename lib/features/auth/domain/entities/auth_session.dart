/// The signed-in user, as the app reasons about them.
class AuthUser {
  final String? id;
  final String? fullName;
  final String? phone;
  final String? deviceName;
  final String? deviceType;
  final String? profileImage;

  const AuthUser({
    this.id,
    this.fullName,
    this.phone,
    this.deviceName,
    this.deviceType,
    this.profileImage,
  });

  String get displayName =>
      (fullName == null || fullName!.trim().isEmpty) ? 'User' : fullName!;
}

/// A successful authentication: the bearer token plus who it belongs to.
class AuthSession {
  final String token;
  final AuthUser user;

  const AuthSession({required this.token, required this.user});

  bool get isValid => token.isNotEmpty;
}

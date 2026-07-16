class AuthUser {
  const AuthUser({
    required this.id,
    this.email,
    this.phone,
    this.name,
    this.avatar,
    this.token,
  });

  final String id;
  final String? email;
  final String? phone;
  final String? name;
  final String? avatar;
  final String? token;
}

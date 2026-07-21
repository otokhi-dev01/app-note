class AuthSession {
  final String? id;
  final String? phone;
  final String? fullName;
  final String? email;
  final String? avatarUrl;

  const AuthSession({
    this.id,
    this.phone,
    this.fullName,
    this.email,
    this.avatarUrl,
  });

  String get displayName {
    final String name = fullName?.trim() ?? '';
    if (name.isNotEmpty) {
      return name;
    }

    final String phoneNumber = phone?.trim() ?? '';
    if (phoneNumber.isNotEmpty) {
      return phoneNumber;
    }

    final String emailAddress = email?.trim() ?? '';
    if (emailAddress.isNotEmpty) {
      return emailAddress;
    }

    return 'Piisiit Note User';
  }
}

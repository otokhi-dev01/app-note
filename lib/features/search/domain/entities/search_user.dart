class SearchUser {
  final String id;
  final String account;
  final String fullName;

  const SearchUser({
    required this.id,
    required this.account,
    required this.fullName,
  });

  String get displayName => fullName.isNotEmpty
      ? fullName
      : account.isNotEmpty
      ? account
      : id;
}

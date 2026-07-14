class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? avatar;
  final String? token;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.avatar,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      avatar: json['avatar'] as String?,
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar': avatar,
      'token': token,
    };
  }
}

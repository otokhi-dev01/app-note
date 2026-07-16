import '../../domain/entities/auth_user.dart';

class UserModel extends AuthUser {
  const UserModel({
    required super.id,
    super.email,
    super.phone,
    super.name,
    super.avatar,
    super.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      email: json['email']?.toString(),
      phone: (json['phone'] ?? json['phoneNumber'])?.toString(),
      name: json['name']?.toString(),
      avatar: (json['avatar'] ?? json['avatar_url'])?.toString(),
      token: (json['token'] ?? json['access_token'] ?? json['accessToken'])
          ?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'name': name,
      'avatar': avatar,
      'token': token,
    };
  }
}

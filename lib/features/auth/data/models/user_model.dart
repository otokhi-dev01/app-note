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
      id: (json['id'] ?? json['_id'] ?? json['userId'] ?? json['UserId'] ?? '').toString(),
      email: json['email']?.toString(),
      phone: (json['phone'] ?? json['phoneNumber'] ?? json['Phone'])?.toString(),
      name: (json['name'] ?? json['fullName'] ?? json['FullName'])?.toString(),
      avatar: (json['avatar'] ?? json['avatar_url'] ?? json['avatarUrl'])?.toString(),
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

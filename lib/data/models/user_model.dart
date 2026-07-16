class UserModel {
  final String id;
  final String? email;
  final String? phone;
  final String? name;
  final String? avatar;
  final String? token;

  UserModel({
    required this.id,
    this.email,
    this.phone,
    this.name,
    this.avatar,
    this.token,
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

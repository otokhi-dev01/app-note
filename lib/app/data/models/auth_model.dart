class LoginRequest {
  final String phone;
  final String password;

  LoginRequest({required this.phone, required this.password});

  Map<String, dynamic> toJson() => {
    "phone": phone,
    "password": password,
  };
}

class RegisterRequest {
  final String fullName;
  final String phone;
  final String password;
  final String deviceName;
  final String deviceType;

  RegisterRequest({
    required this.fullName,
    required this.phone,
    required this.password,
    required this.deviceName,
    required this.deviceType,
  });

  Map<String, dynamic> toJson() => {
    "fullName": fullName,
    "phone": phone,
    "password": password,
    "deviceName": deviceName,
    "deviceType": deviceType,
  };
}

class AuthResponse {
  final String token;
  final UserData user;
  final int code;
  final String message;

  AuthResponse({
    required this.token,
    required this.user,
    required this.code,
    required this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return AuthResponse(
      token: data['token']?.toString() ?? '',
      user: UserData.fromJson(data),
      code: json['code'] ?? 0,
      message: json['message'] ?? '',
    );
  }
}

class UserData {
  final String? id;
  final String? fullName;
  final String? phone;
  final String? deviceName;
  final String? deviceType;

  UserData({
    this.id,
    this.fullName,
    this.phone,
    this.deviceName,
    this.deviceType,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['userId']?.toString(),
      fullName: json['fullName']?.toString(),
      phone: json['phone']?.toString(),
      deviceName: json['deviceName']?.toString(),
      deviceType: json['deviceType']?.toString(),
    );
  }
}

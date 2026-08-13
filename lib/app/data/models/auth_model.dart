class LoginRequest {
  final String phone;
  final String password;

  LoginRequest({required this.phone, required this.password});

  Map<String, dynamic> toJson() => {"phone": phone, "password": password};
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
    final dynamic dataRaw = json['data'];
    final Map<String, dynamic> data = (dataRaw is Map<String, dynamic>) ? dataRaw : {};
    final int code = json['code'] ?? 0;
    
    // Only parse user data on success codes
    final UserData user = (code == 200 || code == 201) 
        ? UserData.fromJson(data) 
        : UserData();

    return AuthResponse(
      token: data['token']?.toString() ?? '',
      user: user,
      code: code,
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
  final String? profileImage;

  UserData({
    this.id,
    this.fullName,
    this.phone,
    this.deviceName,
    this.deviceType,
    this.profileImage,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: (json['userId'] ?? json['id'])?.toString(),
      fullName: (json['fullName'] ?? json['name'])?.toString(),
      phone: (json['phone'] ?? json['email'])?.toString(),
      deviceName: json['deviceName']?.toString(),
      deviceType: json['deviceType']?.toString(),
      profileImage: (json['profileImage'] ?? json['avatar'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    "userId": id,
    "fullName": fullName,
    "phone": phone,
    "deviceName": deviceName,
    "deviceType": deviceType,
    "profileImage": profileImage,
  };

  UserData copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? deviceName,
    String? deviceType,
    String? profileImage,
  }) {
    return UserData(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      deviceName: deviceName ?? this.deviceName,
      deviceType: deviceType ?? this.deviceType,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}

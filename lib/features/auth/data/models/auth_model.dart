import 'package:Note/core/utils/json_parsers.dart';
import 'package:Note/features/auth/domain/entities/auth_session.dart';

class LoginRequest {
  final String phone;
  final String password;

  const LoginRequest({required this.phone, required this.password});

  Map<String, dynamic> toJson() => {'phone': phone, 'password': password};
}

class RegisterRequest {
  final String fullName;
  final String phone;
  final String password;
  final String deviceName;
  final String deviceType;

  const RegisterRequest({
    required this.fullName,
    required this.phone,
    required this.password,
    required this.deviceName,
    required this.deviceType,
  });

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'phone': phone,
    'password': password,
    'deviceName': deviceName,
    'deviceType': deviceType,
  };
}

/// The `/api/auth/*` envelope.
class AuthResponse {
  final String token;
  final UserData user;
  final int code;
  final String message;

  const AuthResponse({
    required this.token,
    required this.user,
    required this.code,
    required this.message,
  });

  bool get isSuccess => code == 200 || code == 201;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final dynamic dataRaw = json['data'] ?? json['Data'];
    final Map<String, dynamic> data = dataRaw is Map
        ? Map<String, dynamic>.from(dataRaw)
        : {};
    final dynamic userRaw =
        data['user'] ?? data['userData'] ?? data['profile'] ?? data['User'];
    final Map<String, dynamic> user = userRaw is Map
        ? Map<String, dynamic>.from(userRaw)
        : data;
    final int code = asInt(json['code'] ?? json['Code']);

    return AuthResponse(
      token: asString(
        data['token'] ??
            data['accessToken'] ??
            data['Token'] ??
            json['token'] ??
            json['accessToken'],
      ),
      // Only parse user data on success codes; an error body's `data` holds
      // validation details, not a user.
      user: (code == 200 || code == 201)
          ? UserData.fromJson(user)
          : const UserData(),
      code: code,
      message: asString(json['message'] ?? json['Message']),
    );
  }
}

/// [AuthUser] plus the wire format and local-storage encoding.
class UserData extends AuthUser {
  const UserData({
    super.id,
    super.fullName,
    super.phone,
    super.deviceName,
    super.deviceType,
    super.profileImage,
  });

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
    id: (json['userId'] ?? json['id'] ?? json['UserId'] ?? json['Id'])
        ?.toString(),
    fullName:
        (json['fullName'] ?? json['name'] ?? json['FullName'] ?? json['Name'])
            ?.toString(),
    phone: (json['phone'] ?? json['email'] ?? json['Phone'] ?? json['Email'])
        ?.toString(),
    deviceName: (json['deviceName'] ?? json['DeviceName'])?.toString(),
    deviceType: (json['deviceType'] ?? json['DeviceType'])?.toString(),
    profileImage:
        (json['profileImage'] ??
                json['avatar'] ??
                json['ProfileImage'] ??
                json['Avatar'])
            ?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'userId': id,
    'fullName': fullName,
    'phone': phone,
    'deviceName': deviceName,
    'deviceType': deviceType,
    'profileImage': profileImage,
  };

  UserData copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? deviceName,
    String? deviceType,
    String? profileImage,
  }) => UserData(
    id: id ?? this.id,
    fullName: fullName ?? this.fullName,
    phone: phone ?? this.phone,
    deviceName: deviceName ?? this.deviceName,
    deviceType: deviceType ?? this.deviceType,
    profileImage: profileImage ?? this.profileImage,
  );
}

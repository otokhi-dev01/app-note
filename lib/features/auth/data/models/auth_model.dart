import 'package:Note/core/utils/json_parsers.dart';
import 'package:Note/features/auth/domain/entities/auth_session.dart';

/// Login and registration share the same credentials and device payload.
class AuthCredentialsRequest {
  final String account;
  final String password;
  final String clientDeviceId;
  final String appVersion;
  final String deviceName;
  final String platform;
  final String deviceModel;

  const AuthCredentialsRequest({
    required this.account,
    required this.password,
    required this.clientDeviceId,
    required this.appVersion,
    required this.deviceName,
    required this.platform,
    required this.deviceModel,
  });

  Map<String, dynamic> toJson() => {
    'account': account,
    'password': password,
    'clientDeviceId': clientDeviceId,
    'appVersion': appVersion,
    'deviceName': deviceName,
    'platform': platform,
    'deviceModel': deviceModel,
  };
}

/// The `/api/auth/*` envelope.
class AuthResponse {
  final String token;
  final UserData user;
  final int code;
  final String message;
  final bool? success;

  const AuthResponse({
    required this.token,
    required this.user,
    required this.code,
    required this.message,
    this.success,
  });

  bool get isSuccess => success != false && (code == 200 || code == 201);

  factory AuthResponse.fromJson(Map<String, dynamic> json, {int? statusCode}) {
    final dynamic dataRaw = json['data'] ?? json['Data'];
    final Map<String, dynamic> data = dataRaw is Map
        ? Map<String, dynamic>.from(dataRaw)
        : {};
    final dynamic userRaw =
        data['user'] ??
        data['userData'] ??
        data['profile'] ??
        data['User'] ??
        json['user'] ??
        json['User'];
    final Map<String, dynamic> user = userRaw is Map
        ? Map<String, dynamic>.from(userRaw)
        : data;
    final int code = asInt(json['code'] ?? json['Code'] ?? statusCode);
    final successRaw = json['success'] ?? json['Success'];
    final success = successRaw == null ? null : asBool(successRaw);

    return AuthResponse(
      token: asString(
        data['token'] ??
            data['accessToken'] ??
            data['Token'] ??
            data['AccessToken'] ??
            data['access_token'] ??
            json['token'] ??
            json['accessToken'] ??
            json['Token'] ??
            json['AccessToken'] ??
            json['access_token'],
      ),
      // Only parse user data on success codes; an error body's `data` holds
      // validation details, not a user.
      user: success != false && (code == 200 || code == 201)
          ? UserData.fromJson(user)
          : const UserData(),
      code: code,
      message: asString(json['message'] ?? json['Message']),
      success: success,
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

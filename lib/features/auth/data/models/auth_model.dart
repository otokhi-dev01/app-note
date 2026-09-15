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
    'Account': account,
    'phone': account,
    'Phone': account,
    'phoneNumber': account,
    'PhoneNumber': account,
    'username': account,
    'Username': account,
    'userName': account,
    'UserName': account,
    'email': account,
    'Email': account,
    'name': account,
    'Name': account,
    'fullName': account,
    'FullName': account,
    'password': password,
    'Password': password,
    'clientDeviceId': clientDeviceId,
    'appVersion': appVersion,
    'deviceName': deviceName,
    'deviceType': platform, // Use original casing
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

  bool get isSuccess => success == true || (success != false && (code == 200 || code == 201 || code == 0 || code == 1));

  factory AuthResponse.fromJson(Map<String, dynamic> json, {int? statusCode}) {
    final dynamic dataRaw = json['data'] ?? json['Data'] ?? json['payload'] ?? json['result'];
    final Map<String, dynamic> data = dataRaw is Map
        ? Map<String, dynamic>.from(dataRaw)
        : (Map<String, dynamic>.from(json)..removeWhere((k, _) => k == 'code' || k == 'message' || k == 'success' || k == 'status'));
    
    // Some backends return the token directly in 'data' if it's a string
    final String? dataToken = dataRaw is String ? dataRaw : null;

    final dynamic userRaw =
        data['user'] ??
        data['userData'] ??
        data['profile'] ??
        data['User'] ??
        json['user'] ??
        json['User'] ??
        json['profile'];
    final Map<String, dynamic> user = userRaw is Map
        ? Map<String, dynamic>.from(userRaw)
        : data;
    
    final int code = asInt(json['code'] ?? json['Code'] ?? json['status'] ?? statusCode);
    final successRaw = json['success'] ?? json['Success'] ?? json['status'];
    
    // Handle 'status': 'success' string
    bool? success;
    if (successRaw is String) {
      final s = successRaw.toLowerCase();
      if (s == 'success' || s == 'ok' || s == '200' || s == '201') success = true;
      else if (s == 'error' || s == 'fail' || s == '400' || s == '401') success = false;
      else success = asBool(successRaw);
    } else if (successRaw != null) {
      success = asBool(successRaw);
    }

    return AuthResponse(
      token: dataToken ?? asString(
        data['token'] ??
            data['accessToken'] ??
            data['Token'] ??
            data['AccessToken'] ??
            data['access_token'] ??
            data['jwt'] ??
            json['token'] ??
            json['accessToken'] ??
            json['Token'] ??
            json['AccessToken'] ??
            json['access_token'] ??
            json['jwt'],
      ),
      // Only parse user data on success codes; an error body's `data` holds
      // validation details, not a user.
      user: success != false && (code == 200 || code == 201 || code == 0)
          ? UserData.fromJson(user)
          : const UserData(),
      code: code,
      message: asString(json['message'] ?? json['Message'] ?? json['error'] ?? json['detail']),
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
    // 'displayName' is what GET /api/users/profile actually returns
    // (confirmed live); the rest are the auth-response spellings.
    fullName:
        (json['fullName'] ??
                json['displayName'] ??
                json['name'] ??
                json['FullName'] ??
                json['Name'])
            ?.toString(),
    phone: (json['phone'] ?? json['email'] ?? json['Phone'] ?? json['Email'])
        ?.toString(),
    deviceName: (json['deviceName'] ?? json['DeviceName'])?.toString(),
    deviceType: (json['deviceType'] ?? json['DeviceType'])?.toString(),
    // 'avatarUrl' is what GET /api/users/profile actually returns.
    profileImage:
        (json['profileImage'] ??
                json['avatarUrl'] ??
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

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
    'email': account,
    'Email': account,
    'username': account,
    'Username': account,
    'phone': account,
    'Phone': account,
    'password': password,
    'Password': password,
    'clientDeviceId': clientDeviceId,
    'ClientDeviceId': clientDeviceId,
    'appVersion': appVersion,
    'AppVersion': appVersion,
    'deviceName': deviceName,
    'DeviceName': deviceName,
    'platform': platform,
    'Platform': platform,
    'deviceModel': deviceModel,
    'DeviceModel': deviceModel,
  };
}

/// The `/api/auth/*` envelope.
class AuthResponse {
  final String token;
  final String refreshToken;
  final UserData user;
  final int code;
  final String message;
  final bool? success;

  const AuthResponse({
    required this.token,
    required this.user,
    required this.code,
    required this.message,
    this.refreshToken = '',
    this.success,
  });

  bool get isSuccess =>
      success == true ||
      (success != false &&
          (code == 200 || code == 201 || code == 0 || code == 1));

  factory AuthResponse.fromJson(Map<String, dynamic> json, {int? statusCode}) {
    final dynamic dataRaw =
        json['data'] ?? json['Data'] ?? json['payload'] ?? json['result'];
    final Map<String, dynamic> data = dataRaw is Map
        ? Map<String, dynamic>.from(dataRaw)
        : (Map<String, dynamic>.from(json)..removeWhere(
            (k, _) =>
                k == 'code' ||
                k == 'message' ||
                k == 'success' ||
                k == 'status',
          ));

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

    final int code = asInt(
      json['code'] ?? json['Code'] ?? json['status'] ?? statusCode,
    );
    final successRaw = json['success'] ?? json['Success'] ?? json['status'];

    // Handle 'status': 'success' string
    bool? success;
    if (successRaw is String) {
      final s = successRaw.toLowerCase();
      if (s == 'success' || s == 'ok' || s == '200' || s == '201') {
        success = true;
        // ignore: curly_braces_in_flow_control_structures
      } else if (s == 'error' || s == 'fail' || s == '400' || s == '401')
        // ignore: curly_braces_in_flow_control_structures
        success = false;
      // ignore: curly_braces_in_flow_control_structures
      else
        // ignore: curly_braces_in_flow_control_structures
        success = asBool(successRaw);
    } else if (successRaw != null) {
      success = asBool(successRaw);
    }

    return AuthResponse(
      refreshToken: asString(
        data['refreshToken'] ??
            data['RefreshToken'] ??
            data['refresh_token'] ??
            json['refreshToken'] ??
            json['RefreshToken'] ??
            json['refresh_token'],
      ),
      token: _accessToken(json, data, dataRaw),
      // Only parse user data on success codes; an error body's `data` holds
      // validation details, not a user.
      user: success != false && (code == 200 || code == 201 || code == 0)
          ? UserData.fromJson(user)
          : const UserData(),
      code: code,
      message: asString(
        json['message'] ?? json['Message'] ?? json['error'] ?? json['detail'],
      ),
      success: success,
    );
  }

  static String _accessToken(
    Map<String, dynamic> json,
    Map<String, dynamic> data,
    dynamic dataRaw,
  ) {
    // Explicit access-token fields take priority even when a generic token
    // also appears in another envelope level. Never substitute refresh or ID
    // tokens, or stringify validation objects/numbers into credentials.
    final candidates = [
      for (final source in [data, json])
        for (final key in ['accessToken', 'AccessToken', 'access_token'])
          source[key],
      for (final source in [data, json])
        for (final key in ['token', 'Token', 'jwt']) source[key],
      dataRaw,
    ];
    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate;
      }
    }
    return '';
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

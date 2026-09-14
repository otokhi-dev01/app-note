class AppConstants {
  /// Account, user, and encryption services use the Chat server.
  static const String baseUrl = "https://chat.piisiit.com";

  /// Folders, notes, and attachments use the Note server.
  static const String noteBaseUrl = "https://note.piisiit.com";

  /// API Base URLs
  static const String apiBaseUrl = "$baseUrl/api";
  static const String authBaseUrl = "$apiBaseUrl/auth";
  static const String userApiUrl = "$apiBaseUrl/users";
  static const String encryptionBaseUrl = "$apiBaseUrl/encryption";

  /// Auth Endpoints
  static const String registerEndpoint = "/register";
  static const String loginEndpoint = "/login";
  static const String logoutEndpoint = "/logout-current-device";

  /// Used by [ApiClient]'s best-effort silent-refresh-before-logout on a
  /// 401. UNVERIFIED against the live backend — no refresh token is ever
  /// issued by login/register today, so the request assumes the server
  /// accepts the just-expired access token itself as proof of a recent
  /// session. See `ApiClient._tryRefreshSession` for the full caveat.
  static const String refreshTokenEndpoint = "/refresh-token";

  // Recovery Password
  static const String forgotPasswordEndpoint = "/password/forgot";

  /// User endpoints
  static const String userProfileEndpoint = "/profile";
  static const String userUploadProfileEndpoint = "/upload-profile";
  static const String userUpdateProfileEndpoint = "/update-profile";

  /// encryption
  static const String identityKeyEndpoint = "/identity-key";
  static const String preKeyEndpoint = "/pre-keys";

  /// Timeout configurations
  static const int connectTimeoutSeconds = 10;
  static const int receiveTimeoutSeconds = 10;

  /// Content types
  static const String contentTypeJson = 'application/json';
  static const String contentTypeMultipart = 'multipart/form-data';
}

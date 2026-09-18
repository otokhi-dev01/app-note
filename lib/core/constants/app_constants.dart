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

  /// POST JSON {refreshToken: ...}; confirmed in Chat Swagger.
  static const String refreshTokenEndpoint = "/refresh-token";
  static const String sessionsEndpoint = "/sessions";

  // Recovery Password
  static const String forgotPasswordEndpoint = "/password/forgot";
  static const String verifyPasswordOtpEndpoint = "/password/verify-otp";
  static const String resetPasswordEndpoint = "/password/reset";
  static const String securityQuestionsEndpoint =
      "/password/security-questions";
  static const String verifySecurityAnswersEndpoint =
      "/password/verify-security";

  /// User endpoints
  static const String userProfileEndpoint = "/profile";
  static const String userUploadProfileEndpoint = "/upload-profile";
  static const String userUpdateProfileEndpoint = "/update-profile";
  static const String uploadDocumentEndpoint = "/upload-document";

  /// encryption
  static const String identityKeyEndpoint = "/identity-key";
  static const String preKeyEndpoint = "/pre-keys";

  /// Digital Civic ID (national ID) scan/e-KYC.
  ///
  /// PROPOSED — not yet confirmed against a live backend. No such route has
  /// been verified to exist on the server; `IdentityRemoteDataSource` posts
  /// the front/back card photos here and expects the JSON shape documented
  /// on `NationalIdCard.fromJson`. Update this path (and that parser)
  /// together once the real contract is confirmed with the backend team —
  /// see `UserRemoteDataSource`'s doc comment for how a wrong guess here
  /// has played out before (a confirmed 404).
  static const String identityApiUrl = "$apiBaseUrl/identity";
  static const String identityScanEndpoint = "/scan";

  /// Timeout configurations
  static const int connectTimeoutSeconds = 10;
  static const int receiveTimeoutSeconds = 10;

  /// Content types
  static const String contentTypeJson = 'application/json';
  static const String contentTypeMultipart = 'multipart/form-data';
}

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

  /// API Endpoints

  /// Auth Endpoints
  static const String googleLoginEndpoint = "/google-login";
  static const String registerEndpoint = "/register";
  static const String loginEndpoint = "/login";
  static const String refreshTokenEndpoint = "/refresh-token";
  static const String logoutEndpoint = "/logout-current-device";
  static const String sessionEndpoint = "/sessions";
  static const String deleteAllSessionsEndpoint = "/sessions";
  static const String deleteSessionEndpoint = "/sessions/";

  // Recovery Password
  static const String googleVerifyEndpoint = "/google/verify";
  static const String forgotPasswordEndpoint = "/password/forgot";
  static const String resetPasswordEndpoint = "/password/reset";
  static const String emailVerifyOTPEndpoint = "/password/verify-otp";
  static const String securityQuestionEndpoint = "/password/security-question";
  static const String securityAnswerEndpoint = "/password/security-answers";
  static const String verifySecurityEndpoint = "/password/verify-security";
  static const String recoveryPasswordMethodsListEndpoint =
      "/auth/v1/password-recovery/methods";
  static const String saveRecoveryPasswordMethodsEndpoint =
      "/auth/v1/password-recovery/save-methods";

  /// User endpoints
  static const String userProfileEndpoint = "/profile";
  static const String userUploadProfileEndpoint = "/upload-profile";
  static const String userUpdateProfileEndpoint = "/update-profile";
  static const String resetUserPasswordEndpoint = "/user/reset-password";

  /// Notification
  static const String pushTokensEndpoint = "/push-tokens";
  static const String deletePushTokenEndpoint = "/push-tokens/current-device";

  /// Chat
  static const String chatSidebarEndpoint = "/conversations/sidebar";
  static const String searchUsersChatEndpoint = "/users/search";
  static const String chatFoldersEndpoint = "/chat-folders";
  static const String createChatFolderEndpoint = "/api/chat-folders";

  /// encryption
  static const String identityKeyEndpoint = "/identity-key";
  static const String preKeyEndpoint = "/pre-keys";
  static const String chatBundleEndpoint = "/chat-bundle";
  static const String sessionHandshakeEndpoint = "/session-handshake";

  /// Timeout configurations
  static const int connectTimeoutSeconds = 10;
  static const int receiveTimeoutSeconds = 10;

  /// Content types
  static const String contentTypeJson = 'application/json';
  static const String contentTypeMultipart = 'multipart/form-data';
}

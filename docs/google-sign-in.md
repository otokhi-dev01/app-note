# Google sign-in setup and verification

Login, signup, and password recovery share the same Google authentication flow.
Google accounts can sign in from the recovery screen; changing the Google
password opens Google's recovery page in the browser. Note's OTP/security-answer
password reset remains a separate flow and never accepts a Google token as reset proof.

## iOS

Set the real Google Cloud OAuth IDs in `ios/Flutter/GoogleSignIn.xcconfig`:

- `GOOGLE_IOS_CLIENT_ID`: iOS OAuth client registered for the Runner bundle ID.
- `GOOGLE_SERVER_CLIENT_ID`: Web application OAuth client accepted by the backend.
- `GOOGLE_REVERSED_CLIENT_ID`: reverse the dot-separated iOS client ID, for
  example `com.googleusercontent.apps.<ios-client-id>`.

Both Debug and Release/Profile include this configuration. The app checks the
resolved bundle IDs and URL scheme before invoking the Google SDK. The IDs use
app-owned `NoteGoogleIOSClientID` / `NoteGoogleServerClientID` bundle keys and are
passed to the SDK only after validation, so empty configuration is never consumed
by Google's native initialization. Empty or
unresolved configuration displays an availability message instead of risking an
iOS exception. Rebuild the app after changing these settings; hot reload is insufficient.

## Android

Register the Android package and signing certificate SHA fingerprints in the same
Google Cloud project. Build with
`--dart-define=GOOGLE_SERVER_CLIENT_ID=<web-oauth-client-id>`.
The backend must validate Google ID tokens against this Web client ID.

## Verification

Run `flutter test test/google_sign_in_service_test.dart test/auth_flow_test.dart
test/password_recovery_test.dart test/account_input_test.dart`.

On a device with real configuration, test Google signup/login, cancellation,
return from Google's browser/account chooser, and sign-in from Forgot Password.
Verify that the backend accepts the ID token and opens the notes screen. Also
verify OTP/security-answer reset and Google account recovery in the browser.
Automated tests use fakes and do not prove that production OAuth IDs, signing
certificates, or backend token verification are correctly configured.

Setup reference: https://pub.dev/packages/google_sign_in_ios

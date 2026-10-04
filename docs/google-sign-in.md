# Google sign-in setup and verification

The existing Google sign-in service obtains Google ID tokens for backend use.
The **Forgot Password → Verify with Google** action now uses it for recovery:

1. Open Google's account chooser and obtain the Google ID token.
2. POST only `{idToken}` to `/api/auth/password/google/verify` using the shared
   Dio client with `requiresAuth: false`.
3. Require `success: true` and a nonempty `data.resetToken` (or top-level
   `resetToken`) before showing New Password.
4. Submit the reset proof and matching new passwords to `/api/auth/password/reset`.
5. Return to login after reset succeeds. Google verification itself does not
   save a session or log the user in.

The verification response uses the existing recovery parser. Swagger documents
the request body but not the success payload, so the reset-proof response must
still be confirmed using a real configured Google account. Tests simulate that
response and reject successful envelopes without reset proof.

The Google ID token stays in the request's local scope and the reset token stays
in the recovery screen's memory. Neither is logged or persisted. Loading prevents
duplicate actions. Cancellation, failed configuration, and rejected verification
keep the recovery form usable; results arriving after the screen closes are
ignored.

This endpoint provides password recovery. Registration still uses the separate
direct email/password flow described in [email-registration.md](email-registration.md).

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

The configuration bridge also accepts standard `GIDClientID` and
`GIDServerClientID` values in the app's `Info.plist`. If the custom iOS client ID
and `GIDClientID` are absent, it can read `CLIENT_ID` from a
`GoogleService-Info.plist` included in the Runner app bundle. A Web client ID and
the matching callback URL scheme must still be configured; adding the downloaded
plist alone does not enable backend verification. Empty or unresolved custom
settings do not mask valid standard settings.

If verification reports that it is unavailable, check the Flutter debug console
for `[GOOGLE] Configuration incomplete`. It identifies a missing `iosClientId`,
`serverClientId`, `callbackScheme`, or `nativeConfigurationBridge` without printing
credentials or tokens. Rebuilding with blank IDs will reproduce the same error.

## Android

Register the Android package and signing certificate SHA fingerprints in the same
Google Cloud project. Build with
`--dart-define=GOOGLE_SERVER_CLIENT_ID=<web-oauth-client-id>`.
The backend must validate Google ID tokens against this Web client ID.

## Verification

Run:

```sh
flutter test --no-pub test/google_sign_in_service_test.dart test/password_recovery_test.dart test/email_registration_test.dart
```

On a configured device, open Forgot Password and tap Verify with Google. Choose
a Google account linked to an existing app account. Confirm that the backend
accepts its ID token and provides reset proof, that New Password appears, and
that the app remains signed out (or preserves an existing session until password
reset completes). Set a new password, complete reset, and sign in separately.
Also test cancellation, unlinked accounts, offline verification, duplicate taps,
and leaving the screen during verification.

OAuth client IDs in `ios/Flutter/GoogleSignIn.xcconfig` are currently blank. They
must come from the Google Cloud project configured for this app/backend; an API
access token is not an OAuth client ID or Google ID token. Rebuild after supplying
the IDs. No production OAuth sign-in was performed during this change.

Automated tests use fake Google identity and HTTP responses; they do not prove
that production OAuth IDs, signing certificates, or backend token verification
are correctly configured.

Setup reference: https://pub.dev/packages/google_sign_in_ios

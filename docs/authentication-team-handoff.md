# Authentication code: team handoff

Prepared on October 4, 2026, for the Pii Note development team.

Repository: [otokhi-dev01/app-note](https://github.com/otokhi-dev01/app-note)  
Working branch: [`nona.dev`](https://github.com/otokhi-dev01/app-note/tree/nona.dev)  
Main authentication folder: [`lib/features/auth/`](https://github.com/otokhi-dev01/app-note/tree/nona.dev/lib/features/auth)

## Message to share with the team

> Hi team, please use the authentication implementation from my GitHub repository:
> https://github.com/otokhi-dev01/app-note, branch `nona.dev`.
>
> It includes username/email/phone sign-in, registration, email OTP verification,
> manual phone country selection, password recovery through OTP or security
> questions, Google password verification, secure session storage, and logout.
> Google sign-in service code is also included; its login-screen button is
> currently commented out.
>
> Please clone the whole project first. If you copy authentication into another
> app, include its core services, shared widgets, bindings, routes, dependencies,
> assets, and native configuration—not only the screen files. Follow this guide
> and the linked setup documents before testing.
>
> Google verification needs real Google OAuth client IDs configured for our
> backend. Copying the code alone does not enable Google verification. Please
> use the commit SHA I provide after I push the handoff changes, so everyone
> starts from the same version.

## 1. Publish the handoff version first

At preparation time, the latest Google configuration changes, input styling,
and this document are local changes. They must be committed and pushed before
the team can download them from GitHub. This document does not publish changes.

For the repository owner, run these from the project folder:

```sh
git switch nona.dev
git status --short
git diff
```

Review and stage the authentication handoff files:

```sh
git add README.md docs/authentication-team-handoff.md docs/google-sign-in.md
git add lib/features/auth lib/shared/widgets/glass_inputs.dart lib/shared/widgets/glass_input_surface.dart
git add ios/Runner/AppDelegate.swift ios/RunnerTests/RunnerTests.swift
git add test/google_sign_in_service_test.dart test/password_recovery_test.dart
git diff --cached
git commit -m "Share authentication implementation and team setup guide"
git push origin nona.dev
git rev-parse HEAD
```

These commands stage the auth-related changes, not all local app changes. Add
any other reviewed integration changes needed for the version you are sharing.
Send the final commit SHA with this guide. If the repository is private, team
members need access before they can clone it.

## 2. Download and run the project

For a new checkout:

```sh
git clone --branch nona.dev https://github.com/otokhi-dev01/app-note.git
cd app-note
git rev-parse HEAD
flutter --version
flutter pub get
flutter run
```

Use a Flutter SDK that satisfies the Dart constraint in `pubspec.yaml`
(`^3.11.5` at preparation time). Keep `pubspec.lock` when running this app to
use its resolved dependency versions. The full project also contains local
packages under `packages/`; keep those folders when cloning the whole app.

For an existing checkout, commit or stash your own changes first, then update:

```sh
git fetch origin
git switch nona.dev
git pull --ff-only origin nona.dev
git rev-parse HEAD
flutter pub get
```

To inspect the exact version supplied by the owner, use
`git switch --detach COMMIT_SHA`, replacing `COMMIT_SHA` with the shared SHA.
Create your own branch from that version before making changes.

## 3. Authentication features and source files

| Feature | Main implementation |
| --- | --- |
| Username, email, and phone sign-in | `presentation/views/login_view.dart`, `presentation/controllers/auth_controller.dart` |
| Manual country selection and phone formatting | `presentation/controllers/account_input_controller.dart`, `presentation/widgets/account_input_field.dart` |
| Registration and email OTP | `presentation/views/register_view.dart`, `presentation/controllers/registration_controller.dart`, `data/services/registration_service.dart` |
| OTP input, paste, and resend | `presentation/widgets/password_otp_step.dart` and the registration/recovery screens |
| Forgot password and new password | `presentation/views/forgot_password_view.dart` |
| Security-question recovery | `presentation/widgets/security_answers_form.dart`, `domain/entities/security_question.dart` |
| Google password verification | `presentation/controllers/google_password_verification_controller.dart`, `data/services/google_sign_in_service.dart` |
| API requests and response parsing | `data/datasources/auth_remote_data_source.dart`, `data/models/auth_model.dart` |
| Validation, use cases, and session persistence | `domain/usecases/auth_usecases.dart`, `data/repositories/auth_repository_impl.dart` |
| Route controller registration | `presentation/bindings/auth_binding.dart`, `presentation/bindings/registration_binding.dart` |

Paths in this table are relative to `lib/features/auth/`. Copy that entire
folder when reusing the feature.

Registration behavior: email accounts verify a six-digit email OTP before
creation; username and phone accounts skip that email step. Username signup
finishes after account creation. Email/phone flows also save profile details,
using temporary login if registration returns no usable profile token.
Successful signup returns to Sign In with the account filled in and the password
blank. See [the complete registration flow](email-registration.md).

Phone selection defaults to Cambodia (`+855`). Typing does not detect or change
the country. Keep the selected country metadata when navigating from signup to
login, and submit the country prefix exactly once.

## 4. Copy authentication into another Flutter app

The authentication folder is integrated with Pii Note; it is not a standalone
Flutter package. Start with the working full checkout, then move these pieces
into the destination project and adapt their integration points.

| Supporting code | What to copy or adapt |
| --- | --- |
| Network | `lib/core/network/api_client.dart`, `access_token.dart`, `auth_diagnostics.dart`, `api_error_parser.dart` |
| Errors and use cases | `lib/core/error/`, `lib/core/usecase/` |
| Session and device preferences | `lib/core/storage/session_storage.dart`, `guest_mode_service.dart`; language/theme storage used by the copied UI |
| API configuration | `lib/core/constants/app_constants.dart` |
| Helpers | `lib/core/utils/validators.dart`, `json_parsers.dart`, `attachment_url.dart` |
| Auth notifications | `lib/core/feedback/app_snackbar.dart` |
| Shared UI | `glass_widgets.dart`, `glass_inputs.dart`, `glass_input_surface.dart`, `glass_surfaces.dart`, `app_logo.dart`, `language_toggle_button.dart`, `language_popup.dart` under `lib/shared/widgets/` |
| Localization and theme | `lib/core/localization/` and the theme files imported by the selected screens/widgets |
| Startup restore | `lib/features/splash/`, or equivalent startup logic that waits for session restoration |
| Logout/delete-account UI | Relevant settings views, `account_controller.dart`, and `account_binding.dart` under `lib/features/settings/presentation/` |
| Native Google setup | Google configuration channel and resolver in `ios/Runner/AppDelegate.swift`, relevant `Info.plist` entries, and `ios/Flutter/GoogleSignIn.xcconfig` |

Use `lib/core/di/injector.dart`, `lib/routes/app_pages.dart`, `lib/routes/app_routes.dart`,
`lib/main.dart`, and `lib/app.dart` as integration references. They also include
non-auth features, so adapt them rather than copying the complete application
dependency graph into an auth-only project.

Integration steps:

1. Update `package:Note/...` imports to the destination package name.
2. Merge the needed dependencies from `pubspec.yaml`: `get`, `dio`, `get_storage`,
   `flutter_secure_storage`, `device_info_plus`, `package_info_plus`, `uuid`,
   `google_sign_in`, `intl_phone_field`, `flutter_animate`, `font_awesome_flutter`,
   `cupertino_icons`, and `liquid_glass_widgets`. Include any additional packages
   required by the theme or encryption code you retain. Match source versions
   first, then handle upgrades separately.
3. Copy the logo/font assets referenced by the copied widgets and theme, and add
   them to the destination `pubspec.yaml`. The source app declares them under
   `assets/icons/` and `assets/fonts/`.
4. Initialize Flutter bindings, `GetStorage`, and the liquid-glass runtime as in
   `main.dart`. Register `SessionStorage`, `GuestModeService`, `ApiClient`,
   `AuthRemoteDataSource`, `AuthRepository`, and the auth use cases before opening
   an auth route. Follow `InitialBinding._authUseCases()` for the use-case list.
5. Register login and forgot-password routes with `AuthBinding`, and registration
   with `RegistrationBinding`. Keep the login controller registered permanently
   so replacing the signup stack does not close the new sign-in form's controller.
   Each new sign-in screen clears its password and any prior form error.
6. Replace Pii Note's `Routes.FOLDER` destination with your app's signed-in home.
   Handle the guest destination separately. `AuthController` invokes
   `EncryptionController.setupForCurrentUser()` after login; either provide that
   service and its dependencies or adapt the hook to your app's own initialization.
7. Configure the root `ScaffoldMessenger` using `AppSnackbar.messengerKey` and
   provide the translations/theme used by the auth screens.
8. Configure iOS Keychain entitlements for the destination bundle ID and Google
   callback handling for its own OAuth client. Preserve other native services
   when merging the Google channel into an existing `AppDelegate`.
9. Run analysis and the applicable tests after resolving all imports and routes.

## 5. Backend requests

Account requests use `https://chat.piisiit.com`; the auth base is
`https://chat.piisiit.com/api/auth`. The following table describes the current
Flutter implementation. Confirm compatibility with your backend before reusing
it with a different server.

| Action | Method and path | Request body |
| --- | --- | --- |
| Sign in | `POST /api/auth/login` | `account`, `password`, device fields |
| Create account | `POST /api/auth/register` | `account`, `password`, device fields |
| Send signup email OTP | `POST /api/auth/signup/send-otp` | `email` |
| Verify signup email OTP | `POST /api/auth/verify-otp/email` | `email`, `otp` |
| Save signup profile | `POST /api/users/profile/save` | Applicable `username`, `email`, `phone`; temporary/new-account bearer token |
| Request recovery OTP | `POST /api/auth/password/forgot` | `account` |
| Verify recovery OTP | `POST /api/auth/password/verify-otp` | `account`, `otp` |
| Google recovery | `POST /api/auth/password/google/verify` | `idToken` |
| Load security questions | `GET /api/auth/password/security-questions` | No body |
| Verify security answers | `POST /api/auth/password/verify-security` | `account`, `answers: [{questionId, answer}]` |
| Set new password | `POST /api/auth/password/reset` | `resetToken`, `newPassword`, `confirmPassword` |
| Refresh session | `POST /api/auth/refresh-token` | `refreshToken` |
| List sessions | `GET /api/auth/sessions` | No body; authenticated |
| Revoke this device's session | `POST /api/auth/logout-current-device` | `sessionId`; authenticated |
| Delete account | `POST /api/auth/delete-account` | `password`; authenticated |

Device fields are `clientDeviceId`, `appVersion`, `deviceName`, `platform`, and
`deviceModel`, provided by `AuthDeviceService`. Password confirmation is checked
locally for registration.

Google login service code calls `POST /api/auth/google-login`, sending `idToken`
and legacy `token`/`googleToken` aliases plus device fields. Its login-screen
button is commented out. Confirm the backend contract before enabling that
button; Google recovery is a separate action that sends only `{idToken}`.

Public auth/recovery requests use `requiresAuth: false`. Successful recovery
verification must return an explicit nonempty `resetToken`; a generic session
token is not accepted as recovery proof. Keep Google verification separate from
app login: verification itself must not create or overwrite an app session.

For token normalization, refresh, and server validation details, read
[note-auth-validation.md](note-auth-validation.md). Its historical descriptions
should be checked against `ApiClient` and the selected commit's tests; current
code preserves the session on signature/issuer/audience validation mismatches.

## 6. Google configuration required before device testing

The OAuth IDs are blank in the handoff workspace. The rebuilt iOS app was also
checked and had no configured Google callback scheme. Rebuilding alone does not
fill those values.

For iOS, supply the real values in `ios/Flutter/GoogleSignIn.xcconfig`:

```text
GOOGLE_IOS_CLIENT_ID = YOUR_IOS_OAUTH_CLIENT_ID
GOOGLE_SERVER_CLIENT_ID = YOUR_WEB_OAUTH_CLIENT_ID
GOOGLE_REVERSED_CLIENT_ID = YOUR_REVERSED_IOS_CLIENT_ID
```

These are placeholders, not working credentials. Register the iOS client for
the destination app's bundle ID. The source Runner bundle ID is
`com.kimchheang.otokhi-note`. The Web client ID must be accepted by the backend.
Use the dot-reversed iOS client ID as the registered callback scheme. Standard
Google configuration is also supported as explained in
[google-sign-in.md](google-sign-in.md).

For Android, register the destination package and signing SHA fingerprint with
Google. The source application ID is `com.kimchheang.pii_note`. Run with the real
Web client ID:

```sh
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_OAUTH_CLIENT_ID
```

Fully rebuild after native configuration changes. Test with a Google account
associated with an existing backend account. Google tokens and recovery tokens
must not be included in team messages, screenshots, or diagnostic logs.

## 7. Verification before accepting the copied feature

From the full source checkout:

```sh
flutter analyze --no-pub
flutter test --no-pub test/auth_flow_test.dart test/account_input_test.dart test/email_registration_test.dart test/password_recovery_test.dart test/google_sign_in_service_test.dart test/login_integration_test.dart test/session_restore_test.dart test/auth_response_test.dart test/access_token_test.dart test/auth_diagnostics_test.dart test/snackbar_focus_test.dart
```

Port the relevant fixtures and dependencies when running these in another app.
Use `test/session_recovery_test.dart` for refresh coverage too, while reviewing
the known failures below against the selected version.

Manual acceptance checks:

- Create username, email, and phone accounts; then sign in with the same account.
- Confirm OTP paste/autofill, leading zeroes, resend cooldown, and error retry.
- Change country manually; confirm the submitted prefix appears exactly once.
- Restart after sign-in; confirm session restoration and secure-storage retry.
- Verify password recovery through OTP, security questions, and configured Google.
- Change the password, finish recovery, and sign in separately with the new password.
- Cancel Google selection, go offline, tap twice, and leave during a pending request.
- Sign out; confirm the auth screen opens and personal note data is preserved.
- Check account deletion only with a disposable test account.

### Status at preparation time

Whole-app analysis passed. The focused Google/auth tests passed: 45 Flutter tests
and four native configuration tests. A later full suite run had **240 passing
tests and 11 failures** in card, document, identity, and session recovery tests.
The full iOS build was not verified because the Xcode check stalled.

Treat these results as the October 4, 2026 workspace status, not proof of a clean
GitHub checkout or live backend authentication. Re-run checks for the actual
shared commit. Google OAuth and a successful real-device Google recovery flow
remain unverified until the correct client IDs are supplied.

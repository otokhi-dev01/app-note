# Email registration using the Chat API

Signup now follows the published `POST https://chat.piisiit.com/api/auth/register`
contract. The previous registration OTP endpoints were not available on the
server. Following the request to use the existing API, signup now runs:

**Email + password + confirmation → register → success message → login.**

There is no registration OTP screen, OTP request, or automatic login in this flow.
Google password recovery remains a separate feature.

## Request

The current [Swagger schema](https://chat.piisiit.com/swagger/v1/swagger.json)
requires `account`, `password`, and `clientDeviceId`. Optional device metadata
is supplied by the existing `AuthDeviceService`:

```json
{
  "account": "person@example.com",
  "password": "<password>",
  "clientDeviceId": "<installation UUID>",
  "deviceName": "<device name>",
  "platform": "<platform>",
  "deviceModel": "<model>",
  "appVersion": "<app version>"
}
```

The form's email becomes `account` and is trimmed. Password contents are preserved
exactly. Confirmation is validated locally. The form no longer asks for a name
because the registration schema does not accept one. No field aliases, name,
confirmation, OTP, or Google token are sent.

`RegistrationService` uses the shared `ApiClient.dio` with `requiresAuth: false`.
The existing `AuthRemoteDataSource.register` delegates to this service too, so
both registration entry points use the same payload. Login transport is unchanged.

Responses use the existing `AuthResponse` parser. Non-JSON/empty responses,
explicit failure envelopes, application error codes, and error collections are
rejected. Swagger does not describe the successful response schema, so the parser
retains the project's existing auth envelope compatibility. Any returned access
or refresh token is ignored by signup; no session is stored.

`RegistrationController` validates inputs, locks submission while obtaining device
metadata or awaiting the server, reports errors inline, and respects HTTP 429
`Retry-After` seconds (60 seconds when absent). It clears temporary input after
success, shows the existing success snackbar, and replaces the auth navigation
stack with Login. Closing the route cancels the request and suppresses late results.
A cancellation after a request reaches the server cannot undo server-side creation.

## Files

- `lib/features/auth/presentation/views/register_view.dart`
- `lib/features/auth/presentation/controllers/registration_controller.dart`
- `lib/features/auth/presentation/bindings/registration_binding.dart`
- `lib/features/auth/data/services/registration_service.dart`
- `lib/features/auth/data/datasources/auth_remote_data_source.dart`
- `lib/routes/app_pages.dart` and `app_routes.dart`
- `test/email_registration_test.dart` and registration cases in `auth_flow_test.dart`

The obsolete `EmailVerificationScreen` and its route were removed.

## Test

```sh
flutter test --no-pub test/email_registration_test.dart
flutter test --no-pub test/auth_flow_test.dart --plain-name Register
flutter test --no-pub test/login_integration_test.dart --plain-name 'Registration and authenticated account operations stay on Chat'
```

Automated tests use the real Dio interceptors with a fake HTTP adapter and device
service. They check the exact documented payload, validation, rejected responses,
duplicate submits, rate limiting, request cancellation, field cleanup, safe logs,
and navigation without automatic login. They do not create a production account.

For live testing:

1. Open Sign Up. Enter an unused email address and matching passwords.
2. Submit once. Check that the request targets `/api/auth/register`; no request
   should target `/register/request`, `/register/verify`, or `/register/resend`.
3. On success, confirm the success message and Login screen, then sign in manually.
4. Try an existing email, invalid fields, and loss of network. Confirm errors stay
   on the registration form and loading ends so the request can be retried.
5. During a slow request, repeatedly tap Sign Up or submit from the keyboard.
   Only one request should be sent.

No live account was created to validate this change. Production success still
requires a live test with an unused email and password chosen by the tester.

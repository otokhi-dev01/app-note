# Signup with email OTP and profile details

The signup form uses the same single account input as login: **Username, Email
or Phone**, followed by password and confirmation. Phone input automatically
shows the country selector and is normalized exactly like login.

For email signup, the app sends a six-digit OTP to that address immediately.
For username or phone signup, the next screen asks for an email to receive the
OTP. Any valid email, including Gmail, can be used. Account creation follows
successful verification.

The [Chat Swagger schema](https://chat.piisiit.com/swagger/v1/swagger.json),
checked on October 2, 2026, documents this flow:

1. `POST /api/auth/signup/send-otp` with `{email}`.
2. `POST /api/auth/verify-otp/email` with `{email, otp}`.
3. `POST /api/auth/register` with `{account, password, clientDeviceId,
   deviceName, platform, deviceModel, appVersion}`. `account` is the selected
   username, email, or normalized phone. Password confirmation is checked locally.
4. `POST /api/users/profile/save` with the verified `email`, plus `username`
   for username signup or `phone` for phone signup, authorized using the new
   account's token. Unprovided fields are omitted from the payload.
5. Clear temporary data and show the email verification success screen after
   all steps succeed. Done (or system back) opens Sign In and clears the signup
   navigation history.

The register schema does not accept username or phone. Saving these through
`/api/users/profile/save` uses the documented `SaveProfileRequest` instead of
sending unsupported fields to register. If registration does not return an
access token, the app temporarily calls `/api/auth/login` with the new account's
credentials to authorize profile saving. It never stores these temporary tokens
or changes an existing app session. The profile request uses an isolated Dio
client sharing the transport adapter, so existing session interceptors cannot
replace its temporary credential.

Sending/resending and verification require an explicit success envelope. All
steps reject invalid responses, explicit failures, error collections, and
application error codes. The successful response schemas are not specified in
Swagger; registration/profile saving retain the existing auth response parser.
A live email signup API test on October 2, 2026 confirmed delivery and the
response shapes used by the signup flow; see the verification results below.

The OTP input supports paste and autofill, only accepts six digits, and preserves
leading zeroes. Resending has a 60-second cooldown; HTTP 429 `Retry-After` blocks
attempts across the flow. Countdowns refresh when the app resumes. Editing the
email resets verification. Duplicate submissions are locked and leaving the
screen cancels in-flight work and discards late results.

A retry after successful verification does not verify the same code twice.
If profile saving fails after registration, the screen lets the user retry
without recreating the account. Username/phone signup can also correct its
account field while retaining the same account type. This
recovery state and temporary credentials last only while the screen is open.
If the user leaves before completing the profile, the account already exists.

## Validation

```sh
flutter analyze --no-pub lib/features/auth/data/services/registration_service.dart lib/features/auth/presentation/controllers/registration_controller.dart lib/features/auth/presentation/views/register_view.dart
flutter test --no-pub test/email_registration_test.dart
flutter test --no-pub test/auth_flow_test.dart --plain-name Register
flutter test --no-pub test/login_integration_test.dart --plain-name 'Registration and authenticated account operations stay on Chat'
flutter test --no-pub test/password_recovery_test.dart
```

Tests use fake HTTP/device services with the real app interceptors. They cover
request order/payloads, local validation, invalid codes, resend, rate limiting,
profile retries, duplicate submissions, cancellation, cleanup, session isolation,
and secret-free logs. They do not create production accounts or send real email.

For live testing, choose a unique username, unused email, or valid phone as
account input and enter matching passwords. If prompted, provide an email you
control. Enter the received code, confirm the success screen, tap Done, then log in and
check the saved profile. Also test an incorrect/expired
code and a taken username. Email delivery and OTP generation belong to the backend.

## Live email signup API verification — October 2, 2026

Using a unique Gmail alias controlled by the user, the live API test passed:

- Signup OTP request: HTTP 200; the user received the code.
- Email OTP verification: HTTP 200.
- Account registration and profile saving: HTTP 200.
- Login with the current app payload, including its field aliases: HTTP 200
  with an access token and user ID.
- Authenticated profile access: HTTP 200.
- Test session logout with the documented `sessionId`: HTTP 200.

The initial logout request omitted `sessionId` and returned HTTP 500 with
`Session not found`. `AuthRemoteDataSource.logout` now automatically requests
`GET /api/auth/sessions`, matches the installation's `clientDeviceId` to the
response's `deviceId`, and sends each matching `sessionId` to logout. Repeated
sign-ins can create several sessions for one installation; each is revoked
once. The user does not need to supply an ID. Missing/invalid matches and
explicit server failures are rejected; other devices are not selected. The existing
repository still clears local credentials when server logout is unavailable.

Automated logout tests cover automatic lookup, exact payload, multiple sessions
for one device, server GUID formats, rejected responses, incorrect session
matches, account changes during lookup, and local sign-out when the server is
unavailable. A live Flutter data-layer test also passed login, automatic session
lookup, revocation of all matching sessions, and local credential clearing.

An OTP request for an already registered address returned HTTP 500 with
`Email is already registered`, rather than a validation status.

Credentials are kept outside the repository. This was an API test, not a device
UI test; username and phone signup paths remain covered by simulated API tests.

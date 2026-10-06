# Signup with email OTP and profile details

The signup form uses the same single account input as login: **Username, Email
or Phone**, followed by password and confirmation. Phone input shows a manual
country selector beside the number field on both signup and Sign In. Cambodia
(`+855`) is the initial selection; typing or pasting a number never detects or
changes the selected country. Selecting another country leaves the entered
number intact. Local numbers are submitted with the selected prefix; an explicit
international number is submitted with its existing prefix only once.
After phone signup, Sign In restores the chosen country explicitly and displays
only the local number in the editable field. The server still receives the full
registered number with the country prefix once.

Email signup sends a six-digit OTP before account creation. Username and phone
signup skip email verification. Usernames accept letters (including Khmer),
numbers, and spaces, with at least one letter; symbols and punctuation are
rejected before any request. Outer whitespace is trimmed and internal spaces
are preserved.

Username signup completes after `/api/auth/register` succeeds. It does not
create an email from the username or call profile setup. If the register
response has no access token, it uses the existing credentials once to open an
authenticated session. It shows the glass success screen, and Done opens the
app directly.
Phone signup retains its separate profile setup. Login submits the documented
`account`, `password`, and device fields, without duplicating the account as
email/username/phone aliases. API-mocked tests cover matching username values
between registration and login; this is not live validation of existing accounts.

Each login route now creates its own auth controller. Previously, replacing the
signup stack could reuse the original login route's controller, then close it
when that route was removed. The visible Sign In button silently ignored taps.
A regression test uses the real route bindings to cover this transition.

The [Chat Swagger schema](https://chat.piisiit.com/swagger/v1/swagger.json),
checked on October 2, 2026, documents this flow:

1. Email only: `POST /api/auth/signup/send-otp` with `{email}`.
2. Email only: `POST /api/auth/verify-otp/email` with `{email, otp}`.
3. `POST /api/auth/register` with `{account, password, clientDeviceId,
   deviceName, platform, deviceModel, appVersion}`. `account` is the selected
   username, email, or normalized phone. Password confirmation is checked locally.
4. Email/phone flows use `POST /api/users/profile/save`, authorized using the new
   account's token. Username signup skips this step.
5. Clear temporary data and persist the new session. After successful
   registration (and profile saving where required), show the glass success
   screen. Email signup confirms verification; username and phone signup
   confirm account creation. Done or system back opens the app and replaces the
   signup stack. Repeated completion cannot push duplicate app routes.
6. The new session opens the app without requiring a second sign-in, and the
   authentication screens are removed from the navigation stack.

The register schema does not accept username or phone. Saving these through
`/api/users/profile/save` uses the documented `SaveProfileRequest` instead of
sending unsupported fields to register. If registration does not return an
access token, the app temporarily calls `/api/auth/login` with the new account's
credentials to authorize profile saving. The resulting credential is stored as
the new app session after registration completes. The profile request uses an isolated Dio
client sharing the transport adapter, so existing session interceptors cannot
replace its temporary credential.

Registration, sending/resending, and verification require an explicit boolean
`success: true` (or `Success: true`) envelope. HTTP 200 alone and message-only
or null-data responses without confirmation never show signup success. All
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
control. Enter the received code and tap Done on the success screen to open the
app, then check the saved profile. Also test an incorrect/expired
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

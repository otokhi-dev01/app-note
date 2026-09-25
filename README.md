# OTOKHI NOTE APP

A new Flutter project.

## API servers

Folders, notes, and attachments use `https://note.piisiit.com`. Folder creation
and updates send `POST /api/folder/save` with the logged-in user's bearer token.
Login, registration, and other account features use `https://chat.piisiit.com`.

To use a local Note server (the `piisiit_note_local` Postman variable), run:

```sh
flutter run --dart-define=PIISIIT_NOTE_BASE_URL=http://localhost:5000
```

Replace the example address with your Note server's address reachable from the
device. This override only changes the Note server; account requests still use
the Chat server. Restart the app after changing it.

## Card scanning

Open **Profile → My Cards → Add New Card → Start Scanning**. The app opens a
custom live camera with a blue card guide, front/back steps, a shutter, torch,
and photo-library import. Align the front within the guide, then turn the card
when prompted. Two matching OCR readings capture a side automatically; the
shutter can also capture each side. Use the back arrow to retake the front.
Review the detected details before saving, and correct any missing fields.

The camera uses Flutter's `camera` plugin, with Apple Vision on iOS and Google
ML Kit on Android for on-device recognition. No card photos are uploaded. Live
OCR samples are cropped to the guide, processed off the UI isolate, and their
temporary files are removed after recognition. Camera still captures are also
removed after OCR. Selecting a gallery image never deletes the original photo.

Automatic front capture requires a checksum-valid card number; automatic back
capture requires a stable security-code reading. Cards with the number on the
back can be captured using the shutter. Ambiguous or unreadable fields should
be entered manually. **Enter Card Manually** is available from the intro and
camera error screens. Camera permission can be enabled in Settings.

This flow uses the custom camera regardless of any old BlinkCard license
configuration. A full app restart is required after adding the camera plugin:

```sh
flutter run
```

Widget tests cover the two-side flow, gallery selection, camera lifecycle,
permission errors, and layouts. Camera focus, torch, rotation, and OCR accuracy
still need verification with physical cards on iPhone and Android. Cards remain
in memory for the session.

## Identity (Digital Civic ID) scanning

Open **Profile → Digital Civic ID → Camera Scan / New OCR**. Unlike card
scanning above, this flow uses Microblink's **BlinkID** SDK
(`blinkid_flutter`) when a license is configured — its native scanning UI
handles alignment, capture, and OCR/MRZ extraction entirely on-device.
Recognized details automatically save to encrypted, account-scoped storage and
appear in **Profile Details → ID Information**, including after restarting the app.
**View Profile Details** opens the saved result; a failed save offers a retry.
**Review & Upload Document** still opens an editable form to submit the document
and images to the account server. Profile autosave does not require an upload;
these local details are not synced across devices.

Configure a license (one per platform, tied to this app's bundle id /
`applicationId`, obtained from the
[Microblink Developer Hub](https://developer.microblink.com/)):

```sh
flutter run \
  --dart-define=BLINKID_IOS_LICENSE_KEY=... \
  --dart-define=BLINKID_ANDROID_LICENSE_KEY=...
```

Without a license configured for the current platform, this falls back to
the app's own camera screen. Throttled OCR inside the guide automatically
captures a side after two matching readings: ID heading/number/date on the front,
then a readable MRZ with valid document, DOB, and expiry check digits on the back.
Manual shutter and gallery selection remain available. Local MRZ parsing supplies
the ID number, Latin name, DOB, and expiry. A separate
offline Tesseract pass reads both captured photos with bundled Khmer and English
models and extracts labelled Khmer names, birth place, and current address.
These fields cannot come from MRZ; they require readable printed text. Unknown
fields remain explicitly marked as unread, with **Edit card details** available
for correction. No external OCR service receives images for this printed-text pass.

The full Khmer ID (both name scripts, addresses, dates, MRZ, and photo references)
and the profile summary are committed together in one encrypted per-account
snapshot. Camera photos are copied to app-private documents storage so previews
survive temporary-file cleanup. Reopening the Khmer ID screen restores the saved
card, and edits from either screen update the shared record. Existing profile-only
records migrate on the next save. Partial rescans of the same ID preserve previous
address corrections; a different ID does not inherit them.
Identity responses also retain document type, gender, nationality, issuing country,
issue date, and issuing authority. Both identity and Profile details display these
values; the upload review form prefills the supported document fields. Additional
response fields are preserved in the encrypted card snapshot and displayed as
labeled rows, including nested values. These fields survive card switching,
partial rescans, and profile edits. Generic Khmer names and addresses are shown
in their Khmer fields, and bundled Noto Sans Khmer fonts support offline display.
The published Chat Swagger currently documents document upload fields but no
identity-read/OCR response schema, so live response mapping still needs a confirmed
endpoint or a redacted sample response.

**Download Card** saves the generated PNG directly to Photos on iPhone and to
Pictures/Pii Note in the Android photo library. The front/back download buttons
save the original side images to the same library. iPhone requests permission to
add photos; Android 10+ saves without a storage permission prompt, while older
Android versions request storage access. Success appears only after the native
save completes. Denied permission displays instructions to enable access in
Settings. Desktop downloads retain the file-save dialog. Rebuild the phone app
after this change so the new native method and photo permission are included.

Server OCR is attempted only when local parsing fails; `AppConstants.identityApiUrl`
is still an unconfirmed endpoint. OCR capture does not verify document authenticity.

`test/identity_scan_test.dart` covers consecutive-frame capture, late camera
callbacks, local parsing/persistence, missing fields, account changes during OCR,
Khmer multiline addresses, screen restoration, two-way edits, and photo retention.
The iOS simulator build with the native OCR library passed. All 25 identity and
shared-camera tests passed, including Khmer model preparation
and cleanup. The OCR temporary-directory creation bug was also corrected in both
the live frame scanner and the full-photo text scanner. Android validation with a
temporary JDK 17 reaches an existing project blocker: `android/app/build.gradle.kts`
requires the missing `android/key.properties` even for debug/library builds. The
new Android native plugin still needs a build after signing configuration is available.
Real-device testing is still needed for lighting, focus, orientation, and OCR accuracy.

**Before shipping this**, note two things this integration did not change:

- The card-scanning flow above deliberately moved *away* from a Microblink
  SDK to the custom camera. Adding `blinkid_flutter` here reintroduces a
  Microblink dependency for a different feature — worth being a deliberate
  choice, not just a side effect of copying the card flow's old pattern.
- BlinkID's own requirements table calls for **AGP 9.1.0+** and **Kotlin
  2.2.21+** on Android; this project currently pins AGP 8.12.1 and Kotlin
  2.2.20 (`android/settings.gradle.kts`). iOS already meets BlinkID's
  requirement (deployment target 16.0). Bumping AGP a major version is a
  project-wide change with real breaking-change risk, so it wasn't done as
  part of this integration — do it deliberately, with a full Android build
  verification, before relying on BlinkID on Android.

## Identity document upload

Open **Profile → Digital Civic ID → Review & Upload Document**. You can enter
details manually without scanning, or review the scanned fields first. Document
type is editable text (the API specifies no enum); scanned IDs start with
`National ID`. The form accepts optional front/back images from the photo library.

The authenticated `POST https://chat.piisiit.com/upload-document` uses multipart
form data with required `DocumentType` and `DocumentNumber`. Optional fields are
`FullName`, `DateOfBirth`, `Gender`, `Nationality`, `IssuingCountry`, `IssuedDate`,
`ExpiryDate`, `IssuingAuthority`, `FrontImage`, and `BackImage`. Empty optional
fields are omitted and dates use ISO date-time strings. Only a successful API
envelope completes the upload; failures preserve the form for retry. Image files
are not deleted, and multipart retries recreate the form after session refresh.
An upload stores a document; it does not establish an OCR or identity-verification
result. Documents other than `National ID` do not overwrite the local ID card.

Swagger defines the request fields. An empty multipart request confirmed the live
server requires authentication (401). Tests in `test/document_upload_test.dart`
cover the multipart data/files, session refresh, validation, failures, and form
submission using simulated responses. A successful live upload and accepted
document-type values still need checking with a signed-in test account.

## Session recovery

Login, registration, and other account features use `https://chat.piisiit.com`.
Folders, notes, and attachments use `https://note.piisiit.com`. Folder creation
and updates send `POST /api/folder/save` with the logged-in user's bearer token.
A `code: 200` folder response with `data: null` is successful.

### Login diagnostics

Login and registration send only the fields defined in the Chat Swagger request:
`account`, `password`, `clientDeviceId`, `appVersion`, `deviceName`, `platform`, and
`deviceModel`. Account whitespace is trimmed; passwords are sent unchanged.

On September 18, 2026, a login with a deliberately nonexistent diagnostic account
returned HTTP 500 with `Success: false` and `Message: "Invalid credential!"`.
The app recognizes that specific rejection as an account/password error; unrelated
5xx failures remain server errors. The backend should return HTTP 401 for rejected
credentials. That server-side status-code issue is not fixed in this Flutter repo.

A successful response must contain a sign-in token. The app reports malformed
server responses and secure-storage failures separately, and only publishes the
session after storage succeeds. Late session restores cannot overwrite a new
login, and queued sign-out clears any pending session writes. Login transport and
storage regression tests are in `test/login_integration_test.dart`; a successful
live login still requires checking with a valid test account.

On launch, Splash and authenticated API requests await the same secure-storage
restore before choosing a route or attaching the bearer token. A temporary
Keychain read failure offers Retry without erasing saved credentials. A saved
account takes precedence over a stale guest flag. Login verifies that both token
and user can be read back before reporting success, and sign-out removes only
those credentials, preserving identity records and encryption keys. The iOS
entitlements explicitly include the app's private Keychain access group. Restart,
slow-read, unavailable-storage, and early-request cases are covered by
`test/session_restore_test.dart` and `test/login_integration_test.dart`.

Authentication route replacement now dismisses keyboard focus and drains pending
focus changes before removing the old screens. Notifications use the app's root
Flutter `ScaffoldMessenger`, so they are not owned by a separate GetX snackbar
overlay during navigation. Closed auth controllers ignore late responses.
Regression cases in `test/auth_flow_test.dart` and `test/snackbar_focus_test.dart`
cover a focused login field, overlapping notifications, and screen disposal.
These focus regression tests pass, along with login transport/storage, password
recovery, and guest-profile tests. The original device-specific login crash still
needs a confirmation run on the affected device.

### Forgot password

Login, Profile, and Settings open the same recovery screen. Enter a username,
email, or phone number, verify the delivered code, then enter and confirm a new
password. Resending has a 60-second UI cooldown; server rate limits and expired
code/token errors are shown with retry and start-again controls. A successful
reset clears the local session and offers sign-in with the new password.

**Use Security Questions** is available when entering an account or verifying
an OTP. It loads the current questions from the server. Select the questions
previously configured for the account, add rows as needed, and enter the saved
answers. Verified answers unlock the same new-password screen. This recovery
flow does not enroll or overwrite an account's security answers. Answers are
masked and stay in memory until the form is closed or verification succeeds.

The request contracts were checked against the
[Chat API Swagger document](https://chat.piisiit.com/swagger/v1/swagger.json)
on September 18, 2026:

- `POST /api/auth/password/forgot`: `{account}`
- `POST /api/auth/password/verify-otp`: `{account, otp}`
- `POST /api/auth/password/reset`: `{resetToken, newPassword, confirmPassword}`
- `GET /api/auth/password/security-questions`: reads `data: [{id, question}]`
- `POST /api/auth/password/verify-security`:
  `{account, answers: [{questionId, answer}]}`

All recovery requests are public and bypass bearer-token injection/session refresh.
The client requires a JSON `success: true` envelope; OTP/security verification must also
return a nonempty `data.resetToken` (or top-level `resetToken`). The reset token
stays in screen memory and is discarded on restart, completion, or disposal.

Automated tests in `test/password_recovery_test.dart` exercise the real client
and repository with simulated HTTP responses, plus the full screen flow.
Empty live requests confirmed the recovery envelope and required request fields.
Swagger does not describe successful response payloads, so the OTP token payload,
actual code delivery, and signing in with the changed password still need an
end-to-end check using a test account and its delivered code.
The live security-question list was also verified. Successful security recovery
still needs a test account with existing security answers; empty verification
requests currently return a 500 error envelope, which the client surfaces as a
failure without advancing to reset.

`POST /api/auth/password/google/verify` is a separate recovery method requiring
`{idToken}`. Google sign-in and its OAuth client configuration are not currently
present in this app, so this method is not exposed in the recovery UI.

### Authenticated session recovery

An authenticated 401 triggers one shared recovery attempt through Chat. The
original request is retried only when recovery produces a refreshed token, at
most once. A valid account session alone does not retry a Note request with the
same rejected token. There are no delayed replication-lag retries.
Chat Swagger requires `POST /api/auth/refresh-token` with JSON
`{"refreshToken":"..."}`. Login now parses and securely persists the refresh
token alongside the access token, and renewal saves rotated tokens before
retrying. Profile edits retain it; sign-out removes both tokens. The previous
empty POST caused HTTP 400 and could never renew a session.

Older saved sessions without a refresh token skip that POST and check the
documented authenticated `GET /api/auth/sessions` endpoint. If the account
rejects the session, the app returns to login; one new sign-in is needed to
obtain any refresh token issued by the backend. Timeouts and server failures
preserve credentials. Failed recovery and Note-only rejections of newly issued
tokens back off for 30 seconds instead of repeatedly refreshing. A valid Chat
session rejected by Note still requires checking the Note server's token
validation. `test/session_recovery_test.dart` covers renewal, rotation, restart,
concurrent 401s, legacy sessions, failures, and sign-out during refresh. Successful
live renewal still needs verification with an authenticated test account; Swagger
does not specify the successful login/refresh response bodies.

For a persistent 401, debug builds emit `[API] Auth diagnostics:` with JWT
issuer/audience metadata, token-format checks, device-clock validity checks,
and a category derived from `WWW-Authenticate`. This is diagnostic decoding,
not signature verification. Tokens, user claims, and raw authentication error
descriptions are omitted. `[API] Account recovery:` reports Chat's recovery
outcome. These two lines help identify the rejection without sharing credentials.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

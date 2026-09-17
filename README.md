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
handles alignment, capture, and OCR/MRZ extraction entirely on-device, and
the result is applied straight to the Profile screen's ID Information
(`IdentityScanController.onConfirm` → `ProfileController.applyScannedIdInformation`).
No backend call happens on this path.

Configure a license (one per platform, tied to this app's bundle id /
`applicationId`, obtained from the
[Microblink Developer Hub](https://developer.microblink.com/)):

```sh
flutter run \
  --dart-define=BLINKID_IOS_LICENSE_KEY=... \
  --dart-define=BLINKID_ANDROID_LICENSE_KEY=...
```

Without a license configured for the current platform, this falls back to
the app's own camera screen (front/back photo capture, same style as card
scanning) and submits both photos to a backend endpoint for OCR — see
`AppConstants.identityApiUrl` for why that endpoint is still an unconfirmed,
proposed contract rather than a live one.

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

## Session recovery

An authenticated 401 triggers one recovery attempt and at most one retry. If the
refresh endpoint rejects the request format, the app checks the account profile
endpoint before signing out. An explicit account-server rejection returns to
login; timeouts, server failures, and Note-only rejections with a valid account
session preserve the session. Persistent Note-only authorization errors require
checking the Note server's token validation; repeated client retries do not fix
that server-side condition.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

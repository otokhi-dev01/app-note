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

On iPhone, card scanning works without a BlinkCard license. When no BlinkCard
key is configured, the app uses its existing Apple document camera and on-device
text recognition. This flow does not use the Note server or upload card images.

Open **Profile → My Cards → Add Card → Start Scanning**, capture the card sides
(up to two), and tap **Save** in the camera. Review the detected number and expiry,
then fill in any missing fields. A card number must pass its checksum before
OCR is accepted. Unreadable names or security codes are left empty. Temporary
camera captures are deleted after recognition, including failed attempts.
**Enter Card Manually** is also available if the camera cannot read the card.

Stop and restart the app to pick up this change:

```sh
flutter run
```

Apple recognition uses [Vision](https://developer.apple.com/documentation/vision/vnrecognizetextrequest)
and the existing VisionKit document scanner. Camera accuracy still needs testing
with physical cards on a device; unit tests use simulated native responses.
Cards currently remain in memory for the session.

### Optional BlinkCard configuration

Android scanning requires a valid BlinkCard v3000 license. Configuring an iOS
license also selects BlinkCard on iPhone instead of Apple recognition.

1. Obtain a license from the [Microblink dashboard](https://developer.microblink.com/).
   The iOS license must cover `com.kimchheang.otokhi-note`; the current Android
   application ID is `com.example.otokhi001`.
2. Copy `config/blinkcard.example.json` to `config/blinkcard.local.json` if the
   local file does not exist, then enter the complete key for the platform.
   The local file is gitignored.
3. Run `flutter run --dart-define-from-file=config/blinkcard.local.json`, or use
   this workspace's **Note (card scanning)** VS Code launch configuration.

Use the same define-file option for builds that should use BlinkCard. Hot reload
cannot update compile-time keys. For rejected keys, check the platform, app ID,
SDK version and expiry. See [BlinkCard setup](https://github.com/BlinkCard/blinkcard-ios#readme).

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

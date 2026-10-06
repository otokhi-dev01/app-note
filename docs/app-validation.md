# App validation — 2026-10-04

Toolchain: Flutter 3.44.8 / Dart 3.12.2. Validation uses synthetic credentials, fake HTTP responses, and temporary storage. No production login, upload, account deletion, or messages were sent.

## Repairs

- Fixed deactivated-widget ancestor lookups in camera and rename dialogs; cancelled editor focus and menu actions when their owning widget/controller closes.
- Bound note and folder operations to their original account and account revision. Serialized queue replay and mutations so completed sync cannot erase newer edits. Removed the shared `unknown` owner fallback and kept authorization failures separate from offline work.
- Scoped profile extras and pending attachments by account, and restricted direct media bearer headers to the API origin.
- Required an explicit successful account-deletion response before signing out and removing that account's cache, queues, identity/passport collection, profile extras, pending attachments, and daily-note photos. Guest data and other accounts remain intact.
- Preserved passports when deleting the final identity card, handled passport-only records, and stopped deleted identity cards from reappearing through legacy keys.
- Allowed saving an empty note body. Restricted attachment deletion to managed app files; preserved files referenced by surviving notes and cleaned shared files when all references are deleted.
- Restored identity scan controls, profile images/details, date formatting, the card confirmation label, and printable identity PDF generation. Phone gallery saves still render PDFs as images.
- Added Quill localization delegates to the application. Repaired test fixtures for multipart refresh and profile storage.
- Allowed Android debug builds without release credentials, kept release signing mandatory, used Flutter's build version, added the missing ProGuard file, restored launcher icon resources and their version-control visibility, and configured the OCR dependency's [official JitPack repository](https://github.com/adaptech-cz/Tesseract4Android/blob/master/README.md).

## Verification

| Check | Result |
| --- | --- |
| Static analysis | Passed: no issues found. |
| Full unit/widget suite | Passed: 277 tests, zero failures. |
| iOS debug simulator build | Passed. |
| Android debug APK | Passed: `build/app/outputs/flutter-apk/app-debug.apk`. |
| iPhone simulator smoke test | In progress. |

Commands:

```sh
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter build ios --simulator --debug --no-pub
flutter build apk --debug --no-pub
flutter test integration_test/app_smoke_test.dart --no-pub -d <simulator-id> --reporter expanded
```

The simulator smoke test uses real application screens and bindings with temporary guest storage and a fake API. It creates and saves a note, then opens and closes the tested routes. It uses a default Material theme rather than the production Google Fonts theme, and starts at the folder route rather than splash/share startup.

## Limits and remaining product work

Automated tests cannot establish that every possible bug is absent. Physical camera, microphone, OCR accuracy, photo-library writes, real share intents, background behavior, and signed release builds still need device validation. Live authentication, OTP, Google OAuth, upload, and server deletion need configured services and a test account; this run tests their response handling with fakes.

The historical review also identifies product work beyond the repaired regressions: app-level note/media encryption, authenticated note locking, encryption/verification labels that exceed implemented protection, backup exclusions, confirmed cloud profile/OCR contracts, persistent payment-card storage, and backend support for signed-in permanent deletion. These remain unresolved; this validation is not a production-security certification. Existing unscoped profile extras are retained but no longer exposed to another account; ownership must be verified before migrating them.

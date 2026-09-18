# Offline identity OCR

Local Flutter plugin for the full-photo Khmer/English OCR pass after ID capture.
Live camera/MRZ detection continues to use the existing native recognizer.

- iOS: SwiftPM `libtesseract` 0.2.0, direct C API with recoverable initialization failures.
- Android: Tesseract4Android 4.9.0, single background executor; requires JDK 17 with this app's Gradle.
- Both platforms: bundled `khm+eng` LSTM models, no network calls during recognition.
- App service normalizes photo orientation, bounds resolution, and removes OCR working files.

Model source: https://github.com/tesseract-ocr/tessdata_fast (Apache-2.0).
The model license is included at `assets/tessdata/LICENSE` in the app.
Native dependency sources and licenses:
https://github.com/SwiftyTesseract/libtesseract
https://github.com/adaptech-cz/Tesseract4Android

The iOS simulator app build passed. Android build validation is blocked by the
app build script requiring missing `android/key.properties`, including for debug
tasks. Real-card OCR quality still needs a device check;
blur, glare, missing labels, or unusual card layouts can leave fields unread.
The card editor allows users to correct those fields while keeping both screens in sync.

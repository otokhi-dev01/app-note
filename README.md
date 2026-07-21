# Piisiit Note

A Flutter note application with folders, rich note editing, authentication,
recycle-bin recovery, themes, and English/Khmer localization.

## Project structure

- `lib/app`: application setup, routes, theme, translations, and splash flow.
- `lib/core`: shared networking, configuration, storage, and UI primitives.
- `lib/feature`: feature-first data, domain, and presentation code.
- `test`: behavior tests plus architecture guards.

Each named widget class lives in its own Dart file. Feature-local private
widgets use `part` files, while widgets shared by multiple screens live in a
feature's `widgets/common` directory or in `core/presentation/widgets`.

## Configuration

The default backend is `https://note.piisiit.com`. Override it at build time
when needed:

```sh
flutter run \
  --dart-define=API_BASE_URL=https://example.com \
  --dart-define=AUTH_BASE_URL=https://example.com
```

## Quality checks

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

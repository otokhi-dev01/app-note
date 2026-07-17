# Notes

Notes is a Flutter application for writing, organizing, and finding notes. It
supports folders, tags, attachments, light and dark themes, an account-scoped
local cache, and remote note synchronization.

## Requirements

- Flutter compatible with the SDK constraint in `pubspec.yaml`
- Dart 3.11.5 or newer, below Dart 4
- CocoaPods when building the iOS target

## Run the app

```sh
flutter pub get
flutter run
```

The application starts in `lib/main.dart`. App-wide routing, dependency
registration, and themes live under `lib/app`.

## API configuration

The app uses `https://note.piisiit.com` by default. API hosts are compile-time
settings supplied with Dart defines:

```sh
# Use a development API for this run. A non-empty local value takes precedence.
flutter run --dart-define=PIISIIT_NOTE_LOCAL=https://dev-api.example.com

# Override the production API for a release build.
flutter build apk --release \
  --dart-define=PIISIIT_NOTE_PROD=https://api.example.com
```

Use an absolute HTTPS origin without an API route suffix; the app adds paths
such as `/api/auth/login` and `/api/note`. HTTPS is required for consistent
Android, iOS, and macOS behavior. Because Dart defines are compiled into the
application, restart or rebuild after changing them.

## Project structure

```text
lib/
├── app/                  # Bootstrap, routing, dependency injection, and theme
├── core/                 # Reusable infrastructure and cross-feature utilities
├── features/             # Feature-first modules
│   └── <feature>/
│       ├── data/         # API, persistence, DTOs, and repository implementations
│       ├── domain/       # Entities, repository contracts, and use cases
│       └── presentation/ # Pages, controllers, bindings, and widgets
└── main.dart             # Flutter entry point
```

The implementation lives entirely in feature-first modules; the previous
layer-first `data`, `domain`, `presentation`, and `shared` trees have been
removed. See [Architecture](docs/architecture.md) for dependency rules.

## Quality checks

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
git diff --check
```

Run the formatter without `--output=none` before committing code that needs
formatting.

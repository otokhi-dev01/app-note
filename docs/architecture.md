# Architecture

## Goals

The project uses feature-first clean architecture so that a feature can evolve
without turning app bootstrap, shared infrastructure, or unrelated screens into
change hotspots. The practical rules are:

- keep business rules independent from Flutter, GetX, HTTP, and persistence;
- keep serialization and platform APIs at the data boundary;
- keep widgets focused on rendering and forwarding user intent;
- wire concrete implementations only at an application composition root.

## Dependency direction

```text
app bootstrap / bindings
        │
        ├──────────────► feature presentation
        │                        │
        │                        ▼
        └────► feature data ───► feature domain
                                  ▲
                                  │
                           repository contracts
```

The domain layer is the stable center:

- **Domain** contains entities, repository contracts, and use cases. It must not
  import Flutter, GetX, database packages, HTTP clients, or a data model.
- **Data** implements domain contracts and owns API payloads, local database
  rows, secure storage, and mapping between DTOs and domain entities.
- **Presentation** owns pages, controllers, bindings, and feature widgets. It
  depends on domain use cases or feature-facing facades rather than concrete
  storage and API implementations.
- **App** owns startup, route registration, global dependency composition, and
  theme selection. It may see concrete data implementations because it connects
  them to domain contracts.
- **Core** is reserved for genuinely cross-feature code. Core must not import a
  feature's data or presentation layer.

Dependencies between two features should go through a small public facade or a
domain contract. A feature must not reach into another feature's private
widgets, controllers, or data sources.

## Feature layout

A feature uses only the folders it needs:

```text
lib/features/<feature>/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── bindings/
    ├── controllers/
    ├── pages/
    ├── widgets/
    └── <feature>.dart
```

The presentation barrel exports only the route-visible or intentionally public
surface. Helpers and implementation widgets remain unexported.

### Library feature

The library feature currently exposes these route pages from
`package:notes/features/library/presentation/library.dart`:

- `MediaGalleryView`
- `TagsManagerView`
- `NoteCalendarView`
- `SmartCategoriesView`
- `StorageManagementView`
- `NoteHistoryView`

Its shared visual building blocks live in
`presentation/widgets/library_components.dart`. Pure tag and history queries
live in `application/library_note_queries.dart`; local attachment sizing is a
data implementation of the `AttachmentSizeQuery` application port. Visual-only
decoration helpers remain in presentation.

The pages depend on the framework-free `LibraryCoordinator` facade. The home
shell implements that small contract and is registered under the interface by
its binding, so library presentation never imports notes presentation.

## Imports and public API

- Use `package:notes/...` imports across features or architectural layers.
- Use relative imports for nearby implementation files inside one feature.
- Import a feature through its public barrel when consuming its route-visible
  API.
- Do not create broad barrels that export models, data sources, widgets, and
  controllers together; they hide dependency violations and cause name
  collisions.

Public constructors and method signatures used by routes, bindings, tests, and
subclasses are compatibility contracts. Structural work must not silently make
an injectable constructor private, convert an extendable service to
`final`/`sealed`, or change positional parameters to named parameters.

## State and dependency injection

GetX bindings are composition code. A binding may resolve a repository contract
and construct use cases/controllers, but widgets should not register global
services while building. Controllers own disposable UI state such as text
controllers and reactive values, and must release those resources in
`onClose`.

Asynchronous startup work must finish or fail safely. Session restoration and
theme restoration should remain testable without requiring a real device or
network.

## Data boundaries

Unstructured `dynamic` maps are acceptable only at API and persistence
boundaries. Convert them immediately to typed data models, validate required
values, and expose only domain entities through repository contracts. UI code
must not know server field aliases, database column names, authentication
storage keys, HTTP response envelopes, or local file APIs.

Local records are account-scoped. Repository refactors must preserve owner
identifiers and must not expose cached notes from one authenticated account to
another.

## Verification

Use these checks for every architecture slice:

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
git diff --check
```

Run focused tests while iterating, followed by the complete suite before handoff.
Native iOS and macOS placeholder tests are separate from `flutter test`; run
platform builds when a change affects plugins, entitlements, CocoaPods, or native
entry points.

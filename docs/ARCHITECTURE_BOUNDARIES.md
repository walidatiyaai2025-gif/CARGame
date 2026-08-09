# CARGame Architecture Boundaries

## Purpose

ENG-005 establishes enforceable dependency directions without a destabilizing repository-wide rewrite. Existing player saves, gameplay state, economy rules, navigation, optional-service isolation, and screen contracts remain authoritative while boundaries are migrated incrementally.

## Dependency direction

Dependencies point inward toward stable policy:

`composition root -> adapters/presentation -> application -> domain`

### Domain — `lib/core/domain/`

- Pure Dart state and business vocabulary.
- May depend only on Dart SDK and other `core/domain` sources.
- Must not import Flutter UI, plugins, feature presentation, storage, ads, services, assets, motion, navigation, theme, or widgets.

### Application — `lib/core/application/`

- Use-case/service ports and orchestration contracts.
- May depend only on Dart SDK, `core/domain`, and `core/application`.
- Must not know Flutter widgets, feature screens, persistence adapters, ad implementations, optional-service implementations, assets, motion, theme, or navigation UI.

### Storage adapters — `lib/core/storage/` and settings persistence

- Own local persistence, migration/recovery behavior, and platform-backed preferences.
- May implement application ports as those ports are introduced.
- Storage keys and migration compatibility remain stable during ENG-005.

### External/optional services — `lib/core/services/` and `lib/core/ads/`

- Own SDK/plugin implementations, retries, timeouts, and external side effects.
- Depend inward on application/domain contracts where appropriate.
- Core gameplay must remain usable when these adapters are unavailable.

### Presentation — `lib/features/`, shared theme/widgets/navigation

- Own widgets, screen state, localization presentation, accessibility, and user interaction.
- Shared motion/assets/theme/widgets are presentation infrastructure and must never be imported by domain/application layers.
- Some existing screens still depend directly on `ProgressStore` or ad adapters. This is recorded migration debt: ENG-005 forbids adding new inward-layer violations first, then moves screen dependencies behind ports in reviewable checkpoints rather than a mass rewrite.

### Assets and motion — `lib/core/assets/`, `lib/core/motion/`

- Presentation support only.
- They may consume domain/application values but cannot become sources of reward, persistence, economy, or navigation truth.

### Analytics

- Analytics is a reserved outward adapter boundary.
- Future analytics must enter through an application port and privacy/consent gate; domain/application code must not import an analytics SDK.

### Composition root — `lib/bootstrap/`

- The only layer intentionally allowed to know concrete storage/settings/service implementations together.
- `AppComposition` owns construction and disposal of process-level dependencies.
- `main.dart` remains the Flutter entry point and consumes the composition root instead of constructing concrete adapters directly.

## Executable contract

`tool/architecture/architecture_contract.dart` scans `core/domain` and `core/application` imports/exports. `test/core/architecture/architecture_dependency_test.dart` fails when an inward layer imports a forbidden outward layer or package.

The contract also verifies that `main.dart` uses `bootstrap/app_composition.dart` rather than directly importing ProgressStore, AppSettingsStore, or OptionalServiceCoordinator.

## Compatibility rules

- No storage key rename or schema move is part of this checkpoint.
- No gameplay/reward/economy formula changes are part of architecture migration.
- Existing imports from `optional_service_coordinator.dart` continue to expose `OptionalServiceStatus` and `OptionalServiceSnapshot` through re-export compatibility.
- Boundary migrations must preserve public screen constructors until callers/tests are migrated in the same reviewed checkpoint.
- Every new domain/application source is covered automatically by the architecture contract.

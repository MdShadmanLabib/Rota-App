# Architecture

## Overview
Rota is a SwiftUI app built around **MVVM + a repository abstraction**, with dependency injection at the app root. The guiding principle: **views depend on view models, view models depend on a single repository protocol** — never on a concrete backend.

```
View  ─▶  ViewModel (@Observable)  ─▶  RotaRepository (protocol)
                                          ├── MockRepository      (in-memory sample data)
                                          └── SupabaseRepository   (PostgREST + Auth + Realtime)
```

## Layers

### App
- `RotaApp` — `@main` entry; builds `AppEnvironment`, injects `SessionStore` + `ToastCenter`.
- `AppEnvironment` — composition root; picks Mock vs Supabase from `AppConfig`.
- `SessionStore` (`@Observable`) — top-level state: current user, organization, auth `phase` (loading / unauthenticated / locked / authenticated). Drives root routing and biometric unlock.
- `RootView` — switches between onboarding, auth, biometric lock and the role-based home (`EmployerHomeView` / `EmployeeHomeView`).

### Features
Each feature is a folder with a `View` + an `@Observable` `ViewModel`. View models expose a `LoadState` (`idle/loading/loaded/failed`) and call the repository via async/await. UI state changes are animated with shared `Theme.Motion` springs.

### Models
Plain `Codable, Sendable, Identifiable` structs (`Shift`, `LeaveRequest`, `TimeEntry`, `UserProfile`, `Organization`, `ShiftTemplate`, `SwapRequest`, `Announcement`, `Availability`). Enums (`Role`, `ShiftStatus`, `RequestStatus`, `LeaveType`) carry display + capability helpers.

### Services
- **Repositories** — `RotaRepository` is the one data contract used everywhere.
  - `MockRepository` is an `actor` over `SampleData`, simulating latency and persisting the demo session.
  - `SupabaseRepository` maps the same contract onto PostgREST queries with snake_case JSON coding.
- **System** — pure/utility services: `SchedulingEngine` (conflict/overtime/auto-assign, pure functions), `BiometricAuth`, `LocationProvider`, `PDFExporter`.

### Design system
`DesignSystem/Theme` holds tokens (`Theme.Colors/Spacing/Radius/Shadow/Motion`) and `Font.Rota` typography. `DesignSystem/Components` holds reusable primitives. Everything reads from tokens so light/dark and future re-theming are trivial.

## State & concurrency
- View models are `@MainActor @Observable`. Async work uses structured concurrency (`async let` for parallel fetches).
- `MockRepository` is an `actor` for safe shared mutable state; the repository protocol is `Sendable`.
- `SWIFT_STRICT_CONCURRENCY = targeted` to balance safety with pragmatic adoption.

## Data flow example (clock-in)
1. `ClockView` calls `ClockViewModel.clockIn(...)`.
2. VM optionally fetches a one-shot location (`LocationProvider`) and validates it against the org geofence.
3. VM builds a `TimeEntry` and calls `repository.clockIn(_:)`.
4. Mock appends in-memory / Supabase inserts a row (RLS enforces `user_id = auth.uid()`).
5. VM updates `activeEntry`, starts the live timer; the view reflects the new state with a spring animation + haptic.

## Why these choices
- **Repository protocol + Mock** → the whole app is demoable and testable without a backend, and the backend can be swapped or stubbed freely.
- **`@Observable`** → less boilerplate than `ObservableObject`, fine-grained invalidation.
- **XcodeGen** → no merge-conflict-prone `.pbxproj`; the project is reproducible from `project.yml`.
- **Supabase** → managed Postgres + Auth + Realtime + RLS gives role-based security at the data layer with minimal ops.

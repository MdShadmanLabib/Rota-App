# Rota — Workforce & Shift Scheduling for iOS

A modern, premium rota / workforce-management app for small and mid-sized teams — think Deputy / WhenIWork / Homebase, but **simpler, cleaner and faster**. Built with **SwiftUI (iOS 18+)**, MVVM, and a **Supabase** backend, with a fully-featured **mock mode** so it runs in the Simulator with zero setup.

> **Heads-up:** this repository was authored in a Linux environment and cannot be compiled there. Build and run it on a Mac with **Xcode 16+**. See [Getting started](#getting-started).

## Highlights

- **Two role-based experiences** from one codebase — Employer/Admin and Employee/Staff — routed automatically from the signed-in user's role.
- **Runs instantly in MOCK mode** with a rich, realistic dataset (no backend required). Flip a single flag to use real Supabase.
- **Premium design system** — tokens for color, type, spacing, radius, motion; reusable components (cards, buttons, segmented control, stat tiles, skeletons, toasts, empty states); full light/dark support.
- **Smart scheduling** — conflict/clash detection, overtime warnings and a heuristic auto-scheduler (pure, unit-tested functions).
- **Native data viz** with Swift Charts (coverage, hours worked, scheduled-vs-worked, role distribution, top performers).

## Features

### Employer / Admin
- Weekly rota builder with day & week views, drag-and-drop assignment, templates and one-tap auto-schedule
- Create / edit / delete shifts, notes per shift, open-shift handling, emergency reassignment
- Approve / reject leave and shift-swap requests
- Live team status, attendance & clock-in tracking
- Analytics dashboard + payroll hours summary, **export weekly rota to PDF**
- Team announcements, shift templates, staff availability, organization settings (overtime threshold, geofence radius)

### Employee / Staff
- Personal dashboard with next shift, weekly hours and announcements
- View rota (week navigation), **clock in/out** with optional geofenced verification
- Request leave, request shift swaps, set weekly availability
- Worked-hours history with charts, profile management, biometric unlock

### Smart / UX
Conflict detection · overtime warnings · shift-clash prevention · heuristic auto-scheduling · location-aware clock-in · biometric (Face ID/Touch ID) login · dark mode · onboarding · empty & skeleton states · spring animations · haptics · accessibility · fast search/filter · realtime-ready.

## Tech stack

| Layer | Choice |
|------|--------|
| UI | SwiftUI, Swift Charts, iOS 18+ |
| Architecture | MVVM, `@Observable`, async/await, repository pattern + DI |
| Backend | Supabase (Auth, Postgres + RLS, Realtime) with a swappable Mock |
| Persistence | Lightweight on-device cache; Supabase as source of truth |
| Project gen | XcodeGen (`project.yml`) |

## Getting started

```bash
# 1. Install XcodeGen (once)
brew install xcodegen

# 2. Generate the Xcode project
cd Rota-App
xcodegen generate

# 3. Open and run (defaults to MOCK mode — no backend needed)
open Rota.xcodeproj
# Select the "Rota" scheme + an iOS 18 simulator, then ⌘R
```

**Demo logins (MOCK mode)** — password is `password` for every seeded account:
- Employer: `owner@rota.app`
- Employee: `alex@rota.app`
- Employer sign-up needs no code; employee sign-up invite code is `BREW42`.

To use a real backend, see [docs/SETUP.md](docs/SETUP.md).

## Project structure

```
Rota/
  App/            App entry, DI container, session store, root routing
  Config/         Build config + secrets template
  Core/           Errors, extensions, small utilities
  DesignSystem/   Theme tokens, typography, haptics, reusable components
  Features/
    Auth/ Onboarding/
    Employer/     Dashboard, Rota builder, Team, Requests, Analytics, …
    Employee/     Dashboard, Rota, Clock, Requests, Availability, Hours
    Profile/ Shared/
  Models/         Domain models (Codable, Sendable)
  Services/
    Repositories/ RotaRepository protocol (single data contract)
    Mock/         In-memory repository + sample data
    Supabase/     PostgREST repository + client wrapper + JSON coders
    System/       SchedulingEngine, BiometricAuth, LocationProvider, PDFExporter
RotaTests/        Unit tests (scheduling engine, date/number helpers)
supabase/         SQL migrations (schema, RLS, realtime) + seed
docs/             Setup, architecture, database, security, business docs
```

## Documentation
- [Setup guide](docs/SETUP.md) — Supabase project, env config, running locally
- [Architecture](docs/ARCHITECTURE.md) — layers, state, data flow
- [Database & schema](docs/DATABASE.md) — tables, RLS, realtime
- [Security](docs/SECURITY.md) — auth, RLS, secrets, privacy
- [Business: monetisation, subscriptions, scaling, App Store](docs/BUSINESS.md)

## Tests
Unit tests live in `RotaTests/` and run via the `Rota` scheme (`⌘U`) or CI. They cover the pure scheduling logic and formatting helpers — the parts most worth protecting from regressions.

## License
Provided as a starter/reference implementation for the requesting team. Add your preferred license before publishing.

# Setup guide

## Prerequisites
- macOS with **Xcode 16+** (iOS 18 SDK)
- [XcodeGen](https://github.com/yonyz/XcodeGen) — `brew install xcodegen`

## 1. Generate & run (MOCK mode, zero backend)
```bash
xcodegen generate
open Rota.xcodeproj
```
The app ships in **MOCK** mode: a full in-memory dataset powers every screen so you can explore both the employer and employee experiences immediately. Demo accounts (password `password`): `owner@rota.app`, `alex@rota.app`. Employee invite code: `BREW42`.

## 2. Wire up a real Supabase backend (optional)

1. Create a project at [supabase.com](https://supabase.com).
2. Apply the SQL migrations (in order) from `supabase/migrations/` using the Supabase SQL editor or the CLI:
   ```bash
   supabase db push        # if using the Supabase CLI with this repo linked
   # — or paste 0001_init.sql, 0002_rls.sql, 0003_realtime.sql into the SQL editor
   ```
   Optionally run `supabase/seed.sql` to create the demo organization + templates.
3. In **Project Settings → API**, copy the **Project URL** host (without `https://`) and the **anon public** key.
4. Configure the app's build settings:
   ```bash
   cp Rota/Config/Secrets.example.xcconfig Rota/Config/Secrets.xcconfig
   ```
   Edit `Secrets.xcconfig`:
   ```
   SUPABASE_URL_HOST = your-project-ref.supabase.co
   SUPABASE_ANON_KEY = ey...
   BACKEND_MODE      = SUPABASE
   ```
5. Point the project at the real config (instead of the example) and regenerate:
   - In `project.yml`, under the `Rota` target `configFiles`, change both `Debug`/`Release` to `Rota/Config/Secrets.xcconfig`, then `xcodegen generate`.

`Secrets.xcconfig` is git-ignored. If `BACKEND_MODE=SUPABASE` but the URL/key are missing, the app safely falls back to MOCK mode.

## 3. Auth & profiles
- Sign-up uses Supabase Auth (email/password). A Postgres trigger (`on_auth_user_created`) creates a matching `profiles` row, defaulting role from sign-up metadata.
- New employers create/are attached to an organization; employees join via an invite code. Adjust this onboarding to your org-provisioning policy as needed.

## 4. Push notifications (optional)
Supabase doesn't send APNs directly. Recommended path:
- Add an Edge Function triggered on insert to `shifts` / `leave_requests` / `announcements`.
- Store device tokens (register for remote notifications client-side) and send via APNs from the function.
The Info.plist already declares the `remote-notification` background mode.

## Troubleshooting
- **"No such module 'Supabase'"** → run `xcodegen generate` and let SPM resolve packages on first build.
- **Build fails on signing** → for Simulator runs no signing is needed; for devices set `DEVELOPMENT_TEAM` in `Secrets.xcconfig`.
- **Empty screens with a real backend** → confirm migrations ran, RLS policies exist, and the signed-in profile has an `organization_id`.

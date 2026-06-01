# Database & schema

Postgres on Supabase. Migrations live in `supabase/migrations/` and are applied in order.

| File | Purpose |
|------|---------|
| `0001_init.sql` | Enums, tables, indexes, new-user trigger |
| `0002_rls.sql` | Row-Level Security policies + helper functions |
| `0003_realtime.sql` | Adds tables to the `supabase_realtime` publication |
| `seed.sql` | Optional demo organization + shift templates |

## Tables
- **organizations** — workspace + settings (timezone, weekly overtime threshold, workplace lat/lng, clock-in radius, invite code).
- **profiles** — one per `auth.users` row; role, organization, hourly rate, contact details.
- **shifts** — scheduled work: title/role/location, start/end, break minutes, assignee, status, notes, colour.
- **shift_templates** — reusable shift presets for fast rota building.
- **leave_requests** — type, date range, reason, status, reviewer.
- **swap_requests** — shift, requester, optional target, message, status.
- **time_entries** — clock in/out times, optional geo, capture method.
- **availability** — per-weekday availability windows per user.
- **announcements** — team updates with pin + author snapshot.

Column naming is `snake_case`; the Swift client uses `convertFromSnakeCase` / `convertToSnakeCase` JSON coding so models stay idiomatic Swift.

## Security model (RLS)
Two `security definer` helpers avoid recursive policy evaluation on `profiles`:
- `current_org_id()` → the caller's `organization_id`.
- `is_manager()` → true for `owner` / `admin` / `manager`.

Policy summary:
- **Read**: any authenticated member can read rows in **their own** organization.
- **Scheduling writes** (shifts, templates, availability rules, announcements): **managers only**.
- **Self-service writes** (own leave, own swaps, own time entries, own availability): the owning **employee** (managers too).
- **Organizations**: members read; managers update.

Because every table is scoped by `organization_id` and gated by `auth.uid()`, a compromised client still cannot read or mutate another org's data.

## Realtime
`0003_realtime.sql` publishes `shifts`, `leave_requests`, `swap_requests`, `time_entries`, `announcements`, and `availability`. Subscribe client-side (Supabase Realtime channels) to drive live team status and rota updates. The repository contract is realtime-ready; wire channel callbacks into the relevant view models to push changes into the UI.

## Indexing
Hot paths are indexed: shifts by `(organization_id, start_at)` and `(assigned_user_id, start_at)`, time entries by org/user + time, plus org indexes on requests and announcements. Add composite indexes as query patterns grow.

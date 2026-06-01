# Business: monetisation, subscriptions, scaling & App Store

## Monetisation

**Model:** B2B SaaS, **per-active-employee / month**, billed to the employer. This is the proven model for the category (Deputy, When I Work, Homebase) and aligns cost with value.

Revenue levers:
- **Per-seat subscription** (primary).
- **Tiered plans** unlocking advanced scheduling, analytics, integrations.
- **Add-ons:** payroll export/integration, SMS notifications, advanced reporting.
- **Annual billing** discount to improve retention & cash flow.

## Suggested subscription tiers

| Plan | Price (illustrative) | For | Key features |
|------|----------------------|-----|--------------|
| **Free** | £0 (up to 5 staff) | Tiny teams trying it out | Rota builder, clock in/out, requests, announcements |
| **Starter** | ~£2.50 / user / mo | Single-site SMBs | Everything in Free + templates, availability, basic analytics, PDF export |
| **Pro** | ~£4.50 / user / mo | Growing / multi-team | + Auto-scheduling, overtime/conflict insights, geofenced clock-in, advanced charts |
| **Business** | Custom | Multi-site / chains | + Multiple locations, roles & permissions, payroll/integrations, priority support, SSO |

Implementation: gate features behind a `plan` on the organization; use **StoreKit 2** if billing individual operators via the App Store, or Stripe for invoiced B2B (most workforce tools bill outside IAP as a business service).

## Free-to-paid conversion
- Generous free tier capped by **headcount**, not core usefulness.
- Show value early: auto-schedule suggestion + "you're approaching overtime" nudges are natural Pro upsell moments.
- In-app upgrade prompts at the point of friction (e.g. adding the 6th employee, exporting PDF).

## Scaling recommendations

**Data & backend**
- Postgres scales vertically a long way; add **composite indexes** as query shapes emerge, and paginate rota/history queries by date window (already date-scoped).
- Partition `time_entries` / `shifts` by month once volume is large.
- Use **Realtime** selectively (status + current week) to limit fan-out; fall back to pull-to-refresh elsewhere.
- Cache read-heavy, rarely-changing data (org, team) on device; invalidate on realtime events.

**App**
- Repository abstraction means you can introduce an offline store (e.g. SwiftData/SQLite) behind `RotaRepository` without touching views.
- Keep view models thin; push shared logic into `SchedulingEngine`-style pure functions (testable, reusable).

**Org & multi-site**
- Model locations as a child of organization; extend RLS with a `location_id` scope.
- Add an explicit memberships table if users can belong to multiple orgs.

**Ops**
- Edge Functions for notifications and scheduled jobs (reminders, no-show detection).
- Observability: Supabase logs + a crash/analytics SDK; alert on auth and error-rate anomalies.

## Suggested App Store screenshots (6.7" + 5.5")
1. **Employer dashboard** — coverage at a glance, today's shifts, live status. Caption: *"Run your rota in seconds."*
2. **Weekly rota builder** — week grid with assignments + auto-schedule. Caption: *"Build the week with one tap."*
3. **Employee home** — next shift + weekly hours. Caption: *"Your shifts, always in your pocket."*
4. **Clock in/out** — big timer + geofence check. Caption: *"Clock in from the right place."*
5. **Requests** — leave & swaps with clean status pills. Caption: *"Time off and swaps, sorted."*
6. **Analytics** — Swift Charts hours/coverage. Caption: *"Insights that save money."*
7. **Dark mode** — same screen in dark. Caption: *"Beautiful in light and dark."*

Tips: use device frames, a consistent accent gradient background, one short benefit-led caption each, and localise for primary markets.

## App Store listing essentials
- Name/subtitle emphasising clarity & speed ("Rota — Shifts & Scheduling").
- Privacy policy URL + completed Privacy Nutrition Label (location, contact info).
- Keywords: rota, shift, schedule, timesheet, clock in, workforce, staff, employee.
- Support URL + marketing URL; demo account credentials for review (MOCK mode is ideal for reviewers).

# Security & privacy

## Authentication
- Supabase Auth (email/password) issues JWTs; the SDK persists and refreshes the session in the Keychain.
- `SessionStore` restores the session on launch and can gate access behind **biometrics** (Face ID / Touch ID) when the user opts in.
- Sign-out clears the session and in-memory user/org state.

## Authorization (defense in depth)
- **Server-side (authoritative):** Row-Level Security on every table scopes data by `organization_id` and `auth.uid()`. Managers vs employees are distinguished by `is_manager()`. The client cannot bypass these rules.
- **Client-side (UX):** `Role` capability checks hide actions the user can't perform (e.g. only managers see compose/approve controls). This is convenience, not security — the database is the source of truth.

## Secrets handling
- No secrets are committed. `Secrets.xcconfig` is git-ignored; only `Secrets.example.xcconfig` (placeholders) is tracked.
- The Supabase **anon key** is a public client key and is safe to ship — it is meaningless without RLS-passing auth. Never embed the **service-role** key in the app.
- Build config is injected via xcconfig → Info.plist → `AppConfig`, keeping keys out of source.

## Data protection
- Sensitive auth tokens live in the Keychain (handled by the Supabase SDK).
- Location is requested **only** at clock-in (`when-in-use`), used to compute distance to the workplace, and not tracked in the background. Usage strings are declared in Info.plist.
- Camera permission is declared for QR check-in and requested only on use.

## Privacy
- Collect the minimum: profile basics, shifts, time entries, optional clock-in coordinates.
- Provide account deletion (cascades via FKs) and document data retention before App Store submission (a privacy policy URL is required).
- Complete the App Store **Privacy Nutrition Label** (identifiers, location, contact info as applicable).

## Hardening checklist before production
- [ ] Review every RLS policy against your real org-provisioning flow.
- [ ] Enforce strong password / enable MFA in Supabase Auth settings.
- [ ] Rate-limit and validate Edge Functions (e.g. push senders).
- [ ] Rotate keys if ever exposed; restrict the service-role key to server use only.
- [ ] Add logging/alerting for auth anomalies.

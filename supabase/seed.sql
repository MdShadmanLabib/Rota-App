-- Rota — optional seed for a fresh Supabase project.
--
-- Profiles are created automatically by the on_auth_user_created trigger when
-- users sign up, so we only seed an organization (with a known invite code)
-- plus a few shift templates. After your first employer signs up, set their
-- profile.organization_id to this org (or create the org from the app).
--
-- NOTE: the in-app MOCK mode already ships with a full realistic dataset, so
-- this seed is only needed when wiring up a real backend for demos.

insert into organizations (id, name, invite_code, timezone, weekly_overtime_threshold, clock_in_radius_meters)
values ('00000000-0000-0000-0000-0000000000a0', 'Brew & Co.', 'BREW42', 'Europe/London', 40, 150)
on conflict (id) do nothing;

insert into shift_templates (organization_id, name, role, start_time, end_time, break_minutes, color_hex)
values
  ('00000000-0000-0000-0000-0000000000a0', 'Opening', 'Barista', '07:00', '15:00', 30, '#6366F1'),
  ('00000000-0000-0000-0000-0000000000a0', 'Mid', 'Floor', '11:00', '19:00', 45, '#10B981'),
  ('00000000-0000-0000-0000-0000000000a0', 'Closing', 'Barista', '15:00', '23:00', 30, '#F59E0B')
on conflict do nothing;

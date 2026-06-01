-- Rota — Row Level Security
-- Role-based access: every row is scoped to an organization. Members can read
-- their org's data; managers (owner/admin/manager) can write scheduling data;
-- employees can manage their own requests, time entries and availability.

-- ---------------------------------------------------------------------------
-- Helper functions (security definer to avoid recursive RLS on profiles)
-- ---------------------------------------------------------------------------
create or replace function public.current_org_id()
returns uuid
language sql stable security definer set search_path = public
as $$ select organization_id from public.profiles where id = auth.uid() $$;

create or replace function public.is_manager()
returns boolean
language sql stable security definer set search_path = public
as $$
  select coalesce(
    (select role in ('owner', 'admin', 'manager') from public.profiles where id = auth.uid()),
    false
  )
$$;

-- ---------------------------------------------------------------------------
-- Enable RLS
-- ---------------------------------------------------------------------------
alter table organizations   enable row level security;
alter table profiles        enable row level security;
alter table shifts          enable row level security;
alter table shift_templates enable row level security;
alter table leave_requests  enable row level security;
alter table swap_requests   enable row level security;
alter table time_entries    enable row level security;
alter table availability    enable row level security;
alter table announcements   enable row level security;

-- Organizations -------------------------------------------------------------
drop policy if exists org_select on organizations;
create policy org_select on organizations for select
  using (id = public.current_org_id());

drop policy if exists org_update on organizations;
create policy org_update on organizations for update
  using (id = public.current_org_id() and public.is_manager());

drop policy if exists org_insert on organizations;
create policy org_insert on organizations for insert
  with check (auth.uid() is not null);

-- Profiles ------------------------------------------------------------------
drop policy if exists profiles_select on profiles;
create policy profiles_select on profiles for select
  using (organization_id = public.current_org_id() or id = auth.uid());

drop policy if exists profiles_update_self on profiles;
create policy profiles_update_self on profiles for update
  using (id = auth.uid() or (organization_id = public.current_org_id() and public.is_manager()));

drop policy if exists profiles_insert_self on profiles;
create policy profiles_insert_self on profiles for insert
  with check (id = auth.uid());

-- Shifts --------------------------------------------------------------------
drop policy if exists shifts_select on shifts;
create policy shifts_select on shifts for select
  using (organization_id = public.current_org_id());

drop policy if exists shifts_write on shifts;
create policy shifts_write on shifts for all
  using (organization_id = public.current_org_id() and public.is_manager())
  with check (organization_id = public.current_org_id() and public.is_manager());

-- Templates -----------------------------------------------------------------
drop policy if exists templates_select on shift_templates;
create policy templates_select on shift_templates for select
  using (organization_id = public.current_org_id());

drop policy if exists templates_write on shift_templates;
create policy templates_write on shift_templates for all
  using (organization_id = public.current_org_id() and public.is_manager())
  with check (organization_id = public.current_org_id() and public.is_manager());

-- Leave requests ------------------------------------------------------------
drop policy if exists leave_select on leave_requests;
create policy leave_select on leave_requests for select
  using (organization_id = public.current_org_id() and (public.is_manager() or user_id = auth.uid()));

drop policy if exists leave_insert on leave_requests;
create policy leave_insert on leave_requests for insert
  with check (organization_id = public.current_org_id() and user_id = auth.uid());

drop policy if exists leave_update on leave_requests;
create policy leave_update on leave_requests for update
  using (organization_id = public.current_org_id() and (public.is_manager() or user_id = auth.uid()));

-- Swap requests -------------------------------------------------------------
drop policy if exists swap_select on swap_requests;
create policy swap_select on swap_requests for select
  using (organization_id = public.current_org_id());

drop policy if exists swap_insert on swap_requests;
create policy swap_insert on swap_requests for insert
  with check (organization_id = public.current_org_id() and requested_by = auth.uid());

drop policy if exists swap_update on swap_requests;
create policy swap_update on swap_requests for update
  using (organization_id = public.current_org_id() and (public.is_manager() or requested_by = auth.uid() or target_user_id = auth.uid()));

-- Time entries --------------------------------------------------------------
drop policy if exists time_select on time_entries;
create policy time_select on time_entries for select
  using (organization_id = public.current_org_id() and (public.is_manager() or user_id = auth.uid()));

drop policy if exists time_insert on time_entries;
create policy time_insert on time_entries for insert
  with check (organization_id = public.current_org_id() and user_id = auth.uid());

drop policy if exists time_update on time_entries;
create policy time_update on time_entries for update
  using (organization_id = public.current_org_id() and (public.is_manager() or user_id = auth.uid()));

-- Availability --------------------------------------------------------------
drop policy if exists availability_select on availability;
create policy availability_select on availability for select
  using (organization_id = public.current_org_id());

drop policy if exists availability_write on availability;
create policy availability_write on availability for all
  using (organization_id = public.current_org_id() and (public.is_manager() or user_id = auth.uid()))
  with check (organization_id = public.current_org_id() and user_id = auth.uid());

-- Announcements -------------------------------------------------------------
drop policy if exists announcements_select on announcements;
create policy announcements_select on announcements for select
  using (organization_id = public.current_org_id());

drop policy if exists announcements_write on announcements;
create policy announcements_write on announcements for all
  using (organization_id = public.current_org_id() and public.is_manager())
  with check (organization_id = public.current_org_id() and public.is_manager());

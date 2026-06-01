-- Rota — initial schema
-- Postgres / Supabase. Snake_case columns map to the Swift models via
-- PostgREST + convertFromSnakeCase JSON coding.

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
do $$ begin
  create type user_role as enum ('owner', 'admin', 'manager', 'employee');
exception when duplicate_object then null; end $$;

do $$ begin
  create type shift_status as enum ('scheduled', 'published', 'in_progress', 'completed', 'cancelled');
exception when duplicate_object then null; end $$;

do $$ begin
  create type leave_type as enum ('holiday', 'sick', 'unpaid', 'parental', 'other');
exception when duplicate_object then null; end $$;

do $$ begin
  create type request_status as enum ('pending', 'approved', 'rejected', 'cancelled');
exception when duplicate_object then null; end $$;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------
create table if not exists organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  invite_code text not null unique,
  timezone text not null default 'UTC',
  weekly_overtime_threshold double precision not null default 40,
  workplace_latitude double precision,
  workplace_longitude double precision,
  clock_in_radius_meters double precision not null default 150,
  created_at timestamptz not null default now()
);

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  email text not null,
  phone text,
  avatar_url text,
  job_title text,
  role user_role not null default 'employee',
  organization_id uuid references organizations(id) on delete set null,
  hourly_rate double precision,
  created_at timestamptz not null default now()
);
create index if not exists profiles_org_idx on profiles(organization_id);

create table if not exists shifts (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  title text not null,
  role text not null default '',
  location text,
  start_at timestamptz not null,
  end_at timestamptz not null,
  break_minutes int not null default 0,
  assigned_user_id uuid references profiles(id) on delete set null,
  status shift_status not null default 'scheduled',
  notes text,
  color_hex text,
  created_by uuid references profiles(id) on delete set null,
  created_at timestamptz not null default now()
);
create index if not exists shifts_org_start_idx on shifts(organization_id, start_at);
create index if not exists shifts_assigned_idx on shifts(assigned_user_id, start_at);

create table if not exists shift_templates (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  name text not null,
  role text not null default '',
  start_time text not null,
  end_time text not null,
  break_minutes int not null default 0,
  color_hex text
);
create index if not exists templates_org_idx on shift_templates(organization_id);

create table if not exists leave_requests (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  type leave_type not null default 'holiday',
  start_date timestamptz not null,
  end_date timestamptz not null,
  reason text,
  status request_status not null default 'pending',
  reviewed_by uuid references profiles(id) on delete set null,
  created_at timestamptz not null default now()
);
create index if not exists leave_org_idx on leave_requests(organization_id);
create index if not exists leave_user_idx on leave_requests(user_id);

create table if not exists swap_requests (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  shift_id uuid not null references shifts(id) on delete cascade,
  requested_by uuid not null references profiles(id) on delete cascade,
  target_user_id uuid references profiles(id) on delete set null,
  message text,
  status request_status not null default 'pending',
  created_at timestamptz not null default now()
);
create index if not exists swap_org_idx on swap_requests(organization_id);

create table if not exists time_entries (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  shift_id uuid references shifts(id) on delete set null,
  clock_in_at timestamptz not null default now(),
  clock_out_at timestamptz,
  clock_in_lat double precision,
  clock_in_lng double precision,
  method text not null default 'manual',
  created_at timestamptz not null default now()
);
create index if not exists time_entries_org_idx on time_entries(organization_id, clock_in_at);
create index if not exists time_entries_user_idx on time_entries(user_id, clock_in_at);

create table if not exists availability (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  weekday int not null check (weekday between 1 and 7),
  is_available boolean not null default true,
  start_time text,
  end_time text,
  unique (user_id, weekday)
);
create index if not exists availability_user_idx on availability(user_id);

create table if not exists announcements (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  author_id uuid references profiles(id) on delete set null,
  author_name text not null default '',
  title text not null,
  body text not null default '',
  is_pinned boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists announcements_org_idx on announcements(organization_id, created_at desc);

-- ---------------------------------------------------------------------------
-- New-user trigger: create a profile row when an auth user signs up.
-- organization_id / role come from sign-up metadata where provided.
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    coalesce((new.raw_user_meta_data ->> 'role')::user_role, 'employee')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

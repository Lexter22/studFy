-- Supabase schema for Studfy
-- This schema matches the current app structure and leaves auth wiring to Supabase Auth later.

create extension if not exists "pgcrypto";

create type public.user_role as enum ('admin', 'professor', 'student');
create type public.request_status as enum ('pending', 'approved', 'rejected', 'cancelled');
create type public.request_kind as enum (
  'account_edit',
  'class_creation',
  'schedule_conflict',
  'role_assignment',
  'subject_update'
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  first_name text not null,
  middle_name text,
  last_name text not null,
  display_name text not null,
  role public.user_role not null default 'student',
  is_email_verified boolean not null default false,
  avatar_url text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'admin'
  );
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    email,
    first_name,
    middle_name,
    last_name,
    display_name,
    role,
    is_email_verified,
    avatar_url
  ) values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data->>'first_name', ''),
    nullif(new.raw_user_meta_data->>'middle_name', ''),
    coalesce(new.raw_user_meta_data->>'last_name', ''),
    coalesce(new.raw_user_meta_data->>'display_name', new.email, ''),
    coalesce((new.raw_user_meta_data->>'role')::public.user_role, 'student'),
    coalesce((new.raw_user_meta_data->>'is_email_verified')::boolean, false),
    nullif(new.raw_user_meta_data->>'avatar_url', '')
  );
  return new;
end;
$$;

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create table if not exists public.instructor_profiles (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  instructor_id text not null unique,
  department text not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create trigger instructor_profiles_set_updated_at
before update on public.instructor_profiles
for each row execute function public.set_updated_at();

create table if not exists public.student_profiles (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  student_number text not null unique,
  course_code text not null,
  year_section text not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create trigger student_profiles_set_updated_at
before update on public.student_profiles
for each row execute function public.set_updated_at();

create table if not exists public.subject_offerings (
  id uuid primary key default gen_random_uuid(),
  subject_name text not null,
  course_code text not null,
  year_level smallint not null check (year_level between 1 and 4),
  section text not null,
  professor_profile_id uuid references public.instructor_profiles(profile_id) on delete set null,
  semester smallint check (semester between 1 and 2),
  academic_year text,
  schedule_label text,
  room text,
  status text not null default 'active',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists subject_offerings_course_idx
  on public.subject_offerings (course_code, year_level, section);

create index if not exists subject_offerings_professor_idx
  on public.subject_offerings (professor_profile_id);

create trigger subject_offerings_set_updated_at
before update on public.subject_offerings
for each row execute function public.set_updated_at();

create table if not exists public.subject_enrollments (
  id uuid primary key default gen_random_uuid(),
  student_profile_id uuid not null references public.student_profiles(profile_id) on delete cascade,
  subject_offering_id uuid not null references public.subject_offerings(id) on delete cascade,
  enrolled_at timestamptz not null default timezone('utc', now()),
  unique (student_profile_id, subject_offering_id)
);

create index if not exists subject_enrollments_student_idx
  on public.subject_enrollments (student_profile_id);

create index if not exists subject_enrollments_subject_idx
  on public.subject_enrollments (subject_offering_id);

create table if not exists public.requests (
  id uuid primary key default gen_random_uuid(),
  kind public.request_kind not null,
  title text not null,
  details text,
  status public.request_status not null default 'pending',
  requester_profile_id uuid references public.profiles(id) on delete set null,
  instructor_profile_id uuid references public.instructor_profiles(profile_id) on delete set null,
  student_profile_id uuid references public.student_profiles(profile_id) on delete set null,
  subject_offering_id uuid references public.subject_offerings(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  resolved_by uuid references public.profiles(id) on delete set null,
  resolved_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists requests_status_idx
  on public.requests (status);

create index if not exists requests_kind_idx
  on public.requests (kind);

create index if not exists requests_requester_idx
  on public.requests (requester_profile_id);

create index if not exists requests_subject_idx
  on public.requests (subject_offering_id);

create trigger requests_set_updated_at
before update on public.requests
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.instructor_profiles enable row level security;
alter table public.student_profiles enable row level security;
alter table public.subject_offerings enable row level security;
alter table public.subject_enrollments enable row level security;
alter table public.requests enable row level security;

drop policy if exists "profiles_select_own_or_admin" on public.profiles;
create policy "profiles_select_own_or_admin"
on public.profiles
for select
using (auth.uid() = id or public.is_admin());

drop policy if exists "profiles_update_own_or_admin" on public.profiles;
create policy "profiles_update_own_or_admin"
on public.profiles
for update
using (auth.uid() = id or public.is_admin())
with check (auth.uid() = id or public.is_admin());

drop policy if exists "profiles_insert_admin_only" on public.profiles;
create policy "profiles_insert_admin_only"
on public.profiles
for insert
with check (public.is_admin());

drop policy if exists "instructor_profiles_select_own_or_admin" on public.instructor_profiles;
create policy "instructor_profiles_select_own_or_admin"
on public.instructor_profiles
for select
using (public.is_admin() or profile_id = auth.uid());

drop policy if exists "instructor_profiles_write_admin_only" on public.instructor_profiles;
create policy "instructor_profiles_write_admin_only"
on public.instructor_profiles
for all
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "student_profiles_select_own_or_admin" on public.student_profiles;
create policy "student_profiles_select_own_or_admin"
on public.student_profiles
for select
using (public.is_admin() or profile_id = auth.uid());

drop policy if exists "student_profiles_write_admin_only" on public.student_profiles;
create policy "student_profiles_write_admin_only"
on public.student_profiles
for all
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "subject_offerings_select_authenticated" on public.subject_offerings;
create policy "subject_offerings_select_authenticated"
on public.subject_offerings
for select
using (auth.uid() is not null);

drop policy if exists "subject_offerings_write_admin_or_professor" on public.subject_offerings;
create policy "subject_offerings_write_admin_or_professor"
on public.subject_offerings
for insert
with check (public.is_admin() or exists (
  select 1
  from public.instructor_profiles ip
  where ip.profile_id = auth.uid()
));

drop policy if exists "subject_offerings_update_admin_or_professor" on public.subject_offerings;
create policy "subject_offerings_update_admin_or_professor"
on public.subject_offerings
for update
using (public.is_admin() or professor_profile_id = auth.uid())
with check (public.is_admin() or professor_profile_id = auth.uid());

drop policy if exists "subject_offerings_delete_admin_only" on public.subject_offerings;
create policy "subject_offerings_delete_admin_only"
on public.subject_offerings
for delete
using (public.is_admin());

drop policy if exists "subject_enrollments_select_own_or_admin" on public.subject_enrollments;
create policy "subject_enrollments_select_own_or_admin"
on public.subject_enrollments
for select
using (public.is_admin() or student_profile_id = auth.uid());

drop policy if exists "subject_enrollments_write_own_or_admin" on public.subject_enrollments;
create policy "subject_enrollments_write_own_or_admin"
on public.subject_enrollments
for all
using (public.is_admin() or student_profile_id = auth.uid())
with check (public.is_admin() or student_profile_id = auth.uid());

drop policy if exists "requests_select_own_or_admin" on public.requests;
create policy "requests_select_own_or_admin"
on public.requests
for select
using (public.is_admin() or requester_profile_id = auth.uid());

drop policy if exists "requests_insert_authenticated" on public.requests;
create policy "requests_insert_authenticated"
on public.requests
for insert
with check (auth.uid() is not null and requester_profile_id = auth.uid());

drop policy if exists "requests_update_admin_only" on public.requests;
create policy "requests_update_admin_only"
on public.requests
for update
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "requests_delete_admin_only" on public.requests;
create policy "requests_delete_admin_only"
on public.requests
for delete
using (public.is_admin());

comment on table public.profiles is 'Application profile data linked one-to-one with auth.users.';
comment on table public.instructor_profiles is 'Instructor-specific profile fields.';
comment on table public.student_profiles is 'Student-specific profile fields.';
comment on table public.subject_offerings is 'Offered classes/subjects shown in the admin screens.';
comment on table public.subject_enrollments is 'Join table for student subject enrollment.';
comment on table public.requests is 'Generic request queue used by admin and profile workflows.';


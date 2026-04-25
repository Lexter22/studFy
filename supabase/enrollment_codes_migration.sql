-- Enrollment codes table
create table if not exists public.enrollment_codes (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  course_code text not null,
  year_section text not null,
  max_uses integer default null, -- null = unlimited
  current_uses integer not null default 0,
  is_active boolean not null default true,
  expires_at timestamptz default null,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now())
);

alter table public.enrollment_codes enable row level security;

-- Only admins can manage codes
create policy "enrollment_codes_admin_all"
on public.enrollment_codes
for all
using (public.is_admin())
with check (public.is_admin());

-- Authenticated users can read active codes (needed for validation in Edge Function)
create policy "enrollment_codes_read_active"
on public.enrollment_codes
for select
using (auth.uid() is not null and is_active = true);

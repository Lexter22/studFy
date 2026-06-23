-- Migration: announcements, meetings, reminders (persistent storage)

-- ── Announcements ─────────────────────────────────────────────────────────
create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  subject_offering_id uuid not null references public.subject_offerings(id) on delete cascade,
  content text not null,
  posted_by uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists announcements_subject_idx
  on public.announcements (subject_offering_id);

create index if not exists announcements_posted_by_idx
  on public.announcements (posted_by);

create trigger announcements_set_updated_at
before update on public.announcements
for each row execute function public.set_updated_at();

-- ── Meetings ──────────────────────────────────────────────────────────────
create table if not exists public.meetings (
  id uuid primary key default gen_random_uuid(),
  subject_offering_id uuid not null references public.subject_offerings(id) on delete cascade,
  title text not null,
  platform text not null default 'Google Meet',
  link text,
  meeting_date date not null,
  meeting_time text not null,
  created_by uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists meetings_subject_idx
  on public.meetings (subject_offering_id);

create index if not exists meetings_date_idx
  on public.meetings (meeting_date);

create trigger meetings_set_updated_at
before update on public.meetings
for each row execute function public.set_updated_at();

-- ── Reminders (per-professor personal calendar reminders) ─────────────────
create table if not exists public.reminders (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text,
  reminder_date date not null,
  reminder_time text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists reminders_profile_idx
  on public.reminders (profile_id);

create index if not exists reminders_date_idx
  on public.reminders (reminder_date);

create trigger reminders_set_updated_at
before update on public.reminders
for each row execute function public.set_updated_at();

-- ── RLS Policies ──────────────────────────────────────────────────────────
alter table public.announcements enable row level security;
alter table public.meetings enable row level security;
alter table public.reminders enable row level security;

-- Announcements: professor of subject or admin can write; any authenticated can read
drop policy if exists "announcements_select_authenticated" on public.announcements;
create policy "announcements_select_authenticated" on public.announcements
  for select using (auth.uid() is not null);

drop policy if exists "announcements_write_professor_or_admin" on public.announcements;
create policy "announcements_write_professor_or_admin" on public.announcements
  for all using (
    public.is_admin() or posted_by = auth.uid()
  ) with check (
    public.is_admin() or posted_by = auth.uid()
  );

-- Meetings: professor of subject or admin can write; any authenticated can read
drop policy if exists "meetings_select_authenticated" on public.meetings;
create policy "meetings_select_authenticated" on public.meetings
  for select using (auth.uid() is not null);

drop policy if exists "meetings_write_professor_or_admin" on public.meetings;
create policy "meetings_write_professor_or_admin" on public.meetings
  for all using (
    public.is_admin() or created_by = auth.uid()
  ) with check (
    public.is_admin() or created_by = auth.uid()
  );

-- Reminders: only the owner can read/write their own reminders
drop policy if exists "reminders_select_own" on public.reminders;
create policy "reminders_select_own" on public.reminders
  for select using (profile_id = auth.uid());

drop policy if exists "reminders_write_own" on public.reminders;
create policy "reminders_write_own" on public.reminders
  for all using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

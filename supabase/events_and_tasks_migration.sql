-- 1. Create Event Types
do $$
begin
  create type public.event_type as enum ('quiz', 'activity', 'meeting');
exception
  when duplicate_object then null;
end $$;

-- 2. Create Class Events Table (For Quizzes, Deadlines, and Meetings)
create table if not exists public.class_events (
  id uuid primary key default gen_random_uuid(),
  subject_offering_id uuid not null references public.subject_offerings(id) on delete cascade,
  event_type public.event_type not null,
  title text not null,
  description text,
  start_time timestamptz, -- Used for meetings/quizzes
  end_time timestamptz,   -- Used for deadlines or event end times
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

-- Trigger for updated_at
create trigger class_events_set_updated_at
before update on public.class_events
for each row execute function public.set_updated_at();

-- 3. Create Student Tasks Table (For Pending Tasks)
create table if not exists public.student_tasks (
  id uuid primary key default gen_random_uuid(),
  student_profile_id uuid not null references public.student_profiles(profile_id) on delete cascade,
  title text not null,
  description text,
  is_completed boolean not null default false,
  due_date timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

-- Trigger for updated_at
create trigger student_tasks_set_updated_at
before update on public.student_tasks
for each row execute function public.set_updated_at();

-- 4. Setup Row Level Security (RLS)
alter table public.class_events enable row level security;
alter table public.student_tasks enable row level security;

-- Class Events: Anyone enrolled (or the professor) can view events for the subject
create policy "class_events_select_access"
on public.class_events
for select
using (
  public.is_admin()
  or exists (
    select 1 from public.subject_offerings so
    where so.id = class_events.subject_offering_id and so.professor_profile_id = auth.uid()
  )
  or exists (
    select 1 from public.subject_enrollments se
    where se.subject_offering_id = class_events.subject_offering_id and se.student_profile_id = auth.uid()
  )
);

-- Class Events: Only Admins and the subject's Professor can create/update/delete events
create policy "class_events_write_access"
on public.class_events
for all
using (
  public.is_admin()
  or exists (
    select 1 from public.subject_offerings so
    where so.id = class_events.subject_offering_id and so.professor_profile_id = auth.uid()
  )
)
with check (
  public.is_admin()
  or exists (
    select 1 from public.subject_offerings so
    where so.id = class_events.subject_offering_id and so.professor_profile_id = auth.uid()
  )
);

-- Student Tasks: Students can only view and manage their own tasks
create policy "student_tasks_all_access"
on public.student_tasks
for all
using (public.is_admin() or student_profile_id = auth.uid())
with check (public.is_admin() or student_profile_id = auth.uid());
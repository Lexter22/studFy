-- Migration: modules, quizzes, quiz_questions, assignments

-- ── Modules ───────────────────────────────────────────────────────────────
create table if not exists public.modules (
  id uuid primary key default gen_random_uuid(),
  subject_offering_id uuid not null references public.subject_offerings(id) on delete cascade,
  title text not null,
  description text,
  order_index smallint not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists modules_subject_idx on public.modules (subject_offering_id);

create trigger modules_set_updated_at
before update on public.modules
for each row execute function public.set_updated_at();

-- ── Quizzes ───────────────────────────────────────────────────────────────
create table if not exists public.quizzes (
  id uuid primary key default gen_random_uuid(),
  subject_offering_id uuid not null references public.subject_offerings(id) on delete cascade,
  module_id uuid references public.modules(id) on delete set null,
  title text not null,
  description text,
  deadline timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists quizzes_subject_idx on public.quizzes (subject_offering_id);
create index if not exists quizzes_module_idx on public.quizzes (module_id);

create trigger quizzes_set_updated_at
before update on public.quizzes
for each row execute function public.set_updated_at();

-- ── Quiz Questions ────────────────────────────────────────────────────────
create table if not exists public.quiz_questions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.quizzes(id) on delete cascade,
  question text not null,
  options jsonb not null default '[]'::jsonb,
  correct_answer text not null,
  order_index smallint not null default 0,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists quiz_questions_quiz_idx on public.quiz_questions (quiz_id);

-- ── Assignments ───────────────────────────────────────────────────────────
create table if not exists public.assignments (
  id uuid primary key default gen_random_uuid(),
  subject_offering_id uuid not null references public.subject_offerings(id) on delete cascade,
  module_id uuid references public.modules(id) on delete set null,
  title text not null,
  description text,
  deadline timestamptz,
  file_url text,
  file_name text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists assignments_subject_idx on public.assignments (subject_offering_id);
create index if not exists assignments_module_idx on public.assignments (module_id);

create trigger assignments_set_updated_at
before update on public.assignments
for each row execute function public.set_updated_at();

-- ── RLS ───────────────────────────────────────────────────────────────────
alter table public.modules enable row level security;
alter table public.quizzes enable row level security;
alter table public.quiz_questions enable row level security;
alter table public.assignments enable row level security;

-- Modules: professor of the subject or admin can write, authenticated can read
drop policy if exists "modules_select_authenticated" on public.modules;
create policy "modules_select_authenticated" on public.modules
  for select using (auth.uid() is not null);

drop policy if exists "modules_write_professor_or_admin" on public.modules;
create policy "modules_write_professor_or_admin" on public.modules
  for all using (
    public.is_admin() or exists (
      select 1 from public.subject_offerings so
      where so.id = subject_offering_id and so.professor_profile_id = auth.uid()
    )
  ) with check (
    public.is_admin() or exists (
      select 1 from public.subject_offerings so
      where so.id = subject_offering_id and so.professor_profile_id = auth.uid()
    )
  );

-- Quizzes: same pattern
drop policy if exists "quizzes_select_authenticated" on public.quizzes;
create policy "quizzes_select_authenticated" on public.quizzes
  for select using (auth.uid() is not null);

drop policy if exists "quizzes_write_professor_or_admin" on public.quizzes;
create policy "quizzes_write_professor_or_admin" on public.quizzes
  for all using (
    public.is_admin() or exists (
      select 1 from public.subject_offerings so
      where so.id = subject_offering_id and so.professor_profile_id = auth.uid()
    )
  ) with check (
    public.is_admin() or exists (
      select 1 from public.subject_offerings so
      where so.id = subject_offering_id and so.professor_profile_id = auth.uid()
    )
  );

-- Quiz questions: same pattern via quiz -> subject
drop policy if exists "quiz_questions_select_authenticated" on public.quiz_questions;
create policy "quiz_questions_select_authenticated" on public.quiz_questions
  for select using (auth.uid() is not null);

drop policy if exists "quiz_questions_write_professor_or_admin" on public.quiz_questions;
create policy "quiz_questions_write_professor_or_admin" on public.quiz_questions
  for all using (
    public.is_admin() or exists (
      select 1 from public.quizzes q
      join public.subject_offerings so on so.id = q.subject_offering_id
      where q.id = quiz_id and so.professor_profile_id = auth.uid()
    )
  ) with check (
    public.is_admin() or exists (
      select 1 from public.quizzes q
      join public.subject_offerings so on so.id = q.subject_offering_id
      where q.id = quiz_id and so.professor_profile_id = auth.uid()
    )
  );

-- Assignments: same pattern
drop policy if exists "assignments_select_authenticated" on public.assignments;
create policy "assignments_select_authenticated" on public.assignments
  for select using (auth.uid() is not null);

drop policy if exists "assignments_write_professor_or_admin" on public.assignments;
create policy "assignments_write_professor_or_admin" on public.assignments
  for all using (
    public.is_admin() or exists (
      select 1 from public.subject_offerings so
      where so.id = subject_offering_id and so.professor_profile_id = auth.uid()
    )
  ) with check (
    public.is_admin() or exists (
      select 1 from public.subject_offerings so
      where so.id = subject_offering_id and so.professor_profile_id = auth.uid()
    )
  );

-- ── Storage bucket for assignment files ───────────────────────────────────
insert into storage.buckets (id, name, public)
values ('assignments', 'assignments', true)
on conflict (id) do nothing;

drop policy if exists "assignments_upload_professor_or_admin" on storage.objects;
create policy "assignments_upload_professor_or_admin" on storage.objects
  for insert with check (
    bucket_id = 'assignments' and auth.uid() is not null
  );

drop policy if exists "assignments_read_authenticated" on storage.objects;
create policy "assignments_read_authenticated" on storage.objects
  for select using (
    bucket_id = 'assignments' and auth.uid() is not null
  );

drop policy if exists "assignments_delete_professor_or_admin" on storage.objects;
create policy "assignments_delete_professor_or_admin" on storage.objects
  for delete using (
    bucket_id = 'assignments' and auth.uid() is not null
  );

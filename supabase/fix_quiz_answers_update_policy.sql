-- Fix for quiz submission persistence.
--
-- Two issues are corrected here:
--   1. The quiz_answers table in the database was missing columns
--      (answers / score / max_score / submitted_at) because it was created
--      by an older partial migration. Error: PGRST204 "Could not find the
--      'max_score' column of 'quiz_answers'".
--   2. Supabase upsert (INSERT ... ON CONFLICT DO UPDATE) requires an UPDATE
--      RLS policy, which did not exist for students.
--
-- Run this against the existing database.

-- ── Ensure the quiz_answers table exists with all expected columns ─────────
create table if not exists public.quiz_answers (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.quizzes(id) on delete cascade,
  student_profile_id uuid not null references public.student_profiles(profile_id) on delete cascade,
  answers jsonb not null default '[]'::jsonb,
  score numeric(6,2),
  max_score numeric(6,2),
  submitted_at timestamptz not null default timezone('utc', now())
);

-- Add any columns missing from an older version of the table
alter table public.quiz_answers add column if not exists answers jsonb not null default '[]'::jsonb;
alter table public.quiz_answers add column if not exists score numeric(6,2);
alter table public.quiz_answers add column if not exists max_score numeric(6,2);
alter table public.quiz_answers add column if not exists submitted_at timestamptz not null default timezone('utc', now());

-- Ensure the unique constraint needed for upsert exists
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'quiz_answers_quiz_id_student_profile_id_key'
  ) then
    alter table public.quiz_answers
      add constraint quiz_answers_quiz_id_student_profile_id_key
      unique (quiz_id, student_profile_id);
  end if;
end $$;

create index if not exists quiz_answers_quiz_idx
  on public.quiz_answers (quiz_id);
create index if not exists quiz_answers_student_idx
  on public.quiz_answers (student_profile_id);

-- ── RLS policies ───────────────────────────────────────────────────────────
alter table public.quiz_answers enable row level security;

drop policy if exists "quiz_answers_select" on public.quiz_answers;
create policy "quiz_answers_select" on public.quiz_answers
  for select using (auth.uid() is not null);

drop policy if exists "quiz_answers_insert_student" on public.quiz_answers;
create policy "quiz_answers_insert_student" on public.quiz_answers
  for insert with check (student_profile_id = auth.uid());

drop policy if exists "quiz_answers_update_student" on public.quiz_answers;
create policy "quiz_answers_update_student" on public.quiz_answers
  for update using (student_profile_id = auth.uid())
  with check (student_profile_id = auth.uid());

-- Refresh PostgREST schema cache so the new columns are recognized immediately
notify pgrst, 'reload schema';

-- Migration: attendance_records, student_grades, assignment_submissions, quiz_answers

-- ── Attendance Records ────────────────────────────────────────────────────
create table if not exists public.attendance_records (
  id uuid primary key default gen_random_uuid(),
  subject_offering_id uuid not null references public.subject_offerings(id) on delete cascade,
  student_profile_id uuid not null references public.student_profiles(profile_id) on delete cascade,
  date date not null default current_date,
  status text not null default 'present' check (status in ('present', 'late', 'absent')),
  remarks text,
  recorded_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (subject_offering_id, student_profile_id, date)
);

create index if not exists attendance_records_subject_idx
  on public.attendance_records (subject_offering_id);

create index if not exists attendance_records_student_idx
  on public.attendance_records (student_profile_id);

create index if not exists attendance_records_date_idx
  on public.attendance_records (date);

create trigger attendance_records_set_updated_at
before update on public.attendance_records
for each row execute function public.set_updated_at();

-- ── Student Grades ────────────────────────────────────────────────────────
create table if not exists public.student_grades (
  id uuid primary key default gen_random_uuid(),
  subject_offering_id uuid not null references public.subject_offerings(id) on delete cascade,
  student_profile_id uuid not null references public.student_profiles(profile_id) on delete cascade,
  category text not null default 'general' check (category in ('quiz', 'assignment', 'exam', 'project', 'general')),
  title text not null,
  score numeric(6,2) not null,
  max_score numeric(6,2) not null default 100,
  remarks text,
  graded_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists student_grades_subject_idx
  on public.student_grades (subject_offering_id);

create index if not exists student_grades_student_idx
  on public.student_grades (student_profile_id);

create index if not exists student_grades_category_idx
  on public.student_grades (category);

create trigger student_grades_set_updated_at
before update on public.student_grades
for each row execute function public.set_updated_at();

-- ── Assignment Submissions ────────────────────────────────────────────────
create table if not exists public.assignment_submissions (
  id uuid primary key default gen_random_uuid(),
  assignment_id uuid not null references public.assignments(id) on delete cascade,
  student_profile_id uuid not null references public.student_profiles(profile_id) on delete cascade,
  file_url text,
  file_name text,
  submitted_at timestamptz not null default timezone('utc', now()),
  grade numeric(6,2),
  feedback text,
  unique (assignment_id, student_profile_id)
);

create index if not exists assignment_submissions_assignment_idx
  on public.assignment_submissions (assignment_id);

create index if not exists assignment_submissions_student_idx
  on public.assignment_submissions (student_profile_id);

-- ── Quiz Answers ──────────────────────────────────────────────────────────
create table if not exists public.quiz_answers (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.quizzes(id) on delete cascade,
  student_profile_id uuid not null references public.student_profiles(profile_id) on delete cascade,
  answers jsonb not null default '[]'::jsonb,
  score numeric(6,2),
  max_score numeric(6,2),
  submitted_at timestamptz not null default timezone('utc', now()),
  unique (quiz_id, student_profile_id)
);

create index if not exists quiz_answers_quiz_idx
  on public.quiz_answers (quiz_id);

create index if not exists quiz_answers_student_idx
  on public.quiz_answers (student_profile_id);

-- ── RLS Policies ──────────────────────────────────────────────────────────
alter table public.attendance_records enable row level security;
alter table public.student_grades enable row level security;
alter table public.assignment_submissions enable row level security;
alter table public.quiz_answers enable row level security;

-- Attendance: professor of the subject or admin can write, authenticated can read own
drop policy if exists "attendance_select_authenticated" on public.attendance_records;
create policy "attendance_select_authenticated" on public.attendance_records
  for select using (auth.uid() is not null);

drop policy if exists "attendance_write_professor_or_admin" on public.attendance_records;
create policy "attendance_write_professor_or_admin" on public.attendance_records
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

-- Grades: professor of the subject or admin can write, authenticated can read own
drop policy if exists "grades_select_authenticated" on public.student_grades;
create policy "grades_select_authenticated" on public.student_grades
  for select using (auth.uid() is not null);

drop policy if exists "grades_write_professor_or_admin" on public.student_grades;
create policy "grades_write_professor_or_admin" on public.student_grades
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

-- Assignment Submissions: student can insert own, professor/admin can read all for their subject
drop policy if exists "assignment_submissions_select" on public.assignment_submissions;
create policy "assignment_submissions_select" on public.assignment_submissions
  for select using (auth.uid() is not null);

drop policy if exists "assignment_submissions_insert_student" on public.assignment_submissions;
create policy "assignment_submissions_insert_student" on public.assignment_submissions
  for insert with check (
    student_profile_id = auth.uid()
  );

drop policy if exists "assignment_submissions_update_professor" on public.assignment_submissions;
create policy "assignment_submissions_update_professor" on public.assignment_submissions
  for update using (
    public.is_admin() or exists (
      select 1 from public.assignments a
      join public.subject_offerings so on so.id = a.subject_offering_id
      where a.id = assignment_id and so.professor_profile_id = auth.uid()
    )
  );

-- Quiz Answers: student can insert own, professor/admin can read
drop policy if exists "quiz_answers_select" on public.quiz_answers;
create policy "quiz_answers_select" on public.quiz_answers
  for select using (auth.uid() is not null);

drop policy if exists "quiz_answers_insert_student" on public.quiz_answers;
create policy "quiz_answers_insert_student" on public.quiz_answers
  for insert with check (
    student_profile_id = auth.uid()
  );

-- Quiz Answers: students can update their own answers (required for upsert/re-take)
drop policy if exists "quiz_answers_update_student" on public.quiz_answers;
create policy "quiz_answers_update_student" on public.quiz_answers
  for update using (
    student_profile_id = auth.uid()
  ) with check (
    student_profile_id = auth.uid()
  );

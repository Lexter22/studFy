-- Google Classroom-style per-class join codes.
--
-- Each subject_offering gets a short, unique join_code. Professors can view and
-- regenerate it. Students join a specific class by entering the code, which
-- enrolls them into subject_enrollments. This complements the admin-managed
-- enrollment_codes (account onboarding); this one is per-class enrollment.

-- ── Code generator: 6-char uppercase alphanumeric, ambiguity-free alphabet ──
create or replace function public.gen_class_join_code()
returns text
language plpgsql
as $$
declare
  alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- no I,O,0,1
  result text;
  i int;
begin
  loop
    result := '';
    for i in 1..6 loop
      result := result || substr(alphabet, floor(random() * length(alphabet))::int + 1, 1);
    end loop;
    -- ensure uniqueness
    exit when not exists (select 1 from public.subject_offerings where join_code = result);
  end loop;
  return result;
end;
$$;

-- ── Add the column and backfill existing rows ───────────────────────────────
alter table public.subject_offerings add column if not exists join_code text;

update public.subject_offerings
set join_code = public.gen_class_join_code()
where join_code is null;

-- Enforce uniqueness and a default for new rows
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'subject_offerings_join_code_key'
  ) then
    alter table public.subject_offerings
      add constraint subject_offerings_join_code_key unique (join_code);
  end if;
end $$;

alter table public.subject_offerings alter column join_code set default public.gen_class_join_code();

-- ── Regenerate a class code (professor of the subject or admin) ──────────────
create or replace function public.regenerate_class_code(p_subject_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_new text;
  v_owner uuid;
begin
  select professor_profile_id into v_owner
  from public.subject_offerings
  where id = p_subject_id;

  if not found then
    raise exception 'Subject not found';
  end if;

  if not (public.is_admin() or v_owner = auth.uid()) then
    raise exception 'Not authorized to regenerate this class code';
  end if;

  v_new := public.gen_class_join_code();
  update public.subject_offerings set join_code = v_new where id = p_subject_id;
  return v_new;
end;
$$;

-- ── Join a class by code (student) ──────────────────────────────────────────
-- Returns (status, subject_id, subject_name)
--   status = 'ok'             -> enrolled (or already enrolled)
--   status = 'invalid'        -> no class with that code
--   status = 'not_student'    -> caller has no student_profile
--   status = 'already'        -> already enrolled (still returns subject info)
create or replace function public.join_class_by_code(p_code text)
returns table (status text, subject_id uuid, subject_name text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_subject public.subject_offerings%rowtype;
  v_is_student boolean;
begin
  select * into v_subject
  from public.subject_offerings
  where join_code = upper(trim(p_code));

  if not found then
    return query select 'invalid'::text, null::uuid, null::text;
    return;
  end if;

  select exists(select 1 from public.student_profiles where profile_id = auth.uid())
    into v_is_student;
  if not v_is_student then
    return query select 'not_student'::text, null::uuid, null::text;
    return;
  end if;

  if exists (
    select 1 from public.subject_enrollments
    where subject_offering_id = v_subject.id and student_profile_id = auth.uid()
  ) then
    return query select 'already'::text, v_subject.id, v_subject.subject_name;
    return;
  end if;

  insert into public.subject_enrollments (student_profile_id, subject_offering_id)
  values (auth.uid(), v_subject.id);

  return query select 'ok'::text, v_subject.id, v_subject.subject_name;
end;
$$;

-- Allow students to self-enroll via the RPC (RLS on subject_enrollments otherwise
-- limits inserts). The SECURITY DEFINER function performs the insert safely after
-- verifying the caller is a student.
grant execute on function public.regenerate_class_code(uuid) to authenticated, service_role;
grant execute on function public.join_class_by_code(text) to authenticated, service_role;

-- ── Fix professor read access (pre-existing RLS gap) ────────────────────────
-- Professors could not read the enrollments / student_profiles / profiles of
-- students in their own classes, so rosters, attendance and grade lists were
-- empty or nameless for professors. We grant professors read access scoped to
-- students enrolled in subjects they teach.
--
-- A SECURITY DEFINER helper avoids RLS recursion: it checks "does this student
-- share a class with this professor" while bypassing RLS on the joined tables.
create or replace function public.shares_class_with_professor(p_student uuid, p_professor uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.subject_enrollments se
    join public.subject_offerings so on so.id = se.subject_offering_id
    where se.student_profile_id = p_student
      and so.professor_profile_id = p_professor
  );
$$;

grant execute on function public.shares_class_with_professor(uuid, uuid) to authenticated, service_role;

-- subject_enrollments: admin, the student, or the owning professor can read
alter table public.subject_enrollments enable row level security;
drop policy if exists "subject_enrollments_select_own_or_admin" on public.subject_enrollments;
drop policy if exists "subject_enrollments_select_own_or_staff" on public.subject_enrollments;
create policy "subject_enrollments_select_own_or_staff" on public.subject_enrollments
  for select using (
    public.is_admin()
    or student_profile_id = auth.uid()
    or exists (
      select 1 from public.subject_offerings so
      where so.id = subject_offering_id and so.professor_profile_id = auth.uid()
    )
  );

-- profiles: add professor read for students in their classes (keep own/admin)
drop policy if exists "profiles_select_own_or_admin" on public.profiles;
create policy "profiles_select_own_or_admin" on public.profiles
  for select using (
    auth.uid() = id
    or public.is_admin()
    or public.shares_class_with_professor(id, auth.uid())
  );

-- student_profiles: add professor read for students in their classes
drop policy if exists "student_profiles_select_own_or_admin" on public.student_profiles;
create policy "student_profiles_select_own_or_admin" on public.student_profiles
  for select using (
    public.is_admin()
    or profile_id = auth.uid()
    or public.shares_class_with_professor(profile_id, auth.uid())
  );

notify pgrst, 'reload schema';



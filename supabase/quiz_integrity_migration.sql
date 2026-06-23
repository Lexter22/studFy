-- Quiz integrity: stop leaking correct answers to students and score server-side.
--
-- Before: quiz_questions was readable by ANY authenticated user (correct_answer
-- included), and the student app scored quizzes locally. A student could read the
-- answers from the table/network. Now:
--   * quiz_questions is readable only by admins and the owning professor.
--   * students fetch questions WITHOUT correct_answer via an RPC.
--   * scoring happens server-side in submit_quiz.
--   * correct answers are only revealed (for review) AFTER the student submits.

-- ── Lock down quiz_questions reads ──────────────────────────────────────────
drop policy if exists "quiz_questions_select_authenticated" on public.quiz_questions;
drop policy if exists "quiz_questions_select_professor_or_admin" on public.quiz_questions;
create policy "quiz_questions_select_professor_or_admin" on public.quiz_questions
  for select using (
    public.is_admin() or exists (
      select 1
      from public.quizzes q
      join public.subject_offerings so on so.id = q.subject_offering_id
      where q.id = quiz_id and so.professor_profile_id = auth.uid()
    )
  );

-- ── Questions for taking (no correct_answer) ────────────────────────────────
create or replace function public.get_quiz_questions_for_taking(p_quiz_id uuid)
returns table (id uuid, question text, options jsonb, order_index smallint)
language sql
security definer
set search_path = public
stable
as $$
  select qq.id, qq.question, qq.options, qq.order_index
  from public.quiz_questions qq
  where qq.quiz_id = p_quiz_id
  order by qq.order_index;
$$;

-- ── Server-side scoring ─────────────────────────────────────────────────────
-- p_answers is a jsonb array of selected option strings, ordered to match the
-- questions' order_index. Returns the computed score and max score and persists
-- the attempt. Correct answers are never returned.
create or replace function public.submit_quiz(p_quiz_id uuid, p_answers jsonb)
returns table (score numeric, max_score numeric)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_is_student boolean;
  v_score int := 0;
  v_total int := 0;
  v_idx int := 0;
  v_q record;
  v_given text;
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  select exists(select 1 from public.student_profiles where profile_id = v_uid)
    into v_is_student;
  if not v_is_student then
    raise exception 'Only students can submit quizzes';
  end if;

  for v_q in
    select correct_answer
    from public.quiz_questions
    where quiz_id = p_quiz_id
    order by order_index
  loop
    v_given := nullif(p_answers ->> v_idx, '');
    if v_given is not null and v_given = v_q.correct_answer then
      v_score := v_score + 1;
    end if;
    v_total := v_total + 1;
    v_idx := v_idx + 1;
  end loop;

  insert into public.quiz_answers (quiz_id, student_profile_id, answers, score, max_score, submitted_at)
  values (p_quiz_id, v_uid, p_answers, v_score, v_total, timezone('utc', now()))
  on conflict (quiz_id, student_profile_id)
  do update set answers = excluded.answers,
                score = excluded.score,
                max_score = excluded.max_score,
                submitted_at = excluded.submitted_at;

  return query select v_score::numeric, v_total::numeric;
end;
$$;

-- ── Review (correct answers) — only AFTER the student has submitted ─────────
create or replace function public.get_quiz_review(p_quiz_id uuid)
returns table (id uuid, question text, options jsonb, correct_answer text, order_index smallint)
language plpgsql
security definer
set search_path = public
stable
as $$
declare
  v_uid uuid := auth.uid();
begin
  -- Owners/admins can always review; students only after submitting.
  if public.is_admin()
     or exists (
       select 1 from public.quizzes q
       join public.subject_offerings so on so.id = q.subject_offering_id
       where q.id = p_quiz_id and so.professor_profile_id = v_uid
     )
     or exists (
       select 1 from public.quiz_answers qa
       where qa.quiz_id = p_quiz_id and qa.student_profile_id = v_uid
     )
  then
    return query
      select qq.id, qq.question, qq.options, qq.correct_answer, qq.order_index
      from public.quiz_questions qq
      where qq.quiz_id = p_quiz_id
      order by qq.order_index;
  end if;
  -- otherwise returns no rows
end;
$$;

grant execute on function public.get_quiz_questions_for_taking(uuid) to authenticated, service_role;
grant execute on function public.submit_quiz(uuid, jsonb) to authenticated, service_role;
grant execute on function public.get_quiz_review(uuid) to authenticated, service_role;

notify pgrst, 'reload schema';

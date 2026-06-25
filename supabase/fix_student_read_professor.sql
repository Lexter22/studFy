-- Fix: students cannot read their professor's profile (shows "Unassigned Professor").
-- The existing profiles SELECT policy only allowed:
--   own row, admin, or professor reading a student in their class.
-- It did NOT allow a student to read the profile of a professor teaching their class.

create or replace function public.is_my_professor(p_profile_id uuid)
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
    where se.student_profile_id = auth.uid()
      and so.professor_profile_id = p_profile_id
  );
$$;

grant execute on function public.is_my_professor(uuid) to authenticated, service_role;

-- Recreate the profiles SELECT policy with the additional check
drop policy if exists "profiles_select_own_or_admin" on public.profiles;
create policy "profiles_select_own_or_admin" on public.profiles
  for select using (
    auth.uid() = id
    or public.is_admin()
    or public.shares_class_with_professor(id, auth.uid())
    or public.is_my_professor(id)
  );

notify pgrst, 'reload schema';

-- Fix RLS policy to allow professors to see student profiles for enrolled students
-- This fixes the "No students found" issue in View Students dialog

drop policy if exists "student_profiles_select_own_or_admin" on public.student_profiles;

create policy "student_profiles_select_own_or_admin"
on public.student_profiles
for select
using (
  public.is_admin() 
  or profile_id = auth.uid()
  or exists (
    select 1
    from public.subject_enrollments se
    join public.subject_offerings so on se.subject_offering_id = so.id
    where se.student_profile_id = student_profiles.profile_id
      and so.professor_profile_id = auth.uid()
  )
);

comment on policy "student_profiles_select_own_or_admin" on public.student_profiles is 'Allows admin, students (own), and professors (enrolled students) to view student profiles';

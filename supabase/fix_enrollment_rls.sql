-- Fix RLS policy to allow professors to see enrollments for their subjects
-- This fixes the issue where professors see 0 students in their subjects

-- First, drop the old policies
drop policy if exists "subject_enrollments_select_own_or_admin" on public.subject_enrollments;
drop policy if exists "subject_enrollments_write_own_or_admin" on public.subject_enrollments;

-- Create new SELECT policy that includes professors
create policy "subject_enrollments_select_own_or_admin"
on public.subject_enrollments
for select
using (
  public.is_admin() 
  or student_profile_id = auth.uid()
  or exists (
    select 1
    from public.subject_offerings so
    where so.id = subject_enrollments.subject_offering_id
      and so.professor_profile_id = auth.uid()
  )
);

-- Recreate the write policy (INSERT, UPDATE, DELETE)
create policy "subject_enrollments_write_own_or_admin"
on public.subject_enrollments
for all
using (public.is_admin() or student_profile_id = auth.uid())
with check (public.is_admin() or student_profile_id = auth.uid());

comment on policy "subject_enrollments_select_own_or_admin" on public.subject_enrollments is 'Allows admin, students (own), and professors (their subjects) to view enrollments';
comment on policy "subject_enrollments_write_own_or_admin" on public.subject_enrollments is 'Allows admin and students (own) to modify enrollments';

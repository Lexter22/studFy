-- SQL to fix RLS policy on public.profiles
-- This allows students to view their professors' profiles (and vice-versa)
-- by checking the shared class relationship in both directions.

drop policy if exists "profiles_select_own_or_admin" on public.profiles;

create policy "profiles_select_own_or_admin" on public.profiles
  for select using (
    auth.uid() = id
    or public.is_admin()
    -- Allows professors to view profiles of students in their classes
    or public.shares_class_with_professor(id, auth.uid())
    -- Allows students to view profiles of professors teaching their classes
    or public.shares_class_with_professor(auth.uid(), id)
  );

notify pgrst, 'reload schema';

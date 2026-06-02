# Fix for Professor Student Count Issue

## Problem
Professors were seeing 0 students in their subjects even after admin enrolled students. This was caused by a missing RLS (Row Level Security) policy.

## Root Cause
The `subject_enrollments` table RLS policy only allowed:
- ✅ Admins to see all enrollments
- ✅ Students to see their own enrollments
- ❌ **Professors could NOT see enrollments for their subjects**

## Solution
Updated the RLS policy to allow professors to view enrollments for subjects they are assigned to.

## How to Apply the Fix

### Option 1: Using Supabase CLI (Recommended)
```bash
# Make sure you're in the project directory
cd /Users/johnlexterbartolome/Codes/studfy

# Apply the migration
supabase db reset
```

### Option 2: Using Supabase Dashboard
1. Go to your Supabase project dashboard
2. Navigate to SQL Editor
3. Copy and paste the contents of `fix_enrollment_rls.sql`
4. Click "Run"

### Option 3: Manual SQL Execution
Run this SQL in your Supabase SQL editor:

```sql
drop policy if exists "subject_enrollments_select_own_or_admin" on public.subject_enrollments;

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
```

## Testing
After applying the fix:
1. Login as admin
2. Enroll a student in a subject assigned to a professor
3. Login as that professor
4. The student count should now show correctly (not 0)

## Files Modified
- `supabase/schema.sql` - Updated the RLS policy
- `supabase/fix_enrollment_rls.sql` - Migration file to apply the fix

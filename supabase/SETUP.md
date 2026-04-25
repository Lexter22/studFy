# Supabase Setup Guide

This guide covers creating the Supabase project and applying the schema for Studfy.

## 1. Create a Supabase project
1. Open the Supabase dashboard and sign in.
2. Click **New project**.
3. Choose your organization.
4. Enter a project name, for example `studfy`.
5. Set a database password and save it somewhere secure.
6. Pick the region closest to your users.
7. Create the project and wait for it to finish provisioning.

## 2. Get the project credentials
1. Open the project settings.
2. Go to **API**.
3. Copy the **Project URL**.
4. Copy the **anon public key**.

You will use these values when running the app:

```bash
flutter run --dart-define=SUPABASE_URL=YOUR_PROJECT_URL --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

## 3. Configure authentication
1. Open **Authentication**.
2. Enable the auth providers you want to support later.
3. For now, you can leave email/password setup for the next step of the migration.
4. If you plan to use email confirmation, make sure the email templates and redirect URLs are configured.

## 4. Apply the schema
1. Open the SQL editor.
2. Create a new query.
3. Paste the contents of [schema.sql](schema.sql).
4. Run the query.

The schema creates:
- `profiles`
- `instructor_profiles`
- `student_profiles`
- `subject_offerings`
- `subject_enrollments`
- `requests`

It also creates the trigger that auto-creates a `profiles` row whenever a new `auth.users` row is inserted.

## 5. Verify the tables
1. Open the table editor.
2. Confirm the tables exist.
3. Confirm row-level security is enabled on the app tables.
4. Confirm the trigger on `auth.users` exists.

## 6. Wire the app later
When you are ready to connect the app:
1. Replace the temporary local auth repositories with Supabase Auth calls.
2. Read the user role from `profiles.role`.
3. Use `subject_offerings`, `subject_enrollments`, and `requests` for the admin screens.
4. Keep the `SUPABASE_URL` and `SUPABASE_ANON_KEY` values in your run configuration.

# StudFy

A university student management system built with Flutter and Supabase. Supports role-based access for **Admin**, **Professor**, and **Student** users.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) |
| Backend | Supabase (Auth, Database, Edge Functions) |
| Hosting | Firebase Hosting |
| State | Provider + ChangeNotifier |
| Routing | go_router |
| Error Tracking | Sentry |

---

## Project Structure

```
lib/
├── core/
│   ├── constants/       # Colors, theme values
│   ├── router/          # GoRouter config + route guards
│   ├── services/        # Error telemetry
│   ├── state/           # AppState (global state)
│   └── widgets/         # Shared widgets (header, footer, dialogs)
├── features/
│   ├── admin/           # Admin dashboard, CRUD screens
│   │   ├── data/        # Supabase repository
│   │   ├── domain/      # Models (Instructor, Student)
│   │   └── presentation/# Screens + widgets
│   ├── auth/            # Login, registration, password reset
│   │   ├── data/        # Auth + profile repositories
│   │   ├── domain/      # AuthService, models, enums
│   │   └── presentation/# Login, signup, verify screens
│   ├── professor/       # Professor dashboard
│   └── student/         # Student dashboard
└── main.dart            # App entry point

supabase/
├── functions/           # Edge Functions (server-side logic)
│   ├── create-instructor/
│   ├── create-student/
│   ├── delete-user/
│   ├── redeem-enrollment-code/
│   ├── resolve-role-request/
│   ├── update-instructor/
│   └── update-student/
├── schema.sql           # Database schema
├── features_migration.sql
└── enrollment_codes_migration.sql
```

---

## Roles & Permissions

| Role | Access |
|------|--------|
| Admin | Full CRUD on students, instructors, subjects, enrollment codes. Approve/reject registration requests. |
| Professor | View assigned subjects, manage assignments (in progress) |
| Student | View enrolled subjects, modules (in progress) |

---

## Authentication Flow

1. Admin pre-creates student/professor accounts (via dashboard or enrollment codes)
2. User logs in with email/password
3. App checks `profiles` table for role → checks `student_profiles` or `instructor_profiles` for approval
4. If approved → route to role-specific dashboard
5. If not found → "Access Denied" message

Google OAuth is partially implemented — it matches by email against existing profiles.

---

## Database Tables

| Table | Purpose |
|-------|---------|
| `profiles` | User metadata (id, email, display_name, role) |
| `student_profiles` | Student-specific data (course_code, year_section, student_number) |
| `instructor_profiles` | Instructor-specific data (department, instructor_id) |
| `subject_offerings` | Subjects per semester (name, course_code, section, professor) |
| `subject_enrollments` | Student ↔ Subject mapping |
| `enrollment_codes` | Admin-generated codes for student self-registration |
| `requests` | Pending role assignment / account requests |

---

## Getting Started

### Prerequisites

- Flutter SDK 3.11+
- Firebase CLI (`npm install -g firebase-tools`)
- Supabase project with Edge Functions deployed

### Run Locally

```bash
# Install dependencies
flutter pub get

# Run on Chrome (web)
flutter run -d chrome --dart-define-from-file=.env

# Or use the helper script
./run.sh -d chrome
```

### Environment Variables

Create a `.env` file in the project root:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SENTRY_DSN=your-sentry-dsn (optional)
```

### Build for Production

```bash
flutter build web --dart-define-from-file=.env
```

### Deploy to Firebase Hosting

```bash
firebase deploy --only hosting
```

---

## Edge Functions

All admin write operations go through Supabase Edge Functions (because they require `auth.admin` privileges):

| Function | Purpose |
|----------|---------|
| `create-student` | Creates auth user + profile + student_profiles row |
| `create-instructor` | Creates auth user + profile + instructor_profiles row |
| `delete-user` | Removes auth user + all related rows |
| `update-student` | Updates student name, course, year/section |
| `update-instructor` | Updates instructor name, department |
| `resolve-role-request` | Approves/rejects pending registration requests |
| `redeem-enrollment-code` | Validates and consumes an enrollment code during student signup |

---

## VS Code 

The project includes a `launch.json` with pre-configured targets:

- **studfy (Chrome)** — web
- **studfy (macOS)** — desktop
- **studfy (iOS Simulator)** — mobile
- **studfy (Android)** — mobile

All configs pass `--dart-define-from-file=.env` automatically.

---

## Known Limitations

- Google OAuth sign-in works but requires pre-existing profile (no self-registration via Google)
- No offline support
- No automated tests yet

## Scope: Single Semester

StudFy is intentionally scoped to **one active semester**. There is no academic-year/term model: subjects, enrollments, attendance, grades, and quizzes all live in a single current term. The `subject_offerings` table has optional `semester` / `academic_year` columns, but no application logic reads or filters by them — they are reserved for a future multi-term feature. For now, treat the whole system as a single semester; to start a new term you would archive/reset data rather than switch terms in-app.

---

## Backend Features Missing a Frontend

These have working backend (Edge Function + repository + state) but no UI to trigger them:

- **Bulk student import** — `bulk-import-students` Edge Function, `SupabaseAdminRepository.bulkImportStudents`, and `AppState.bulkImportStudents` all exist, but there is no admin UI (button, CSV file picker, preview, or results dialog) that calls them. Admins can currently only add students one at a time. The flow is exercised only via `supabase/scripts/test_bulk_import.sh`.

---

## Team

University capstone project — BSIT / BSCpE

---

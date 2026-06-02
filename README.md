# StudFy

A web-based school management system built with Flutter and Supabase.

---

## Features

### Admin
- **Dashboard** — Overview of pending requests, instructors, students, and subjects
- **Instructor Management** — Add, edit, and delete instructor accounts
- **Student Management** — Add, edit, delete, and enroll students in subjects
- **Subject Management** — Create, edit, delete subjects and assign professors
- **Enrollment Codes** — Generate codes for student self-registration with optional max uses and expiry
- **Role Requests** — Approve or reject professor registration requests
- **Google Sign-In** — Login with existing Google account

### Professor
- Login with email/password or Google account
- Access to professor dashboard

### Student
- Self-registration using an enrollment code
- Login with email/password or Google account
- Access to student dashboard

### Authentication
- Email/password login and registration
- Google OAuth sign-in
- Role-based access control (Admin, Professor, Student)
- Forgot password flow

---

## System Structure

```
studfy/
├── lib/
│   ├── core/
│   │   ├── constants/        # App colors and theme
│   │   ├── router/           # GoRouter navigation and route guards
│   │   ├── services/         # Error telemetry
│   │   ├── state/            # AppState (ChangeNotifier)
│   │   └── widgets/          # Shared widgets (AppDialog, Header, Footer)
│   ├── features/
│   │   ├── admin/
│   │   │   ├── data/         # SupabaseAdminRepository
│   │   │   ├── domain/       # Models (Instructor, Student)
│   │   │   └── presentation/ # Admin screens and widgets
│   │   ├── auth/
│   │   │   ├── data/         # Supabase auth and profile repositories
│   │   │   ├── domain/       # AuthService, models, enums
│   │   │   └── presentation/ # Login, registration, forgot password screens
│   │   ├── professor/
│   │   │   └── presentation/ # Professor dashboard
│   │   └── student/
│   │       └── presentation/ # Student dashboard
│   ├── app.dart              # App entry, auth state listener
│   └── main.dart             # Supabase initialization
├── supabase/
│   ├── functions/            # Edge Functions (see below)
│   └── schema.sql            # Full database schema
└── .env                      # Supabase URL and anon key (not committed)
```

---

## Database

Built on **Supabase** (PostgreSQL) with the following tables:

| Table | Description |
|---|---|
| `profiles` | Core user data linked to `auth.users` |
| `instructor_profiles` | Instructor-specific data (department, instructor ID) |
| `student_profiles` | Student-specific data (student number, course, section) |
| `subject_offerings` | Subjects/classes offered |
| `subject_enrollments` | Student-subject enrollment records |
| `enrollment_codes` | Registration codes for student self-enrollment |
| `requests` | Role assignment and other pending requests |

Row Level Security (RLS) is enabled on all tables. Access is controlled via the `is_admin()` function and user-specific policies.

---

## Edge Functions

Sensitive operations that require the Supabase **service role key** are handled server-side via Deno Edge Functions:

| Function | Description |
|---|---|
| `create-instructor` | Creates a new instructor auth user and profile |
| `create-student` | Creates a new student auth user and profile |
| `update-instructor` | Updates instructor name and department |
| `update-student` | Updates student name, course, and section |
| `delete-user` | Deletes a user from `auth.users` (cascades to all profile data) |
| `resolve-role-request` | Approves or rejects a professor registration request |
| `redeem-enrollment-code` | Validates an enrollment code and creates a student profile |

All Edge Functions verify the caller is an authenticated admin before executing.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Web) |
| Backend / Database | Supabase (PostgreSQL) |
| Authentication | Supabase Auth (Email + Google OAuth) |
| Server-side Logic | Supabase Edge Functions (Deno) |
| State Management | Provider + ChangeNotifier |
| Navigation | GoRouter |
| Error Tracking | Sentry |

---

## Getting Started

### Prerequisites
- Flutter SDK
- Supabase project
- Supabase CLI (for Edge Functions)

### Setup

1. **Clone the repository**
```bash
git clone <repo-url>
cd studfy
```

2. **Create `.env` file**
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

3. **Run database schema**

Go to **Supabase Dashboard → SQL Editor** and run `supabase/schema.sql`.

4. **Deploy Edge Functions**
```bash
supabase login
supabase link --project-ref your-project-ref
supabase functions deploy
```

5. **Run the app**
```bash
flutter run -d chrome --web-port=8080 --dart-define-from-file=.env
```

### Creating the first Admin

1. Go to **Supabase Dashboard → Authentication → Users → Add user**
2. Create a user with email and password
3. Run in **SQL Editor**:
```sql
UPDATE public.profiles
SET role = 'admin'
WHERE email = 'your-admin-email@here.com';
```

---

## Default Credentials

Admin-created instructor and student accounts use the default password:
```
Studfy@123
```

Users should change their password after first login.

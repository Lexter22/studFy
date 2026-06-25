-- Adds the 'student_unenroll' request kind.
--
-- When a professor un-enrolls a student, the app does NOT remove the student
-- immediately. Instead it inserts a pending request (kind = 'student_unenroll')
-- that an admin approves from the Instructor Requests list. On approval the
-- student's subject_enrollments row is deleted.
--
-- The Flutter code already uses this kind; the enum just needs the value.

alter type public.request_kind add value if not exists 'student_unenroll';

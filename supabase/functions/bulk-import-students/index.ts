import { createClient } from 'jsr:@supabase/supabase-js@2'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}
const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), { status, headers: { ...cors, 'Content-Type': 'application/json' } })

interface StudentRow {
  name: string
  email: string
  course: string
  yearSection: string
  studentNumber?: string
}

interface ImportResult {
  email: string
  name: string
  status: 'created' | 'skipped' | 'error'
  reason?: string
  defaultPassword?: string
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })

  try {
    // ── Auth check ──────────────────────────────────────────────────────
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) return json({ error: 'Missing authorization header' }, 401)

    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    const { data: { user }, error: userError } = await admin.auth.getUser(
      authHeader.replace('Bearer ', ''),
    )
    if (userError || !user) return json({ error: 'Unauthorized' }, 401)

    const { data: profile } = await admin
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single()
    if (profile?.role !== 'admin') return json({ error: 'Forbidden: admin only' }, 403)

    // ── Parse input ─────────────────────────────────────────────────────
    const { students } = await req.json() as { students: StudentRow[] }

    if (!students || !Array.isArray(students) || students.length === 0) {
      return json({ error: 'No students provided. Expected { students: [...] }' }, 400)
    }

    if (students.length > 100) {
      return json({ error: 'Maximum 100 students per batch. Split into multiple requests.' }, 400)
    }

    // ── Validate rows ───────────────────────────────────────────────────
    const defaultPassword = 'Studfy@123'
    const results: ImportResult[] = []
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

    for (const row of students) {
      const email = (row.email ?? '').trim().toLowerCase()
      const name = (row.name ?? '').trim()
      const course = (row.course ?? '').trim()
      const yearSection = (row.yearSection ?? '').trim()
      const studentNumber = (row.studentNumber ?? '').trim()

      // ── Validate required fields ──────────────────────────────────────
      if (!name || !email || !course || !yearSection) {
        results.push({
          email: email || '(empty)',
          name: name || '(empty)',
          status: 'error',
          reason: 'Missing required fields (name, email, course, yearSection)',
        })
        continue
      }

      if (!emailRegex.test(email)) {
        results.push({ email, name, status: 'error', reason: 'Invalid email format' })
        continue
      }

      // ── Check if email already exists ─────────────────────────────────
      const { data: existingProfile } = await admin
        .from('profiles')
        .select('id')
        .eq('email', email)
        .maybeSingle()

      if (existingProfile) {
        results.push({ email, name, status: 'skipped', reason: 'Email already exists' })
        continue
      }

      // ── Create auth user ──────────────────────────────────────────────
      const nameParts = name.split(' ')
      const firstName = nameParts[0] ?? ''
      const lastName = nameParts.length > 1 ? nameParts.slice(1).join(' ') : ''
      const displayName = name

      const { data: newUser, error: createError } = await admin.auth.admin.createUser({
        email,
        email_confirm: true,
        password: defaultPassword,
        user_metadata: {
          first_name: firstName,
          last_name: lastName,
          display_name: displayName,
          role: 'student',
        },
      })

      if (createError) {
        results.push({ email, name, status: 'error', reason: createError.message })
        continue
      }

      const uid = newUser.user.id

      // ── Generate student number if not provided ───────────────────────
      const year = new Date().getFullYear()
      const randomNum = String(Math.floor(Math.random() * 99999) + 1).padStart(5, '0')
      const resolvedStudentNumber = studentNumber || `${year}-${randomNum}-BN-0`

      // ── Create student_profiles row ───────────────────────────────────
      const { error: studentError } = await admin.from('student_profiles').insert({
        profile_id: uid,
        student_number: resolvedStudentNumber,
        course_code: course,
        year_section: yearSection,
      })

      if (studentError) {
        // Rollback: delete the auth user
        await admin.auth.admin.deleteUser(uid)
        results.push({ email, name, status: 'error', reason: studentError.message })
        continue
      }

      // ── Set role in profiles table ────────────────────────────────────
      await admin.from('profiles').update({ role: 'student' }).eq('id', uid)

      results.push({ email, name, status: 'created', defaultPassword })
    }

    // ── Summary ─────────────────────────────────────────────────────────
    const created = results.filter((r) => r.status === 'created').length
    const skipped = results.filter((r) => r.status === 'skipped').length
    const errors = results.filter((r) => r.status === 'error').length

    return json({
      summary: { total: students.length, created, skipped, errors },
      results,
    })
  } catch (err) {
    return json({ error: String(err) }, 500)
  }
})

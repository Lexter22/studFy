import { createClient } from 'jsr:@supabase/supabase-js@2'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}
const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), { status, headers: { ...cors, 'Content-Type': 'application/json' } })

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })
  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) return json({ error: 'Missing authorization header' }, 401)

    const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!)

    const { data: { user }, error: userError } = await admin.auth.getUser(authHeader.replace('Bearer ', ''))
    if (userError || !user) return json({ error: 'Unauthorized' }, 401)

    const { code } = await req.json()
    if (!code) return json({ error: 'Missing enrollment code' }, 400)

    // Prevent duplicate student profiles before consuming a code use
    const { data: existing } = await admin.from('student_profiles').select('profile_id').eq('profile_id', user.id).maybeSingle()
    if (existing) return json({ error: 'You already have a student profile.' }, 400)

    // Atomically validate + consume one use of the code (race-safe via row lock in the RPC)
    const { data: consumeRows, error: consumeError } = await admin
      .rpc('consume_enrollment_code', { p_code: code.trim() })
    if (consumeError) return json({ error: consumeError.message }, 400)

    const consumed = Array.isArray(consumeRows) ? consumeRows[0] : consumeRows
    const status = consumed?.status ?? 'invalid'
    if (status !== 'ok') {
      const messages: Record<string, string> = {
        invalid: 'Invalid enrollment code.',
        inactive: 'This enrollment code is inactive.',
        expired: 'This enrollment code has expired.',
        exhausted: 'This enrollment code has reached its maximum uses.',
      }
      return json({ error: messages[status] ?? 'Invalid or inactive enrollment code.' }, 400)
    }

    const courseCode = consumed.course_code as string
    const yearSection = consumed.year_section as string

    // Deterministic, collision-free student number derived from the user id
    const year = new Date().getFullYear()
    const uidPart = user.id.replace(/-/g, '').substring(0, 8).toUpperCase()
    const studentNumber = `${year}-${uidPart}-BN-0`

    const { error: studentError } = await admin.from('student_profiles').insert({
      profile_id: user.id,
      student_number: studentNumber,
      course_code: courseCode,
      year_section: yearSection,
    })
    if (studentError) {
      // Compensate: release the use we just consumed
      await admin.rpc('release_enrollment_code', { p_code: code.trim() })
      return json({ error: studentError.message }, 400)
    }

    await admin.from('profiles').update({ role: 'student' }).eq('id', user.id)

    return json({ success: true, course_code: courseCode, year_section: yearSection })
  } catch (err) {
    return json({ error: String(err) }, 500)
  }
})

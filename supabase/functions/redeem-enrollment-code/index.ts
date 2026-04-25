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

    const { data: enrollment, error: codeError } = await admin
      .from('enrollment_codes')
      .select('*')
      .eq('code', code.trim().toUpperCase())
      .eq('is_active', true)
      .single()
    if (codeError || !enrollment) return json({ error: 'Invalid or inactive enrollment code.' }, 400)

    if (enrollment.expires_at && new Date(enrollment.expires_at) < new Date())
      return json({ error: 'This enrollment code has expired.' }, 400)

    if (enrollment.max_uses !== null && enrollment.current_uses >= enrollment.max_uses)
      return json({ error: 'This enrollment code has reached its maximum uses.' }, 400)

    const { data: existing } = await admin.from('student_profiles').select('profile_id').eq('profile_id', user.id).maybeSingle()
    if (existing) return json({ error: 'You already have a student profile.' }, 400)

    const year = new Date().getFullYear()
    const randomNum = String(Math.floor(Math.random() * 99999) + 1).padStart(5, '0')

    const { error: studentError } = await admin.from('student_profiles').insert({
      profile_id: user.id,
      student_number: `${year}-${randomNum}-BN-0`,
      course_code: enrollment.course_code,
      year_section: enrollment.year_section,
    })
    if (studentError) return json({ error: studentError.message }, 400)

    await admin.from('profiles').update({ role: 'student' }).eq('id', user.id)
    await admin.from('enrollment_codes').update({ current_uses: enrollment.current_uses + 1 }).eq('id', enrollment.id)

    return json({ success: true, course_code: enrollment.course_code, year_section: enrollment.year_section })
  } catch (err) {
    return json({ error: String(err) }, 500)
  }
})

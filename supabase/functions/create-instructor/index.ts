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

    // Verify caller is admin
    const { data: { user }, error: userError } = await admin.auth.getUser(authHeader.replace('Bearer ', ''))
    if (userError || !user) return json({ error: 'Unauthorized' }, 401)

    const { data: profile } = await admin.from('profiles').select('role').eq('id', user.id).single()
    if (profile?.role !== 'admin') return json({ error: 'Forbidden: admin only' }, 403)

    const { firstName, lastName, email, department, instructorId } = await req.json()
    if (!firstName || !lastName || !email || !department) return json({ error: 'Missing required fields' }, 400)

    const displayName = `${firstName.trim()} ${lastName.trim()}`.trim()
    const defaultPassword = 'Studfy@123'

    const { data: newUser, error: createError } = await admin.auth.admin.createUser({
      email: email.trim().toLowerCase(),
      email_confirm: true,
      password: defaultPassword,
      user_metadata: { first_name: firstName.trim(), last_name: lastName.trim(), display_name: displayName, role: 'professor', must_change_password: true },
    })
    if (createError) return json({ error: createError.message }, 400)

    const uid = newUser.user.id
    const resolvedId = (instructorId ?? '').trim() || `INS-${uid.substring(0, 8).toUpperCase()}`

    const { error: insertError } = await admin.from('instructor_profiles').insert({
      profile_id: uid,
      instructor_id: resolvedId,
      department: department.trim(),
    })

    if (insertError) {
      await admin.auth.admin.deleteUser(uid)
      return json({ error: insertError.message }, 400)
    }

    await admin.from('profiles').update({ role: 'professor' }).eq('id', uid)

    return json({ id: uid, defaultPassword })
  } catch (err) {
    return json({ error: String(err) }, 500)
  }
})

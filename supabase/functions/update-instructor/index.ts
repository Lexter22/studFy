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

    const { data: profile } = await admin.from('profiles').select('role').eq('id', user.id).single()
    if (profile?.role !== 'admin') return json({ error: 'Forbidden: admin only' }, 403)

    const { profileId, name, department } = await req.json()
    if (!profileId || !name || !department) return json({ error: 'Missing required fields' }, 400)

    const nameParts = name.trim().split(' ')
    const firstName = nameParts[0] ?? ''
    const lastName = nameParts.slice(1).join(' ') || firstName

    const { error: profileError } = await admin.from('profiles').update({
      display_name: name.trim(),
      first_name: firstName,
      last_name: lastName,
    }).eq('id', profileId)
    if (profileError) return json({ error: profileError.message }, 400)

    const { error: deptError } = await admin.from('instructor_profiles').update({
      department: department.trim(),
    }).eq('profile_id', profileId)
    if (deptError) return json({ error: deptError.message }, 400)

    return json({ success: true })
  } catch (err) {
    return json({ error: String(err) }, 500)
  }
})

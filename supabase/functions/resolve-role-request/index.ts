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

    const { requestId, approve } = await req.json()
    if (!requestId) return json({ error: 'Missing requestId' }, 400)

    const { data: row, error: fetchError } = await admin
      .from('requests')
      .select('requester_profile_id,metadata')
      .eq('id', requestId)
      .single()
    if (fetchError || !row) return json({ error: 'Request not found' }, 404)

    await admin.from('requests').update({
      status: approve ? 'approved' : 'rejected',
      resolved_by: user.id,
      resolved_at: new Date().toISOString(),
    }).eq('id', requestId)

    if (!approve || !row.requester_profile_id) return json({ success: true })

    const requesterId = row.requester_profile_id
    const metadata = row.metadata ?? {}
    const requestedRole = (metadata.requested_role ?? '').toLowerCase().trim()
    const val = (v: string | undefined, fallback: string) => (v ?? '').trim() || fallback

    if (requestedRole === 'student') {
      await admin.from('student_profiles').upsert({
        profile_id: requesterId,
        student_number: val(metadata.student_number, `STU-${requesterId.substring(0, 8).toUpperCase()}`),
        course_code: val(metadata.course_code, 'BSIT'),
        year_section: val(metadata.year_section, '1-1'),
      }, { onConflict: 'profile_id' })
      await admin.from('profiles').update({ role: 'student' }).eq('id', requesterId)
    } else if (requestedRole === 'professor') {
      await admin.from('instructor_profiles').upsert({
        profile_id: requesterId,
        instructor_id: val(metadata.instructor_id, `INS-${requesterId.substring(0, 8).toUpperCase()}`),
        department: val(metadata.department, 'General'),
      }, { onConflict: 'profile_id' })
      await admin.from('profiles').update({ role: 'professor' }).eq('id', requesterId)
    }

    return json({ success: true })
  } catch (err) {
    return json({ error: String(err) }, 500)
  }
})

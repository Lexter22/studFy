import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

async function verifyAdmin(supabaseAdmin: any, authHeader: string) {
  const callerClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } },
  )
  const { data: { user }, error } = await callerClient.auth.getUser()
  if (error || !user) return null
  const { data: profile } = await supabaseAdmin.from('profiles').select('role').eq('id', user.id).single()
  return profile?.role === 'admin' ? user : null
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) return new Response(JSON.stringify({ error: 'Missing authorization header' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })

    const supabaseAdmin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!)
    const admin = await verifyAdmin(supabaseAdmin, authHeader)
    if (!admin) return new Response(JSON.stringify({ error: 'Forbidden: admin only' }), { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })

    const { requestId, approve } = await req.json()
    if (!requestId) return new Response(JSON.stringify({ error: 'Missing requestId' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })

    // Fetch the request
    const { data: row, error: fetchError } = await supabaseAdmin
      .from('requests')
      .select('requester_profile_id,metadata')
      .eq('id', requestId)
      .single()

    if (fetchError || !row) return new Response(JSON.stringify({ error: 'Request not found' }), { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })

    // Update request status
    await supabaseAdmin.from('requests').update({
      status: approve ? 'approved' : 'rejected',
      resolved_by: admin.id,
      resolved_at: new Date().toISOString(),
    }).eq('id', requestId)

    if (!approve || !row.requester_profile_id) {
      return new Response(JSON.stringify({ success: true }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const requesterId = row.requester_profile_id
    const metadata = row.metadata ?? {}
    const requestedRole = (metadata.requested_role ?? '').toLowerCase().trim()

    const valueOrFallback = (val: string | undefined, fallback: string) => (val ?? '').trim() || fallback

    if (requestedRole === 'student') {
      await supabaseAdmin.from('student_profiles').upsert({
        profile_id: requesterId,
        student_number: valueOrFallback(metadata.student_number, `STU-${requesterId.substring(0, 8).toUpperCase()}`),
        course_code: valueOrFallback(metadata.course_code, 'BSIT'),
        year_section: valueOrFallback(metadata.year_section, '1-1'),
      }, { onConflict: 'profile_id' })
      await supabaseAdmin.from('profiles').update({ role: 'student' }).eq('id', requesterId)
    } else if (requestedRole === 'professor') {
      await supabaseAdmin.from('instructor_profiles').upsert({
        profile_id: requesterId,
        instructor_id: valueOrFallback(metadata.instructor_id, `INS-${requesterId.substring(0, 8).toUpperCase()}`),
        department: valueOrFallback(metadata.department, 'General'),
      }, { onConflict: 'profile_id' })
      await supabaseAdmin.from('profiles').update({ role: 'professor' }).eq('id', requesterId)
    }

    return new Response(JSON.stringify({ success: true }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing authorization header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // Get the calling user
    const callerClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    )

    const { data: { user }, error: userError } = await callerClient.auth.getUser()
    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { code } = await req.json()
    if (!code) {
      return new Response(JSON.stringify({ error: 'Missing enrollment code' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Look up the code
    const { data: enrollment, error: codeError } = await supabaseAdmin
      .from('enrollment_codes')
      .select('*')
      .eq('code', code.trim().toUpperCase())
      .eq('is_active', true)
      .single()

    if (codeError || !enrollment) {
      return new Response(JSON.stringify({ error: 'Invalid or inactive enrollment code.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Check expiry
    if (enrollment.expires_at && new Date(enrollment.expires_at) < new Date()) {
      return new Response(JSON.stringify({ error: 'This enrollment code has expired.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Check max uses
    if (enrollment.max_uses !== null && enrollment.current_uses >= enrollment.max_uses) {
      return new Response(JSON.stringify({ error: 'This enrollment code has reached its maximum uses.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Check if user already redeemed a code
    const { data: existing } = await supabaseAdmin
      .from('student_profiles')
      .select('profile_id')
      .eq('profile_id', user.id)
      .maybeSingle()

    if (existing) {
      return new Response(JSON.stringify({ error: 'You already have a student profile.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Insert student_profiles row
    const year = new Date().getFullYear()
    const randomNum = String(Math.floor(Math.random() * 99999) + 1).padStart(5, '0')
    const { error: studentError } = await supabaseAdmin
      .from('student_profiles')
      .insert({
        profile_id: user.id,
        student_number: `${year}-${randomNum}-BN-0`,
        course_code: enrollment.course_code,
        year_section: enrollment.year_section,
      })

    if (studentError) {
      return new Response(JSON.stringify({ error: studentError.message }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Update profile role to student
    await supabaseAdmin
      .from('profiles')
      .update({ role: 'student' })
      .eq('id', user.id)

    // Increment current_uses
    await supabaseAdmin
      .from('enrollment_codes')
      .update({ current_uses: enrollment.current_uses + 1 })
      .eq('id', enrollment.id)

    return new Response(JSON.stringify({
      success: true,
      course_code: enrollment.course_code,
      year_section: enrollment.year_section,
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

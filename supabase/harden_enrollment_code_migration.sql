-- Hardening: atomic enrollment-code consumption.
--
-- Previously the redeem-enrollment-code Edge Function read current_uses and then
-- wrote current_uses + 1 in two separate steps. Under concurrent redemptions this
-- could exceed max_uses (lost-update race). This RPC validates and increments the
-- usage counter in a single transaction, locking the row with FOR UPDATE so two
-- callers cannot both pass the max_uses check.
--
-- Returns one row: (course_code, year_section, status)
--   status = 'ok'        -> a use was consumed; course_code/year_section are set
--   status = 'invalid'   -> no such code
--   status = 'inactive'  -> code disabled
--   status = 'expired'   -> past expires_at
--   status = 'exhausted' -> max_uses reached

create or replace function public.consume_enrollment_code(p_code text)
returns table (course_code text, year_section text, status text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.enrollment_codes%rowtype;
begin
  select * into v_row
  from public.enrollment_codes
  where code = upper(trim(p_code))
  for update;

  if not found then
    return query select null::text, null::text, 'invalid'::text;
    return;
  end if;

  if not v_row.is_active then
    return query select null::text, null::text, 'inactive'::text;
    return;
  end if;

  if v_row.expires_at is not null and v_row.expires_at < now() then
    return query select null::text, null::text, 'expired'::text;
    return;
  end if;

  if v_row.max_uses is not null and v_row.current_uses >= v_row.max_uses then
    return query select null::text, null::text, 'exhausted'::text;
    return;
  end if;

  update public.enrollment_codes
  set current_uses = current_uses + 1
  where id = v_row.id;

  return query select v_row.course_code, v_row.year_section, 'ok'::text;
end;
$$;

-- Compensating helper: release a consumed use if profile creation fails afterwards.
create or replace function public.release_enrollment_code(p_code text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.enrollment_codes
  set current_uses = greatest(current_uses - 1, 0)
  where code = upper(trim(p_code));
end;
$$;

-- Allow authenticated users to call these via the service role (Edge Function).
-- (Edge Functions use the service role key, which bypasses RLS, but we grant
--  execute explicitly so the functions can also be called by authenticated roles
--  if ever needed.)
grant execute on function public.consume_enrollment_code(text) to authenticated, service_role;
grant execute on function public.release_enrollment_code(text) to authenticated, service_role;

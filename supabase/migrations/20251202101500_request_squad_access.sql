-- ###########################################################################
-- Migration: request squad access (pending)
-- Purpose:
--   - Allow authenticated users to request access by creating pending membership.
-- Decisions:
--   - Use SECURITY DEFINER to control insert/update without direct table access.
--   - Allow re-apply for pending/declined/removed roles.
-- ###########################################################################

create or replace function public.request_squad_access(target_squad_id uuid)
returns void
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not exists (
    select 1
    from public.squads s
    where s.squad_id = target_squad_id
  ) then
    raise exception 'squad_not_found';
  end if;

  insert into public.user_squads (user_id, squad_id, role)
  values (auth.uid(), target_squad_id, 'pending')
  on conflict (user_id, squad_id) do update
    set role = 'pending'
    where public.user_squads.role in ('declined', 'removed', 'pending');
end;
$$;

comment on function public.request_squad_access is
  'Request access to a squad by creating a pending membership.';

revoke all on function public.request_squad_access(uuid) from public;
grant execute on function public.request_squad_access(uuid) to authenticated;

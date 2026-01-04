-- ###########################################################################
-- Migration: create invite_links table + join function
-- Purpose:
--   - Store single active invite code per squad.
--   - Provide RPC to join via invite code.
-- Decisions:
--   - RLS is owner-only; join happens via RPC.
-- ###########################################################################

create table public.invite_links (
  code text primary key,
  squad_id uuid not null
    references public.squads (squad_id)
    on delete cascade,
  created_at timestamptz not null default now(),
  valid_until timestamptz not null,
  created_by uuid not null
    references auth.users (id),
  constraint invite_links_squad_unique unique (squad_id)
);

alter table public.invite_links enable row level security;

create policy "Owners can read invite links"
  on public.invite_links
  for select
  using (
    exists (
      select 1
      from public.squads s
      where s.squad_id = invite_links.squad_id
        and s.owner_id = auth.uid()
    )
  );

create policy "Owners can insert invite links"
  on public.invite_links
  for insert
  with check (
    created_by = auth.uid()
    and exists (
      select 1
      from public.squads s
      where s.squad_id = invite_links.squad_id
        and s.owner_id = auth.uid()
    )
  );

create policy "Owners can update invite links"
  on public.invite_links
  for update
  using (
    exists (
      select 1
      from public.squads s
      where s.squad_id = invite_links.squad_id
        and s.owner_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from public.squads s
      where s.squad_id = invite_links.squad_id
        and s.owner_id = auth.uid()
    )
  );

create policy "Owners can delete invite links"
  on public.invite_links
  for delete
  using (
    exists (
      select 1
      from public.squads s
      where s.squad_id = invite_links.squad_id
        and s.owner_id = auth.uid()
    )
  );

create or replace function public.join_squad_by_invite(invite_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  target_squad_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  select squad_id
    into target_squad_id
  from public.invite_links
  where code = invite_code
    and valid_until > now()
  limit 1;

  if target_squad_id is null then
    raise exception 'invalid_invite_code';
  end if;

  insert into public.user_squads (user_id, squad_id, role)
  values (auth.uid(), target_squad_id, 'member')
  on conflict (user_id, squad_id) do nothing;

  return target_squad_id;
end;
$$;

comment on function public.join_squad_by_invite is
  'Join a squad by invite code. Validates expiry and adds current user as member.';

revoke all on function public.join_squad_by_invite(text) from public;
grant execute on function public.join_squad_by_invite(text) to authenticated;

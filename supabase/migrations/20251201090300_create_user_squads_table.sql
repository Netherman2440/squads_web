-- ###########################################################################
-- Migration: create user_squads table
-- Purpose:
--   - Model user membership and role per squad.
-- Decisions:
--   - Composite primary key (user_id, squad_id).
-- ###########################################################################

create table public.user_squads (
  user_id uuid not null,

  squad_id uuid not null,

  role public.user_squad_role not null,

  created_at timestamptz not null
    default now(),

  constraint user_squads_pk
    primary key (user_id, squad_id),
  constraint user_squads_user_fk
    foreign key (user_id)
    references auth.users (id)
    on delete cascade,

  constraint user_squads_squad_fk
    foreign key (squad_id)
    references public.squads (squad_id)
    on delete cascade
);

create index user_squads_user_idx
  on public.user_squads (user_id);

create index user_squads_squad_idx
  on public.user_squads (squad_id);

-- RLS helper functions (SECURITY DEFINER) to avoid policy recursion.
create or replace function public.is_squad_owner(target_squad_id uuid)
returns boolean
language sql
security definer
set search_path = public
set row_security = off
as $$
  select exists (
    select 1
    from public.squads s
    where s.squad_id = target_squad_id
      and s.owner_id = auth.uid()
  );
$$;

create or replace function public.is_squad_admin(target_squad_id uuid)
returns boolean
language sql
security definer
set search_path = public
set row_security = off
as $$
  select exists (
    select 1
    from public.user_squads us
    where us.squad_id = target_squad_id
      and us.user_id = auth.uid()
      and us.role in ('owner', 'admin')
  );
$$;

create or replace function public.is_squad_member(target_squad_id uuid)
returns boolean
language sql
security definer
set search_path = public
set row_security = off
as $$
  select exists (
    select 1
    from public.user_squads us
    where us.squad_id = target_squad_id
      and us.user_id = auth.uid()
      and us.role in ('owner', 'admin', 'member')
  );
$$;

revoke all on function public.is_squad_owner(uuid) from public;
revoke all on function public.is_squad_admin(uuid) from public;
revoke all on function public.is_squad_member(uuid) from public;
grant execute on function public.is_squad_owner(uuid) to anon, authenticated;
grant execute on function public.is_squad_admin(uuid) to anon, authenticated;
grant execute on function public.is_squad_member(uuid) to anon, authenticated;

alter table public.user_squads enable row level security;

create policy "Users can read own memberships or owned squads"
  on public.user_squads
  for select
  using (
    user_id = auth.uid()
    or public.is_squad_owner(user_squads.squad_id)
  );

create policy "Owners can insert their membership"
  on public.user_squads
  for insert
  with check (
    user_id = auth.uid()
    and role = 'owner'
    and public.is_squad_owner(user_squads.squad_id)
  );

create policy "Owners can update memberships"
  on public.user_squads
  for update
  using (public.is_squad_owner(user_squads.squad_id))
  with check (public.is_squad_owner(user_squads.squad_id));

create policy "Owners can delete memberships"
  on public.user_squads
  for delete
  using (public.is_squad_owner(user_squads.squad_id));

-- Squads SELECT policy depends on user_squads existence.
create policy "Members can read squads"
  on public.squads
  for select
  using (
    visibility = 'public'
    or public.is_squad_member(squads.squad_id)
  );

create policy "Owners can read profiles of squad members"
  on public.users
  for select
  using (
    exists (
      select 1
      from public.user_squads us
      where us.user_id = users.user_id
        and public.is_squad_owner(us.squad_id)
    )
  );

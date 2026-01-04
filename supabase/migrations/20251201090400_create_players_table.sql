-- ###########################################################################
-- Migration: create players table
-- Purpose:
--   - Store players within squads with base/derived scores.
-- Decisions:
--   - Enforce unique player name per squad.
-- ###########################################################################

create table public.players (
  player_id uuid primary key
    default gen_random_uuid(),

  squad_id uuid not null,

  name text not null,

  position text null,

  base_score integer not null
    default 0,

  score numeric(5,2) not null,

  created_at timestamptz not null
    default now(),

  constraint players_squad_fk
    foreign key (squad_id)
    references public.squads (squad_id)
    on delete cascade,

  constraint players_squad_name_unique
    unique (squad_id, name),

  constraint players_score_range_chk
    check (score >= 0 and score <= 100),

  constraint players_base_score_range_chk
    check (base_score >= 0 and base_score <= 100)
);

create index players_squad_idx
  on public.players (squad_id);

alter table public.players enable row level security;

create policy "Members can read players"
  on public.players
  for select
  using (
    exists (
      select 1
      from public.squads s
      where s.squad_id = players.squad_id
        and s.visibility = 'public'
    )
    or exists (
      select 1
      from public.user_squads us
      where us.squad_id = players.squad_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin', 'member')
    )
  );

create policy "Admins can insert players"
  on public.players
  for insert
  with check (
    exists (
      select 1
      from public.user_squads us
      where us.squad_id = players.squad_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

create policy "Admins can update players"
  on public.players
  for update
  using (
    exists (
      select 1
      from public.user_squads us
      where us.squad_id = players.squad_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  )
  with check (
    exists (
      select 1
      from public.user_squads us
      where us.squad_id = players.squad_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

create policy "Admins can delete players"
  on public.players
  for delete
  using (
    exists (
      select 1
      from public.user_squads us
      where us.squad_id = players.squad_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

-- ###########################################################################
-- Migration: create teams table
-- Purpose:
--   - Store home/away teams per match.
-- Decisions:
--   - Enforce unique side per match (home/away).
-- ###########################################################################

create table public.teams (
  team_id uuid primary key
    default gen_random_uuid(),

  match_id uuid not null,

  tournament_id uuid null,

  side public.side_enum not null,

  name text null,

  color text null,

  created_at timestamptz not null
    default now(),

  constraint teams_match_fk
    foreign key (match_id)
    references public.matches (match_id)
    on delete cascade,

  constraint teams_tournament_fk
    foreign key (tournament_id)
    references public.tournaments (tournament_id)
    on delete set null,

  constraint teams_match_side_unique
    unique (match_id, side),

  constraint teams_match_team_unique
    unique (match_id, team_id)
);

create index teams_match_idx
  on public.teams (match_id);

create index teams_tournament_idx
  on public.teams (tournament_id);

alter table public.teams enable row level security;

create policy "Members can read teams"
  on public.teams
  for select
  using (
    exists (
      select 1
      from public.matches m
      join public.squads s on s.squad_id = m.squad_id
      where m.match_id = teams.match_id
        and s.visibility = 'public'
    )
    or exists (
      select 1
      from public.matches m
      join public.user_squads us on us.squad_id = m.squad_id
      where m.match_id = teams.match_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin', 'member')
    )
  );

create policy "Admins can insert teams"
  on public.teams
  for insert
  with check (
    exists (
      select 1
      from public.matches m
      join public.user_squads us on us.squad_id = m.squad_id
      where m.match_id = teams.match_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

create policy "Admins can update teams"
  on public.teams
  for update
  using (
    exists (
      select 1
      from public.matches m
      join public.user_squads us on us.squad_id = m.squad_id
      where m.match_id = teams.match_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  )
  with check (
    exists (
      select 1
      from public.matches m
      join public.user_squads us on us.squad_id = m.squad_id
      where m.match_id = teams.match_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

create policy "Admins can delete teams"
  on public.teams
  for delete
  using (
    exists (
      select 1
      from public.matches m
      join public.user_squads us on us.squad_id = m.squad_id
      where m.match_id = teams.match_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

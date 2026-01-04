-- ###########################################################################
-- Migration: create team_players table
-- Purpose:
--   - Link players to teams within matches.
-- Decisions:
--   - Unique player per match enforced via constraint.
-- ###########################################################################

create table public.team_players (
  match_id uuid not null,

  team_id uuid not null,

  player_id uuid not null,

  tournament_id uuid null,

  created_at timestamptz not null
    default now(),

  constraint team_players_pk
    primary key (match_id, team_id, player_id),

  constraint team_players_match_fk
    foreign key (match_id)
    references public.matches (match_id)
    on delete cascade,

  constraint team_players_team_fk
    foreign key (team_id)
    references public.teams (team_id)
    on delete cascade,

  constraint team_players_match_team_fk
    foreign key (match_id, team_id)
    references public.teams (match_id, team_id),

  constraint team_players_player_fk
    foreign key (player_id)
    references public.players (player_id)
    on delete restrict,

  constraint team_players_tournament_fk
    foreign key (tournament_id)
    references public.tournaments (tournament_id)
    on delete set null,

  constraint team_players_unique_player_per_match
    unique (match_id, player_id)
);

create index team_players_player_idx
  on public.team_players (player_id);

create index team_players_team_idx
  on public.team_players (team_id);

alter table public.team_players enable row level security;

create policy "Members can read team players"
  on public.team_players
  for select
  using (
    exists (
      select 1
      from public.matches m
      join public.squads s on s.squad_id = m.squad_id
      where m.match_id = team_players.match_id
        and s.visibility = 'public'
    )
    or exists (
      select 1
      from public.matches m
      join public.user_squads us on us.squad_id = m.squad_id
      where m.match_id = team_players.match_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin', 'member')
    )
  );

create policy "Admins can insert team players"
  on public.team_players
  for insert
  with check (
    exists (
      select 1
      from public.matches m
      join public.user_squads us on us.squad_id = m.squad_id
      where m.match_id = team_players.match_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
    and exists (
      select 1
      from public.matches m
      join public.players p on p.squad_id = m.squad_id
      where m.match_id = team_players.match_id
        and p.player_id = team_players.player_id
    )
  );

create policy "Admins can update team players"
  on public.team_players
  for update
  using (
    exists (
      select 1
      from public.matches m
      join public.user_squads us on us.squad_id = m.squad_id
      where m.match_id = team_players.match_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  )
  with check (
    exists (
      select 1
      from public.matches m
      join public.user_squads us on us.squad_id = m.squad_id
      where m.match_id = team_players.match_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
    and exists (
      select 1
      from public.matches m
      join public.players p on p.squad_id = m.squad_id
      where m.match_id = team_players.match_id
        and p.player_id = team_players.player_id
    )
  );

create policy "Admins can delete team players"
  on public.team_players
  for delete
  using (
    exists (
      select 1
      from public.matches m
      join public.user_squads us on us.squad_id = m.squad_id
      where m.match_id = team_players.match_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

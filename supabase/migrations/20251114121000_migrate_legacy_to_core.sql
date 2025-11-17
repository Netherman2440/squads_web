-- ###########################################################################
-- Migration: migrate legacy data (old schema) into new core schema
-- ###########################################################################
-- Assumptions:
--   - Old data has been imported into a separate schema `legacy`.
--   - The following tables exist in `legacy`:
--       users, squads, user_squads, players, matches,
--       tournaments, teams, team_players, score_history.
--   - Types and constraints in `legacy` do not matter much; this script
--     only reads from them and writes into the new `public` schema.
--   - New core schema from `20251114120000_create_core_schema.sql`
--     has already been applied (tables in `public` exist).
--
-- Notes:
--   - IDs in legacy tables are assumed to be UUID strings.
--   - We treat `legacy.matches.created_at` as both `played_at` and
--     `created_at` in `public.matches`.
--   - We map team colors to sides:
--       'black' -> home, 'white' -> away, others -> home (fallback).
--   - We derive match scores from `legacy.teams.score`:
--       home_score = score of black team,
--       away_score = score of white team.
-- ###########################################################################

set search_path to public;

-- ###########################################################################
-- 1. squads
-- legacy.squads(squad_id, name, created_at, owner_id)
-- -> public.squads(squad_id, owner_id, name, visibility, sport_type, created_at)
-- ###########################################################################

insert into public.squads (
  squad_id,
  owner_id,
  name,
  created_at
)
select
  squad_id::uuid,
  case
    when owner_id = '6f86342c-4078-48fe-be40-193985742ea8'
      then '663b94bc-9a86-4d51-8336-5fc804d99fe0'
    else owner_id
  end::uuid,
  name,
  created_at::timestamptz
from legacy.squads;

-- ###########################################################################
-- 2. user_squads
-- legacy.user_squads(user_id, squad_id, player_id, role, created_at)
-- -> public.user_squads(user_id, squad_id, role, created_at)
-- ###########################################################################

insert into public.user_squads (
  user_id,
  squad_id,
  role,
  created_at
)
select
  case
    when user_id = '6f86342c-4078-48fe-be40-193985742ea8'
      then '663b94bc-9a86-4d51-8336-5fc804d99fe0'
    else user_id
  end::uuid,
  squad_id::uuid,
  coalesce(role, 'member')::legacy.user_squad_role,
  created_at::timestamptz
from legacy.user_squads;

-- ###########################################################################
-- 3. players
-- legacy.players(
--   player_id, squad_id, name, position,
--   base_score, score, created_at
-- )
-- -> public.players(
--   player_id, squad_id, name, position,
--   base_score, score, created_at
-- )
-- score/base_score limited to 0–100 and stored as numeric(5,2)
-- ###########################################################################

insert into public.players (
  player_id,
  squad_id,
  name,
  position,
  base_score,
  score,
  created_at
)
select
  player_id::uuid,
  squad_id::uuid,
  name,
  nullif(position, 'none'),
  base_score,
  round(score::numeric, 2),
  created_at::timestamptz
from legacy.players;

-- ###########################################################################
-- 4. tournaments
-- legacy.tournaments(squad_id, tournament_id, name, created_at)
-- -> public.tournaments(
--   tournament_id, squad_id, name, teams_expected_count, created_at
-- )
-- ###########################################################################

insert into public.tournaments (
  tournament_id,
  squad_id,
  name,
  teams_expected_count,
  created_at
)
select
  tournament_id::uuid,
  squad_id::uuid,
  name,
  null,
  created_at::timestamptz
from legacy.tournaments;

-- ###########################################################################
-- 5. matches
-- legacy.matches(squad_id, match_id, created_at, tournament_id)
-- + legacy.teams(score przypisany do drużyny)
--
-- Założenia:
--   - dla każdego meczu są dwie drużyny: 'black' i 'white';
--   - 'black' -> side = 'home', 'white' -> side = 'away';
--   - wynik meczu (home_score/away_score) bierzemy z legacy.teams.score;
--   - played_at = legacy.matches.created_at
-- ###########################################################################

with match_teams as (
  select
    m.match_id,
    m.squad_id,
    m.tournament_id,
    m.created_at,
    max(case when t.color = 'black' then t.score end)    as home_score,
    max(case when t.color = 'white' then t.score end)    as away_score
  from legacy.matches m
  left join legacy.teams t
    on t.match_id = m.match_id
  group by m.match_id, m.squad_id, m.tournament_id, m.created_at
)
insert into public.matches (
  match_id,
  squad_id,
  tournament_id,
  score_type,
  home_score,
  away_score,
  score_meta,
  played_at,
  created_at
)
select
  match_id::uuid,
  squad_id::uuid,
  tournament_id::uuid,
  null,
  home_score::smallint,
  away_score::smallint,
  '{}'::jsonb,
  created_at::timestamptz,
  created_at::timestamptz
from match_teams;

-- ###########################################################################
-- 6. teams
-- legacy.teams(
--   squad_id, match_id, team_id, color, name, created_at, score
-- )
-- -> public.teams(
--   team_id, match_id, tournament_id, side, name, color, created_at
-- )
--
--   - bierzemy tylko rekordy z przypisanym meczem (match_id is not null)
--   - side: color='black' -> 'home'; 'white' -> 'away' (inne kolory -> 'home')
--   - tournament_id dziedziczymy z matches.tournament_id
-- ###########################################################################

insert into public.teams (
  team_id,
  match_id,
  tournament_id,
  side,
  name,
  color,
  created_at
)
select
  t.team_id::uuid,
  t.match_id::uuid,
  m.tournament_id,
  case
    when t.color = 'black' then 'home'::legacy.side_enum
    when t.color = 'white' then 'away'::legacy.side_enum
    else 'home'::legacy.side_enum
  end,
  t.name,
  t.color,
  t.created_at::timestamptz
from legacy.teams t
join public.matches m
  on m.match_id = t.match_id::uuid
where t.match_id is not null;

-- ###########################################################################
-- 7. team_players
-- legacy.team_players(
--   squad_id, match_id, team_id, player_id, created_at
-- )
-- -> public.team_players(
--   match_id, team_id, player_id, tournament_id, created_at
-- )
--
--   - tournament_id dziedziczymy z matches.tournament_id
-- ###########################################################################

insert into public.team_players (
  match_id,
  team_id,
  player_id,
  tournament_id,
  created_at
)
select
  tp.match_id::uuid,
  tp.team_id::uuid,
  tp.player_id::uuid,
  m.tournament_id,
  tp.created_at::timestamptz
from legacy.team_players tp
join public.matches m
  on m.match_id = tp.match_id::uuid
join public.teams t
  on t.team_id = tp.team_id::uuid;

-- ###########################################################################
-- 8. score_history
-- legacy.score_history(
--   score_history_id, match_id, player_id, created_at,
--   previous_score, new_score, delta
-- )
-- -> public.score_history(
--   score_history_id, player_id, match_id,
--   delta, previous_rating, new_rating, created_at
-- )
-- ###########################################################################

insert into public.score_history (
  score_history_id,
  player_id,
  match_id,
  delta,
  previous_rating,
  new_rating,
  created_at
)
select
  sh.score_history_id::uuid,
  sh.player_id::uuid,
  sh.match_id::uuid,
  round(sh.delta::numeric, 3),
  round(sh.previous_score::numeric, 3),
  round(sh.new_score::numeric, 3),
  sh.created_at::timestamptz
from legacy.score_history sh
join public.players p
  on p.player_id = sh.player_id::uuid
join public.matches m
  on m.match_id = sh.match_id::uuid;

-- ###########################################################################
-- 9. Cleanup (optional)
-- If you no longer need the legacy schema, you can uncomment:
--
-- drop schema legacy cascade;
-- ###########################################################################



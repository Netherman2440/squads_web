-- ###########################################################################
-- Migration: add squad stats function
-- Purpose:
--   - Provide aggregated squad-level stats for the stats dashboard.
-- Decisions:
--   - Use players.score and players.base_score to compute rising star.
--   - Only count matches with complete scores.
-- ###########################################################################

create or replace function public.get_squad_stats(p_squad_id uuid)
returns table (
  top_player jsonb,
  worst_player jsonb,
  top_rising_star jsonb,
  matches_count int,
  total_goals int,
  total_home_goals int,
  total_away_goals int,
  avg_goals_per_match numeric,
  avg_home_goals numeric,
  avg_away_goals numeric,
  players_count int,
  avg_player_score numeric
)
language sql
stable
as $$
with squad_players as (
  select *
  from public.players
  where squad_id = p_squad_id
),
top_player_row as (
  select to_jsonb(sp.*) as player
  from squad_players sp
  order by sp.score desc, sp.name asc
  limit 1
),
worst_player_row as (
  select to_jsonb(sp.*) as player
  from squad_players sp
  order by sp.score asc, sp.name asc
  limit 1
),
rising_star_row as (
  select to_jsonb(sp.*) as player
  from squad_players sp
  order by (sp.score - sp.base_score) desc, sp.score desc, sp.name asc
  limit 1
),
match_rows as (
  select m.home_score, m.away_score
  from public.matches m
  where m.squad_id = p_squad_id
    and m.home_score is not null
    and m.away_score is not null
),
match_stats as (
  select
    count(*)::int as matches_count,
    coalesce(sum(home_score + away_score), 0)::int as total_goals,
    coalesce(sum(home_score), 0)::int as total_home_goals,
    coalesce(sum(away_score), 0)::int as total_away_goals,
    coalesce(avg(home_score + away_score), 0) as avg_goals_per_match,
    coalesce(avg(home_score), 0) as avg_home_goals,
    coalesce(avg(away_score), 0) as avg_away_goals
  from match_rows
),
player_stats as (
  select
    count(*)::int as players_count,
    coalesce(avg(score), 0) as avg_player_score
  from squad_players
)
select
  (select player from top_player_row) as top_player,
  (select player from worst_player_row) as worst_player,
  (select player from rising_star_row) as top_rising_star,
  ms.matches_count,
  ms.total_goals,
  ms.total_home_goals,
  ms.total_away_goals,
  ms.avg_goals_per_match,
  ms.avg_home_goals,
  ms.avg_away_goals,
  ps.players_count,
  ps.avg_player_score
from match_stats ms
cross join player_stats ps;
$$;

-- ###########################################################################
-- Migration: add match win probability function
-- Purpose:
--   - Estimate win probability for each team in a match.
-- Decisions:
--   - Use head-to-head player history with draw = 0.5 and neutral 0.5 fallback.
--   - Ignore matches without a complete score.
-- ###########################################################################

create or replace function public.get_match_win_probability(p_match_id uuid)
returns table (
  team_id uuid,
  win_probability numeric
)
language sql
stable
as $$
with context as (
  select m.squad_id
  from public.matches m
  where m.match_id = p_match_id
),
match_players as (
  select tp.player_id, tp.team_id
  from public.team_players tp
  where tp.match_id = p_match_id
),
pair_history as (
  select
    tp1.player_id as player_id,
    tp2.player_id as opp_player_id,
    avg(
      case
        when t1.side = 'home' and m.home_score > m.away_score then 1.0
        when t1.side = 'away' and m.away_score > m.home_score then 1.0
        when m.home_score = m.away_score then 0.5
        else 0.0
      end
    ) as win_rate
  from public.team_players tp1
  join public.team_players tp2
    on tp2.match_id = tp1.match_id
   and tp2.team_id <> tp1.team_id
  join public.teams t1 on t1.team_id = tp1.team_id
  join public.matches m on m.match_id = tp1.match_id
  join context c on c.squad_id = m.squad_id
  where m.home_score is not null
    and m.away_score is not null
    and tp1.match_id <> p_match_id
  group by tp1.player_id, tp2.player_id
),
team_scores as (
  select
    mp1.team_id,
    avg(coalesce(ph.win_rate, 0.5)) as avg_win_rate
  from match_players mp1
  join match_players mp2 on mp2.team_id <> mp1.team_id
  left join pair_history ph
    on ph.player_id = mp1.player_id
   and ph.opp_player_id = mp2.player_id
  group by mp1.team_id
),
total as (
  select sum(avg_win_rate) as total_rate
  from team_scores
)
select
  ts.team_id,
  case
    when t.total_rate = 0 then null
    else ts.avg_win_rate / t.total_rate
  end as win_probability
from team_scores ts
cross join total t;
$$;

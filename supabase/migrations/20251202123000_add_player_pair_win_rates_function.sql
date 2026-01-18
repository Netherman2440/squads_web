-- ###########################################################################
-- Migration: add player pair win rates function
-- Purpose:
--   - Provide a pairwise win-rate matrix for a given list of players.
-- Decisions:
--   - Draws count as 0.5, wins as 1, losses as 0; fallback to 0.5 if no history.
--   - Only completed matches (home_score/away_score) are considered.
-- ###########################################################################

create or replace function public.get_player_pair_win_rates(p_player_ids uuid[])
returns table (
  player_id uuid,
  opp_player_id uuid,
  win_rate numeric
)
language sql
stable
as $$
with input_players as (
  select distinct unnest(p_player_ids) as player_id
),
context as (
  select p.squad_id
  from public.players p
  join input_players ip on ip.player_id = p.player_id
  group by p.squad_id
  order by count(*) desc
  limit 1
),
pair_history as (
  select
    tp1.player_id,
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
  join input_players ip1 on ip1.player_id = tp1.player_id
  join input_players ip2 on ip2.player_id = tp2.player_id
  where m.home_score is not null
    and m.away_score is not null
  group by tp1.player_id, tp2.player_id
),
pair_matrix as (
  select
    ip1.player_id,
    ip2.player_id as opp_player_id
  from input_players ip1
  join input_players ip2 on ip2.player_id <> ip1.player_id
)
select
  pm.player_id,
  pm.opp_player_id,
  coalesce(ph.win_rate, 0.5) as win_rate
from pair_matrix pm
left join pair_history ph
  on ph.player_id = pm.player_id
 and ph.opp_player_id = pm.opp_player_id
order by pm.player_id, pm.opp_player_id;
$$;

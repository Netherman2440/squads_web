-- ###########################################################################
-- Migration: add player head-to-head stats function
-- Purpose:
--   - Provide aggregated player-vs-player stats for comparison UI.
-- Decisions:
--   - Only count matches with complete scores (home_score and away_score).
-- ###########################################################################

create or replace function public.get_player_head_to_head_stats(p_player_id uuid)
returns table (
  other_player_id uuid,
  other_name text,
  together_matches int,
  together_wins int,
  together_draws int,
  together_losses int,
  together_goals_for int,
  together_goals_against int,
  vs_matches int,
  vs_wins int,
  vs_draws int,
  vs_losses int,
  vs_goals_for int,
  vs_goals_against int
)
language sql
stable
as $$
with base as (
  select
    tp.player_id,
    tp.match_id,
    tp.team_id,
    t.side,
    m.home_score,
    m.away_score,
    case when t.side = 'home' then m.home_score else m.away_score end as my_goals,
    case when t.side = 'home' then m.away_score else m.home_score end as opp_goals
  from public.team_players tp
  join public.teams t on t.team_id = tp.team_id
  join public.matches m on m.match_id = tp.match_id
  where tp.player_id = p_player_id
    and m.home_score is not null
    and m.away_score is not null
),
peers as (
  select
    base.*,
    tp2.player_id as other_player_id,
    tp2.team_id as other_team_id
  from base
  join public.team_players tp2
    on tp2.match_id = base.match_id
   and tp2.player_id <> base.player_id
)
select
  peers.other_player_id,
  p.name as other_name,
  count(*) filter (where peers.other_team_id = peers.team_id)::int as together_matches,
  sum(case when peers.other_team_id = peers.team_id and peers.my_goals > peers.opp_goals then 1 else 0 end)::int as together_wins,
  sum(case when peers.other_team_id = peers.team_id and peers.my_goals = peers.opp_goals then 1 else 0 end)::int as together_draws,
  sum(case when peers.other_team_id = peers.team_id and peers.my_goals < peers.opp_goals then 1 else 0 end)::int as together_losses,
  sum(case when peers.other_team_id = peers.team_id then peers.my_goals else 0 end)::int as together_goals_for,
  sum(case when peers.other_team_id = peers.team_id then peers.opp_goals else 0 end)::int as together_goals_against,
  count(*) filter (where peers.other_team_id <> peers.team_id)::int as vs_matches,
  sum(case when peers.other_team_id <> peers.team_id and peers.my_goals > peers.opp_goals then 1 else 0 end)::int as vs_wins,
  sum(case when peers.other_team_id <> peers.team_id and peers.my_goals = peers.opp_goals then 1 else 0 end)::int as vs_draws,
  sum(case when peers.other_team_id <> peers.team_id and peers.my_goals < peers.opp_goals then 1 else 0 end)::int as vs_losses,
  sum(case when peers.other_team_id <> peers.team_id then peers.my_goals else 0 end)::int as vs_goals_for,
  sum(case when peers.other_team_id <> peers.team_id then peers.opp_goals else 0 end)::int as vs_goals_against
from peers
join public.players p on p.player_id = peers.other_player_id
group by peers.other_player_id, p.name
order by p.name;
$$;

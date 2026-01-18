-- ###########################################################################
-- Migration: add player stats function
-- Purpose:
--   - Provide aggregated player-level stats for the player stats page.
-- Decisions:
--   - Only count matches with complete scores (home_score and away_score).
--   - Streaks are computed by match order (played_at desc, created_at fallback).
--   - avg_score represents average opponent goals to display avg scoreline.
-- ###########################################################################

create or replace function public.get_player_stats(p_player_id uuid)
returns table (
  base_ranking numeric,
  current_ranking numeric,
  total_matches int,
  total_wins int,
  total_draws int,
  total_losses int,
  win_streak int,
  loss_streak int,
  biggest_win_streak int,
  biggest_loss_streak int,
  goals_scored int,
  goals_conceded int,
  avg_goals_per_match numeric,
  avg_score numeric
)
language sql
stable
as $$
with player_row as (
  select
    p.base_score::numeric as base_ranking,
    p.score::numeric as current_ranking
  from public.players p
  where p.player_id = p_player_id
),
match_rows as (
  select
    m.match_id,
    coalesce(m.played_at, m.created_at) as played_at,
    case when t.side = 'home' then m.home_score else m.away_score end as my_goals,
    case when t.side = 'home' then m.away_score else m.home_score end as opp_goals
  from public.team_players tp
  join public.teams t on t.team_id = tp.team_id
  join public.matches m on m.match_id = tp.match_id
  where tp.player_id = p_player_id
    and m.home_score is not null
    and m.away_score is not null
),
results as (
  select
    match_id,
    played_at,
    my_goals,
    opp_goals,
    case
      when my_goals > opp_goals then 'win'
      when my_goals < opp_goals then 'loss'
      else 'draw'
    end as result
  from match_rows
),
stats as (
  select
    count(*)::int as total_matches,
    sum(case when result = 'win' then 1 else 0 end)::int as total_wins,
    sum(case when result = 'draw' then 1 else 0 end)::int as total_draws,
    sum(case when result = 'loss' then 1 else 0 end)::int as total_losses,
    coalesce(sum(my_goals), 0)::int as goals_scored,
    coalesce(sum(opp_goals), 0)::int as goals_conceded,
    coalesce(avg(my_goals::numeric), 0) as avg_goals_per_match,
    coalesce(avg(opp_goals::numeric), 0) as avg_score
  from results
),
ordered as (
  select
    match_id,
    played_at,
    result,
    sum(case when result <> 'win' then 1 else 0 end)
      over (order by played_at desc, match_id desc) as win_group,
    sum(case when result <> 'loss' then 1 else 0 end)
      over (order by played_at desc, match_id desc) as loss_group
  from results
),
win_runs as (
  select win_group, count(*)::int as run_len
  from ordered
  where result = 'win'
  group by win_group
),
loss_runs as (
  select loss_group, count(*)::int as run_len
  from ordered
  where result = 'loss'
  group by loss_group
),
streaks as (
  select
    coalesce(
      (select count(*) from ordered where result = 'win' and win_group = 0),
      0
    )::int as win_streak,
    coalesce(
      (select count(*) from ordered where result = 'loss' and loss_group = 0),
      0
    )::int as loss_streak,
    coalesce((select max(run_len) from win_runs), 0)::int as biggest_win_streak,
    coalesce((select max(run_len) from loss_runs), 0)::int as biggest_loss_streak
)
select
  pr.base_ranking,
  pr.current_ranking,
  coalesce(s.total_matches, 0) as total_matches,
  coalesce(s.total_wins, 0) as total_wins,
  coalesce(s.total_draws, 0) as total_draws,
  coalesce(s.total_losses, 0) as total_losses,
  coalesce(st.win_streak, 0) as win_streak,
  coalesce(st.loss_streak, 0) as loss_streak,
  coalesce(st.biggest_win_streak, 0) as biggest_win_streak,
  coalesce(st.biggest_loss_streak, 0) as biggest_loss_streak,
  coalesce(s.goals_scored, 0) as goals_scored,
  coalesce(s.goals_conceded, 0) as goals_conceded,
  coalesce(s.avg_goals_per_match, 0) as avg_goals_per_match,
  coalesce(s.avg_score, 0) as avg_score
from player_row pr
left join stats s on true
left join streaks st on true;
$$;

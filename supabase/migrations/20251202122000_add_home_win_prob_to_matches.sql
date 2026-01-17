-- ###########################################################################
-- Migration: add home win probability to matches
-- Purpose:
--   - Store precomputed win probability for the home team.
-- Decisions:
--   - Keep value nullable; recompute via a dedicated refresh function.
-- ###########################################################################

alter table public.matches
  add column home_win_prob numeric(5,4) null;

alter table public.matches
  add constraint matches_home_win_prob_range_chk
  check (
    home_win_prob is null
    or (home_win_prob >= 0 and home_win_prob <= 1)
  );

comment on column public.matches.home_win_prob is
  'Estimated probability of the home team win (0..1).';

create or replace function public.refresh_match_win_probability(p_match_id uuid)
returns numeric
language sql
volatile
as $$
update public.matches m
set home_win_prob = (
  select gwp.win_probability
  from public.get_match_win_probability(p_match_id) gwp
  join public.teams t on t.team_id = gwp.team_id
  where t.match_id = p_match_id
    and t.side = 'home'
  limit 1
)
where m.match_id = p_match_id
returning m.home_win_prob;
$$;

-- ###########################################################################
-- Migration: update team_players player fk to cascade
-- Purpose:
--   - Allow deleting players that are referenced by team_players.
-- Decisions:
--   - Cascade deletes to keep match team membership consistent with players.
-- ###########################################################################

alter table public.team_players
  drop constraint team_players_player_fk;

alter table public.team_players
  add constraint team_players_player_fk
  foreign key (player_id)
  references public.players (player_id)
  on delete cascade;

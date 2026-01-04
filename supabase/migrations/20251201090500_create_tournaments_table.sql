-- ###########################################################################
-- Migration: create tournaments table
-- Purpose:
--   - Store tournaments scoped to a squad.
-- Decisions:
--   - teams_expected_count is nullable until fully specified by UI.
-- ###########################################################################

create table public.tournaments (
  tournament_id uuid primary key
    default gen_random_uuid(),

  squad_id uuid not null,

  name text null,

  teams_expected_count integer null,

  created_at timestamptz not null
    default now(),

  constraint tournaments_squad_fk
    foreign key (squad_id)
    references public.squads (squad_id)
    on delete cascade
);

create index tournaments_squad_idx
  on public.tournaments (squad_id);

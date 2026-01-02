-- ###########################################################################
-- Migration: create core schema for squads app (clean public setup)
-- ###########################################################################
-- Purpose:
--   - Define all enums and tables needed by the squads app in `public`.
--   - No cleanup: assumes this is the first core migration applied on a fresh
--     database (or that older migrations were removed before db reset).
--   - RLS policies are intentionally omitted and can be added later.
-- ###########################################################################

-- ---------------------------------------------------------------------------
-- 1. Extensions
-- ---------------------------------------------------------------------------

create extension if not exists pgcrypto with schema public;

-- ---------------------------------------------------------------------------
-- 2. Enums and composite types (all in public)
-- ---------------------------------------------------------------------------

create type public.squad_visibility as enum ('public', 'private');

create type public.sport_type as enum ('football');

create type public.user_squad_role as enum (
  'owner',
  'admin',
  'member',
  'invited',
  'pending',
  'removed',
  'declined'
);

create type public.side_enum as enum ('home', 'away');

create type public.match_score_type as enum (
  'regular',
  'penalties',
  'walkover',
  'cancelled'
);

create type public.score_pair as (
  home smallint,
  away smallint
);

-- ---------------------------------------------------------------------------
-- 3. Tables (all in public)
-- ---------------------------------------------------------------------------

-- 3.0 users (public copy of auth.users with minimal fields)
create table public.users (
  user_id uuid primary key,
  email text not null,
  created_at timestamptz not null
    default now()
);

-- 3.1 squads
create table public.squads (
  squad_id uuid primary key
    default gen_random_uuid(),

  owner_id uuid not null,

  name text not null,

  visibility public.squad_visibility not null
    default 'public',

  sport_type public.sport_type not null
    default 'football',

  ranking_update boolean not null
    default true,

  ranking_multiplier integer not null
    default 5,

  use_experience_factor boolean not null
    default true,

  created_at timestamptz not null
    default now(),

  constraint squads_owner_fk
    foreign key (owner_id)
    references auth.users (id)
    on delete restrict,

  constraint squads_ranking_multiplier_1_10
    check (ranking_multiplier between 1 and 10)
);

create index squads_owner_idx
  on public.squads (owner_id);

comment on column public.squads.ranking_update is
  'If false, matches in this squad do not affect player ranking.';
comment on column public.squads.ranking_multiplier is
  'Ranking change factor (1..10). Used as: delta = goalDiff * ranking_multiplier.';
comment on column public.squads.use_experience_factor is
  'If true, reduces ranking change for experienced players vs new players.';

-- 3.2 user_squads
create table public.user_squads (
  user_id uuid not null,

  squad_id uuid not null,

  role public.user_squad_role not null,

  created_at timestamptz not null
    default now(),

  constraint user_squads_pk
    primary key (user_id, squad_id),
  constraint user_squads_user_fk
    foreign key (user_id)
    references auth.users (id)
    on delete cascade,

  constraint user_squads_squad_fk
    foreign key (squad_id)
    references public.squads (squad_id)
    on delete cascade
);

create index user_squads_user_idx
  on public.user_squads (user_id);

create index user_squads_squad_idx
  on public.user_squads (squad_id);

-- 3.3 players
create table public.players (
  player_id uuid primary key
    default gen_random_uuid(),

  squad_id uuid not null,

  name text not null,

  position text null,

  base_score integer not null
    default 0,

  score numeric(5,2) not null,

  created_at timestamptz not null
    default now(),

  constraint players_squad_fk
    foreign key (squad_id)
    references public.squads (squad_id)
    on delete cascade,

  constraint players_squad_name_unique
    unique (squad_id, name),

  constraint players_score_range_chk
    check (score >= 0 and score <= 100),

  constraint players_base_score_range_chk
    check (base_score >= 0 and base_score <= 100)
);

create index players_squad_idx
  on public.players (squad_id);

-- 3.4 tournaments
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

-- 3.5 matches
create table public.matches (
  match_id uuid primary key
    default gen_random_uuid(),

  squad_id uuid not null,

  tournament_id uuid null,

  score_type public.match_score_type null,

  home_score smallint null,

  away_score smallint null,

  score_meta jsonb not null
    default '{}'::jsonb,

  played_at timestamptz null,

  created_at timestamptz not null
    default now(),

  constraint matches_squad_fk
    foreign key (squad_id)
    references public.squads (squad_id)
    on delete cascade,

  constraint matches_tournament_fk
    foreign key (tournament_id)
    references public.tournaments (tournament_id)
    on delete cascade
);

create index matches_squad_played_at_idx
  on public.matches (squad_id, played_at desc, created_at desc);

create index matches_tournament_idx
  on public.matches (tournament_id);

-- 3.6 teams
create table public.teams (
  team_id uuid primary key
    default gen_random_uuid(),

  match_id uuid not null,

  tournament_id uuid null,

  side public.side_enum not null,

  name text null,

  color text null,

  created_at timestamptz not null
    default now(),

  constraint teams_match_fk
    foreign key (match_id)
    references public.matches (match_id)
    on delete cascade,

  constraint teams_tournament_fk
    foreign key (tournament_id)
    references public.tournaments (tournament_id)
    on delete set null,

  constraint teams_match_side_unique
    unique (match_id, side),

  constraint teams_match_team_unique
    unique (match_id, team_id)
);

create index teams_match_idx
  on public.teams (match_id);

create index teams_tournament_idx
  on public.teams (tournament_id);

-- 3.7 team_players
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

-- 3.8 ranking_history
create table public.ranking_history (
  ranking_history_id uuid primary key
    default gen_random_uuid(),

  player_id uuid not null,

  match_id uuid null,

  ranking numeric(6,3) not null,

  change numeric(6,3) null,

  match_score jsonb null,

  created_at timestamptz not null
    default now(),

  updated_at timestamptz null,

  constraint ranking_history_player_fk
    foreign key (player_id)
    references public.players (player_id)
    on delete cascade,

  constraint ranking_history_match_fk
    foreign key (match_id)
    references public.matches (match_id)
    on delete set null
);

create unique index ranking_history_player_match_unique_idx
  on public.ranking_history (player_id, match_id)
  where match_id is not null;

create index ranking_history_player_idx
  on public.ranking_history (player_id);

create index ranking_history_match_idx
  on public.ranking_history (match_id)
  where match_id is not null;

comment on table public.ranking_history is
  'Stores the history of player ranking changes, both manual and from matches.';
comment on column public.ranking_history.ranking is
  'The snapshot of the player''s ranking BEFORE the change was applied.';
comment on column public.ranking_history.change is
  'The delta applied to the ranking. NULL if the match result is pending.';
comment on column public.ranking_history.match_score is
  'JSONB snapshot of the match score: {\"player\": int, \"opponent\": int}.';


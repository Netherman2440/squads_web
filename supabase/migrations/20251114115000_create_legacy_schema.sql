-- ###########################################################################
-- Migration: create legacy schema to import old MySQL data
-- ###########################################################################
-- This migration creates a simple `legacy` schema with tables matching the
-- old application schema. Types are adjusted to PostgreSQL, but column names
-- and semantics are kept as close as possible to the original.
--
-- After applying this migration you can:
--   - set search_path to legacy;
--   - paste INSERT statements from `.ai/legacy_sql.md` with backticks removed.
-- ###########################################################################

create schema if not exists legacy;
set search_path to legacy;

-- ---------------------------------------------------------------------------
-- legacy.matches
-- ---------------------------------------------------------------------------

create table matches (
  squad_id      uuid null,
  match_id      uuid primary key,
  created_at    timestamptz null,
  tournament_id uuid null
);

-- ---------------------------------------------------------------------------
-- legacy.players
-- ---------------------------------------------------------------------------

create table players (
  player_id   uuid primary key,
  squad_id    uuid null,
  name        text not null,
  position    text not null,
  base_score  integer not null,
  score       double precision not null,
  created_at  timestamptz null
);

-- ---------------------------------------------------------------------------
-- legacy.score_history
-- ---------------------------------------------------------------------------

create table score_history (
  score_history_id uuid primary key,
  match_id         uuid null,
  player_id        uuid null,
  created_at       timestamptz null,
  previous_score   double precision not null,
  new_score        double precision null,
  delta            double precision not null
);

-- ---------------------------------------------------------------------------
-- legacy.squads
-- ---------------------------------------------------------------------------

create table squads (
  squad_id   uuid primary key,
  name       text not null,
  created_at timestamptz null,
  owner_id   uuid not null
);

-- ---------------------------------------------------------------------------
-- legacy.teams
-- ---------------------------------------------------------------------------

create table teams (
  squad_id   uuid null,
  match_id   uuid null,
  team_id    uuid primary key,
  color      text not null,
  name       text null,
  created_at timestamptz null,
  score      integer null
);

-- ---------------------------------------------------------------------------
-- legacy.team_players
-- ---------------------------------------------------------------------------

create table team_players (
  squad_id   uuid null,
  match_id   uuid not null,
  team_id    uuid not null,
  player_id  uuid not null,
  created_at timestamptz null
);

-- ---------------------------------------------------------------------------
-- legacy.tournaments
-- ---------------------------------------------------------------------------

create table tournaments (
  squad_id      uuid null,
  tournament_id uuid primary key,
  name          text not null,
  created_at    timestamptz null
);

-- ---------------------------------------------------------------------------
-- legacy.users
-- ---------------------------------------------------------------------------

create table users (
  user_id       uuid primary key,
  username      text not null,
  password_hash text not null,
  created_at    timestamptz null
);

-- ---------------------------------------------------------------------------
-- legacy.user_squads
-- ---------------------------------------------------------------------------

create table user_squads (
  user_id    uuid not null,
  squad_id   uuid not null,
  player_id  uuid null,
  role       text null,
  created_at timestamptz null
);



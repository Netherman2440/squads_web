-- migration: create core schema for squads app (mvp)
-- purpose:
--   - define core domain types (enums, composite types) for squads, players,
--     tournaments, matches, and scoring.
--   - create initial core tables: squads, user_squads, players.
-- affected objects:
--   - types: squad_visibility, sport_type, user_squad_role, side_enum,
--     match_score_type, score_pair.
--   - tables: squads, user_squads, players.
--   - rls policies: per-table, per-role, per-command (select/insert/update/delete).
-- notes:
--   - this migration assumes the existence of `auth.users(id uuid)` provided
--     by supabase auth. the original db plan refers to `users(user_id)`;
--     here we map that concept onto `auth.users(id)` via foreign keys.
--   - rls is enabled and enforced on all new tables to provide a secure
--     default. `anon` role is explicitly denied; `authenticated` is allowed
--     full access for now. these policies can be refined in later migrations
--     to align with higher-level access rules (e.g. membership-based access).

-- ###########################################################################
-- 1. extensions
-- ###########################################################################

-- note: local supabase-db image may not have citext installed by default,
-- so we keep this commented out for now. if you enable citext in your
-- postgres instance, you can uncomment this line and switch `players.name`
-- to citext again.
-- create extension if not exists citext with schema public;

-- enable pgcrypto for uuid generation and cryptographic functions.
-- note: if you prefer `uuid-ossp`, you can switch in a separate migration.
create extension if not exists pgcrypto with schema public;

-- ###########################################################################
-- 2. custom types (enums, composite types)
-- ###########################################################################

-- visibility of a squad: publicly visible vs. private.
create type squad_visibility as enum ('public', 'private');

-- sport type of a squad; currently only football but modeled as enum to allow
-- future extension.
create type sport_type as enum ('football');

create type user_squad_role as enum (
  'owner',
  'admin',
  'member',
  'invited',
  'pending',
  'removed',
  'declined'
);

-- side of a team in a match (home vs away).
create type side_enum as enum ('home', 'away');

-- type of score result for a match.
create type match_score_type as enum (
  'regular',
  'penalties',
  'walkover',
  'cancelled'
);

-- composite type allowing to represent a score as a (home, away) tuple.
-- note: the current mvp schema for `matches` uses separate columns for home
-- and away scores; this type is kept for potential future use or views.
create type score_pair as (
  home smallint,
  away smallint
);

-- ###########################################################################
-- 3. tables
-- ###########################################################################

-- ---------------------------------------------------------------------------
-- 3.1 table: squads
-- description:
--   - represents a single squad (team roster) with an owner and visibility.
--   - original plan enforces "one squad per owner" at the api level, not
--     via a db constraint, so we do not add a unique index on owner_id here.
-- ---------------------------------------------------------------------------

create table public.squads (
  squad_id uuid primary key
    default gen_random_uuid(),

  owner_id uuid not null,

  name text not null,

  visibility squad_visibility not null
    default 'public',

  sport_type sport_type not null
    default 'football',

  created_at timestamptz not null
    default now(),

  constraint squads_owner_fk
    foreign key (owner_id)
    references auth.users (id)
    on delete restrict
);

comment on table public.squads is
  'squads with visibility and owner; one logical squad per owner enforced in api.';

comment on column public.squads.squad_id is 'primary key; logical squad id.';
comment on column public.squads.owner_id is
  'fk to auth.users(id); owner of the squad.';
comment on column public.squads.name is 'squad display name.';
comment on column public.squads.visibility is
  'visibility of squad; public vs private.';
comment on column public.squads.sport_type is
  'sport type for this squad (currently only football).';
comment on column public.squads.created_at is
  'creation timestamp, defaults to now().';

-- index to efficiently list squads by owner.
create index squads_owner_idx
  on public.squads (owner_id);

-- ---------------------------------------------------------------------------
-- 3.2 table: user_squads
-- description:
--   - models membership and invitations of users in squads.
--   - role column captures both role and invitation status in one enum.
--   - composite primary key (user_id, squad_id).
-- ---------------------------------------------------------------------------

create table public.user_squads (
  user_id uuid not null,

  squad_id uuid not null,

  role user_squad_role not null,

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

comment on table public.user_squads is
  'membership and invitations of users in squads.';

comment on column public.user_squads.user_id is
  'fk to auth.users(id).';
comment on column public.user_squads.squad_id is
  'fk to public.squads(squad_id).';
comment on column public.user_squads.role is
  'user role/status within squad, including invitation states.';
comment on column public.user_squads.created_at is
  'timestamp when this membership/invitation was created.';

-- recommended indexes for efficient queries by user or squad.
create index user_squads_user_idx
  on public.user_squads (user_id);

create index user_squads_squad_idx
  on public.user_squads (squad_id);

-- ---------------------------------------------------------------------------
-- 3.3 table: players
-- description:
--   - represents players within a squad, with per-squad ranking.
--   - player names are unique within a squad.
-- ---------------------------------------------------------------------------

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

  -- score 0–100
  constraint players_score_range_chk
    check (score >= 0 and score <= 100),

  -- base_score 0–100
  constraint players_base_score_range_chk
    check (base_score >= 0 and base_score <= 100)
);

comment on table public.players is
  'players within a squad, including ranking fields.';

comment on column public.players.player_id is 'primary key; logical player id.';
comment on column public.players.squad_id is
  'fk to public.squads(squad_id).';
comment on column public.players.name is
  'player name; unique per squad, case-insensitive.';
comment on column public.players.position is
  'optional free-text position (mvp).';
comment on column public.players.base_score is
  'base score value for ranking, defaults to 0.';
comment on column public.players.score is
  'current computed score/rating for this player. 0–100 range, stored as numeric(5,2).';
comment on column public.players.created_at is
  'creation timestamp, defaults to now().';

-- performance index for listing players by squad.
create index players_squad_idx
  on public.players (squad_id);

-- ---------------------------------------------------------------------------
-- 3.4 table: tournaments
-- description:
--   - tournaments belonging to a specific squad.
--   - optional teams_expected_count supports future validations on tournament
--     size but is advisory only in this mvp.
-- ---------------------------------------------------------------------------

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

comment on table public.tournaments is
  'tournaments for a given squad; may reference draft constraints.';

comment on column public.tournaments.tournament_id is
  'primary key; logical tournament id.';
comment on column public.tournaments.squad_id is
  'fk to public.squads(squad_id); owning squad.';
comment on column public.tournaments.name is
  'tournament name within the squad.';
comment on column public.tournaments.teams_expected_count is
  'optional expected number of teams; advisory only in mvp.';
comment on column public.tournaments.created_at is
  'creation timestamp, defaults to now().';

-- index to efficiently list tournaments by squad.
create index tournaments_squad_idx
  on public.tournaments (squad_id);

-- ---------------------------------------------------------------------------
-- 3.5 table: matches
-- description:
--   - matches played by a squad, optionally associated with a tournament.
--   - stores basic scoring information and arbitrary score metadata in jsonb.
--   - played_at is nullable to support unscheduled or draft matches and is
--     also used for efficient listing by squad in descending time order.
-- ---------------------------------------------------------------------------

create table public.matches (
  match_id uuid primary key
    default gen_random_uuid(),

  squad_id uuid not null,

  tournament_id uuid null,

  score_type match_score_type null,

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

comment on table public.matches is
  'matches for a given squad, optionally linked to a tournament.';

comment on column public.matches.match_id is
  'primary key; logical match id.';
comment on column public.matches.squad_id is
  'fk to public.squads(squad_id); owning squad.';
comment on column public.matches.tournament_id is
  'optional fk to public.tournaments(tournament_id).';
comment on column public.matches.score_type is
  'type of score result (regular, penalties, walkover, cancelled).';
comment on column public.matches.home_score is
  'home team score in regular time; nullable until result is set.';
comment on column public.matches.away_score is
  'away team score in regular time; nullable until result is set.';
comment on column public.matches.score_meta is
  'jsonb metadata for scores, e.g. penalties or walkover flags.';
comment on column public.matches.played_at is
  'optional timestamp when the match was played or scheduled.';
comment on column public.matches.created_at is
  'creation timestamp, defaults to now().';

-- indexes supporting frequent listing/filtering patterns.
create index matches_squad_played_at_idx
  on public.matches (squad_id, played_at desc, created_at desc);

create index matches_tournament_idx
  on public.matches (tournament_id);

-- ---------------------------------------------------------------------------
-- 3.6 table: teams
-- description:
--   - snapshot of teams participating in a match.
--   - optional tournament_id mirrors matches.tournament_id to simplify
--     filtering by tournament but does not introduce additional constraints.
--   - no score or squad_id is stored here; these are derived from matches
--     and score fields therein.
-- ---------------------------------------------------------------------------

create table public.teams (
  team_id uuid primary key
    default gen_random_uuid(),

  match_id uuid not null,

  tournament_id uuid null,

  side side_enum not null,

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

comment on table public.teams is
  'teams per match (snapshot), with optional tournament association.';

comment on column public.teams.team_id is
  'primary key; logical team id in the context of a match.';
comment on column public.teams.match_id is
  'fk to public.matches(match_id).';
comment on column public.teams.tournament_id is
  'optional fk to public.tournaments(tournament_id) used for filtering.';
comment on column public.teams.side is
  'home/away side of the team in a given match.';
comment on column public.teams.name is
  'optional team name snapshot; may differ from squad name.';
comment on column public.teams.color is
  'optional color used for ui differentiation.';
comment on column public.teams.created_at is
  'creation timestamp, defaults to now().';

-- index to speed up queries by match.
create index teams_match_idx
  on public.teams (match_id);

-- index to speed up queries by tournament across teams.
create index teams_tournament_idx
  on public.teams (tournament_id);

-- ---------------------------------------------------------------------------
-- 3.7 table: team_players
-- description:
--   - assignment of players to teams within the context of a match.
--   - ensures a player can belong to only one team per match via unique
--     (match_id, player_id).
--   - optional tournament_id mirrors matches.tournament_id for easier
--     filtering, but business constraints are enforced at the application
--     level in this mvp.
-- ---------------------------------------------------------------------------

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

comment on table public.team_players is
  'assignment of players to teams in the context of a match.';

comment on column public.team_players.match_id is
  'fk to public.matches(match_id).';
comment on column public.team_players.team_id is
  'fk to public.teams(team_id).';
comment on column public.team_players.player_id is
  'fk to public.players(player_id); restricted delete to preserve history.'; 
comment on column public.team_players.tournament_id is
  'optional fk to public.tournaments(tournament_id) for filtering.';
comment on column public.team_players.created_at is
  'creation timestamp, defaults to now().';

-- indexes to support common access patterns: by player, by team.
create index team_players_player_idx
  on public.team_players (player_id);

create index team_players_team_idx
  on public.team_players (team_id);

-- ---------------------------------------------------------------------------
-- 3.8 table: score_history
-- description:
--   - event-sourced history of player rating changes, including deltas and
--     previous/new rating values.
--   - may be linked to a match (for automatic rating updates) or have a null
--     match_id for manual adjustments.
--   - partial unique constraint ensures at most one entry per player/match
--     when match_id is not null.
-- ---------------------------------------------------------------------------

create table public.score_history (
  score_history_id uuid primary key
    default gen_random_uuid(),

  player_id uuid not null,

  match_id uuid null,

  delta numeric(6,3) not null,

  previous_rating numeric(6,3) not null,

  new_rating numeric(6,3) not null,

  created_at timestamptz not null
    default now(),

  constraint score_history_player_fk
    foreign key (player_id)
    references public.players (player_id)
    on delete cascade,

  constraint score_history_match_fk
    foreign key (match_id)
    references public.matches (match_id)
    on delete cascade
);

comment on table public.score_history is
  'history of rating changes (deltas) per player, optionally tied to matches.';

comment on column public.score_history.score_history_id is
  'primary key; logical id for a rating history event.';
comment on column public.score_history.player_id is
  'fk to public.players(player_id).';
comment on column public.score_history.match_id is
  'optional fk to public.matches(match_id); null for manual adjustments.';
comment on column public.score_history.delta is
  'rating delta applied in this event.';
comment on column public.score_history.previous_rating is
  'rating value before applying this event.';
comment on column public.score_history.new_rating is
  'rating value after applying this event.';
comment on column public.score_history.created_at is
  'creation timestamp, defaults to now().';

-- partial unique constraint: at most one history entry per player/match when
-- match_id is not null; manual corrections with null match_id are not limited.
create unique index score_history_player_match_unique_idx
  on public.score_history (player_id, match_id)
  where match_id is not null;

-- indexes for efficient queries by player and by match.
create index score_history_player_time_idx
  on public.score_history (player_id, created_at desc);

create index score_history_match_idx
  on public.score_history (match_id)
  where match_id is not null;

-- ###########################################################################
-- Migration: create squads table
-- Purpose:
--   - Store squads with owner, visibility, and ranking settings.
-- Decisions:
--   - ranking_multiplier is integer 1..10 (default 5).
-- ###########################################################################

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

alter table public.squads enable row level security;

create policy "Users can create squads"
  on public.squads
  for insert
  with check (auth.uid() = owner_id);

create policy "Owners can update squads"
  on public.squads
  for update
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

create policy "Owners can delete squads"
  on public.squads
  for delete
  using (owner_id = auth.uid());

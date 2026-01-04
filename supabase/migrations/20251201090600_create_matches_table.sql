-- ###########################################################################
-- Migration: create matches table
-- Purpose:
--   - Store match metadata, scores, and optional tournament link.
-- Decisions:
--   - score_meta is JSONB for extensible scoring metadata.
-- ###########################################################################

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

alter table public.matches enable row level security;

create policy "Members can read matches"
  on public.matches
  for select
  using (
    exists (
      select 1
      from public.squads s
      where s.squad_id = matches.squad_id
        and s.visibility = 'public'
    )
    or exists (
      select 1
      from public.user_squads us
      where us.squad_id = matches.squad_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin', 'member')
    )
  );

create policy "Admins can insert matches"
  on public.matches
  for insert
  with check (
    exists (
      select 1
      from public.user_squads us
      where us.squad_id = matches.squad_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

create policy "Admins can update matches"
  on public.matches
  for update
  using (
    exists (
      select 1
      from public.user_squads us
      where us.squad_id = matches.squad_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  )
  with check (
    exists (
      select 1
      from public.user_squads us
      where us.squad_id = matches.squad_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

create policy "Admins can delete matches"
  on public.matches
  for delete
  using (
    exists (
      select 1
      from public.user_squads us
      where us.squad_id = matches.squad_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

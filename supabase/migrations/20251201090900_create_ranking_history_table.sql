-- ###########################################################################
-- Migration: create ranking_history table
-- Purpose:
--   - Track player ranking snapshots and deltas (manual or match-based).
-- Decisions:
--   - Unique (player_id, match_id) when match_id is not null.
-- ###########################################################################

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
  'JSONB snapshot of the match score: {"player": int, "opponent": int}.';

alter table public.ranking_history enable row level security;

create policy "Members can read ranking history"
  on public.ranking_history
  for select
  using (
    exists (
      select 1
      from public.players p
      join public.squads s on s.squad_id = p.squad_id
      where p.player_id = ranking_history.player_id
        and s.visibility = 'public'
    )
    or exists (
      select 1
      from public.players p
      join public.user_squads us on us.squad_id = p.squad_id
      where p.player_id = ranking_history.player_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin', 'member')
    )
  );

create policy "Admins can insert ranking history"
  on public.ranking_history
  for insert
  with check (
    exists (
      select 1
      from public.players p
      join public.user_squads us on us.squad_id = p.squad_id
      where p.player_id = ranking_history.player_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
    and (
      ranking_history.match_id is null
      or exists (
        select 1
        from public.matches m
        join public.players p on p.squad_id = m.squad_id
        where m.match_id = ranking_history.match_id
          and p.player_id = ranking_history.player_id
      )
    )
  );

create policy "Admins can update ranking history"
  on public.ranking_history
  for update
  using (
    exists (
      select 1
      from public.players p
      join public.user_squads us on us.squad_id = p.squad_id
      where p.player_id = ranking_history.player_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  )
  with check (
    exists (
      select 1
      from public.players p
      join public.user_squads us on us.squad_id = p.squad_id
      where p.player_id = ranking_history.player_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
    and (
      ranking_history.match_id is null
      or exists (
        select 1
        from public.matches m
        join public.players p on p.squad_id = m.squad_id
        where m.match_id = ranking_history.match_id
          and p.player_id = ranking_history.player_id
      )
    )
  );

create policy "Admins can delete ranking history"
  on public.ranking_history
  for delete
  using (
    exists (
      select 1
      from public.players p
      join public.user_squads us on us.squad_id = p.squad_id
      where p.player_id = ranking_history.player_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

-- ###########################################################################
-- Migration: expand tournaments feature
-- Purpose:
--   - Add full tournament flow support (status, teams, drafts, ranking link).
--   - Align access control with matches (members/public read, owner/admin write).
-- Decisions:
--   - Tournament ranking snapshots are stored in ranking_history (tournament_id).
--   - Tournament drafts are append-only metadata rows with separate payload table.
-- ###########################################################################

-- tournaments: move to finalized contract
alter table public.tournaments
  drop column if exists teams_expected_count;

alter table public.tournaments
  add column if not exists status text not null default 'drafting',
  add column if not exists updated_at timestamptz not null default now(),
  add constraint tournaments_status_chk
    check (status in ('drafting', 'active', 'completed'));

create index if not exists tournaments_squad_created_at_idx
  on public.tournaments (squad_id, created_at desc);

alter table public.tournaments enable row level security;

drop policy if exists "Members can read tournaments" on public.tournaments;
create policy "Members can read tournaments"
  on public.tournaments
  for select
  using (
    exists (
      select 1
      from public.squads s
      where s.squad_id = tournaments.squad_id
        and s.visibility = 'public'
    )
    or exists (
      select 1
      from public.user_squads us
      where us.squad_id = tournaments.squad_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin', 'member')
    )
  );

drop policy if exists "Admins can insert tournaments" on public.tournaments;
create policy "Admins can insert tournaments"
  on public.tournaments
  for insert
  with check (
    exists (
      select 1
      from public.user_squads us
      where us.squad_id = tournaments.squad_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

drop policy if exists "Admins can update tournaments" on public.tournaments;
create policy "Admins can update tournaments"
  on public.tournaments
  for update
  using (
    exists (
      select 1
      from public.user_squads us
      where us.squad_id = tournaments.squad_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  )
  with check (
    exists (
      select 1
      from public.user_squads us
      where us.squad_id = tournaments.squad_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

drop policy if exists "Admins can delete tournaments" on public.tournaments;
create policy "Admins can delete tournaments"
  on public.tournaments
  for delete
  using (
    exists (
      select 1
      from public.user_squads us
      where us.squad_id = tournaments.squad_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

-- canonical tournament teams
create table if not exists public.tournament_teams (
  tournament_team_id uuid primary key
    default gen_random_uuid(),

  tournament_id uuid not null,

  name text null,

  color text null,

  created_at timestamptz not null
    default now(),

  constraint tournament_teams_tournament_fk
    foreign key (tournament_id)
    references public.tournaments (tournament_id)
    on delete cascade,

  constraint tournament_teams_tournament_team_unique
    unique (tournament_id, tournament_team_id)
);

create index if not exists tournament_teams_tournament_idx
  on public.tournament_teams (tournament_id);

alter table public.tournament_teams enable row level security;

drop policy if exists "Members can read tournament teams" on public.tournament_teams;
create policy "Members can read tournament teams"
  on public.tournament_teams
  for select
  using (
    exists (
      select 1
      from public.tournaments t
      join public.squads s on s.squad_id = t.squad_id
      where t.tournament_id = tournament_teams.tournament_id
        and s.visibility = 'public'
    )
    or exists (
      select 1
      from public.tournaments t
      join public.user_squads us on us.squad_id = t.squad_id
      where t.tournament_id = tournament_teams.tournament_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin', 'member')
    )
  );

drop policy if exists "Admins can insert tournament teams" on public.tournament_teams;
create policy "Admins can insert tournament teams"
  on public.tournament_teams
  for insert
  with check (
    exists (
      select 1
      from public.tournaments t
      join public.user_squads us on us.squad_id = t.squad_id
      where t.tournament_id = tournament_teams.tournament_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

drop policy if exists "Admins can update tournament teams" on public.tournament_teams;
create policy "Admins can update tournament teams"
  on public.tournament_teams
  for update
  using (
    exists (
      select 1
      from public.tournaments t
      join public.user_squads us on us.squad_id = t.squad_id
      where t.tournament_id = tournament_teams.tournament_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  )
  with check (
    exists (
      select 1
      from public.tournaments t
      join public.user_squads us on us.squad_id = t.squad_id
      where t.tournament_id = tournament_teams.tournament_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

drop policy if exists "Admins can delete tournament teams" on public.tournament_teams;
create policy "Admins can delete tournament teams"
  on public.tournament_teams
  for delete
  using (
    exists (
      select 1
      from public.tournaments t
      join public.user_squads us on us.squad_id = t.squad_id
      where t.tournament_id = tournament_teams.tournament_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

-- tournament roster memberships
create table if not exists public.tournament_team_players (
  tournament_team_id uuid not null,

  tournament_id uuid not null,

  player_id uuid not null,

  constraint tournament_team_players_pk
    primary key (tournament_team_id, player_id),

  constraint tournament_team_players_team_fk
    foreign key (tournament_team_id)
    references public.tournament_teams (tournament_team_id)
    on delete cascade,

  constraint tournament_team_players_tournament_fk
    foreign key (tournament_id)
    references public.tournaments (tournament_id)
    on delete cascade,

  constraint tournament_team_players_tournament_team_fk
    foreign key (tournament_id, tournament_team_id)
    references public.tournament_teams (tournament_id, tournament_team_id)
    on delete cascade,

  constraint tournament_team_players_player_fk
    foreign key (player_id)
    references public.players (player_id)
    on delete cascade,

  constraint tournament_team_players_unique_player_per_tournament
    unique (tournament_id, player_id)
);

create index if not exists tournament_team_players_tournament_idx
  on public.tournament_team_players (tournament_id);

create index if not exists tournament_team_players_player_idx
  on public.tournament_team_players (player_id);

alter table public.tournament_team_players enable row level security;

drop policy if exists "Members can read tournament team players" on public.tournament_team_players;
create policy "Members can read tournament team players"
  on public.tournament_team_players
  for select
  using (
    exists (
      select 1
      from public.tournaments t
      join public.squads s on s.squad_id = t.squad_id
      where t.tournament_id = tournament_team_players.tournament_id
        and s.visibility = 'public'
    )
    or exists (
      select 1
      from public.tournaments t
      join public.user_squads us on us.squad_id = t.squad_id
      where t.tournament_id = tournament_team_players.tournament_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin', 'member')
    )
  );

drop policy if exists "Admins can insert tournament team players" on public.tournament_team_players;
create policy "Admins can insert tournament team players"
  on public.tournament_team_players
  for insert
  with check (
    exists (
      select 1
      from public.tournaments t
      join public.user_squads us on us.squad_id = t.squad_id
      where t.tournament_id = tournament_team_players.tournament_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
    and exists (
      select 1
      from public.tournaments t
      join public.players p on p.squad_id = t.squad_id
      where t.tournament_id = tournament_team_players.tournament_id
        and p.player_id = tournament_team_players.player_id
    )
  );

drop policy if exists "Admins can update tournament team players" on public.tournament_team_players;
create policy "Admins can update tournament team players"
  on public.tournament_team_players
  for update
  using (
    exists (
      select 1
      from public.tournaments t
      join public.user_squads us on us.squad_id = t.squad_id
      where t.tournament_id = tournament_team_players.tournament_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  )
  with check (
    exists (
      select 1
      from public.tournaments t
      join public.user_squads us on us.squad_id = t.squad_id
      where t.tournament_id = tournament_team_players.tournament_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
    and exists (
      select 1
      from public.tournaments t
      join public.players p on p.squad_id = t.squad_id
      where t.tournament_id = tournament_team_players.tournament_id
        and p.player_id = tournament_team_players.player_id
    )
  );

drop policy if exists "Admins can delete tournament team players" on public.tournament_team_players;
create policy "Admins can delete tournament team players"
  on public.tournament_team_players
  for delete
  using (
    exists (
      select 1
      from public.tournaments t
      join public.user_squads us on us.squad_id = t.squad_id
      where t.tournament_id = tournament_team_players.tournament_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

-- dedicated tournament drafts metadata
create table if not exists public.tournament_drafts (
  tournament_draft_id uuid primary key
    default gen_random_uuid(),

  squad_id uuid not null,

  tournament_id uuid not null,

  status text not null
    default 'completed',

  team_count smallint not null
    default 2,

  proposals_count integer not null
    default 0,

  error_message text null,

  created_at timestamptz not null
    default now(),

  updated_at timestamptz not null
    default now(),

  constraint tournament_drafts_squad_fk
    foreign key (squad_id)
    references public.squads (squad_id)
    on delete cascade,

  constraint tournament_drafts_tournament_fk
    foreign key (tournament_id)
    references public.tournaments (tournament_id)
    on delete cascade,

  constraint tournament_drafts_status_chk
    check (status in ('completed', 'error')),

  constraint tournament_drafts_team_count_chk
    check (team_count between 2 and 4),

  constraint tournament_drafts_proposals_count_chk
    check (proposals_count >= 0)
);

create index if not exists tournament_drafts_tournament_created_idx
  on public.tournament_drafts (tournament_id, created_at desc);

create index if not exists tournament_drafts_squad_created_idx
  on public.tournament_drafts (squad_id, created_at desc);

create table if not exists public.tournament_draft_payloads (
  tournament_draft_id uuid primary key,

  proposals jsonb not null
    default '[]'::jsonb,

  win_rate_matrix jsonb not null
    default '{}'::jsonb,

  rules jsonb not null
    default '[]'::jsonb,

  selected_player_ids jsonb not null
    default '[]'::jsonb,

  created_at timestamptz not null
    default now(),

  updated_at timestamptz not null
    default now(),

  constraint tournament_draft_payloads_draft_fk
    foreign key (tournament_draft_id)
    references public.tournament_drafts (tournament_draft_id)
    on delete cascade,

  constraint tournament_draft_payloads_proposals_array_chk
    check (jsonb_typeof(proposals) = 'array'),

  constraint tournament_draft_payloads_win_rate_matrix_object_chk
    check (jsonb_typeof(win_rate_matrix) = 'object'),

  constraint tournament_draft_payloads_rules_array_chk
    check (jsonb_typeof(rules) = 'array'),

  constraint tournament_draft_payloads_selected_player_ids_array_chk
    check (jsonb_typeof(selected_player_ids) = 'array')
);

alter table public.tournament_drafts enable row level security;
alter table public.tournament_draft_payloads enable row level security;

drop policy if exists "Members can read tournament drafts" on public.tournament_drafts;
create policy "Members can read tournament drafts"
  on public.tournament_drafts
  for select
  using (
    exists (
      select 1
      from public.squads s
      where s.squad_id = tournament_drafts.squad_id
        and s.visibility = 'public'
    )
    or exists (
      select 1
      from public.user_squads us
      where us.squad_id = tournament_drafts.squad_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin', 'member')
    )
  );

drop policy if exists "Admins can insert tournament drafts" on public.tournament_drafts;
create policy "Admins can insert tournament drafts"
  on public.tournament_drafts
  for insert
  with check (
    exists (
      select 1
      from public.user_squads us
      where us.squad_id = tournament_drafts.squad_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

drop policy if exists "Admins can update tournament drafts" on public.tournament_drafts;
create policy "Admins can update tournament drafts"
  on public.tournament_drafts
  for update
  using (
    exists (
      select 1
      from public.user_squads us
      where us.squad_id = tournament_drafts.squad_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  )
  with check (
    exists (
      select 1
      from public.user_squads us
      where us.squad_id = tournament_drafts.squad_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

drop policy if exists "Admins can delete tournament drafts" on public.tournament_drafts;
create policy "Admins can delete tournament drafts"
  on public.tournament_drafts
  for delete
  using (
    exists (
      select 1
      from public.user_squads us
      where us.squad_id = tournament_drafts.squad_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

drop policy if exists "Members can read tournament draft payloads" on public.tournament_draft_payloads;
create policy "Members can read tournament draft payloads"
  on public.tournament_draft_payloads
  for select
  using (
    exists (
      select 1
      from public.tournament_drafts td
      join public.squads s on s.squad_id = td.squad_id
      where td.tournament_draft_id = tournament_draft_payloads.tournament_draft_id
        and s.visibility = 'public'
    )
    or exists (
      select 1
      from public.tournament_drafts td
      join public.user_squads us on us.squad_id = td.squad_id
      where td.tournament_draft_id = tournament_draft_payloads.tournament_draft_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin', 'member')
    )
  );

drop policy if exists "Admins can insert tournament draft payloads" on public.tournament_draft_payloads;
create policy "Admins can insert tournament draft payloads"
  on public.tournament_draft_payloads
  for insert
  with check (
    exists (
      select 1
      from public.tournament_drafts td
      join public.user_squads us on us.squad_id = td.squad_id
      where td.tournament_draft_id = tournament_draft_payloads.tournament_draft_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

drop policy if exists "Admins can update tournament draft payloads" on public.tournament_draft_payloads;
create policy "Admins can update tournament draft payloads"
  on public.tournament_draft_payloads
  for update
  using (
    exists (
      select 1
      from public.tournament_drafts td
      join public.user_squads us on us.squad_id = td.squad_id
      where td.tournament_draft_id = tournament_draft_payloads.tournament_draft_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  )
  with check (
    exists (
      select 1
      from public.tournament_drafts td
      join public.user_squads us on us.squad_id = td.squad_id
      where td.tournament_draft_id = tournament_draft_payloads.tournament_draft_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

drop policy if exists "Admins can delete tournament draft payloads" on public.tournament_draft_payloads;
create policy "Admins can delete tournament draft payloads"
  on public.tournament_draft_payloads
  for delete
  using (
    exists (
      select 1
      from public.tournament_drafts td
      join public.user_squads us on us.squad_id = td.squad_id
      where td.tournament_draft_id = tournament_draft_payloads.tournament_draft_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

alter table public.tournaments
  add column if not exists accepted_tournament_draft_id uuid null,
  add constraint tournaments_accepted_draft_fk
    foreign key (accepted_tournament_draft_id)
    references public.tournament_drafts (tournament_draft_id)
    on delete set null;

-- ranking_history extension for tournament snapshots
alter table public.ranking_history
  add column if not exists tournament_id uuid null,
  add constraint ranking_history_tournament_fk
    foreign key (tournament_id)
    references public.tournaments (tournament_id)
    on delete set null,
  add constraint ranking_history_source_chk
    check (num_nonnulls(match_id, tournament_id) <= 1);

create index if not exists ranking_history_tournament_idx
  on public.ranking_history (tournament_id)
  where tournament_id is not null;

create unique index if not exists ranking_history_player_tournament_unique_idx
  on public.ranking_history (player_id, tournament_id)
  where tournament_id is not null;

drop policy if exists "Admins can insert ranking history" on public.ranking_history;
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
    and (
      ranking_history.tournament_id is null
      or exists (
        select 1
        from public.tournaments t
        join public.players p on p.squad_id = t.squad_id
        where t.tournament_id = ranking_history.tournament_id
          and p.player_id = ranking_history.player_id
      )
    )
  );

drop policy if exists "Admins can update ranking history" on public.ranking_history;
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
    and (
      ranking_history.tournament_id is null
      or exists (
        select 1
        from public.tournaments t
        join public.players p on p.squad_id = t.squad_id
        where t.tournament_id = ranking_history.tournament_id
          and p.player_id = ranking_history.player_id
      )
    )
  );

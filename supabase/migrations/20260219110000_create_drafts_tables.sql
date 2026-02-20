-- ###########################################################################
-- Migration: create drafts and draft_payloads tables
-- Purpose:
--   - Persist draft metadata and payloads per match.
-- Decisions:
--   - One draft per match via unique (match_id).
--   - Keep heavy payload in a separate 1:1 table.
-- ###########################################################################

create table public.drafts (
  draft_id uuid primary key
    default gen_random_uuid(),

  squad_id uuid not null,

  match_id uuid not null,

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

  constraint drafts_squad_fk
    foreign key (squad_id)
    references public.squads (squad_id)
    on delete cascade,

  constraint drafts_match_fk
    foreign key (match_id)
    references public.matches (match_id)
    on delete cascade,

  constraint drafts_match_unique
    unique (match_id),

  constraint drafts_status_chk
    check (status in ('completed', 'error')),

  constraint drafts_team_count_chk
    check (team_count between 2 and 4),

  constraint drafts_proposals_count_chk
    check (proposals_count >= 0)
);

create index drafts_squad_idx
  on public.drafts (squad_id);

create index drafts_created_at_idx
  on public.drafts (created_at desc);

create table public.draft_payloads (
  draft_id uuid primary key,

  proposals jsonb not null
    default '[]'::jsonb,

  win_rate_matrix jsonb not null
    default '{}'::jsonb,

  created_at timestamptz not null
    default now(),

  updated_at timestamptz not null
    default now(),

  constraint draft_payloads_draft_fk
    foreign key (draft_id)
    references public.drafts (draft_id)
    on delete cascade,

  constraint draft_payloads_proposals_array_chk
    check (jsonb_typeof(proposals) = 'array'),

  constraint draft_payloads_win_rate_matrix_object_chk
    check (jsonb_typeof(win_rate_matrix) = 'object')
);

alter table public.drafts enable row level security;
alter table public.draft_payloads enable row level security;

create policy "Members can read drafts"
  on public.drafts
  for select
  using (
    exists (
      select 1
      from public.squads s
      where s.squad_id = drafts.squad_id
        and s.visibility = 'public'
    )
    or exists (
      select 1
      from public.user_squads us
      where us.squad_id = drafts.squad_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin', 'member')
    )
  );

create policy "Admins can insert drafts"
  on public.drafts
  for insert
  with check (
    exists (
      select 1
      from public.user_squads us
      where us.squad_id = drafts.squad_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

create policy "Admins can update drafts"
  on public.drafts
  for update
  using (
    exists (
      select 1
      from public.user_squads us
      where us.squad_id = drafts.squad_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  )
  with check (
    exists (
      select 1
      from public.user_squads us
      where us.squad_id = drafts.squad_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

create policy "Admins can delete drafts"
  on public.drafts
  for delete
  using (
    exists (
      select 1
      from public.user_squads us
      where us.squad_id = drafts.squad_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

create policy "Members can read draft payloads"
  on public.draft_payloads
  for select
  using (
    exists (
      select 1
      from public.drafts d
      join public.squads s on s.squad_id = d.squad_id
      where d.draft_id = draft_payloads.draft_id
        and s.visibility = 'public'
    )
    or exists (
      select 1
      from public.drafts d
      join public.user_squads us on us.squad_id = d.squad_id
      where d.draft_id = draft_payloads.draft_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin', 'member')
    )
  );

create policy "Admins can insert draft payloads"
  on public.draft_payloads
  for insert
  with check (
    exists (
      select 1
      from public.drafts d
      join public.user_squads us on us.squad_id = d.squad_id
      where d.draft_id = draft_payloads.draft_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

create policy "Admins can update draft payloads"
  on public.draft_payloads
  for update
  using (
    exists (
      select 1
      from public.drafts d
      join public.user_squads us on us.squad_id = d.squad_id
      where d.draft_id = draft_payloads.draft_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  )
  with check (
    exists (
      select 1
      from public.drafts d
      join public.user_squads us on us.squad_id = d.squad_id
      where d.draft_id = draft_payloads.draft_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

create policy "Admins can delete draft payloads"
  on public.draft_payloads
  for delete
  using (
    exists (
      select 1
      from public.drafts d
      join public.user_squads us on us.squad_id = d.squad_id
      where d.draft_id = draft_payloads.draft_id
        and us.user_id = auth.uid()
        and us.role in ('owner', 'admin')
    )
  );

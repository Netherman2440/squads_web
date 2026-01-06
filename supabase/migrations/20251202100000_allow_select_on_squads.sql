-- ###########################################################################
-- Migration: allow select on squads for all users
-- Purpose:
--   - Permit listing squads for guests and non-members.
-- Decisions:
--   - Keep RLS enabled; allow select via a permissive policy.
-- ###########################################################################

drop policy if exists "Members can read squads" on public.squads;

create policy "Anyone can read squads"
  on public.squads
  for select
  using (true);

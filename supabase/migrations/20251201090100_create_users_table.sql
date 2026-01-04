-- ###########################################################################
-- Migration: create public.users table
-- Purpose:
--   - Store a minimal public copy of auth users for app-level joins.
-- Decisions:
--   - Keep only id, email, created_at (no profile fields yet).
-- ###########################################################################

create table public.users (
  user_id uuid primary key
    references auth.users (id)
    on delete cascade,
  email text not null,
  created_at timestamptz not null
    default now(),
  constraint unique_users_email
    unique (email)
);

alter table public.users enable row level security;

create policy "Users can read own profile"
  on public.users
  for select
  using (auth.uid() = user_id);

create policy "Users can insert own profile"
  on public.users
  for insert
  with check (auth.uid() = user_id);

create policy "Users can update own profile"
  on public.users
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete own profile"
  on public.users
  for delete
  using (auth.uid() = user_id);

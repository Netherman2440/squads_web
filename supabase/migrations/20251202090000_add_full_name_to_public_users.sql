-- ###########################################################################
-- Migration: add full_name to public.users
-- Purpose:
--   - Store a display name for user-facing lists.
-- Decisions:
--   - Keep full_name nullable to avoid blocking existing users.
--   - Sync full_name from auth.users raw_user_meta_data when available.
-- ###########################################################################

alter table public.users
  add column if not exists full_name text;

update public.users u
set full_name = nullif(
  trim(
    coalesce(
      a.raw_user_meta_data->>'full_name',
      a.raw_user_meta_data->>'name',
      ''
    )
  ),
  ''
)
from auth.users a
where a.id = u.user_id
  and (u.full_name is null or u.full_name = '')
  and coalesce(
    a.raw_user_meta_data->>'full_name',
    a.raw_user_meta_data->>'name',
    ''
  ) <> '';

create or replace function public.sync_public_user()
returns trigger
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
declare
  resolved_full_name text;
begin
  if new.email is null or length(new.email) = 0 then
    return new;
  end if;

  resolved_full_name := nullif(
    trim(
      coalesce(
        new.raw_user_meta_data->>'full_name',
        new.raw_user_meta_data->>'name',
        ''
      )
    ),
    ''
  );

  insert into public.users (user_id, email, full_name, created_at)
  values (new.id, new.email, resolved_full_name, coalesce(new.created_at, now()))
  on conflict (user_id)
  do update set
    email = excluded.email,
    full_name = coalesce(excluded.full_name, public.users.full_name);

  return new;
end;
$$;

drop trigger if exists on_auth_user_sync on auth.users;

create trigger on_auth_user_sync
  after insert or update of email, raw_user_meta_data
  on auth.users
  for each row
  execute function public.sync_public_user();

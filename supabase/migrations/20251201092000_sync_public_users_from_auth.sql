-- ###########################################################################
-- Migration: sync public.users from auth.users
-- Purpose:
--   - Keep public.users in sync with auth.users inserts and email updates.
-- Decisions:
--   - Use SECURITY DEFINER trigger to bypass RLS and skip rows with no email.
-- ###########################################################################

create or replace function public.sync_public_user()
returns trigger
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
begin
  if new.email is null or length(new.email) = 0 then
    return new;
  end if;

  insert into public.users (user_id, email, created_at)
  values (new.id, new.email, coalesce(new.created_at, now()))
  on conflict (user_id)
  do update set email = excluded.email;

  return new;
end;
$$;

drop trigger if exists on_auth_user_sync on auth.users;

create trigger on_auth_user_sync
  after insert or update of email
  on auth.users
  for each row
  execute function public.sync_public_user();

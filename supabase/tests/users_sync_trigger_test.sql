-- Smoke tests for auth.users -> public.users sync trigger.
begin;

select
  'sync_public_user_fn_exists' as check,
  exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'sync_public_user'
  ) as is_valid;

select
  'on_auth_user_sync_trigger_exists' as check,
  exists (
    select 1
    from pg_trigger t
    join pg_class c on c.oid = t.tgrelid
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'auth'
      and c.relname = 'users'
      and t.tgname = 'on_auth_user_sync'
      and not t.tgisinternal
  ) as is_valid;

rollback;

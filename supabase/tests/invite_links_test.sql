-- Smoke tests for invite_links schema and RPC presence.
begin;

select
  'invite_links_table_present' as check,
  exists (
    select 1
    from information_schema.tables
    where table_schema = 'public'
      and table_name = 'invite_links'
  ) as is_valid;

select
  'invite_links_unique_per_squad' as check,
  exists (
    select 1
    from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'invite_links'
      and constraint_name = 'invite_links_squad_unique'
      and constraint_type = 'UNIQUE'
  ) as is_valid;

select
  'join_squad_by_invite_exists' as check,
  exists (
    select 1
    from pg_proc
    where proname = 'join_squad_by_invite'
      and pg_function_is_visible(oid)
  ) as is_valid;

rollback;

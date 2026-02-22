-- Smoke tests for drafts table.
begin;

select
  'drafts_table_exists' as check,
  exists (
    select 1
    from information_schema.tables
    where table_schema = 'public'
      and table_name = 'drafts'
  ) as is_valid;

select
  'drafts_match_unique_constraint_exists' as check,
  exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'drafts'
      and c.conname = 'drafts_match_unique'
  ) as is_valid;

select
  'drafts_status_constraint_exists' as check,
  exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'drafts'
      and c.conname = 'drafts_status_chk'
  ) as is_valid;

rollback;

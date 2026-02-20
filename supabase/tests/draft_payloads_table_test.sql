-- Smoke tests for draft_payloads table.
begin;

select
  'draft_payloads_table_exists' as check,
  exists (
    select 1
    from information_schema.tables
    where table_schema = 'public'
      and table_name = 'draft_payloads'
  ) as is_valid;

select
  'draft_payloads_fk_exists' as check,
  exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'draft_payloads'
      and c.conname = 'draft_payloads_draft_fk'
  ) as is_valid;

select
  'draft_payloads_proposals_array_constraint_exists' as check,
  exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'draft_payloads'
      and c.conname = 'draft_payloads_proposals_array_chk'
  ) as is_valid;

rollback;

-- Smoke test for matches.home_win_prob column and constraint.
begin;

select
  'matches_home_win_prob_column_exists' as check,
  exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'matches'
      and column_name = 'home_win_prob'
  ) as is_valid;

select
  'matches_home_win_prob_range_constraint_exists' as check,
  exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'matches'
      and c.conname = 'matches_home_win_prob_range_chk'
  ) as is_valid;

rollback;

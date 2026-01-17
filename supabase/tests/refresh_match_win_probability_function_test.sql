-- Smoke test for refresh match win probability function existence.
begin;

select
  'refresh_match_win_probability_function_exists' as check,
  exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'refresh_match_win_probability'
      and p.pronargs = 1
  ) as is_valid;

rollback;

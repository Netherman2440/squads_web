-- Smoke test for player stats function existence.
begin;

select
  'player_stats_function_exists' as check,
  exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'get_player_stats'
      and p.pronargs = 1
  ) as is_valid;

rollback;

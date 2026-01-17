-- Smoke test for player pair win rates function existence.
begin;

select
  'player_pair_win_rates_function_exists' as check,
  exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'get_player_pair_win_rates'
      and p.pronargs = 1
  ) as is_valid;

rollback;

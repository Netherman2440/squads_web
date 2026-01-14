-- Smoke test for team_players player fk delete behavior.
begin;

select
  'team_players_player_fk_delete_cascade' as check,
  exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'team_players'
      and c.conname = 'team_players_player_fk'
      and c.contype = 'f'
      and c.confdeltype = 'c'
  ) as is_valid;

rollback;

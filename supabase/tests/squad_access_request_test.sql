-- Smoke tests for squad access request function.
begin;

select
  'request_squad_access_fn_exists' as check,
  exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'request_squad_access'
  ) as is_valid;

rollback;

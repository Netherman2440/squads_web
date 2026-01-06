-- Smoke tests for squads select policy.
begin;

select
  'squads_select_policy_anyone' as check,
  exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'squads'
      and policyname = 'Anyone can read squads'
      and qual = 'true'
  ) as is_valid;

rollback;

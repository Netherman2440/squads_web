-- Smoke tests for public.users full_name column.
begin;

select
  'users_full_name_column_exists' as check,
  exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'users'
      and column_name = 'full_name'
  ) as is_valid;

rollback;

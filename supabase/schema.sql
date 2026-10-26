-- drktimes community source (specs/002-community-times/contracts/supabase-source.md).
-- Idempotent: safe to re-run in the Supabase SQL editor and in CI.

do $$
begin
  if not exists (select from pg_roles where rolname = 'anon') then
    create role anon nologin;
  end if;
  if not exists (select from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin;
  end if;
end $$;

create table if not exists submissions (
  contribution_id uuid not null,
  film_id         text not null check (film_id ~ '^[a-z0-9][a-z0-9-]{0,79}$'),
  developer_id    text not null check (developer_id ~ '^[a-z0-9][a-z0-9-]{0,79}$'),
  dilution        text not null check (dilution ~ '^(stock|working|1(\+[0-9]+(\.[0-9]+)?){1,2})$'),
  ei              int  not null check (ei between 1 and 25600),
  temp_c          int  not null check (temp_c between 10 and 45),
  time_s          int  not null check (time_s between 30 and 10800),
  updated_at      timestamptz not null default now(),
  primary key (contribution_id, film_id, developer_id, dilution, ei, temp_c)
);

-- The public key has no table access at all (FR-021).
alter table submissions enable row level security;
revoke all on submissions from anon, authenticated, public;

-- The one similarity window (FR-020): times within about +-4 % share a bucket.
create or replace function similarity_ratio() returns numeric
language sql immutable as $$ select 1.08::numeric $$;

create or replace function submit_time(
  contribution_id uuid,
  film_id text,
  developer_id text,
  dilution text,
  ei int,
  temp_c int,
  time_s int
) returns void
language plpgsql security definer set search_path = public as $$
#variable_conflict use_variable
begin
  if contribution_id is null then
    raise exception 'contribution_id required' using errcode = '22023';
  end if;
  if (select count(*) from submissions s
        where s.contribution_id = submit_time.contribution_id
          and s.updated_at > now() - interval '24 hours') >= 200 then
    raise exception 'daily limit reached' using errcode = 'PT429';
  end if;
  -- Range and pattern checks come from the table's CHECK constraints.
  insert into submissions as s
    (contribution_id, film_id, developer_id, dilution, ei, temp_c, time_s)
  values (contribution_id, film_id, developer_id, dilution, ei, temp_c, time_s)
  on conflict on constraint submissions_pkey
  do update set time_s = excluded.time_s, updated_at = now();
exception when check_violation or not_null_violation then
  raise exception 'invalid submission' using errcode = '22023';
end $$;

create or replace function community_feed() returns jsonb
language sql stable security definer set search_path = public as $$
  with bucketed as (
    -- shortcut: bucket edges split near-equal times, switch to gap clustering when real data shows it
    select *, floor(ln(time_s) / ln(similarity_ratio()))::int as bucket
    from submissions
  ), grouped as (
    select film_id, developer_id, dilution, ei, temp_c, bucket,
           round(percentile_cont(0.5) within group (order by time_s))::int as time_s,
           count(distinct contribution_id)::int as installs,
           max(updated_at) as last_confirmed
    from bucketed
    group by film_id, developer_id, dilution, ei, temp_c, bucket
    having count(distinct contribution_id) >= 2
  )
  select jsonb_build_object(
    'format', 'drktimes-community-feed',
    'format_version', 1,
    'generated_at', now(),
    'entries', coalesce(jsonb_agg(jsonb_build_object(
      'film_id', film_id, 'developer_id', developer_id, 'dilution', dilution,
      'ei', ei, 'temp_c', temp_c, 'time_s', time_s,
      'installs', installs, 'last_confirmed', last_confirmed
    ) order by film_id, developer_id, dilution, ei, temp_c, time_s), '[]'::jsonb)
  ) from grouped
$$;

revoke all on function submit_time(uuid, text, text, text, int, int, int) from public;
revoke all on function community_feed() from public;
grant execute on function submit_time(uuid, text, text, text, int, int, int) to anon;
grant execute on function community_feed() to anon;

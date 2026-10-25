-- Run after schema.sql: psql -v ON_ERROR_STOP=1 -f supabase/schema.sql -f supabase/tests/run.sql
-- Any failed assertion raises and aborts the run.

truncate submissions;

create or replace function assert(ok boolean, what text) returns void
language plpgsql as $$ begin
  if not coalesce(ok, false) then raise exception 'FAILED: %', what; end if;
end $$;

grant execute on function assert(boolean, text) to anon;

-- Nothing the public key can do touches the table directly (FR-021).
set role anon;
do $$ begin
  begin perform 1 from submissions; perform assert(false, 'anon can select');
  exception when insufficient_privilege then null; end;
  begin insert into submissions values (gen_random_uuid(),'a','b','stock',400,20,500,now());
        perform assert(false, 'anon can insert');
  exception when insufficient_privilege then null; end;
  begin update submissions set time_s = 60; perform assert(false, 'anon can update');
  exception when insufficient_privilege then null; end;
  begin delete from submissions; perform assert(false, 'anon can delete');
  exception when insufficient_privilege then null; end;
end $$;

-- A lone submission stays hidden.
select submit_time('00000000-0000-0000-0000-000000000001','tri-x','d76','1+1',400,20,540);
select assert(jsonb_array_length(community_feed()->'entries') = 0, 'lone submission is hidden');

-- Two distinct IDs within the window appear, with the median time.
select submit_time('00000000-0000-0000-0000-000000000002','tri-x','d76','1+1',400,20,550);
do $$ declare e jsonb; begin
  e := community_feed()->'entries'->0;
  perform assert(jsonb_array_length(community_feed()->'entries') = 1, 'pair appears');
  perform assert((e->>'installs')::int = 2, 'installs = 2');
  perform assert((e->>'time_s')::int in (545, 546), 'median time');
  perform assert(community_feed()::text !~ '00000000-0000', 'no contribution id in feed');
  perform assert(community_feed()->>'format' = 'drktimes-community-feed', 'format');
end $$;

-- A repeat from one ID replaces its earlier time and changes no count.
select submit_time('00000000-0000-0000-0000-000000000002','tri-x','d76','1+1',400,20,545);
do $$ begin
  perform assert((community_feed()->'entries'->0->>'installs')::int = 2, 'repeat keeps count');
end $$;
reset role;
select assert((select count(*) from submissions) = 2, 'repeat replaced, not added');
set role anon;

-- A far-off time forms its own hidden bucket.
select submit_time('00000000-0000-0000-0000-000000000003','tri-x','d76','1+1',400,20,1200);
do $$ begin
  perform assert(jsonb_array_length(community_feed()->'entries') = 1, 'far-off time stays hidden');
end $$;

-- Out-of-range values are rejected.
do $$ declare bad int := 0; begin
  begin perform submit_time('00000000-0000-0000-0000-000000000004','tri-x','d76','1+1',400,20,29);
  exception when sqlstate '22023' then bad := bad + 1; end;
  begin perform submit_time('00000000-0000-0000-0000-000000000004','tri-x','d76','1+1',400,20,10801);
  exception when sqlstate '22023' then bad := bad + 1; end;
  begin perform submit_time('00000000-0000-0000-0000-000000000004','tri-x','d76','1+1',400,9,500);
  exception when sqlstate '22023' then bad := bad + 1; end;
  begin perform submit_time('00000000-0000-0000-0000-000000000004','tri-x','d76','nope',400,20,500);
  exception when sqlstate '22023' then bad := bad + 1; end;
  begin perform submit_time('00000000-0000-0000-0000-000000000004','Bad Id','d76','1+1',400,20,500);
  exception when sqlstate '22023' then bad := bad + 1; end;
  perform assert(bad = 5, 'out-of-range values rejected');
end $$;

-- The 201st submission within 24 h from one ID is rejected.
do $$ declare i int; rejected boolean := false; begin
  for i in 1..200 loop
    perform submit_time('00000000-0000-0000-0000-000000000009','tri-x','d76','1+1',i,20,500);
  end loop;
  begin perform submit_time('00000000-0000-0000-0000-000000000009','tri-x','d76','1+1',201,20,500);
  exception when sqlstate 'PT429' then rejected := true; end;
  perform assert(rejected, '201st submission rejected');
end $$;
reset role;

select 'sql tests passed' as result;

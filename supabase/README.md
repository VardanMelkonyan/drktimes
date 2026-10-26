# Community source (Supabase)

The SQL behind the app's default community source. The contract is
`specs/002-community-times/contracts/supabase-source.md`; `schema.sql` implements it and
`tests/run.sql` is run against a throwaway Postgres in CI (`sql` job).

## Set up

1. Create a free Supabase project.
2. Run `schema.sql` in the SQL editor (it is idempotent).
3. Build the app with `--dart-define=COMMUNITY_URL=https://<ref>.supabase.co
   --dart-define=COMMUNITY_KEY=<anon key>`. Both values are public by design.
4. In the GitHub repository settings add variables `COMMUNITY_URL` and `COMMUNITY_KEY` for the
   keep-alive workflow.

## Moderation (FR-025)

Run in the SQL editor with the project owner's login:

```sql
-- one bad combination
delete from submissions where film_id = '…' and developer_id = '…'
  and dilution = '…' and ei = … and temp_c = …;
-- everything from one ID
delete from submissions where contribution_id = '…';
```

The next `community_feed()` call no longer includes them.

## Keep-alive

`.github/workflows/community-keepalive.yml` calls `community_feed()` daily so Supabase's free
tier does not pause the project for inactivity.

GitHub disables scheduled workflows after about 60 days without repository activity. If the
workflow stops appearing in the Actions tab, open it and press **Enable workflow**, or run it
once by hand (`workflow_dispatch`). Check the Actions tab at least every two months.

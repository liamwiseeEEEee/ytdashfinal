-- ============================================================
-- Sleep Tracker — migration 001
-- One row per night. Re-running the Shortcut on the same morning
-- upserts (unique constraint on `date`) so duplicates aren't possible.
-- ============================================================

create table if not exists public.sleep_logs (
  id              uuid primary key default gen_random_uuid(),
  date            date not null unique,         -- local date the user woke up
  sleep_start     timestamptz not null,         -- when they got into bed
  wake_time       timestamptz not null,         -- when they woke up
  duration_hours  numeric(4,2) not null,        -- total time asleep
  created_at      timestamptz not null default now()
);

create index if not exists sleep_logs_date_desc
  on public.sleep_logs (date desc);

-- ============================================================
-- OPTIONAL: row-level security
-- ============================================================
-- The Vercel function writes with the service_role key (bypasses RLS).
-- The dashboard reads with the anon key (subject to RLS).
-- If you have RLS enabled on this table, add a read policy for anon:
--
--   alter table public.sleep_logs enable row level security;
--   create policy "anon can read sleep_logs"
--     on public.sleep_logs for select
--     to anon
--     using (true);
--
-- If you don't have RLS enabled, the table is open by default — fine
-- for a personal dashboard, NOT fine if the Supabase project is shared.

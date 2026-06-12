# CLAUDE.md — Sleep Tracker drop-in module

You are integrating this Sleep Tracker module into a user's existing dashboard project. Follow the steps below in order. Pause after each step to confirm with the user before moving on — credentials and DB migrations should not be touched silently.

## What you're installing

```
iPhone Health → iOS Shortcut → POST /api/sleep-log (Vercel) → Supabase row
                                                                  ↓
                              user's dashboard reads via supabase-js
```

Four pieces:

1. **SQL table** in their existing Supabase (`sql/001_sleep_logs.sql`)
2. **Vercel serverless function** copied into their dashboard repo (`api/sleep-log.js`)
3. **Frontend card** pasted into their `index.html` (`frontend/sleep-card.html`)
4. **iOS Shortcut** set up on their phone (`shortcuts/README.md` — they do this manually)

## Before you start — gather context

Ask the user (don't guess):

- **Where is their dashboard project?** (e.g. `../my-dashboard/`). Need the absolute path.
- **What's their Supabase project URL + anon key?** (visible in Supabase dashboard → Project Settings → API)
- **What's their Supabase service role key?** (same place. NEVER commit this — it's only for the Vercel env var.)
- **Is their dashboard on Vercel already?** If not, walk them through `vercel link` first.
- **Do they want to generate a fresh SLEEP_API_SECRET?** If yes, generate with `openssl rand -hex 24` (or Node's `crypto.randomBytes(24).toString('hex')`).

## Step 1 — Run the SQL migration

Open `sql/001_sleep_logs.sql`. Tell the user to:

1. Open their Supabase project → **SQL Editor** → **New query**
2. Paste the contents of `sql/001_sleep_logs.sql`
3. Click **Run**

Verify by asking them to open **Table Editor** and confirm `sleep_logs` exists with the columns shown in the migration.

## Step 2 — Copy the API function

Copy `api/sleep-log.js` → `<their-dashboard>/api/sleep-log.js`.

If their project doesn't have a `package.json`, also copy `package.json` to set up `@supabase/supabase-js`. If they already have one, add `"@supabase/supabase-js": "^2.45.0"` to dependencies and run `npm install` (or whichever package manager they use).

## Step 3 — Set Vercel env vars

The function needs three env vars on Vercel. Tell the user to:

1. Open their Vercel project → **Settings** → **Environment Variables**
2. Add (for Production, Preview, AND Development):
   - `SUPABASE_URL` = their Supabase project URL
   - `SUPABASE_SERVICE_KEY` = their Supabase service role key (the secret one)
   - `SLEEP_API_SECRET` = a random string they'll also paste into the iOS Shortcut later
3. Redeploy: `vercel --prod` (or push to main if auto-deploy is wired up)

After deploy, confirm the endpoint is live:

```bash
curl -X POST https://<their-vercel-domain>/api/sleep-log \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <SLEEP_API_SECRET>" \
  -d '{"sleep_start":"2026-05-16T23:00:00Z","wake_time":"2026-05-17T07:00:00Z","duration_hours":7.5}'
```

Expected: `{ "ok": true, "row": { ... } }`.

## Step 4 — Drop in the frontend card

1. Open `frontend/sleep-card.html`. The file is fully self-contained — one `<section>` block with embedded `<style>` and `<script>`.
2. In the user's dashboard `index.html`, find where they want the card to go (a logical spot is near their Health/Recovery section).
3. **First**, add the config block ABOVE the card (or anywhere before it loads):
   ```html
   <script>
     window.SLEEP_TRACKER = {
       supabaseUrl:     'https://YOUR_PROJECT.supabase.co',
       supabaseAnonKey: 'eyJ...'  // public anon key (safe in browser)
     };
   </script>
   ```
4. Paste the contents of `frontend/sleep-card.html` where the card should appear.
5. The card auto-mounts — no manual init call needed.

The card pulls the last 14 nights from `sleep_logs` and renders:
- Last night's hours + bedtime/waketime
- 7-day rolling average
- Sleep debt vs an 8h target (configurable in the snippet)
- A 14-night sparkline

## Step 5 — iOS Shortcut

Hand the user `shortcuts/README.md` and tell them to follow it on their phone. They'll need the deployed endpoint URL and the `SLEEP_API_SECRET` from step 3.

You can't do step 5 for them — it's all on the phone. But confirm afterward that the first night logged correctly by asking them to open their dashboard the next morning.

## Verification checklist

After all 5 steps, verify:

- [ ] `sleep_logs` table exists in Supabase
- [ ] `/api/sleep-log` returns 200 OK with a valid bearer token
- [ ] `/api/sleep-log` returns 401 without (or with wrong) token
- [ ] Dashboard renders the sleep card (even if empty)
- [ ] iOS Shortcut runs manually without errors and inserts a row
- [ ] Dashboard shows the new row after a refresh

## Out of scope

- This module does NOT set up auth on the dashboard side. The frontend uses the Supabase **anon key** and reads `sleep_logs` directly. If the user has RLS enabled, they must add a SELECT policy for anon (see commented-out policy at the bottom of `sql/001_sleep_logs.sql`).
- This module does NOT support Apple Watch / Whoop sleep stages. Only iPhone-detected "in bed" / "asleep" totals.
- This module does NOT compete with the user's existing WHOOP integration. If they already have one, the sleep card can coexist as a secondary "iPhone-detected" sleep source.

## File map

- `README.md` — user-facing intro
- `CLAUDE.md` — this file
- `package.json` — declares `@supabase/supabase-js` for the API function
- `.env.example` — template for SUPABASE_URL, SUPABASE_SERVICE_KEY, SLEEP_API_SECRET
- `sql/001_sleep_logs.sql` — the migration
- `api/sleep-log.js` — the Vercel function
- `frontend/sleep-card.html` — the drop-in card (HTML + CSS + JS in one file)
- `shortcuts/README.md` — iOS Shortcut step-by-step
- `index.html` — local preview with mock data

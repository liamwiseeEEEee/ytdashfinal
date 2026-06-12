# 🌙 Sleep Tracker

A **drop-in sleep tracking module** for personal dashboards. Clone this repo into your Claude Code session, say *"install this into my dashboard"*, and Claude reads [CLAUDE.md](CLAUDE.md) to wire it up.

It auto-logs your sleep every morning from your iPhone (no wearable required) and shows it on your dashboard.

```
iPhone Health  ──▶  iOS Shortcut (on wake)  ──POST──▶  Vercel API  ──▶  your Supabase
                                                                              │
your dashboard  ◀──────────────── supabase-js client ─────────────────────────┘
```

## What you get

- **`sql/001_sleep_logs.sql`** — one table to add to your existing Supabase
- **`api/sleep-log.js`** — one Vercel serverless function, auth via shared secret
- **`frontend/sleep-card.html`** — drop-in HTML+CSS+JS card for your dashboard (matches Dashboard11 aesthetic)
- **`shortcuts/README.md`** — step-by-step iOS Shortcut setup
- **`index.html`** — local preview with mock data so you can see the card before integrating

## What it tracks

iPhone alone (no Apple Watch, no Whoop):

- `sleep_start` — when you got into bed
- `wake_time` — when you woke up
- `duration_hours` — total time asleep

No REM/Deep/Light stages — that requires a wearable.

## Prerequisites

You must already have:

- A dashboard project (any HTML/JS dashboard works; tested against Dashboard11-style projects)
- A **Supabase** project (free tier is fine — reuse your existing one)
- A **Vercel** account (free tier — the function deploys here)
- An iPhone with **Sleep tracking** turned on in Health (see [Step 1 of the iOS Shortcut guide](shortcuts/README.md))

## Quick install (with Claude Code)

```bash
git clone https://github.com/RowanThistlebrooke/Sleep-tracker.git sleep-tracker
cd sleep-tracker
claude
> install this into my dashboard at ../my-dashboard
```

Claude reads `CLAUDE.md` and runs through the 5-step integration: SQL, API deploy, frontend snippet, env vars, Shortcut setup.

## Manual install

If you'd rather do it yourself, follow [`CLAUDE.md`](CLAUDE.md) — it's written for Claude Code but a human can follow it line by line.

## Preview the card

Open `index.html` in any browser. You'll see the card with mock data (last 14 nights of made-up sleep). No Supabase needed for the preview.

## License

MIT — do whatever.

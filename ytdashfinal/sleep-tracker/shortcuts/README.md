# iOS Shortcut — Sleep Logger

Builds the "When I Wake Up" automation that reads last night's sleep from Health and POSTs it to your `/api/sleep-log` endpoint.

You'll need:

- The deployed Vercel endpoint URL: `https://<your-domain>/api/sleep-log`
- Your `SLEEP_API_SECRET` (the same value you set in Vercel env vars)
- iPhone with **Sleep tracking** already configured in Health (see "Prerequisite" below)

## Prerequisite — turn on iPhone sleep tracking

If you haven't already:

1. Health app → Browse → Sleep → Get Started
2. Set a Sleep Schedule (bedtime + wake time)
3. Options → turn ON **"Track Time in Bed with iPhone"**
4. Settings → Focus → Sleep → enable + schedule

Verify after one night: Health → Sleep should show "In Bed" / "Asleep" rows.

---

## Build the Shortcut (10 min)

### Part A — Create the Shortcut itself

1. Open **Shortcuts** app → **Shortcuts** tab → **+** (top-right)
2. Name it **"Log sleep"**
3. Add actions in this order:

#### Action 1 — Find Sleep Samples
- Search "**Find Health Samples**"
- Set:
  - **Type:** Sleep Analysis
  - **Sort by:** End Date
  - **Order:** Latest First
  - **Limit:** 50 (we'll filter to last night)

#### Action 2 — Get the most recent "asleep" sample
- Add "**Get Item from List**"
- **From:** Find Health Samples (the variable from Action 1)
- **Get:** First Item

#### Action 3 — Extract start time
- Add "**Get Details of Health Sample**"
- **Sample:** the item from Action 2
- **Detail:** Start Date

Tap the result variable to rename it → **SleepStart**

#### Action 4 — Extract end time
- Add another "**Get Details of Health Sample**"
- **Sample:** same item from Action 2
- **Detail:** End Date

Rename the result variable → **WakeTime**

#### Action 5 — Format start as ISO 8601
- Add "**Format Date**"
- **Date:** SleepStart
- **Format:** Custom → `yyyy-MM-dd'T'HH:mm:ssXXX`

Rename the result → **SleepStartISO**

#### Action 6 — Format end as ISO 8601
- Add another "**Format Date**"
- **Date:** WakeTime
- **Format:** Custom → `yyyy-MM-dd'T'HH:mm:ssXXX`

Rename → **WakeTimeISO**

#### Action 7 — Build the JSON body
- Add "**Dictionary**"
- Add three keys:
  - `sleep_start` → SleepStartISO
  - `wake_time` → WakeTimeISO
  - (skip `duration_hours` — the API computes it from start/end)

#### Action 8 — POST to your endpoint
- Add "**Get Contents of URL**"
- **URL:** `https://<your-domain>/api/sleep-log`
- **Method:** POST
- **Headers** (tap "Add new header" twice):
  - `Content-Type` → `application/json`
  - `Authorization` → `Bearer <your SLEEP_API_SECRET>`
- **Request Body:** JSON
- **JSON:** the Dictionary from Action 7

#### Action 9 — Show the response (for testing only — delete later)
- Add "**Show Result**"
- **Content:** Contents of URL (the result of Action 8)

### Part B — Test manually

1. Tap **Done** to save the Shortcut
2. From the Shortcuts list, tap **Log sleep** to run it
3. You should see a popup with `{"ok":true,"row":{...}}`
4. Open your Supabase **Table Editor** → `sleep_logs` → confirm the row exists
5. Open your dashboard → confirm the sleep card shows last night's data

**If you see an error**, common issues:
- `401 unauthorized` → wrong SLEEP_API_SECRET, or Bearer header malformed
- `400 sleep_start and wake_time are required` → date formatting failed; check Action 5/6's custom format string
- No popup at all → Shortcut may have crashed silently; tap the Shortcut while looking at the action list to see which step fails

### Part C — Wire to "When I Wake Up" automation

Only do this once the manual test works.

1. Shortcuts app → **Automation** tab → **+** → **Personal Automation**
2. **When I Wake Up**
3. **Next** → **+ Add Action** → search "**Run Shortcut**"
4. **Shortcut:** Log sleep
5. **Next** → turn **OFF** "**Ask Before Running**" ← critical, otherwise it never fires
6. (Optional) turn ON "Notify When Run" while testing so you know it fired
7. **Done**

### Part D — Clean up

After 2–3 successful auto-runs:

- Edit the "Log sleep" Shortcut
- **Delete Action 9** ("Show Result") — otherwise it pops up every morning when the automation runs
- Save

---

## Daily verification (first week)

The first few mornings, after you wake up:

1. Check Supabase Table Editor → `sleep_logs` → look for the row dated today
2. If missing: open Shortcuts → run "Log sleep" manually → check what happens
3. Once you've seen 5 nights auto-log successfully, you can stop checking

## Troubleshooting

| Symptom | Fix |
|---|---|
| Row inserted with `duration_hours: 0` | Sleep sample didn't have separate start/end. Make sure you're filtering for "Asleep" not just "In Bed". |
| Row inserted but `date` is yesterday | Timezone mismatch. The API uses the wake_time's local date from the ISO string — make sure the Format Date action's format string ends in `XXX` (timezone offset), not `'Z'`. |
| Same data inserted multiple mornings | The API upserts on `date`, so duplicates are impossible — but if you see this, the `date` field is computing wrong. Check the Format Date string. |
| Nothing fires on wake | "Ask Before Running" is still ON, or Sleep Focus isn't enabled. Both required. |

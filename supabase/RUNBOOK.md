# Burgundy — Supabase Runbook

## Project

Supabase project: **burgundy**

---

## 1. Prerequisites

```bash
brew install supabase/tap/supabase
supabase login
```

---

## 2. Apply migrations

```bash
cd /path/to/TasteMatch
supabase db push --db-url "postgresql://postgres:<password>@db.<project-ref>.supabase.co:5432/postgres"
```

Or via the Supabase dashboard → SQL Editor → paste the contents of
`supabase/migrations/20240101000000_initial_schema.sql`.

---

## 3. Deploy edge functions

```bash
supabase functions deploy identity-bootstrap --project-ref <project-ref>
supabase functions deploy record-event       --project-ref <project-ref>
supabase functions deploy fetch-events       --project-ref <project-ref>
```

Functions require `SUPABASE_SERVICE_ROLE_KEY` as a secret (set automatically when
linked to a project). To set additional secrets:

```bash
supabase secrets set MY_SECRET=value --project-ref <project-ref>
```

---

## 4. Run edge functions locally

```bash
supabase start          # starts local Supabase stack
supabase functions serve --env-file .env.local
```

`.env.local` (git-ignored):
```
SUPABASE_URL=http://localhost:54321
SUPABASE_SERVICE_ROLE_KEY=<local service role key from supabase start output>
```

---

## 5. Wire the iOS app

### Option A — Config.xcconfig (recommended)

1. Copy `ios/Config.xcconfig` → `ios/Config.local.xcconfig` (already git-ignored).
2. Fill in real values:
   ```
   SUPABASE_URL = https://<project-ref>.supabase.co
   SUPABASE_ANON_KEY = <anon key from Supabase dashboard → Settings → API>
   ```
3. In Xcode: Project → Info → Configurations → set Debug **and** Release to
   `Config.local.xcconfig`.
4. Build & run — `BurgundySession.bootstrap()` fires on launch and resolves the
   device's identity from the server.

### Option B — Direct Info.plist edit (quick local dev only)

Edit `ios/TasteMatch/Info.plist` and replace the `$(SUPABASE_URL)` /
`$(SUPABASE_ANON_KEY)` placeholders with the real values.
⚠️ Do NOT commit real keys.

---

## 6. Verify the loop

1. Launch app → `BurgundySession.bootstrap()` runs → identity resolved from server.
2. Scan tab → Try a Demo → vote **Me** on a Sofa → `record-event` is called
   server-side, pending_reinforcement created, identity version bumped.
3. History tab → events fetched via `fetch-events`.

---

## 7. RLS notes

All three tables have RLS enabled. The current policy grants full access to the
service role key (used by edge functions). Anonymous/authenticated iOS clients
never touch the database directly — they go through edge functions only.

When auth is added:
- Replace `device_install_id` ownership checks with `auth.uid()` checks.
- Update the `user_id` column on sign-in to link anonymous identity to account.

---

## 8. Endpoints summary

| Function            | Method | Path                                    |
|---------------------|--------|-----------------------------------------|
| identity-bootstrap  | POST   | `/functions/v1/identity-bootstrap`      |
| record-event        | POST   | `/functions/v1/record-event`            |
| fetch-events        | GET    | `/functions/v1/fetch-events?identity_id=&device_install_id=` |

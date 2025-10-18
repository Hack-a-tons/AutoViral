# TODO.md

> Implementation plan broken into independently runnable parts. **Start with Monitoring.** Each step includes a deliverable and a test.

## Phase 0 — Repo & Scaffolding (0.5d)

### Environment & Deployment Setup ✓
* [x] Create `.env.example` with all required variables
* [x] Configure `.gitignore` for security (env files, credentials, generated media)
* [x] Create `daytona.yaml` workspace configuration
* [x] Create `Dockerfile` for Daytona sandbox creation (Node 20 + Playwright + ffmpeg)
* [x] Create deployment scripts (`scripts/deploy.sh`, `scripts/sandbox-cleanup.sh`, `scripts/sandbox-status.sh`)
* [x] Add help (`-h`/`--help`) to all scripts
* [x] Scripts work from any directory (use `#!/usr/bin/env bash` and resolve `.env` path correctly)
* [x] Updated for Daytona CLI v0.111.0 compatibility (`daytona sandbox` commands, `daytona login`, `--dockerfile`)
* [x] Install Daytona CLI on macOS (`daytona-darwin-arm64` binary v0.111.0)
* [x] Create `docs/` folder with `DEPLOYMENT.md`
* [x] Update README.md with Quick Start guide

### Application Scaffolding (TODO)
* [ ] Init Node/TS project; add `compose.yml`
* [ ] Create folders: `api/`, `worker/`, `media/`, `prompts/`
* [ ] Add DB (SQLite via Prisma/Drizzle). Migrate schemas for trends/generations/posts/metrics/settings/lists.
* **Deliverable:** `GET /health` returns OK. DB file exists.

**Note:** Install Daytona CLI before deploying: `brew install daytona` (see README Quick Start)

## Phase 1 — Monitoring: Trend Discovery (speed > volume)

* [ ] Implement `discovery` worker (BrowserUse inside Daytona sandbox):

  * Scrape **X trending** (logged‑out), **Reddit r/all hot/new**, optional Google Trends.
  * Normalize items → `{keyword, source, discovered_at}`.
  * De‑dupe; push to control plane via `POST /webhook/trend`.
* [ ] API: `GET /trends?status=discovering&since=1h`.
* [ ] Selection policy v1 (prompt + heuristics: recency boost, novelty, length).
* **Test:** run for 10 minutes; `/trends` shows fresh items.

## Phase 2 — Selection & Kill Switch

* [ ] Implement selection scorer (prompt‑assisted) → marks some trends **selected**.
* [ ] Add deny/allow list checks.
* [ ] **Kill switch:** `POST /stop/trend/:id`, `POST /stop/keyword`.
* **Test:** mark a live trend as stopped; observe no further jobs created.

## Phase 3 — Content Generation (idea → assets)

* [ ] Add prompt loaders for OpenAI/Gemini/Claude under `/prompts/*`.
* [ ] Generator: produce `{title, hook, script_15s, caption, hashtags, thumb_prompt}`.
* [ ] Pexels fetcher (`/media/fetcher.ts`) to download vertical B‑roll (12–15s) → `/tmp/<post>_bg.mp4`.
* [ ] ffmpeg compositor: overlay timed text + subtitles; optional audio merge.
* [ ] Safety filter prompt → PASS/FAIL with `required_edits`.
* **Deliverable:** `generations` row moves to `ready` with MP4 path.

## Phase 4 — Posting Workers

* [ ] `worker/browser/platforms/x.ts` and `reddit.ts` (Playwright + humanized delays).
* [ ] Post video + caption; capture canonical URL; webhook → `/webhook/post`.
* [ ] API: `GET /posts?trend_id=...`.
* **Test:** one public post appears on X or Reddit; URL stored.

## Phase 5 — Metrics & Follow‑ups

* [ ] Poll views/reactions for each platform (parse DOM or APIs where available).
* [ ] Metrics snapshots into `metrics`.
* [ ] Policy: if signal > threshold in first N minutes → enqueue **follow‑up**; else **auto‑stop**.
* **Test:** simulate positive/negative outcomes; verify behavior.

## Phase 6 — Control & Observability API

* [ ] Endpoints:

  * `/trends`, `/trends/:id`
  * `/generations`, `/generations/:id`
  * `/posts`, `/metrics`
  * `/stop/trend/:id`, `/stop/keyword`
  * `/lists/deny` (POST/DELETE)
  * `/settings` (upsert) — add/remove media/API keys, networks
* [ ] Auth: Bearer key + rate limits.
* **Test:** curl scripts for all flows; returns JSON.

## Phase 7 — Daytona Sandbox Orchestration

* [ ] Add module `daytona.ts` to create/destroy ephemeral workspaces for discovery/gen/post jobs.
* [ ] Artifacts are uploaded back (webhook/S3) and sandbox is destroyed.
* **Test:** run 3 concurrent jobs in separate sandboxes.

## Phase 8 — Monetization Router (optional v1)

* [ ] Prompt‑based intent: `BUY|JOIN|AFFIL|ASK` with CTA.
* [ ] Landing `/in/:postId` renders CTA, links to Stripe test checkout (if BUY) or email capture.
* **Test:** clickthrough from live post → landing CTA functions.

## Phase 9 — Safety & Compliance

* [ ] Hard filters: profanity list, disallowed topics; country‑specific flags.
* [ ] Rate caps per platform; backoff on failures.
* [ ] Credential vaulting (env/secret store).
* **Test:** attempt forbidden content → blocked by safety gate.

## Phase 10 — Dashboard (stretch)

* [ ] Minimal web UI: live tables for trends, generations, posts, metrics; stop buttons.
* [ ] Charts: posts/hour, win rate, avg time‑to‑post, CTR.
* **Test:** observe live updates while loop runs.

## Scripts (ops)

* [ ] `scripts/seed_prompts.sh` — copy base prompts into `/prompts`.
* [ ] `scripts/post_once.sh TREND="..."` — manual injection for demo.
* [ ] `scripts/stop_keyword.sh "keyword"`

## Definition of Done (Hack‑day)

* Control plane running in Daytona, `/health` OK.
* Discovery adds fresh trends within minutes.
* At least one **public** post published automatically.
* `/stop/keyword` halts a live trend immediately.
* `/trends` • `/generations` • `/posts` • `/metrics` all return useful JSON.

## Nice‑to‑have (if time)

* Galileo.ai check for prompt quality/safety.
* Short‑URL service for captions.
* Email adaptor for JOIN flow.
# README.md

## AutoViral — Fully‑Automated Trend→Content→Post→Monetize Engine (Daytona‑Native)

**AutoViral** is an AI system that detects brand‑new social trends in near‑real‑time, manufactures short vertical videos (with audio + subtitles), posts them autonomously across selected networks, monitors performance, and doubles down on winners — all while letting a human **veto/stop** any trend at any time via API.

* **Runtime:** Daytona sandboxes (workspaces are created/destroyed on demand)
* **Browsing hands:** BrowserUse agents running inside Daytona sandboxes
* **LLMs:** OpenAI / Gemini / Claude (switchable); optional **Galileo.ai** for prompt eval & safety
* **Control plane:** REST API + (optional) MCP for prompts/settings
* **Guardrails:** Safety filter prompts + allowlist/denylist + hard platform policies

> **Key principle:** *Speed beats volume.* We prioritize catching trends early over processing many trends.

---

## Quick Start

### Prerequisites

1. **Install Daytona CLI v0.111.0+** (macOS):
   ```bash
   # Download the binary
   curl -L -o daytona-darwin-arm64 https://download.daytona.io/daytona/latest/daytona-darwin-arm64
   chmod +x daytona-darwin-arm64
   sudo mv daytona-darwin-arm64 /usr/local/bin/daytona
   
   # Verify installation
   daytona --version
   ```
   
   **Note:** If you already have the binary in `~/Downloads/daytona-darwin-arm64`, just run:
   ```bash
   chmod +x ~/Downloads/daytona-darwin-arm64
   sudo mv ~/Downloads/daytona-darwin-arm64 /usr/local/bin/daytona
   ```
   
   Or see [installation guide](https://www.daytona.io/docs/installation/daytona-cli/) for other methods.

2. **Other requirements:**
   - Git repository set up with remote origin
   - API keys for OpenAI/Gemini/Claude, BrowserUse, Pexels

### Setup

1. **Clone and configure environment**
   ```bash
   git clone <your-repo-url>
   cd AutoViral
   cp .env.example .env
   # Edit .env with your actual API keys
   ```

2. **Deploy to Daytona**
   ```bash
   # Deploy to production
   ./scripts/deploy.sh --prod
   
   # Or deploy to dev environment
   ./scripts/deploy.sh --dev
   
   # With commit message
   ./scripts/deploy.sh --prod -m "Initial deployment"
   ```

3. **Monitor sandboxes**
   ```bash
   # View current status
   ./scripts/sandbox-status.sh
   
   # Watch mode (continuous updates)
   ./scripts/sandbox-status.sh --watch
   ```

4. **Cleanup old workers**
   ```bash
   # Remove sandboxes older than 30 minutes
   ./scripts/sandbox-cleanup.sh
   ```

💡 **All scripts support `--help` flag** for detailed usage information.

📖 **Full deployment guide:** [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)

---

## Architecture

```
┌──────────────────────────────── Control Plane (Daytona workspace) ────────────────────────────────┐
│  Express API  ──┬──────────────┬──────────────┬──────────────┬──────────────┐                   │
│                 │ /trends/*    │ /jobs/*      │ /posts/*     │ /settings/*  │  /stop/*         │
│  Scheduler      ├──────────────┼──────────────┼──────────────┼──────────────┤  Webhooks        │
│  (fast loop)    │              │              │              │              │  /webhook/*      │
│                 ▼              ▼              ▼              ▼              ▼                   │
│  Trend Discovery Workers  →  Selection Engine  →  Gen Workers  →  Posting Workers  →  Metrics   │
│   (BrowserUse + APIs)         (scorer)           (LLM+ffmpeg)    (BrowserUse)         (ingest)  │
│                                                                                                 │
│  SQLite/Postgres: trends • generations • posts • metrics • settings • allow/deny lists          │
└─────────────────────────────────────────────────────────────────────────────────────────────────┘

┌────────────── Daytona Sandboxes (ephemeral) ──────────────┐
│  • discovery-<id>  (BrowserUse: scrape X/Reddit/Trends)   │
│  • gen-<id>        (LLM prompts + Pexels fetch + ffmpeg)  │
│  • post-<id>       (BrowserUse uploads + captions)        │
└───────────────────────────────────────────────────────────┘
```

### Core components

* **Control Plane API (Express/Node)**: orchestrates jobs, exposes monitoring/stop endpoints, stores state, emits webhooks.
* **Discovery workers (BrowserUse + API)**: pull *freshest* trending topics (X trending, Reddit hot, Google Trends; BrowserUse fills API gaps).
* **Selection engine**: ranks trends by recency, novelty, predicted virality; dedupes; applies user allow/deny lists.
* **Generation workers**: prompts LLM → script/caption/hashtags/thumbnail prompt; fetches **royalty‑free** B‑roll (Pexels) → composes 9–20s vertical MP4 with audio/subs via ffmpeg.
* **Posting workers (BrowserUse)**: authenticate throwaway/brand accounts; post video + caption; store canonical post URLs.
* **Metrics loop**: polls view/reaction counts; if positive signal → schedule follow‑up; if not → auto‑stop.
* **Kill switch**: global and per‑trend **/stop** API immediately halts discovery/gen/posting for that trend.
* **Settings & Prompts**: live‑editable via API/MCP. Prompts are versioned files under `/prompts/*`.

---

## Data model (minimal)

**trends**: `id, created_at, keyword, source, status{discovering|selected|blocked|stopped}, score, reason`

**generations**: `id, trend_id, created_at, stage{idea|video|ready|failed}, mp4_path, thumb_path, caption_json, safety_decision, notes`

**posts**: `id, generation_id, platform, url, posted_at, status{queued|posted|failed}`

**metrics**: `id, post_id, snapshot_at, views, likes, comments, ctr, cta_type{BUY|JOIN|AFFIL|ASK}`

**settings**: `id, key, value_json` (e.g., social networks on/off, Pexels API key, LLM provider)

**lists**: `type{allow|deny}, value, scope{keyword|user|subreddit|hashtag}`

---

## REST API (initial)

> All endpoints are `Bearer`‑key protected. Return JSON. Timestamps in ISO.

### Monitoring

* `GET /trends?status=discovering|selected&since=1h&query=...` → list trends
* `GET /trends/:id` → single trend (status, score, reason)
* `GET /generations?since=30m&trend_id=...` → list generations
* `GET /generations/:id` → details (files/URLs/status/safety)
* `GET /posts?trend_id=...` → where content was posted
* `GET /metrics?post_id=...&since=...` → performance snapshots

### Control

* `POST /stop/trend/:id` → stop all activity for trend
* `POST /stop/keyword` body `{ keyword }` → stop any matching trend
* `POST /lists/deny` body `{ value, scope }` → add deny rule
* `DELETE /lists/deny` body `{ value, scope }` → remove deny rule
* `POST /settings` body `{ key, value }` → upsert a setting (e.g., add/remove networks, media repos)
* `POST /actions/retry` body `{ generation_id | post_id }`

### Webhooks (from workers)

* `POST /webhook/trend` `{ id, status, score }`
* `POST /webhook/generation` `{ id, trend_id, stage, mp4_path, safety_decision }`
* `POST /webhook/post` `{ id, generation_id, platform, url, status }`
* `POST /webhook/metrics` `{ post_id, snapshot }`

---

## Workflow (fast loop)

1. **Discover**: continuously scrape *new* trends (speed > volume). Emit `trends`.
2. **Select**: score newest items; short‑circuit to **selected** if above threshold & not denied.
3. **Generate**: run prompts → script + caption + hashtags + thumb; Pexels fetcher; ffmpeg build (audio + subs).
4. **Safety**: run safety filter; if FAIL → auto‑edit/regenerate; else proceed.
5. **Post**: BrowserUse uploads to chosen networks; store canonical URLs.
6. **Monitor**: poll metrics; if positive → **follow‑up**; else mark trend **stopped**.
7. **Human control**: at any moment, `/stop` kills a trend or keyword family.

---

## Prompts & Providers

* `/prompts/generator/{openai|gemini|claude}.txt`
* `/prompts/safety/{openai|gemini|claude}.txt`
* `/prompts/monetization/{openai|gemini|claude}.txt`
* `/prompts/selection_policy.txt` – scoring rubric (novelty, recency, risk, platform fit)

Switch provider with env or `/settings` (e.g., `{"llm_provider":"openai"}`).

---

## Daytona orchestration

### Sandbox Management

* **Control plane workspaces** (persistent):
  - `autoviral-control-prod` — Production instance
  - `autoviral-control-dev` — Development instance
  - Contains: API + DB + scheduler + dashboards
  - **Only 2 control plane sandboxes run at a time**

* **Ephemeral worker sandboxes** (auto-managed):
  - `discovery-<id>` — Trend scraping (BrowserUse + APIs)
  - `gen-<id>` — Content generation (LLM + ffmpeg)
  - `post-<id>` — Platform posting (BrowserUse)
  - Auto-created on demand
  - **Auto-deleted after `MAX_SANDBOX_LIFETIME_MINUTES` (default: 30)**
  - All tools pre-installed (BrowserUse, Playwright, ffmpeg)

* **State management**:
  - State lives only in control plane (DB)
  - Worker sandboxes are stateless
  - Artifacts pushed back via webhook
  - `.env` file copied to each sandbox during deployment

* **Deployment strategy**:
  - Deploy script creates new sandbox (dev or prod)
  - Health check validates deployment
  - Old sandbox kept as backup during deploy
  - Failed deploys trigger automatic rollback
  - See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for details

---

## Posting networks (initial set)

* **X (Twitter)**, **Reddit**, **YouTube Shorts**, **Instagram Reels** (as accounts & captchas permit)
* Start with X + Reddit for lowest friction; expand with toggles in `/settings`.

---

## Royalty‑free sources

* **Video:** [https://www.pexels.com/videos/](https://www.pexels.com/videos/) • [https://pixabay.com/videos/](https://pixabay.com/videos/) • [https://mixkit.co/free-stock-video/](https://mixkit.co/free-stock-video/)
* **Audio:** [https://pixabay.com/music/](https://pixabay.com/music/) • [https://studio.youtube.com/audio](https://studio.youtube.com/audio) • [https://mixkit.co/free-stock-music/](https://mixkit.co/free-stock-music/)

> Built‑in Pexels fetcher (`/media/fetcher.ts`) prefers official API; keyless HTML fallback provided for hack‑day.

---

## Environment & compose

### Environment Configuration

**All sensitive values (API keys, tokens, credentials) must be stored in `.env` file — never hardcoded.**

1. Copy `.env.example` to `.env`
2. Fill in your actual values
3. `.env` is gitignored for security

**Required variables in `.env`:**
- `DAYTONA_API_KEY`, `DAYTONA_API_URL` — Daytona access
- `BROWSER_USE_API_KEY` — BrowserUse automation
- `OPENAI_API_KEY`, `GEMINI_API_KEY`, `CLAUDE_API_KEY` — LLM providers
- `PEXELS_API_KEY` — Royalty-free media
- `GALILEO_AI_API_KEY` — Optional prompt evaluation
- `AUTH_BEARER_KEY` — API security
- Platform credentials (X, Reddit, Instagram, etc.)

**compose.yml** (sketch):

```yaml
version: "3.8"
services:
  api:
    image: node:20
    working_dir: /app
    volumes: ["./:/app"]
    command: sh -lc "npm i && npm run dev"
    ports: ["${EXTERNAL_API_PORT:-3000}:3000"]
    env_file: .env
    environment:
      - DB_URL=${DB_URL}
      - AUTH_BEARER_KEY=${AUTH_BEARER_KEY}
      - LLM_PROVIDER=${LLM_PROVIDER}
  
  worker-base:
    image: mcr.microsoft.com/playwright:v1.47.2-jammy
    working_dir: /app
    volumes: ["./:/app"]
    shm_size: 1g
    env_file: .env
    environment:
      - DISPLAY=:99
      - TZ=UTC
```

All environment variables are loaded from `.env` via `env_file` directive.

---

## Security & safety

* API bearer key + optional IP allowlist.
* Enforce allow/deny lists before generation/posting.
* Safety prompt gate + static regex filters (e.g., sensitive terms).
* Rate‑limit posting; emulate human behavior with BrowserUse.
* Separate credentials per platform; never hardcode in repo.

---

## Roadmap (post‑hackathon)

* Multi‑armed bandit for follow‑ups (budget to winners).
* Fine‑tuned style per network; thumbnail A/B.
* Realtime analytics dashboard.
* Auto‑spin affiliate/shop offers per intent.
* Human‑in‑the‑loop “approve queue” mode for brands.

# AutoViral — AI-Powered Instagram Trend Discovery

🌐 **Live App:** [https://app.viral.biaz.hurated.com](https://app.viral.biaz.hurated.com)  
📊 **API:** [https://viral.biaz.hurated.com](https://viral.biaz.hurated.com)

**AutoViral** discovers Instagram trends in real-time using Browser Use Cloud, scores them by engagement velocity, and provides a REST API for building viral content automation systems.

##  Current Status: Phase 1 Complete ✅

**What's Working:**
- ✅ Real Instagram trend discovery every 1-5 minutes
- ✅ Browser Use Cloud integration (managed browser automation)
- ✅ Automatic velocity scoring (speed + engagement)
- ✅ REST API with enhanced fields (media, posts, platform data)
- ✅ Deployed and running 24/7 at `viral.biaz.hurated.com`
- ✅ 10 real trends discovered per cycle

**Tech Stack:**
- **Discovery:** Browser Use Cloud API (no login, public Instagram explore)
- **API:** Express.js + SQLite + Prisma
- **Worker:** Node.js scheduler with configurable intervals
- **Deployment:** Docker Compose on `biaz.hurated.com`

> **Philosophy:** Speed beats volume. We catch trends **early** using real-time scraping.

---

## Quick Start

### Prerequisites

1. **API Keys:**
   - Browser Use Cloud API key → https://cloud.browser-use.com
   
2. **Local Development:**
   - Node.js 20+
   - Docker & Docker Compose

3. **Deployment:**
   - SSH access to your server
   - Git configured

### Installation

```bash
# 1. Clone repository
git clone https://github.com/Hack-a-tons/AutoViral
cd AutoViral

# 2. Configure environment
cp .env.example .env
# Edit .env and add your BROWSER_USE_API_KEY

# 3. Set discovery interval (optional, default: 5 minutes)
./scripts/set-discovery-interval.sh 1   # 1 minute for testing
./scripts/set-discovery-interval.sh 5   # 5 minutes for production

# 4. Deploy to server
./scripts/deploy.sh -m "Initial deployment"
```

### Monitoring

```bash
# View worker logs (real-time)
./scripts/server-logs.sh worker -f

# Check deployment status
./scripts/server-status.sh

# View discovered trends
./scripts/trends.sh

# Test API
curl https://viral.biaz.hurated.com/trends | jq .
```

---

## Architecture

```
┌─────────────────────────────────────────┐
│  AutoViral Worker (biaz.hurated.com)    │
│  - Discovers trends every 1-5 minutes    │
│  - Scores by velocity + engagement       │
│  - Reports to API                        │
└────────────┬────────────────────────────┘
             │ HTTP REST API
             ↓
┌─────────────────────────────────────────┐
│  Browser Use Cloud (api.browser-use.com) │
│  - Managed browser automation            │
│  - Scrapes Instagram explore             │
│  - Returns trending hashtags             │
│  - ~$0.01-0.05 per task                  │
└─────────────────────────────────────────┘
             │ JSON Results
             ↓
┌─────────────────────────────────────────┐
│  AutoViral API (viral.biaz.hurated.com)  │
│  - SQLite database                       │
│  - Enhanced trend data                   │
│  - Public REST endpoints                 │
└─────────────────────────────────────────┘
             │ JSON API
             ↓
┌─────────────────────────────────────────┐
│  Your Frontend App                       │
│  - Displays trends                       │
│  - Shows engagement metrics              │
│  - Real-time updates                     │
└─────────────────────────────────────────┘
```

### How Discovery Works

1. **Worker** runs on schedule (1-5 minute intervals)
2. **Creates task** via Browser Use Cloud API
3. **Browser automation** navigates Instagram explore (no login)
4. **Extracts** trending hashtags with engagement data
5. **Scores** trends by velocity (growth speed)
6. **Reports** to API via webhook
7. **Deduplicates** (same hashtag within 1 hour = skip)
8. **Stores** in database with metadata

---

## API Documentation

See **[API.md](API.md)** for complete client integration guide.

**Quick example:**
```bash
# Get recent trends
curl https://viral.biaz.hurated.com/trends?since=1h | jq .

# Response:
{
  "count": 10,
  "trends": [
    {
      "id": "uuid",
      "keyword": "#art",
      "source": "instagram",
      "score": 87,
      "metadata": {
        "postCount": 150000,
        "engagement": "high",
        "velocity": "fast"
      },
      "discoveredAt": "2025-10-19T00:07:03.833Z"
    }
  ]
}
```

---

## Scripts Reference

All scripts are in `scripts/` directory. Use `--help` for details.

### Core Scripts

| Script | Description | Example |
|--------|-------------|---------|
| `set-discovery-interval.sh` | Configure discovery frequency | `./scripts/set-discovery-interval.sh 1` |
| `deploy.sh` | Deploy to server (commit + push + docker) | `./scripts/deploy.sh -m "message"` |
| `server-logs.sh` | View service logs | `./scripts/server-logs.sh worker -f` |
| `server-status.sh` | Check deployment status | `./scripts/server-status.sh` |
| `trends.sh` | View discovered trends | `./scripts/trends.sh` |

### Discovery Interval

The discovery interval controls how often Instagram is scraped.

```bash
# During development (fast testing)
./scripts/set-discovery-interval.sh 1  # Every 1 minute

# Production (avoid rate limits)
./scripts/set-discovery-interval.sh 5  # Every 5 minutes
```

**Note:** Changes require worker restart: `ssh server "cd AutoViral && docker compose restart worker"`

---

## Environment Variables

All configuration in `.env` file (copy from `.env.example`):

**Required:**
```bash
BROWSER_USE_API_KEY=bu_xxx...  # From cloud.browser-use.com
DATABASE_URL=file:../data/autoviral.db
API_URL=http://api:3000
DISCOVERY_INTERVAL_MINUTES=5
```

**Optional (Phase 2+):**
```bash
INSTAGRAM_USERNAME=username    # Not currently used (no login)
INSTAGRAM_PASSWORD=password    # Not currently used
AUTH_BEARER_KEY=secret         # Future: API authentication
```

---

## Data Model

### Trend Object

```typescript
{
  id: string;              // UUID
  keyword: string;         // e.g., "#art"
  source: "instagram";     // Always instagram for Phase 1
  status: string;          // "discovering" | "selected" | "blocked" | "stopped"
  score: number;           // 0-100 velocity score
  reason: string;          // Why this score
  
  // Enhanced fields (Phase 1 complete)
  thumbnailUrl?: string;   // Main image
  metadata: object;        // postCount, engagement, velocity, hashtags
  media?: object;          // thumbnailUrl, videoUrl, imageUrls
  examplePosts?: array;    // [{creator, thumbnailUrl, postUrl, likes, views}]
  platformData?: object;   // instagram: {hashtagUrl, postCount, avgEngagement}
  analysis?: object;       // category, difficulty, bestTimes
  
  discoveredAt: Date;
  createdAt: Date;
  updatedAt: Date;
}
```

---

## Roadmap

### Phase 1: Discovery ✅ COMPLETE (Oct 2025)
- ✅ Browser Use Cloud integration
- ✅ Real Instagram scraping
- ✅ Velocity scoring
- ✅ REST API with enhanced fields
- ✅ Deployed and operational

### Phase 2: Selection Engine (Next)
- ⏳ LLM-powered trend analysis
- ⏳ Content safety filtering
- ⏳ Trend prioritization
- ⏳ Human veto system

### Phase 3: Content Generation (Future)
- ⏳ Video generation (ffmpeg)
- ⏳ AI script writing
- ⏳ Subtitle generation
- ⏳ Thumbnail creation

### Phase 4: Posting & Monetization (Future)
- ⏳ Multi-platform posting (Instagram, TikTok, YouTube)
- ⏳ Performance tracking
- ⏳ A/B testing
- ⏳ Affiliate integration

---

## Troubleshooting

### Worker not discovering trends

```bash
# Check logs
./scripts/server-logs.sh worker --tail=50

# Look for:
# [Browser Use Cloud] Task created: <uuid>
# [Browser Use Cloud] Received 10 raw trends
# [Reported] #hashtag - Trend created
```

### API not responding

```bash
# Check API health
curl https://viral.biaz.hurated.com/health

# Check status
./scripts/server-status.sh
```

### Discovery too slow/fast

```bash
# Adjust interval
./scripts/set-discovery-interval.sh <minutes>

# Restart worker
ssh biaz.hurated.com "cd AutoViral && docker compose restart worker"
```

---

## Cost Estimate

**Browser Use Cloud:**
- ~$0.01-0.05 per scraping task
- 10 discoveries/hour = ~$2.40-12/day
- Monthly: ~$72-360

**Server:**
- $10-50/month (depending on provider)

**Total:** ~$82-410/month for 24/7 trend discovery

---

## Documentation

- **[API.md](API.md)** - Complete API reference for client apps
- **[TODO.md](TODO.md)** - Detailed roadmap and future phases

---

## Support

- **Issues:** https://github.com/Hack-a-tons/AutoViral/issues
- **Live API:** https://viral.biaz.hurated.com
- **Frontend:** https://app.viral.biaz.hurated.com

**Created with ❤️ for catching viral trends before they explode**

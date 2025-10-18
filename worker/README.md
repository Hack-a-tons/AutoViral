# AutoViral Worker - Instagram Discovery

Discovers fast-moving trends on Instagram using Browser Use + Daytona sandboxes.

## Quick Start

### 1. Install Dependencies
```bash
npm install
```

### 2. Configure Environment
Ensure `.env` has:
- `BROWSER_USE_API_KEY` - Browser Use API key
- `INSTAGRAM_USERNAME` - Instagram login
- `INSTAGRAM_PASSWORD` - Instagram password
- `API_URL` - API endpoint (http://api:3000)
- `AUTH_BEARER_KEY` - API authentication
- `DISCOVERY_INTERVAL_MINUTES` - Discovery frequency (default: 5)

### 3. Start Worker
```bash
npm start
```

## How It Works

1. **Periodic Discovery**: Runs every 5 minutes (configurable)
2. **Browser Use**: Creates Daytona sandbox with browser automation
3. **Instagram Scraping**: Logs in and analyzes Explore/Trending
4. **Velocity Calculation**: Identifies FAST-moving trends (speed > volume)
5. **Report to API**: Sends discovered trends via webhook

## Focus: Speed Over Volume

The worker prioritizes:
- ✅ Fast-moving trends (high velocity)
- ✅ Fresh content (recent activity)
- ✅ Engagement spike detection
- ❌ Not just high post counts

## Discovery Process

```javascript
// Example trend structure
{
  keyword: "#AITrends",
  source: "instagram",
  score: 95.0,
  reason: "High velocity growth in last hour",
  metadata: {
    postCount: 15000,
    engagement: "high",
    velocity: "fast",
    recentPosts: 1250,
    hashtags: ["#AI", "#Technology"]
  }
}
```

## Development

```bash
# Run discovery once
npm run discover

# Auto-reload on changes
npm run dev
```

## Implementation Notes

**Current Status**: Mock implementation
**TODO**: Integrate actual Browser Use SDK

Replace mock data in `src/discover-instagram.js` with:
```javascript
import { BrowserUse } from '@daytona-ai/browser-use';

const browser = new BrowserUse({
  apiKey: BROWSER_USE_API_KEY,
  sandbox: {
    provider: 'daytona',
    credentials: {
      username: INSTAGRAM_USERNAME,
      password: INSTAGRAM_PASSWORD
    }
  }
});

const trends = await browser.execute({
  task: 'Extract trending hashtags from Instagram Explore',
  selectors: {
    hashtags: 'a[href*="/explore/tags/"]',
    metrics: '.engagement-data'
  }
});
```

## Deduplication

- Checks for duplicates within 1-hour windows
- Same keyword + source = deduplicated
- API handles duplicate detection

## Error Handling

- Network errors: Retry with backoff
- Auth failures: Log and skip cycle
- API errors: Log but continue

# AutoViral API Documentation

Complete API reference for integrating with AutoViral trend discovery system.

## Base URLs

**Production:**
```
https://viral.biaz.hurated.com
```

**Local Development:**
```
http://localhost:33000
```

## Authentication

Currently **public** - no authentication required.

**Future:** Bearer token authentication will be added in Phase 2:
```http
Authorization: Bearer YOUR_AUTH_TOKEN
```

---

## Endpoints

### Health Check

```http
GET /health
```

Returns API status and database connection.

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2025-10-19T00:15:00.000Z",
  "database": "connected"
}
```

**Example:**
```bash
curl https://viral.biaz.hurated.com/health
```

---

### Get Trends

```http
GET /trends
```

Retrieve discovered Instagram trends with optional filtering.

**Query Parameters:**

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `status` | string | Filter by status | `discovering`, `selected`, `blocked`, `stopped` |
| `source` | string | Filter by source | `instagram` (only option currently) |
| `since` | string | Time range | `1h`, `30m`, `2d`, `7d` |
| `limit` | number | Max results (default: 50) | `10`, `100` |

**Examples:**
```bash
# Get all trends from last hour
curl "https://viral.biaz.hurated.com/trends?since=1h"

# Get Instagram trends only (all are Instagram in Phase 1)
curl "https://viral.biaz.hurated.com/trends?source=instagram"

# Get top 10 discovering trends
curl "https://viral.biaz.hurated.com/trends?status=discovering&limit=10"

# Get recent trends with jq formatting
curl "https://viral.biaz.hurated.com/trends?since=30m" | jq .
```

**Response:**
```json
{
  "count": 10,
  "trends": [
    {
      "id": "9f1261b6-36b5-47ed-b5bb-67dd3fc0af4f",
      "keyword": "#art",
      "source": "instagram",
      "status": "discovering",
      "score": 87,
      "reason": "High engagement velocity",
      "metadata": {
        "postCount": 150000,
        "engagement": "high",
        "velocity": "fast",
        "hashtags": ["#art", "#artist", "#artwork"]
      },
      "thumbnailUrl": "https://example.com/thumb.jpg",
      "media": {
        "thumbnailUrl": "https://example.com/thumb.jpg",
        "imageUrls": [
          "https://example.com/img1.jpg",
          "https://example.com/img2.jpg"
        ]
      },
      "examplePosts": [
        {
          "creator": "@artist_name",
          "thumbnailUrl": "https://example.com/post.jpg",
          "postUrl": "https://instagram.com/p/ABC123/",
          "likes": 15000,
          "views": 250000,
          "caption": "Check out this amazing art..."
        }
      ],
      "platformData": {
        "instagram": {
          "hashtagUrl": "https://instagram.com/explore/tags/art/",
          "postCount": 150000,
          "avgEngagement": 8.5
        }
      },
      "analysis": {
        "category": "art",
        "difficulty": "medium",
        "bestTimes": ["evening", "weekend"]
      },
      "discoveredAt": "2025-10-19T00:07:03.833Z",
      "createdAt": "2025-10-19T00:07:03.833Z",
      "updatedAt": "2025-10-19T00:07:03.833Z"
    }
  ]
}
```

---

### Get Single Trend

```http
GET /trends/:id
```

Retrieve detailed information about a specific trend.

**Parameters:**
- `id` - Trend UUID

**Example:**
```bash
curl "https://viral.biaz.hurated.com/trends/9f1261b6-36b5-47ed-b5bb-67dd3fc0af4f"
```

**Response:**
```json
{
  "id": "9f1261b6-36b5-47ed-b5bb-67dd3fc0af4f",
  "keyword": "#art",
  "source": "instagram",
  "status": "discovering",
  "score": 87,
  "reason": "High engagement velocity",
  "metadata": { ... },
  "thumbnailUrl": "...",
  "media": { ... },
  "examplePosts": [...],
  "platformData": { ... },
  "analysis": { ... },
  "discoveredAt": "2025-10-19T00:07:03.833Z",
  "createdAt": "2025-10-19T00:07:03.833Z",
  "updatedAt": "2025-10-19T00:07:03.833Z"
}
```

**Error Response (404):**
```json
{
  "error": "Trend not found"
}
```

---

### Report New Trend (Webhook)

```http
POST /webhook/trend
```

**Internal use only** - Used by discovery worker to report new trends.

**Request Body:**
```json
{
  "keyword": "#trending",
  "source": "instagram",
  "score": 85.5,
  "reason": "Rapid engagement increase",
  "metadata": {
    "postCount": 5000,
    "engagement": "high",
    "velocity": "fast",
    "hashtags": ["#trending", "#viral"]
  },
  "thumbnailUrl": "https://example.com/thumb.jpg",
  "media": {
    "thumbnailUrl": "https://example.com/thumb.jpg",
    "imageUrls": ["url1", "url2"]
  },
  "examplePosts": [
    {
      "creator": "@user",
      "thumbnailUrl": "https://example.com/post.jpg",
      "postUrl": "https://instagram.com/p/ABC/",
      "likes": 15000,
      "views": 250000
    }
  ]
}
```

**Response (201 Created):**
```json
{
  "message": "Trend created",
  "id": "uuid"
}
```

**Response (200 Duplicate):**
```json
{
  "message": "Duplicate trend (already exists)",
  "id": "existing-uuid"
}
```

**Duplicate Detection:**
Same keyword from same source within last hour = duplicate.

---

### Stop Trend

```http
POST /stop/trend/:id
```

Mark a trend as stopped (no further processing).

**Parameters:**
- `id` - Trend UUID

**Example:**
```bash
curl -X POST "https://viral.biaz.hurated.com/stop/trend/abc-123"
```

**Response:**
```json
{
  "message": "Trend stopped",
  "id": "abc-123"
}
```

---

### Stop by Keyword

```http
POST /stop/keyword
```

Stop all active trends matching a keyword.

**Request Body:**
```json
{
  "keyword": "#stopthis"
}
```

**Example:**
```bash
curl -X POST "https://viral.biaz.hurated.com/stop/keyword" \
  -H "Content-Type: application/json" \
  -d '{"keyword": "#stopthis"}'
```

**Response:**
```json
{
  "message": "Stopped 3 trends with keyword: #stopthis"
}
```

---

## Data Models

### Trend Object

Complete trend structure with all enhanced fields:

```typescript
interface Trend {
  // Core fields
  id: string;                    // UUID
  keyword: string;               // e.g., "#art"
  source: "instagram";           // Source platform
  status: TrendStatus;           // Current state
  score: number;                 // 0-100 velocity score
  reason: string;                // Scoring explanation
  
  // Enhanced fields (Phase 1)
  thumbnailUrl?: string;         // Main thumbnail image
  
  metadata: {
    postCount: number;           // Total posts with hashtag
    engagement: string;          // "low" | "medium" | "high" | "very-high"
    velocity: string;            // "slow" | "medium" | "fast" | "very-fast"
    hashtags: string[];          // Related hashtags
    avgLikes?: number;           // Average likes per post
    avgViews?: number;           // Average views per post
    topCreators?: string[];      // Top creators using trend
    peakHours?: string[];        // Best posting times
  };
  
  media?: {
    thumbnailUrl: string;        // Main thumbnail
    videoUrl?: string;           // Video if available
    imageUrls?: string[];        // Gallery images
  };
  
  examplePosts?: Array<{
    id?: string;                 // Post ID
    creator: string;             // @username
    thumbnailUrl: string;        // Post thumbnail
    postUrl: string;             // Direct link
    likes: number;               // Like count
    views: number;               // View count
    caption?: string;            // Post caption
  }>;
  
  platformData?: {
    instagram?: {
      hashtagUrl: string;        // Direct hashtag link
      postCount: number;         // Platform-specific count
      avgEngagement: number;     // Engagement rate
    };
    tiktok?: {
      hashtagUrl: string;
      postCount: number;
      avgEngagement: number;
    };
  };
  
  analysis?: {
    category: string;            // "art", "fashion", "tech", etc.
    difficulty: string;          // "easy" | "medium" | "hard"
    equipment?: string[];        // ["smartphone", "ring light"]
    duration?: string;           // "15-30s"
    bestTimes?: string[];        // ["evening", "weekend"]
    aiSummary?: string;          // AI-generated insight
  };
  
  // Timestamps
  discoveredAt: string;          // ISO 8601
  createdAt: string;             // ISO 8601
  updatedAt: string;             // ISO 8601
}

type TrendStatus = "discovering" | "selected" | "blocked" | "stopped";
```

---

## Client Integration Examples

### JavaScript/TypeScript

```typescript
// Fetch recent trends
async function getRecentTrends() {
  const response = await fetch(
    'https://viral.biaz.hurated.com/trends?since=1h&limit=20'
  );
  const data = await response.json();
  return data.trends;
}

// Get specific trend
async function getTrend(id: string) {
  const response = await fetch(
    `https://viral.biaz.hurated.com/trends/${id}`
  );
  return await response.json();
}

// Stop a trend
async function stopTrend(id: string) {
  const response = await fetch(
    `https://viral.biaz.hurated.com/stop/trend/${id}`,
    { method: 'POST' }
  );
  return await response.json();
}
```

### Python

```python
import requests

# Fetch recent trends
def get_recent_trends():
    response = requests.get(
        'https://viral.biaz.hurated.com/trends',
        params={'since': '1h', 'limit': 20}
    )
    return response.json()['trends']

# Get specific trend
def get_trend(trend_id):
    response = requests.get(
        f'https://viral.biaz.hurated.com/trends/{trend_id}'
    )
    return response.json()

# Stop a trend
def stop_trend(trend_id):
    response = requests.post(
        f'https://viral.biaz.hurated.com/stop/trend/{trend_id}'
    )
    return response.json()
```

### cURL

```bash
# Get recent trends
curl "https://viral.biaz.hurated.com/trends?since=1h&limit=10" | jq .

# Get specific trend
curl "https://viral.biaz.hurated.com/trends/TREND_ID" | jq .

# Stop trend
curl -X POST "https://viral.biaz.hurated.com/stop/trend/TREND_ID"

# Stop by keyword
curl -X POST "https://viral.biaz.hurated.com/stop/keyword" \
  -H "Content-Type: application/json" \
  -d '{"keyword": "#stopthis"}'
```

---

## Rate Limiting

**Current:** No rate limiting (Phase 1)

**Future (Phase 2):**
- 100 requests/minute per IP
- 1000 requests/hour per API key

---

## Error Responses

### 400 Bad Request
```json
{
  "error": "keyword and source are required"
}
```

### 404 Not Found
```json
{
  "error": "Trend not found"
}
```

### 500 Internal Server Error
```json
{
  "error": "Failed to fetch trends"
}
```

---

## Discovery Worker Behavior

The worker automatically discovers trends with this flow:

1. **Schedule:** Runs every 1-5 minutes (configurable)
2. **Browser Use:** Creates task via Browser Use Cloud API
3. **Instagram:** Scrapes public explore page (no login)
4. **Extract:** Finds trending hashtags with engagement data
5. **Score:** Calculates velocity (0-100)
6. **Report:** POST to `/webhook/trend`
7. **Dedupe:** Skips if same hashtag reported < 1 hour ago

**Focus:** SPEED > Volume
- Prioritizes fast-moving trends
- Early detection beats comprehensive coverage
- Velocity scoring highlights rapid growth

---

## Environment Configuration

See `.env.example` for all variables.

**Required for API:**
```bash
DATABASE_URL=file:../data/autoviral.db
PORT=3000
```

**Required for Worker:**
```bash
BROWSER_USE_API_KEY=bu_xxx...
API_URL=http://api:3000
DISCOVERY_INTERVAL_MINUTES=5
```

---

## Webhooks & Events

**Future (Phase 2):** Subscribe to trend events

```http
POST /webhooks/subscribe
```

```json
{
  "url": "https://your-app.com/webhook",
  "events": ["trend.discovered", "trend.selected", "trend.stopped"]
}
```

---

## Support

- **API Issues:** https://github.com/Hack-a-tons/AutoViral/issues
- **Live API:** https://viral.biaz.hurated.com
- **Health Check:** https://viral.biaz.hurated.com/health

**Last Updated:** October 19, 2025

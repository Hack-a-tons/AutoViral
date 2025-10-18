# AutoViral API Documentation

## Base URL
```
http://localhost:3000
```

## Authentication
All endpoints (except `/health`) require Bearer token authentication:
```
Authorization: Bearer YOUR_AUTH_BEARER_KEY
```

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
  "timestamp": "2025-10-18T22:30:00.000Z",
  "database": "connected"
}
```

---

### Get Trends
```http
GET /trends
```

**Query Parameters:**
- `status` (optional): Filter by status (`discovering`, `selected`, `blocked`, `stopped`)
- `source` (optional): Filter by source (`instagram`, `x`, `reddit`)
- `since` (optional): Time range (e.g., `1h`, `30m`, `2d`)
- `limit` (optional): Max results (default: 50)

**Examples:**
```bash
# Get all trends from last hour
curl -H "Authorization: Bearer YOUR_KEY" \
  "http://localhost:3000/trends?since=1h"

# Get Instagram trends only
curl -H "Authorization: Bearer YOUR_KEY" \
  "http://localhost:3000/trends?source=instagram"

# Get discovering trends
curl -H "Authorization: Bearer YOUR_KEY" \
  "http://localhost:3000/trends?status=discovering&limit=10"
```

**Response:**
```json
{
  "count": 2,
  "trends": [
    {
      "id": "uuid",
      "keyword": "#AITrends",
      "source": "instagram",
      "status": "discovering",
      "score": 95.0,
      "reason": "High velocity growth in last hour",
      "metadata": {
        "postCount": 15000,
        "engagement": "high",
        "velocity": "fast",
        "hashtags": ["#AI", "#Technology"]
      },
      "discoveredAt": "2025-10-18T22:25:00.000Z",
      "createdAt": "2025-10-18T22:25:00.000Z",
      "updatedAt": "2025-10-18T22:25:00.000Z"
    }
  ]
}
```

---

### Get Single Trend
```http
GET /trends/:id
```

**Example:**
```bash
curl -H "Authorization: Bearer YOUR_KEY" \
  "http://localhost:3000/trends/abc-123"
```

---

### Report New Trend (Webhook)
```http
POST /webhook/trend
```

Used by discovery workers to report new trends.

**Request Body:**
```json
{
  "keyword": "#TrendingTopic",
  "source": "instagram",
  "score": 85.5,
  "reason": "Rapid engagement increase",
  "metadata": {
    "postCount": 5000,
    "engagement": "high",
    "velocity": "fast"
  }
}
```

**Response:**
```json
{
  "message": "Trend created",
  "id": "uuid"
}
```

**Duplicate Detection:**
If the same keyword from the same source was reported in the last hour, returns:
```json
{
  "message": "Duplicate trend (already exists)",
  "id": "existing-uuid"
}
```

---

### Stop Trend
```http
POST /stop/trend/:id
```

Marks a trend as stopped (no further processing).

**Example:**
```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_KEY" \
  "http://localhost:3000/stop/trend/abc-123"
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

Stops all active trends matching a keyword.

**Request Body:**
```json
{
  "keyword": "#TrendToStop"
}
```

**Response:**
```json
{
  "message": "Stopped 3 trends with keyword: #TrendToStop"
}
```

---

## Data Model

### Trend Object
```typescript
{
  id: string;           // UUID
  keyword: string;      // Hashtag or keyword
  source: string;       // "instagram", "x", "reddit"
  status: string;       // "discovering"|"selected"|"blocked"|"stopped"
  score: number;        // 0-100, velocity/engagement score
  reason: string;       // Why selected/blocked
  metadata: object;     // Extra data (engagement, hashtags, etc.)
  discoveredAt: Date;   // When first discovered
  createdAt: Date;
  updatedAt: Date;
}
```

---

## Discovery Worker

The worker automatically discovers trending topics on Instagram every 5 minutes (configurable via `DISCOVERY_INTERVAL_MINUTES`).

**How it works:**
1. Uses Browser Use API with Daytona sandboxes
2. Logs into Instagram with configured credentials
3. Analyzes Explore page for trending hashtags
4. Calculates velocity (how fast topics are moving)
5. Reports trends via `POST /webhook/trend`

**Focus:** SPEED > Volume
- Prioritizes fast-moving, fresh trends
- Deduplicates within 1-hour windows
- Tracks engagement velocity, not just volume

---

## Quick Start

### 1. Initialize Database
```bash
cd api
npm install
npx prisma db push
```

### 2. Start API
```bash
npm start
# or with auto-reload:
npm run dev
```

### 3. Start Worker
```bash
cd ../worker
npm install
npm start
```

### 4. Test API
```bash
# Health check (no auth required)
curl http://localhost:3000/health

# Get trends (requires auth)
curl -H "Authorization: Bearer your_auth_key" \
  "http://localhost:3000/trends?since=1h"
```

---

## Error Responses

### 401 Unauthorized
```json
{
  "error": "Missing or invalid authorization header"
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

## Environment Variables

See `.env.example` for all required configuration.

**Key variables:**
- `AUTH_BEARER_KEY` - API authentication token
- `DATABASE_URL` - SQLite database path
- `BROWSER_USE_API_KEY` - Browser Use API key
- `INSTAGRAM_USERNAME` - Instagram login
- `INSTAGRAM_PASSWORD` - Instagram password
- `DISCOVERY_INTERVAL_MINUTES` - Discovery frequency (default: 5)

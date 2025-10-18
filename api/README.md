# AutoViral API - Instagram Trend Discovery

Simple Express API that discovers fast-moving trends on Instagram using Browser Use.

## Quick Start

### 1. Install Dependencies
```bash
npm install
```

### 2. Initialize Database
```bash
npx prisma db push
```

This creates the SQLite database and tables.

### 3. Start Server
```bash
npm start
```

API will be available at http://localhost:3000

## Endpoints

- `GET /health` - Health check
- `GET /trends` - Get discovered trends
- `POST /webhook/trend` - Report new trend (used by worker)
- `POST /stop/trend/:id` - Stop a trend
- `POST /stop/keyword` - Stop all trends by keyword

See [../API.md](../API.md) for full API documentation.

## Environment Variables

Required in `.env`:
- `DATABASE_URL` - Path to SQLite database
- `AUTH_BEARER_KEY` - API authentication token
- `PORT` - Server port (default: 3000)

## Database Schema

### Trend
- `id` - UUID
- `keyword` - Hashtag or topic
- `source` - "instagram"
- `status` - "discovering", "selected", "blocked", "stopped"
- `score` - Velocity/engagement score (0-100)
- `reason` - Why it was flagged
- `metadata` - JSON with engagement details
- `discoveredAt` - Discovery timestamp

## Development

```bash
# Auto-reload on changes
npm run dev

# View database
npx prisma studio
```

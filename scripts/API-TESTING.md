# API Testing Scripts

Quick scripts to test the AutoViral API from external networks.

## Quick Test (One Command)

```bash
./scripts/quick-test.sh
```

Shows: health status, trend count, and top trend.

## Full Test Suite

```bash
./scripts/test-api.sh
```

Runs comprehensive tests:
1. Health check
2. Get all trends
3. Get recent trends (last hour)
4. Filter by source (Instagram)

## API Examples

```bash
./scripts/api-examples.sh
```

Shows example commands for all endpoints with copy-paste ready code.

## Manual Testing

### Health Check
```bash
curl https://viral.biaz.hurated.com/health | jq .
```

### Get All Trends
```bash
curl https://viral.biaz.hurated.com/trends | jq .
```

### Get Recent Trends
```bash
curl 'https://viral.biaz.hurated.com/trends?since=1h' | jq .
```

### Filter by Source
```bash
curl 'https://viral.biaz.hurated.com/trends?source=instagram' | jq .
```

### Get Top 5 Trends
```bash
curl 'https://viral.biaz.hurated.com/trends?limit=5' | jq .
```

### Get Single Trend
```bash
# Replace TREND_ID with actual ID
curl https://viral.biaz.hurated.com/trends/TREND_ID | jq .
```

### Report New Trend (Webhook)
```bash
curl -X POST https://viral.biaz.hurated.com/webhook/trend \
  -H "Content-Type: application/json" \
  -d '{
    "keyword": "#TestTrend",
    "source": "instagram",
    "score": 90.0,
    "reason": "Manual test",
    "metadata": {
      "engagement": "high",
      "velocity": "fast"
    }
  }'
```

### Stop a Trend
```bash
# Replace TREND_ID with actual ID
curl -X POST https://viral.biaz.hurated.com/stop/trend/TREND_ID
```

### Stop by Keyword
```bash
curl -X POST https://viral.biaz.hurated.com/stop/keyword \
  -H "Content-Type: application/json" \
  -d '{"keyword": "#TrendToStop"}'
```

## Watch for New Trends

```bash
# Check every 10 seconds
watch -n 10 "curl -s 'https://viral.biaz.hurated.com/trends?since=5m' | jq '.count'"

# Monitor top trend
watch -n 5 "curl -s 'https://viral.biaz.hurated.com/trends?limit=1' | jq '.trends[0] | {keyword, score, velocity: .metadata.velocity}'"
```

## Response Format

### Health
```json
{
  "status": "ok",
  "timestamp": "2025-10-18T22:50:00.000Z",
  "database": "connected"
}
```

### Trends
```json
{
  "count": 2,
  "trends": [
    {
      "id": "uuid",
      "keyword": "#AITrends",
      "source": "instagram",
      "status": "discovering",
      "score": 95,
      "reason": "High velocity growth",
      "metadata": {
        "postCount": 15000,
        "engagement": "high",
        "velocity": "fast",
        "hashtags": ["#AI", "#Tech"]
      },
      "discoveredAt": "2025-10-18T22:45:00.000Z",
      "createdAt": "2025-10-18T22:45:00.000Z",
      "updatedAt": "2025-10-18T22:45:00.000Z"
    }
  ]
}
```

## Query Parameters

- `since` - Time range: `1h`, `30m`, `2d`, `7d`
- `status` - Filter: `discovering`, `selected`, `blocked`, `stopped`
- `source` - Filter: `instagram`, `x`, `reddit`
- `limit` - Max results (default: 50)

## No Authentication Required

All endpoints are publicly accessible. No API keys or Bearer tokens needed.

## Setting Custom API URL

```bash
# For local testing
export API_URL=http://localhost:33000
./scripts/test-api.sh

# For production (default)
export API_URL=https://viral.biaz.hurated.com
./scripts/test-api.sh
```

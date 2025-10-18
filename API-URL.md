# AutoViral API URL Configuration

## Public API Endpoint

**🌐 https://viral.biaz.hurated.com**

## Configuration

### Backend
- **Internal Port:** 33000
- **Server:** biaz.hurated.com:33000
- **Protocol:** HTTP (internal)

### Public Access
- **Domain:** viral.biaz.hurated.com
- **Protocol:** HTTPS (via reverse proxy)
- **SSL:** Required (Let's Encrypt recommended)

## Quick Test

```bash
# Health check
curl https://viral.biaz.hurated.com/health

# Get trends
curl https://viral.biaz.hurated.com/trends

# Filter trends
curl 'https://viral.biaz.hurated.com/trends?since=1h&source=instagram'
```

## Test Scripts

All test scripts now default to `https://viral.biaz.hurated.com`:

```bash
# Quick test
./scripts/quick-test.sh

# Full test suite
./scripts/test-api.sh

# See all examples
./scripts/api-examples.sh
```

## JavaScript/Frontend Example

```javascript
// Fetch trending topics
fetch('https://viral.biaz.hurated.com/trends?since=1h')
  .then(res => res.json())
  .then(data => {
    console.log(`Found ${data.count} trends`);
    data.trends.forEach(trend => {
      console.log(`${trend.keyword}: ${trend.score} (${trend.metadata.velocity})`);
    });
  });
```

## Python Example

```python
import requests

# Get Instagram trends from last hour
response = requests.get('https://viral.biaz.hurated.com/trends', params={
    'source': 'instagram',
    'since': '1h'
})

trends = response.json()['trends']
for trend in trends:
    print(f"{trend['keyword']}: {trend['score']} - {trend['metadata']['velocity']}")
```

## cURL Examples

```bash
# Get top 5 trends
curl 'https://viral.biaz.hurated.com/trends?limit=5' | jq '.trends[] | {keyword, score}'

# Monitor for new trends (every 10 seconds)
watch -n 10 "curl -s 'https://viral.biaz.hurated.com/trends?since=5m' | jq '.count'"

# Report a new trend
curl -X POST https://viral.biaz.hurated.com/webhook/trend \
  -H "Content-Type: application/json" \
  -d '{
    "keyword": "#AIHype",
    "source": "instagram",
    "score": 92,
    "metadata": {"velocity": "fast"}
  }'
```

## No Authentication Required

All endpoints are public - no API keys or tokens needed! 🎉

## Available Endpoints

- `GET /health` - API health check
- `GET /trends` - Get all trends (supports filtering)
- `GET /trends/:id` - Get single trend by ID
- `POST /webhook/trend` - Report new trend
- `POST /stop/trend/:id` - Stop a specific trend
- `POST /stop/keyword` - Stop all trends with keyword

## Nginx Configuration (SSL)

```nginx
server {
    listen 80;
    server_name viral.biaz.hurated.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name viral.biaz.hurated.com;

    ssl_certificate /etc/letsencrypt/live/viral.biaz.hurated.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/viral.biaz.hurated.com/privkey.pem;

    location / {
        proxy_pass http://localhost:33000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Status

✅ API running on port 33000  
✅ Public domain configured: viral.biaz.hurated.com  
✅ HTTPS enabled  
✅ No authentication required  
✅ All test scripts updated  

## Documentation

- **[DEPLOYMENT-NOTES.md](DEPLOYMENT-NOTES.md)** - Server setup & SSL configuration
- **[API.md](API.md)** - Complete API reference
- **[scripts/API-TESTING.md](scripts/API-TESTING.md)** - Testing guide with examples

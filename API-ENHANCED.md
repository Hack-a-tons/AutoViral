# Enhanced API Documentation

## Overview

The AutoViral API has been enhanced to provide rich, visual trend data as specified in [API_REQUIREMENTS.md](https://github.com/Pastheroza/AutoViral/blob/main/API_REQUIREMENTS.md).

## Enhanced Trend Structure

### Full Trend Object

```json
{
  "id": "uuid",
  "keyword": "#TechNews2025",
  "source": "instagram",
  "status": "discovering",
  "score": 88.5,
  "reason": "Rapid engagement increase",
  "discoveredAt": "2025-10-18T12:00:00Z",
  "createdAt": "2025-10-18T12:00:00Z",
  "updatedAt": "2025-10-18T12:00:00Z",
  
  "thumbnailUrl": "https://example.com/trend-thumb.jpg",
  
  "metadata": {
    "postCount": 8500,
    "engagement": "very-high",
    "velocity": "very-fast",
    "recentPosts": 890,
    "hashtags": ["#Tech", "#News", "#2025"],
    "avgLikes": 12500,
    "avgViews": 180000,
    "topCreators": ["@techguru", "@newstoday"],
    "peakHours": ["18:00", "20:00"]
  },
  
  "media": {
    "thumbnailUrl": "https://example.com/thumb.jpg",
    "videoUrl": "https://example.com/video.mp4",
    "imageUrls": [
      "https://example.com/img1.jpg",
      "https://example.com/img2.jpg",
      "https://example.com/img3.jpg"
    ]
  },
  
  "examplePosts": [
    {
      "id": "post123",
      "creator": "@techguru",
      "thumbnailUrl": "https://example.com/post1.jpg",
      "postUrl": "https://instagram.com/p/ABC123/",
      "likes": 15000,
      "views": 250000,
      "caption": "Check out this amazing tech trend..."
    },
    {
      "id": "post456",
      "creator": "@newstoday",
      "thumbnailUrl": "https://example.com/post2.jpg",
      "postUrl": "https://instagram.com/p/DEF456/",
      "likes": 12000,
      "views": 180000,
      "caption": "This is huge for the tech industry..."
    }
  ],
  
  "platformData": {
    "instagram": {
      "hashtagUrl": "https://instagram.com/explore/tags/technews2025/",
      "postCount": 5000,
      "avgEngagement": 8.5
    },
    "tiktok": {
      "hashtagUrl": "https://tiktok.com/@hashtag/technews2025",
      "postCount": 3500,
      "avgEngagement": 12.3
    }
  },
  
  "analysis": {
    "category": "technology",
    "difficulty": "easy",
    "equipment": ["smartphone", "ring light"],
    "duration": "15-30s",
    "bestTimes": ["evening", "weekend"],
    "aiSummary": "This trend works because it combines tech news with quick, digestible format. Perfect for engagement during peak evening hours."
  }
}
```

## API Endpoints

### GET /trends

List trends with all enhanced data.

**Query Parameters:**
- `status` - Filter by status (discovering, selected, blocked, stopped)
- `source` - Filter by source (instagram, x, reddit)
- `since` - Time filter (1h, 30m, 2d, 7d)
- `limit` - Max results (default: 50)

**Response:**
```json
{
  "count": 2,
  "trends": [
    { /* full trend object */ },
    { /* full trend object */ }
  ]
}
```

### GET /trends/:id

Get single trend with all details.

**Response:**
```json
{
  /* full trend object */
}
```

### POST /webhook/trend

Create new trend with enhanced data (used by discovery worker).

**Request Body:**
```json
{
  "keyword": "#TechNews2025",
  "source": "instagram",
  "score": 88.5,
  "reason": "High velocity",
  "metadata": {
    "postCount": 8500,
    "engagement": "high",
    "velocity": "fast"
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
      "postUrl": "https://instagram.com/p/ABC123/",
      "likes": 15000,
      "views": 250000
    }
  ],
  "platformData": {
    "instagram": {
      "hashtagUrl": "https://instagram.com/explore/tags/trend/",
      "postCount": 5000
    }
  },
  "analysis": {
    "category": "technology",
    "difficulty": "easy",
    "bestTimes": ["evening"]
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

## Implementation Phases

### Phase 1: Quick Wins ✅ IMPLEMENTED

**Core Fields:**
- `thumbnailUrl` - Main thumbnail image
- `examplePosts` - Array of real posts using the trend
- `platformData` - Platform-specific links and metrics

**Database Schema:**
- Added 5 new fields to Trend model
- All fields are nullable (backward compatible)
- JSON fields for complex data

**API Changes:**
- Enhanced GET /trends to return all fields
- Enhanced GET /trends/:id to return all fields
- Updated POST /webhook/trend to accept all fields
- Automatic JSON parsing for all complex fields

### Phase 2: Enhanced Analytics (Ready for Implementation)

When Browser Use Cloud API is working, the worker will collect:
- Average likes/views per post
- Top creators using the trend
- Peak posting hours
- Demographics data

### Phase 3: AI Features (Future)

Can be added when LLM integration is ready:
- AI-powered trend analysis
- Content strategy recommendations
- Equipment and difficulty ratings
- Success probability predictions

## Database Schema

```prisma
model Trend {
  id            String   @id @default(uuid())
  keyword       String
  source        String
  status        String   @default("discovering")
  score         Float    @default(0.0)
  reason        String?
  
  // Enhanced fields
  thumbnailUrl  String?  // Main thumbnail
  metadata      String?  // JSON: engagement metrics
  media         String?  // JSON: media URLs
  examplePosts  String?  // JSON: example posts array
  platformData  String?  // JSON: platform-specific data
  analysis      String?  // JSON: AI analysis
  
  discoveredAt  DateTime @default(now())
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt
}
```

## Benefits for Frontend

With these enhancements, the frontend can display:

✅ **Real trend images** instead of placeholders  
✅ **Clickable links** to actual trending posts  
✅ **Creator profiles** and engagement metrics  
✅ **Platform-specific** trend data  
✅ **Multiple images/videos** per trend  
✅ **Direct hashtag links** to each platform  

## Migration Notes

### Backward Compatibility

All new fields are **nullable** and **optional**:
- Existing trends will continue to work
- Worker can gradually add enhanced data
- Frontend can handle missing fields gracefully

### Database Migration

On deployment, run:
```bash
npx prisma db push
```

This will add the new columns to existing database without data loss.

## Usage Example

### Worker Sending Enhanced Data

```javascript
await reportTrend({
  keyword: '#AITrends',
  source: 'instagram',
  score: 95,
  thumbnailUrl: 'https://instagram.com/p/ABC123/media?size=l',
  examplePosts: [
    {
      creator: '@ai_expert',
      thumbnailUrl: 'https://instagram.com/p/ABC123/media?size=m',
      postUrl: 'https://instagram.com/p/ABC123/',
      likes: 15000,
      views: 250000
    }
  ],
  platformData: {
    instagram: {
      hashtagUrl: 'https://instagram.com/explore/tags/aitrends/',
      postCount: 15000
    }
  }
});
```

### Frontend Displaying Data

```javascript
// Fetch trends
const response = await fetch('https://viral.biaz.hurated.com/trends?since=1h');
const data = await response.json();

data.trends.forEach(trend => {
  // Display thumbnail
  if (trend.thumbnailUrl) {
    showImage(trend.thumbnailUrl);
  }
  
  // Display example posts
  if (trend.examplePosts) {
    trend.examplePosts.forEach(post => {
      showPost(post.creator, post.thumbnailUrl, post.postUrl, post.likes);
    });
  }
  
  // Show platform links
  if (trend.platformData?.instagram) {
    showLink(trend.platformData.instagram.hashtagUrl);
  }
});
```

## Testing

### Create Test Trend with Enhanced Data

```bash
curl -X POST https://viral.biaz.hurated.com/webhook/trend \
  -H "Content-Type: application/json" \
  -d '{
    "keyword": "#TestTrend",
    "source": "instagram",
    "score": 90,
    "thumbnailUrl": "https://picsum.photos/400/400",
    "examplePosts": [
      {
        "creator": "@test_user",
        "thumbnailUrl": "https://picsum.photos/300/300",
        "postUrl": "https://instagram.com/p/test123/",
        "likes": 1000,
        "views": 5000
      }
    ],
    "platformData": {
      "instagram": {
        "hashtagUrl": "https://instagram.com/explore/tags/testtrend/",
        "postCount": 500
      }
    }
  }'
```

### Fetch Enhanced Trends

```bash
curl https://viral.biaz.hurated.com/trends | jq .
```

## Next Steps

1. **Deploy schema changes** ✅
2. **Test enhanced API** ✅
3. **Update worker** to collect thumbnailUrl and examplePosts from Browser Use Cloud
4. **Frontend integration** to display enhanced data
5. **Phase 2** analytics when Browser Use Cloud is working
6. **Phase 3** AI features when LLM integration is ready

## Status

✅ Database schema enhanced  
✅ API endpoints updated  
✅ JSON parsing implemented  
✅ Backward compatible  
⏳ Waiting for Browser Use Cloud API endpoint  
⏳ Worker to collect enhanced data  

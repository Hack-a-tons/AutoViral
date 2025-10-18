# Browser Use + Daytona Integration Status

## ⚠️ Current Status: MOCK DATA MODE

The AutoViral worker is currently using **mock/placeholder data** and is **NOT yet integrated with Browser Use or Daytona**. This was done to get the API and worker infrastructure running quickly for testing.

## 🔍 Monitoring Scripts

### Check Browser Use Status
```bash
./scripts/browser-use-status.sh
```
Shows:
- Environment variable configuration
- Implementation status (mock vs live)
- Package installation status
- Steps to enable live integration

### Check Daytona Sandboxes
```bash
./scripts/daytona-status.sh
```
Shows:
- Daytona CLI installation status
- Authentication status
- Active sandboxes with details
- Resource usage per sandbox

### Clean Up Sandboxes
```bash
./scripts/sandbox-cleanup.sh           # With confirmation
./scripts/sandbox-cleanup.sh --dry-run # Preview only
./scripts/sandbox-cleanup.sh --force   # No confirmation
```

## 📦 Current Implementation

### What's Working Now

✅ **API** - Fully functional trend storage and retrieval  
✅ **Worker** - Runs every 5 minutes automatically  
✅ **Database** - SQLite with Prisma  
✅ **Discovery** - Using mock Instagram trends  
✅ **Deduplication** - Prevents duplicate trends  
✅ **Kill Switch** - Stop trends by ID or keyword  

### What's Mock Data

⚠️ **Instagram Scraping** - Currently returns 2 hardcoded trends  
⚠️ **Velocity Calculation** - Placeholder values  
⚠️ **Engagement Metrics** - Static mock data  

## 🚀 Enabling Live Browser Use Integration

### Step 1: Add Browser Use Package

```bash
cd worker
npm install @daytona-ai/browser-use
```

This will add the official Browser Use SDK to your worker.

### Step 2: Update Worker Code

Edit `worker/src/discover-instagram.js`:

**Current (Mock) - Lines 51-114:**
```javascript
async function scrapeInstagramWithBrowserUse() {
  console.log('[Browser Use] Analyzing Instagram explore page...');
  
  // Mock data
  const mockTrends = [
    { keyword: '#AITrends', ... },
    { keyword: '#TechNews2025', ... }
  ];
  
  return mockTrends;
}
```

**Replace with (Live) - Uncomment lines 90-111:**
```javascript
async function scrapeInstagramWithBrowserUse() {
  const browserUse = require('@daytona-ai/browser-use');
  
  const result = await browserUse.run({
    apiKey: BROWSER_USE_API_KEY,
    task: 'Navigate to Instagram explore page and extract trending hashtags with their engagement metrics',
    credentials: {
      instagram: {
        username: INSTAGRAM_USERNAME,
        password: INSTAGRAM_PASSWORD
      }
    },
    selectors: {
      trendingHashtags: 'a[href*="/explore/tags/"]',
      postCounts: '.post-count',
      engagement: '.engagement-metrics'
    }
  });
  
  return result.trends;
}
```

### Step 3: Verify Environment Variables

Your `.env` already has these set:

```bash
BROWSER_USE_API_KEY=bu_duKNr...Avdw  ✅
DAYTONA_API_KEY=dtn_c1db...fe28     ✅
DAYTONA_API_URL=https://app.daytona.io/api  ✅
INSTAGRAM_USERNAME=dreayma2025       ✅
INSTAGRAM_PASSWORD=***               ✅
```

### Step 4: Rebuild and Deploy

```bash
# Commit changes
git add worker/
git commit -m "Enable live Browser Use integration"
git push

# Deploy to server
./scripts/deploy.sh
```

### Step 5: Monitor Live Discovery

```bash
# Watch worker logs
./scripts/server-logs.sh worker -f

# Check for new trends
./scripts/trends.sh --since 10m
```

## 🔧 Browser Use Configuration

### Task Definition

The Browser Use task should:
1. Navigate to Instagram explore page
2. Login with credentials
3. Extract trending hashtags
4. Get engagement metrics (likes, comments, shares)
5. Calculate velocity (posts per hour)
6. Return structured trend data

### Expected Response Format

```javascript
{
  trends: [
    {
      keyword: '#AITrends',
      source: 'instagram',
      score: 95.0,
      reason: 'High velocity growth',
      metadata: {
        postCount: 15000,
        engagement: 'high',
        velocity: 'fast',
        recentPosts: 1250,
        hashtags: ['#AI', '#Technology', '#Innovation']
      }
    }
  ]
}
```

## 🏗️ Daytona Sandbox Lifecycle

### Automatic Management

Browser Use automatically:
- Creates Daytona sandboxes on-demand
- Runs browser automation inside sandboxes
- Cleans up after task completion

### Manual Sandbox Management

```bash
# List active sandboxes
daytona sandbox list

# Get sandbox details
daytona sandbox info <sandbox-id>

# Delete specific sandbox
daytona sandbox delete <sandbox-id>

# Clean up ALL sandboxes
./scripts/sandbox-cleanup.sh
```

### Sandbox Configuration

From `.env`:
```bash
MAX_SANDBOX_LIFETIME_MINUTES=30      # Auto-cleanup after 30 min
SANDBOX_CLEANUP_INTERVAL_MINUTES=5   # Check every 5 min
```

## 📊 Monitoring & Debugging

### Check Integration Status
```bash
./scripts/browser-use-status.sh
```

### View Worker Activity
```bash
# Live logs
./scripts/server-logs.sh worker -f

# Last 50 lines
./scripts/server-logs.sh worker --tail=50
```

### Check API Trends
```bash
# All trends
./scripts/trends.sh

# Recent trends
./scripts/trends.sh --since 30m

# By source
./scripts/trends.sh --source instagram
```

### Monitor Sandboxes
```bash
# Check active sandboxes
./scripts/daytona-status.sh

# Clean up if needed
./scripts/sandbox-cleanup.sh --dry-run  # Preview
./scripts/sandbox-cleanup.sh            # Execute
```

## 🐛 Troubleshooting

### Worker Logs Show Errors

```bash
# Check worker status
./scripts/server-logs.sh worker --tail=100

# Common issues:
# - Authentication failed: Check INSTAGRAM_USERNAME/PASSWORD
# - Browser Use API error: Check BROWSER_USE_API_KEY
# - Sandbox timeout: Increase MAX_SANDBOX_LIFETIME_MINUTES
```

### No New Trends Appearing

```bash
# Check if worker is running
ssh biaz.hurated.com "docker ps | grep autoviral-worker"

# Check discovery interval
grep DISCOVERY_INTERVAL_MINUTES .env

# Force a discovery cycle (restart worker)
ssh biaz.hurated.com "cd AutoViral && docker compose restart worker"
```

### Too Many Sandboxes

```bash
# Check sandbox count
./scripts/daytona-status.sh

# Clean up old sandboxes
./scripts/sandbox-cleanup.sh
```

## 📈 Performance Optimization

### Reduce Sandbox Usage

1. **Increase discovery interval**
   ```bash
   # .env
   DISCOVERY_INTERVAL_MINUTES=10  # Instead of 5
   ```

2. **Batch multiple tasks per sandbox**
   - Modify worker to discover multiple platforms in one session

3. **Reuse sandboxes**
   - Keep sandboxes alive between discovery cycles
   - Add sandbox pooling

### Improve Discovery Speed

1. **Parallel discovery**
   - Run Instagram, X, Reddit in parallel
   - Use multiple sandboxes simultaneously

2. **Cache results**
   - Store trend data temporarily
   - Only fetch when significantly changed

## 🎯 Next Steps

### Phase 1: Enable Browser Use (Current)
- [ ] Add `@daytona-ai/browser-use` package
- [ ] Update worker code (uncomment integration)
- [ ] Test with single Instagram scrape
- [ ] Deploy and monitor

### Phase 2: Optimize Discovery
- [ ] Fine-tune selectors for Instagram
- [ ] Add velocity calculation algorithm
- [ ] Implement engagement scoring
- [ ] Add error retry logic

### Phase 3: Expand Platforms
- [ ] Add X (Twitter) discovery
- [ ] Add Reddit discovery
- [ ] Implement multi-platform orchestration

### Phase 4: Production Hardening
- [ ] Add rate limiting
- [ ] Implement sandbox pooling
- [ ] Add comprehensive error handling
- [ ] Set up alerts and monitoring

## 📚 Documentation References

- **Browser Use Docs**: https://docs.daytona.io/browser-use
- **Daytona API Docs**: https://docs.daytona.io/api
- **Instagram Scraping Best Practices**: (See Browser Use examples)

## ✅ Summary

**Current State:**
- ✅ Infrastructure fully deployed
- ✅ API working at https://viral.biaz.hurated.com
- ✅ Worker running every 5 minutes
- ⚠️ Using mock data (not live scraping)

**To Enable Live Discovery:**
1. Install `@daytona-ai/browser-use` package
2. Uncomment Browser Use code in worker
3. Redeploy
4. Monitor with `./scripts/browser-use-status.sh`

**Monitoring Scripts:**
- `./scripts/browser-use-status.sh` - Integration status
- `./scripts/daytona-status.sh` - Active sandboxes
- `./scripts/sandbox-cleanup.sh` - Clean up sandboxes
- `./scripts/trends.sh` - View discovered trends

**Yes, `sandbox-cleanup.sh` is still useful** - it will be needed once you enable live Browser Use to clean up any orphaned sandboxes.

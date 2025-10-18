# Browser Use API Configuration

## Current Status

✅ **Real Browser Use code deployed** (not mock data)  
⚠️ **API endpoint needs verification**

## Current Configuration

### Endpoint Used
```javascript
POST https://api.browseruse.com/v1/execute
```

### Authentication
```javascript
headers: {
  'Authorization': 'Bearer ${BROWSER_USE_API_KEY}'
}
```

### Request Payload
```javascript
{
  task: "Navigate to Instagram explore page and extract trending hashtags...",
  browser: "chromium",
  headless: true,
  credentials: {
    instagram: {
      username: INSTAGRAM_USERNAME,
      password: INSTAGRAM_PASSWORD
    }
  },
  timeout: 60000
}
```

## Error Received

```
[Browser Use] Error: write EPROTO ... SSL alert number 112
```

This indicates the endpoint might not be correct or the SSL certificate verification is failing.

## How to Fix

### Option 1: Verify Browser Use API Endpoint

Check your Browser Use documentation for the correct API endpoint. It might be:

- `https://api.daytona.io/browser-use/v1/execute`
- `https://browser-use.daytona.io/api/v1/execute`  
- `https://api.browseruse.io/v1/tasks`
- Different structure entirely

### Option 2: Update the Endpoint

Edit `worker/src/discover-instagram.js`, line 63:

```javascript
// Change this line:
const response = await axios.post('https://api.browseruse.com/v1/execute', {

// To the correct endpoint:
const response = await axios.post('https://CORRECT-ENDPOINT-HERE', {
```

Then redeploy:
```bash
git add worker/src/discover-instagram.js
git commit -m "Update Browser Use API endpoint"
git push
./scripts/deploy.sh
```

### Option 3: Check Browser Use Dashboard

1. Login to your Browser Use dashboard
2. Check API documentation section
3. Look for:
   - Base API URL
   - Endpoint paths
   - Authentication method
   - Request/response examples

## Testing the Endpoint

### Test with curl
```bash
curl -X POST https://CORRECT-ENDPOINT \
  -H "Authorization: Bearer ${BROWSER_USE_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "task": "test",
    "browser": "chromium"
  }'
```

### Check Response
- ✅ 200 OK = Correct endpoint
- ❌ 404 Not Found = Wrong endpoint
- ❌ 401 Unauthorized = Check API key
- ❌ SSL Error = Certificate issue

## Alternative: Use Daytona SDK Directly

If Browser Use doesn't have a REST API, you might need to:

1. **Use Daytona CLI** to create sandboxes
2. **Run browser automation** inside sandboxes
3. **Extract data** from sandbox output

Example approach:
```javascript
// Create Daytona sandbox
const sandbox = await daytona.createSandbox({
  image: 'playwright-chromium'
});

// Run script in sandbox
const result = await sandbox.exec(`
  node -e "
    const { chromium } = require('playwright');
    (async () => {
      const browser = await chromium.launch();
      // ... scrape Instagram
    })();
  "
`);

// Clean up
await daytona.deleteSandbox(sandbox.id);
```

## Current Code Location

**File:** `worker/src/discover-instagram.js`  
**Function:** `scrapeInstagramWithBrowserUse()`  
**Lines:** 51-131

## Next Steps

1. ✅ Real code deployed
2. ⏳ Verify Browser Use API endpoint
3. ⏳ Update endpoint in code
4. ⏳ Redeploy
5. ⏳ Monitor logs for successful scraping

## Monitoring

```bash
# Watch worker logs
./scripts/server-logs.sh worker -f

# Check if it's working
./scripts/trends.sh --since 10m

# See Daytona sandboxes (once working)
./scripts/daytona-status.sh
```

## Documentation Needed

Please provide:
- Browser Use API documentation URL
- Example API request/response
- Authentication method details
- Any SDK or client libraries available

Once we have the correct endpoint, Instagram trends will start being discovered automatically!

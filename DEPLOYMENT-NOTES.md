# Deployment Notes for api.viral.hurated.com

## Port to Expose

**Expose port 3000** from the server to `api.viral.hurated.com`

```bash
# On your server (biaz.hurated.com), the API runs on:
localhost:3000

# Configure your reverse proxy or DNS to route:
api.viral.hurated.com → biaz.hurated.com:3000
```

## Nginx Configuration Example

If using Nginx as reverse proxy:

```nginx
server {
    listen 80;
    server_name api.viral.hurated.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## Firewall Configuration

Allow external access to port 3000:

```bash
# Using ufw
sudo ufw allow 3000/tcp

# Or using iptables
sudo iptables -A INPUT -p tcp --dport 3000 -j ACCEPT
```

## Docker Compose Port Mapping

Current configuration in `compose.yml`:
```yaml
api:
  ports:
    - "3000:3000"  # Maps host:3000 → container:3000
```

This means:
- Container internal: Port 3000
- Server external: Port 3000
- Public DNS: api.viral.hurated.com → Port 3000

## Testing After Exposure

Once `api.viral.hurated.com` is configured, test with:

```bash
# Quick test
curl http://api.viral.hurated.com/health

# Full test suite
./scripts/test-api.sh

# See all examples
./scripts/api-examples.sh
```

## API is Public (No Authentication)

The API is now **publicly accessible** without any authentication keys.

All endpoints work without Bearer tokens:
- ✅ `/health` - Public
- ✅ `/trends` - Public  
- ✅ `/trends/:id` - Public
- ✅ `/webhook/trend` - Public
- ✅ `/stop/trend/:id` - Public
- ✅ `/stop/keyword` - Public

## Security Notes

**Current State:** No authentication
- Anyone can read trends
- Anyone can report trends
- Anyone can stop trends

**Future Enhancement (if needed):**
Add rate limiting or API keys in production.

## Current Status

✅ API deployed on `biaz.hurated.com:3000`  
✅ Authentication removed  
⏳ Waiting for DNS/proxy configuration for `api.viral.hurated.com`  

## Verification Commands

```bash
# From server (works now)
ssh biaz.hurated.com "curl -s http://localhost:3000/health"

# From external (after DNS setup)
curl http://api.viral.hurated.com/health
```

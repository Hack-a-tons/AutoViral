# Deployment Guide

## Overview

AutoViral uses Daytona for orchestration and deployment. All services run in Daytona sandboxes with automatic lifecycle management.

## Architecture

### Sandbox Types

1. **Control Plane** (persistent)
   - `autoviral-control-prod` - Production instance
   - `autoviral-control-dev` - Development instance
   - Contains: API, Database, Scheduler
   - Only 2 control plane sandboxes run at a time

2. **Worker Sandboxes** (ephemeral)
   - `discovery-<id>` - Trend discovery workers
   - `gen-<id>` - Content generation workers
   - `post-<id>` - Posting workers
   - Auto-created on demand
   - Auto-deleted after `MAX_SANDBOX_LIFETIME_MINUTES` (default: 30 min)

### Deployment Flow

```
┌──────────────────────────────────────────────────────────────┐
│ Local Machine                                                │
│  1. Commit & Push (optional with -m flag)                    │
│  2. Run scripts/deploy.sh                                    │
└────────────────┬─────────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────────┐
│ Daytona Control Plane (prod or dev)                          │
│  1. Pull latest code                                         │
│  2. Copy .env file                                           │
│  3. docker compose build                                     │
│  4. docker compose up -d                                     │
│  5. Health check on /health                                  │
└────────────────┬─────────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────────┐
│ Sandbox Cleanup                                              │
│  1. List all AutoViral sandboxes                             │
│  2. Delete ephemeral workers older than MAX_LIFETIME         │
│  3. Keep only prod and dev control planes                    │
└──────────────────────────────────────────────────────────────┘
```

## Prerequisites

1. **Daytona CLI v0.111.0+** installed and configured
   
   **macOS (Direct Download - RECOMMENDED):**
   ```bash
   # Download and install
   curl -L -o daytona-darwin-arm64 https://download.daytona.io/daytona/latest/daytona-darwin-arm64
   chmod +x daytona-darwin-arm64
   sudo mv daytona-darwin-arm64 /usr/local/bin/daytona
   
   # Verify
   daytona --version  # Should show v0.111.0 or later
   ```
   
   **Important:** This project requires Daytona CLI v0.111.0+. Scripts use the new command syntax:
   - `daytona sandbox` (not `daytona workspace`)
   - `daytona login --api-key` (not `daytona auth login`)
   
   **Alternative methods:**
   ```bash
   # Homebrew (may have outdated version)
   brew install daytona
   
   # Official installer script
   curl -sf https://download.daytona.io/daytona/install.sh | sh
   ```

2. **Environment Configuration**
   - Copy `.env.example` to `.env`
   - Fill in all required API keys and credentials

3. **Git Repository**
   - Code must be in a Git repository
   - Remote origin configured (for Daytona to pull)

## Environment Variables

### Required Variables

```bash
# Daytona
DAYTONA_API_KEY=your_api_key
DAYTONA_API_URL=https://api.daytona.io/v1

# LLM Providers
OPENAI_API_KEY=sk-...
GEMINI_API_KEY=...
CLAUDE_API_KEY=...

# Browser Use
BROWSER_USE_API_KEY=...

# Media APIs
PEXELS_API_KEY=...
```

### Optional Variables

```bash
# Deployment Configuration
DAYTONA_WORKSPACE_PREFIX=autoviral
DAYTONA_CONTROL_PLANE_NAME=autoviral-control-prod
DAYTONA_DEV_WORKSPACE=autoviral-control-dev

# Sandbox Lifecycle
MAX_SANDBOX_LIFETIME_MINUTES=30
SANDBOX_CLEANUP_INTERVAL_MINUTES=5

# Rate Limiting
MAX_POSTS_PER_HOUR=10
MAX_GENERATIONS_PER_HOUR=20
```

## Deployment Commands

### Deploy to Production

```bash
# Deploy current code
./scripts/deploy.sh --prod

# Commit, push, and deploy
./scripts/deploy.sh --prod -m "Deploy new feature"
```

### Deploy to Development

```bash
# Deploy to dev environment
./scripts/deploy.sh --dev

# With commit message
./scripts/deploy.sh --dev -m "Test new changes"
```

### Sandbox Management

```bash
# View all sandbox status
./scripts/sandbox-status.sh

# Watch mode (updates every 5 seconds)
./scripts/sandbox-status.sh --watch

# Custom interval
./scripts/sandbox-status.sh --watch --interval 10

# Cleanup old sandboxes
./scripts/sandbox-cleanup.sh

# Dry run (see what would be deleted)
./scripts/sandbox-cleanup.sh --dry-run

# Force cleanup with custom age
./scripts/sandbox-cleanup.sh --force --max-age 15
```

## Manual Deployment Steps

If you need to deploy manually:

```bash
# 1. Authenticate to Daytona
daytona auth login --api-key $DAYTONA_API_KEY --url $DAYTONA_API_URL

# 2. Create or update workspace
daytona workspace create autoviral-control-prod --repository <git-url>
# OR
daytona workspace stop autoviral-control-prod
daytona exec autoviral-control-prod -- bash -c "cd /workspace && git pull"

# 3. Copy environment file
cat .env | daytona exec autoviral-control-prod -- bash -c "cat > /workspace/.env"

# 4. Build and start
daytona exec autoviral-control-prod -- bash -c "cd /workspace && docker compose build && docker compose up -d"

# 5. Check logs
daytona exec autoviral-control-prod -- bash -c "cd /workspace && docker compose logs -f"
```

## Accessing Services

### Get Workspace URL

```bash
daytona workspace info autoviral-control-prod --format json | jq -r '.url'
```

### View Logs

```bash
# Real-time logs
daytona exec autoviral-control-prod -- bash -c 'cd /workspace && docker compose logs -f'

# Last 100 lines
daytona exec autoviral-control-prod -- bash -c 'cd /workspace && docker compose logs --tail=100'

# Specific service
daytona exec autoviral-control-prod -- bash -c 'cd /workspace && docker compose logs -f api'
```

### Execute Commands

```bash
# Run arbitrary commands in workspace
daytona exec autoviral-control-prod -- bash -c 'command here'

# Interactive shell
daytona exec autoviral-control-prod -- bash
```

## Troubleshooting

### Daytona CLI Installation Issues

**Problem: Homebrew installation fails with 404 error**

If `brew install daytona` fails with:
```
curl: (56) The requested URL returned error: 404
```

**Solutions:**

1. **Try the official installer:**
   ```bash
   curl -sf https://download.daytona.io/daytona/install.sh | bash
   ```

2. **Manual download from releases:**
   - Visit https://github.com/daytonaio/daytona/releases
   - Download the appropriate binary for your platform
   - Move to `/usr/local/bin/`:
   ```bash
   sudo mv daytona-darwin-arm64 /usr/local/bin/daytona
   sudo chmod +x /usr/local/bin/daytona
   ```

3. **Build from source:**
   ```bash
   git clone https://github.com/daytonaio/daytona.git
   cd daytona
   make install
   ```

4. **Verify installation:**
   ```bash
   daytona --version
   which daytona
   ```

### Health Check Fails

If deployment fails at health check:

```bash
# View logs
daytona exec autoviral-control-prod -- bash -c 'cd /workspace && docker compose logs --tail=50'

# Check service status
daytona exec autoviral-control-prod -- bash -c 'cd /workspace && docker compose ps'

# Restart services
daytona exec autoviral-control-prod -- bash -c 'cd /workspace && docker compose restart'
```

### Sandboxes Not Cleaning Up

```bash
# Force cleanup
./scripts/sandbox-cleanup.sh --force --max-age 0

# List all sandboxes
daytona workspace list

# Delete specific sandbox
daytona workspace delete <sandbox-name> --force
```

### .env File Not Loaded

Ensure `.env` exists locally before deploying:

```bash
# Check if .env exists
test -f .env && echo "Found" || echo "Not found"

# Compare with .env.example
diff .env.example .env
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Deploy to Daytona

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Create .env
        run: |
          echo "DAYTONA_API_KEY=${{ secrets.DAYTONA_API_KEY }}" >> .env
          echo "OPENAI_API_KEY=${{ secrets.OPENAI_API_KEY }}" >> .env
          # ... add all other secrets
      
      - name: Install Daytona CLI
        run: curl -sf https://download.daytona.io/daytona/install.sh | sh
      
      - name: Deploy
        run: ./scripts/deploy.sh --prod
```

## Best Practices

1. **Always test in dev first**
   ```bash
   ./scripts/deploy.sh --dev
   # Verify it works
   ./scripts/deploy.sh --prod
   ```

2. **Monitor sandbox usage**
   ```bash
   ./scripts/sandbox-status.sh --watch
   ```

3. **Regular cleanup**
   - Set up a cron job to run `sandbox-cleanup.sh` every hour
   - Or use the built-in cleanup interval in the control plane

4. **Environment parity**
   - Keep dev and prod `.env` files in sync
   - Use feature flags for testing new features

5. **Rollback strategy**
   - Keep previous workspace alive during deploy
   - Only delete old workspace after health check passes
   - Can quickly switch back by restarting old workspace

## Security Considerations

1. **Never commit .env file** - It's in `.gitignore`
2. **Rotate API keys regularly** - Update in .env and redeploy
3. **Use Daytona secrets** - For production, consider using Daytona's secret management
4. **Limit workspace access** - Use Daytona RBAC features
5. **Monitor sandbox creation** - Alert on unexpected sandbox spawning

## Resource Limits

Daytona sandboxes have resource limits. Monitor:

```bash
# View resource usage
daytona workspace info autoviral-control-prod --format json | jq '.resources'
```

Adjust in `compose.yml` if needed:

```yaml
services:
  api:
    resources:
      limits:
        cpus: '2'
        memory: 2G
      reservations:
        cpus: '1'
        memory: 1G
```

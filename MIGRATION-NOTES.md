# Migration from Daytona Deployment to SSH Deployment

## Date: 2025-10-18

## Summary

Migrated AutoViral from Daytona-based deployment to direct SSH deployment on `biaz.hurated.com`.

## What Changed

### 1. Deployment Method

**Before:** Deploy to Daytona sandboxes
**After:** Deploy to remote server via SSH

### 2. Daytona sandboxes deleted all. Use:**

Deleted all existing Daytona sandboxes:
- `3801abd6-7014-43d9-bd17-1916f948cc51` (autoviral-control-prod)
- `6615a692-f278-4d2f-92ad-f87934dc7b48` (autoviral-control-dev)

**Daytona is now only used for:**
- Browser Use automation (ephemeral sandboxes)
- Optional browser automation tasks
- NOT for main application deployment

### 3. New Scripts

**Created:**
- `scripts/deploy.sh` - SSH-based deployment script
- `scripts/server-logs.sh` - View server logs remotely
- `scripts/server-status.sh` - Check server status
- `scripts/sandbox-cleanup.sh` - Delete ALL Daytona sandboxes (updated)

**Backed up:**
- `scripts/deploy.sh.daytona.bak` - Old Daytona deployment script
- `scripts/sandbox-cleanup.sh.old` - Old cleanup script

**Removed/Deprecated:**
- `sandbox-logs.sh` - No longer needed (use `server-logs.sh`)
- `sandbox-status.sh` - No longer needed (use `server-status.sh`)
- Daytona-specific documentation

### 4. Configuration Changes

**`.env.example` updated:**
```bash
# Old (Daytona-specific)
DAYTONA_WORKSPACE_PREFIX=autoviral
DAYTONA_CONTROL_PLANE_NAME=autoviral-control-prod
DAYTONA_DEV_WORKSPACE=autoviral-control-dev
EXTERNAL_API_PORT=3000
EXTERNAL_WORKER_PORT=3001

# New (SSH deployment)
SERVER_HOST=biaz.hurated.com
SERVER_USER=root
SERVER_PATH=AutoViral
API_PORT=3000
WORKER_PORT=3001
DB_PORT=5432
REDIS_PORT=6379
```

**Keep these for Browser Use:**
```bash
DAYTONA_API_KEY=your_daytona_api_key_here
DAYTONA_API_URL=https://api.daytona.io/v1
```

### 5. Deployment Workflow

**Before:**
```bash
./scripts/deploy.sh --prod
# → Creates Daytona sandbox
# → Generates sandbox-setup.sh
# → Manual setup in browser terminal
```

**After:**
```bash
./scripts/deploy.sh
# → Commits and pushes
# → SCPs .env to server
# → SSHs and runs: git pull && docker compose build && docker compose up -d
```

### 6. Files Created

- `compose.yml.example` - Docker Compose configuration with env vars
- `MIGRATION-NOTES.md` - This file
- `server-logs.sh` - Remote log viewing
- `server-status.sh` - Remote status checking

### 7. Documentation Updates

**Updated:**
- `README.md` - SSH deployment instructions
- `.env.example` - SSH configuration
- `.gitignore` - Added backup files

**Deprecated (but kept for reference):**
- `docs/SSH-ACCESS.md` - SSH to Daytona sandboxes (not needed for main deployment)
- `docs/MCP-INTEGRATION.md` - Daytona MCP integration
- `docs/DEPLOYMENT.md` - Needs update for SSH deployment

## How to Deploy Now

### 1. Setup SSH Access

```bash
# Configure SSH key
ssh-copy-id root@biaz.hurated.com

# Test connection
ssh root@biaz.hurated.com "echo 'OK'"
```

### 2. Update .env

```bash
cp .env.example .env

# Edit these values:
SERVER_HOST=biaz.hurated.com
SERVER_USER=root
SERVER_PATH=AutoViral

# Set all your API keys
OPENAI_API_KEY=...
PEXELS_API_KEY=...
# etc.
```

### 3. Deploy

```bash
# First deployment
./scripts/deploy.sh -m "Initial deployment"

# Subsequent deployments
./scripts/deploy.sh

# Skip rebuild (faster)
./scripts/deploy.sh --skip-build

# Deploy and view logs
./scripts/deploy.sh --logs
```

### 4. Monitor

```bash
# View logs
./scripts/server-logs.sh -f

# Check status
./scripts/server-status.sh

# Check ports
ssh biaz.hurated.com docker ps | cut -c131-
```

## Port Management

All ports in `compose.yml` must come from `.env`:

```yaml
services:
  api:
    ports:
      - "${API_PORT}:3000"
  
  worker:
    ports:
      - "${WORKER_PORT}:3001"
  
  db:
    ports:
      - "${DB_PORT}:5432"
  
  redis:
    ports:
      - "${REDIS_PORT}:6379"
```

Check available ports:
```bash
ssh biaz.hurated.com docker ps | cut -c131-
```

## Daytona Use Cases (Still Supported)

Daytona is still used for:

1. **Browser Use automation** - Ephemeral sandboxes for scraping/posting
2. **AI agent integration** - MCP with Claude/Windsurf/Cursor
3. **Optional browser tasks** - Created via API when needed

To clean up Daytona sandboxes:
```bash
./scripts/sandbox-cleanup.sh          # Delete all sandboxes
./scripts/sandbox-cleanup.sh --dry-run  # Preview what would be deleted
```

## Rollback Plan

If you need to roll back to Daytona deployment:

```bash
# Restore old scripts
mv scripts/deploy.sh scripts/deploy.sh.ssh
mv scripts/deploy.sh.daytona.bak scripts/deploy.sh
mv scripts/sandbox-cleanup.sh.old scripts/sandbox-cleanup.sh

# Update .env with Daytona config
# Redeploy to Daytona
```

## Benefits of SSH Deployment

1. **Simpler** - Direct deployment, no sandbox management
2. **Faster** - No sandbox creation time
3. **Cheaper** - No Daytona sandbox costs for control plane
4. **More control** - Direct access to server
5. **Easier debugging** - Direct log access via SSH

## Next Steps

1. ✅ Clean up old Daytona sandboxes (Done)
2. ✅ Update deployment scripts (Done)
3. ✅ Test SSH deployment
4. ⏳ Create actual `compose.yml` from example
5. ⏳ Update DEPLOYMENT.md documentation
6. ⏳ Test full deployment pipeline
7. ⏳ Configure CI/CD if needed

## Questions?

See:
- `scripts/deploy.sh --help`
- `scripts/server-logs.sh --help`
- `scripts/server-status.sh --help`
- `README.md` - Quick Start section

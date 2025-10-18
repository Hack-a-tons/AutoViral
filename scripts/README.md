# Scripts Directory

This directory contains operational scripts for deploying and managing AutoViral on Daytona.

## Available Scripts

### 🚀 deploy.sh

Main deployment script for Daytona sandboxes.

**Usage:**
```bash
# Deploy to production
./scripts/deploy.sh --prod

# Deploy to development
./scripts/deploy.sh --dev

# Commit, push, and deploy
./scripts/deploy.sh --prod -m "Deploy message"
```

**Features:**
- Optional git commit & push with `-m` flag
- Automatic workspace creation/update
- Health check validation
- Automatic rollback on failure
- Sandbox cleanup
- Environment file deployment

**Process:**
1. Optionally commit and push changes
2. Authenticate to Daytona
3. Create or update target workspace (prod/dev)
4. Copy `.env` to workspace
5. Build and start services
6. Wait for health check
7. Clean up old sandboxes

---

### 🧹 sandbox-cleanup.sh

Cleanup script for ephemeral worker sandboxes.

**Usage:**
```bash
# Clean up sandboxes older than 30 minutes
./scripts/sandbox-cleanup.sh

# Dry run (see what would be deleted)
./scripts/sandbox-cleanup.sh --dry-run

# Force cleanup with custom max age
./scripts/sandbox-cleanup.sh --force --max-age 15

# Clean all worker sandboxes immediately
./scripts/sandbox-cleanup.sh --force --max-age 0
```

**Features:**
- Deletes ephemeral worker sandboxes (`discovery-*`, `gen-*`, `post-*`)
- Keeps control plane sandboxes (`autoviral-control-prod`, `autoviral-control-dev`)
- Respects `MAX_SANDBOX_LIFETIME_MINUTES` from `.env`
- Dry run mode for safety
- Age-based filtering

**When to use:**
- Scheduled cleanup (cron job every hour)
- Manual cleanup when too many sandboxes exist
- Emergency cleanup to free resources

---

### 📊 sandbox-status.sh

Monitor and display status of all AutoViral sandboxes.

**Usage:**
```bash
# View current status
./scripts/sandbox-status.sh

# Watch mode (updates every 5 seconds)
./scripts/sandbox-status.sh --watch

# Custom refresh interval
./scripts/sandbox-status.sh --watch --interval 10
```

**Displays:**
- Control plane sandboxes (prod/dev)
- Worker sandboxes with type and age
- Status (running/stopped)
- URLs and resource info
- Color-coded warnings for old sandboxes

**When to use:**
- Monitor deployment progress
- Check sandbox health
- Identify stuck or long-running workers
- Debug deployment issues

---

## Environment Variables

All scripts load environment variables from `.env` file in the project root.

**Required:**
- `DAYTONA_API_KEY` - Daytona authentication
- `DAYTONA_API_URL` - Daytona API endpoint

**Optional:**
- `DAYTONA_WORKSPACE_PREFIX` - Prefix for sandbox names (default: `autoviral`)
- `DAYTONA_CONTROL_PLANE_NAME` - Production workspace name
- `DAYTONA_DEV_WORKSPACE` - Development workspace name
- `MAX_SANDBOX_LIFETIME_MINUTES` - Max age for ephemeral sandboxes (default: 30)

---

## Automated Workflows

### Continuous Deployment

Set up a cron job or CI/CD pipeline:

```bash
# GitHub Actions example (.github/workflows/deploy.yml)
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to Daytona
        run: ./scripts/deploy.sh --prod
        env:
          DAYTONA_API_KEY: ${{ secrets.DAYTONA_API_KEY }}
          # ... other secrets
```

### Scheduled Cleanup

Add to crontab:

```bash
# Clean up old sandboxes every hour
0 * * * * cd /path/to/AutoViral && ./scripts/sandbox-cleanup.sh

# Monitor and alert if too many sandboxes
*/15 * * * * cd /path/to/AutoViral && ./scripts/sandbox-status.sh | grep "Total:" | mail -s "Sandbox Status" you@example.com
```

---

## Best Practices

1. **Always test in dev first:**
   ```bash
   ./scripts/deploy.sh --dev
   # Verify it works
   ./scripts/deploy.sh --prod
   ```

2. **Use watch mode during deployment:**
   ```bash
   # Terminal 1: Deploy
   ./scripts/deploy.sh --prod
   
   # Terminal 2: Monitor
   ./scripts/sandbox-status.sh --watch
   ```

3. **Regular cleanup:**
   - Schedule hourly cleanup via cron
   - Or enable auto-cleanup in control plane

4. **Emergency procedures:**
   ```bash
   # Stop all AutoViral sandboxes
   daytona workspace list | grep autoviral | awk '{print $1}' | xargs -I {} daytona workspace stop {}
   
   # Force cleanup everything
   ./scripts/sandbox-cleanup.sh --force --max-age 0
   ```

5. **Rollback:**
   ```bash
   # If prod deployment fails, old workspace is still available
   daytona workspace start autoviral-control-prod-old
   daytona workspace stop autoviral-control-prod
   ```

---

## Troubleshooting

### Script fails with "Not authenticated"

```bash
# Re-authenticate
daytona auth login --api-key $DAYTONA_API_KEY --url $DAYTONA_API_URL
```

### Health check fails

```bash
# View logs
daytona exec autoviral-control-prod -- bash -c 'cd /workspace && docker compose logs --tail=100'

# Check service status
daytona exec autoviral-control-prod -- bash -c 'cd /workspace && docker compose ps'
```

### Too many sandboxes

```bash
# Force cleanup all workers
./scripts/sandbox-cleanup.sh --force --max-age 0

# List all AutoViral sandboxes
daytona workspace list | grep autoviral
```

### .env not found

```bash
# Ensure .env exists in project root
test -f .env && echo "Found" || echo "Create from .env.example"

# Copy from example
cp .env.example .env
# Edit with your values
```

---

## Development

### Testing Scripts Locally

```bash
# Test deploy script (dry run concept)
# Edit script to add --dry-run flag that skips actual deployment

# Test cleanup with dry run
./scripts/sandbox-cleanup.sh --dry-run

# Test status display
./scripts/sandbox-status.sh
```

### Modifying Scripts

All scripts follow these conventions:
- Load `.env` for configuration
- Use color-coded output for readability
- Include `--help` or parameter validation
- Support both interactive and automated use
- Log all major operations
- Fail fast with clear error messages

---

## See Also

- [Deployment Guide](../docs/DEPLOYMENT.md) - Full deployment documentation
- [README.md](../README.md) - Project overview
- [TODO.md](../TODO.md) - Implementation plan

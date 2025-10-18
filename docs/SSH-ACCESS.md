# SSH Access to Daytona Sandboxes

## Overview

SSH access to Daytona sandboxes is managed through the **Daytona web interface only**. The Daytona CLI v0.111.0 does not have SSH management commands.

## Managing SSH Access via Web UI

### 1. Create SSH Key

If you don't have an SSH key yet:

```bash
# Generate a new SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Or use RSA if ed25519 is not supported
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# Copy your public key
cat ~/.ssh/id_ed25519.pub
# Or: cat ~/.ssh/id_rsa.pub
```

### 2. Add SSH Key in Daytona Web UI

1. **Log in** to Daytona web dashboard
2. **Navigate to Settings** → SSH Keys (or similar)
3. **Click "Add SSH Key"**
4. **Paste your public key** (contents of `~/.ssh/id_ed25519.pub`)
5. **Give it a name** (e.g., "MacBook Pro")
6. **Save**

### 3. Access Sandbox via SSH

Once your key is added, you can SSH into sandboxes:

```bash
# Get sandbox connection info
daytona sandbox info autoviral-control-dev

# SSH format (check the web UI or sandbox info for exact format)
ssh user@<sandbox-id>.daytona.works

# Or with specific port
ssh -p 22222 user@<sandbox-url>
```

### 4. Revoke SSH Access

To revoke SSH access:

1. Go to **Settings** → SSH Keys in web UI
2. Find the key you want to remove
3. Click **Delete** or **Revoke**

## Why No CLI for SSH Management?

**Daytona CLI v0.111.0 limitations:**
- ❌ No `daytona ssh` command
- ❌ No `daytona ssh-key` command
- ❌ No SSH access management via CLI
- ❌ **MCP is NOT for SSH** (see below)

**Available workarounds:**
1. **Use web UI** for SSH key management (recommended)
2. **Use web terminal** for quick access (no SSH key needed)
3. **Use API directly** (if you need automation)

### What About MCP?

**MCP (Model Context Protocol) ≠ SSH Access**

The `daytona mcp` commands are for **AI agent integration**, not SSH:

```bash
daytona mcp init claude    # Integrate with Claude Desktop
daytona mcp init windsurf  # Integrate with Windsurf IDE
daytona mcp init cursor    # Integrate with Cursor IDE
```

**What MCP does:**
- Allows AI assistants (Claude, Windsurf, Cursor) to interact with Daytona
- Provides programmatic access to sandbox management
- Enables AI agents to create/manage sandboxes on your behalf
- **NOT** a replacement for SSH or terminal access

**When to use MCP:**
- You want AI assistants to manage Daytona sandboxes for you
- You're building AI-powered development workflows
- You want Claude/Windsurf/Cursor to create sandboxes during conversations

**MCP does NOT provide:**
- ❌ SSH key management
- ❌ Direct terminal access to sandboxes
- ❌ File transfer capabilities
- ❌ Port forwarding

For human SSH access, use the web UI to manage keys.

## Alternative: Web Terminal Access

For most use cases, the web terminal is simpler:

```bash
# Open sandbox terminal in browser
./scripts/sandbox-logs.sh autoviral-control-dev

# Or manually visit:
# https://22222-<sandbox-id>.proxy.daytona.works
```

**Advantages of web terminal:**
- ✅ No SSH key setup needed
- ✅ Works from any browser
- ✅ Integrated with Daytona UI
- ✅ Easy to share access

**When to use SSH instead:**
- Need to use local tools (VS Code Remote SSH, etc.)
- Want to use SSH port forwarding
- Prefer terminal-based workflow
- Need to automate tasks via SSH

## Connecting with VS Code Remote SSH

Once SSH is configured:

1. **Install "Remote - SSH" extension** in VS Code
2. **Open Command Palette** (Cmd+Shift+P)
3. **Run:** "Remote-SSH: Connect to Host..."
4. **Enter:** `user@<sandbox-id>.daytona.works`
5. **VS Code will connect** and you can work in the sandbox

## SSH Port Forwarding

Forward ports from sandbox to your local machine:

```bash
# Forward sandbox port 3000 to local port 3000
ssh -L 3000:localhost:3000 user@<sandbox-id>.daytona.works

# Forward multiple ports
ssh -L 3000:localhost:3000 -L 3001:localhost:3001 user@<sandbox-id>.daytona.works

# Background process with -f -N
ssh -f -N -L 3000:localhost:3000 user@<sandbox-id>.daytona.works
```

## Troubleshooting

### "Permission denied (publickey)"

**Solutions:**
1. Check your public key is added in Daytona web UI
2. Verify you're using the correct private key:
   ```bash
   ssh -i ~/.ssh/id_ed25519 user@<sandbox-url>
   ```
3. Check SSH agent has your key:
   ```bash
   ssh-add -l
   ssh-add ~/.ssh/id_ed25519
   ```

### "Connection refused"

**Solutions:**
1. Check sandbox is running: `./scripts/sandbox-status.sh`
2. Start sandbox if stopped: `daytona sandbox start <name>`
3. Verify SSH URL is correct (check web UI)

### Can't find SSH connection details

**Solution:**
```bash
# Get full sandbox info
daytona sandbox info autoviral-control-dev

# Or check the web UI sandbox page for SSH details
```

## Security Best Practices

1. **Use separate keys per device**
   - Create different SSH keys for laptop, desktop, CI/CD, etc.
   - Easier to revoke if one device is compromised

2. **Use passphrase-protected keys**
   ```bash
   # Add passphrase to existing key
   ssh-keygen -p -f ~/.ssh/id_ed25519
   ```

3. **Regularly rotate keys**
   - Remove old keys from Daytona
   - Generate new keys periodically

4. **Use SSH agent**
   ```bash
   # Start SSH agent
   eval "$(ssh-agent -s)"
   
   # Add key once per session
   ssh-add ~/.ssh/id_ed25519
   ```

5. **Limit key permissions**
   ```bash
   chmod 600 ~/.ssh/id_ed25519
   chmod 644 ~/.ssh/id_ed25519.pub
   ```

## See Also

- [Sandbox Logs](../scripts/README.md#-sandbox-logssh) - Web terminal access
- [Deployment Guide](DEPLOYMENT.md) - Full deployment docs
- [Daytona Documentation](https://www.daytona.io/docs/) - Official docs

# MCP Integration with Daytona

## What is MCP?

**MCP (Model Context Protocol)** is a protocol that allows AI agents to interact with external tools and services. Daytona's MCP integration enables AI assistants like Claude Desktop, Windsurf IDE, and Cursor to programmatically manage Daytona sandboxes.

## Supported AI Agents

| Agent | Description |
|-------|-------------|
| **Claude Desktop** | Anthropic's Claude AI assistant |
| **Windsurf IDE** | Codeium's AI-powered IDE |
| **Cursor IDE** | AI-first code editor |

## Setting Up MCP Integration

### 1. Initialize MCP for Your AI Agent

```bash
# For Claude Desktop
daytona mcp init claude

# For Windsurf IDE
daytona mcp init windsurf

# For Cursor IDE
daytona mcp init cursor
```

This will configure the AI agent to communicate with Daytona.

### 2. Start the MCP Server

```bash
daytona mcp start
```

The server will run in the background and handle requests from AI agents.

### 3. Get Configuration

```bash
# View MCP configuration
daytona mcp config
```

## What Can AI Agents Do via MCP?

Once configured, AI agents can:

### Sandbox Management
- Create new sandboxes
- Start/stop sandboxes
- Delete sandboxes
- List all sandboxes
- Get sandbox information

### Workflow Automation
- Create development environments on-demand
- Setup project-specific sandboxes
- Manage multiple sandboxes in parallel
- Clean up unused sandboxes

### What MCP Does NOT Do
- SSH access or key management
- Direct file access in sandboxes
- Execute commands inside sandboxes
- Real-time terminal access

## Use Cases for MCP

### 1. AI-Powered Development Workflow

Ask your AI assistant:
> "Create a Daytona sandbox for testing the new API feature"

The AI can create, configure, and manage sandboxes automatically.

### 2. Environment Management

Ask your AI:
> "Show me all my running Daytona sandboxes and their status"

The AI can list and report on sandbox states.

### 3. Cleanup Automation

Ask your AI:
> "Delete all stopped Daytona sandboxes"

The AI can manage sandbox lifecycle.

## MCP vs Direct CLI Access

| Feature | MCP | Direct CLI | Web UI |
|---------|-----|------------|--------|
| Sandbox CRUD | Yes | Yes | Yes |
| SSH Key Management | No | No | Yes |
| Terminal Access | No | No | Yes |
| AI Integration | Yes | No | No |
| Automation | Via AI | Via Scripts | Manual |

## Example: Using MCP with Claude Desktop

1. Initialize integration:
   ```bash
   daytona mcp init claude
   ```

2. Start MCP server:
   ```bash
   daytona mcp start
   ```

3. In Claude Desktop, ask:
   > "Can you create a Daytona sandbox named 'test-environment'?"

4. Claude will use MCP to create the sandbox and confirm.

## Troubleshooting

### MCP Server Not Responding

Check logs:
```bash
cat ~/.daytona/daytona-mcp.log
```

Restart server:
```bash
# Stop any existing MCP processes
pkill -f "daytona mcp start"

# Start fresh
daytona mcp start
```

### AI Agent Can't Connect

Verify configuration:
```bash
daytona mcp config
```

Re-initialize:
```bash
daytona mcp init [agent-name]
```

## Security Considerations

1. **API Key Protection**: MCP uses your Daytona API key. Keep it secure.
2. **AI Access Control**: AI agents have the same permissions as your CLI access.
3. **Audit Logs**: Check `~/.daytona/daytona-mcp.log` for all MCP activities.

## For AutoViral Project

MCP integration could be useful for:

- **Automated Testing**: Ask AI to create test sandboxes
- **Environment Replication**: "Create a sandbox matching prod config"
- **Debugging**: "Show me the status of all AutoViral sandboxes"
- **Cleanup**: "Delete old development sandboxes"

However, for direct SSH access and running commands, use:
- Web UI for SSH keys
- Web terminal for command execution
- `./scripts/sandbox-logs.sh` for quick access

## See Also

- [SSH Access](SSH-ACCESS.md) - SSH key management and remote access
- [Deployment Guide](DEPLOYMENT.md) - Complete deployment instructions
- [Scripts Reference](../scripts/README.md) - Deployment automation scripts

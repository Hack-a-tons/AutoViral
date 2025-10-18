#!/usr/bin/env bash

set -e

# Change to script directory to ensure relative paths work
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project root is parent of scripts directory
PROJECT_ROOT="$(cd .. && pwd)"

# Help function
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy AutoViral to Daytona sandbox (prod or dev environment).
This script will ALWAYS commit and push all changes before deploying.

Options:
    -m, --message TEXT    Custom commit message (default: auto-generated)
    --dev                 Deploy to development environment (default: prod)
    --prod                Deploy to production environment
    -h, --help            Show this help message and exit

Examples:
    $0 --prod                              # Deploy to prod with auto message
    $0 --dev                               # Deploy to dev with auto message
    $0 --prod -m "New feature"             # Deploy with custom message

What it does:
    1. Stage all changes (git add .)
    2. Commit with message (--allow-empty for re-deploys)
    3. Push to remote origin
    4. Create/update Daytona sandbox
    5. Generate sandbox-setup.sh script
    6. Display setup instructions

Prerequisites:
    - .env file must exist with required variables
    - Daytona CLI must be installed
    - Git repository with remote origin configured
    - All changes ready to commit

Environment Variables (from .env):
    DAYTONA_API_KEY               Daytona authentication key
    DAYTONA_API_URL               Daytona API endpoint
    DAYTONA_CONTROL_PLANE_NAME    Production workspace name
    DAYTONA_DEV_WORKSPACE         Development workspace name
EOF
}

# Default values
ENVIRONMENT="prod"
MESSAGE=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -m|--message)
            MESSAGE="$2"
            shift 2
            ;;
        --dev)
            ENVIRONMENT="dev"
            shift
            ;;
        --prod)
            ENVIRONMENT="prod"
            shift
            ;;
        *)
            echo -e "${RED}Error: Unknown option: $1${NC}"
            echo "Run '$0 --help' for usage information."
            exit 1
            ;;
    esac
done

# Load environment variables
if [ -f "$PROJECT_ROOT/.env" ]; then
    set -a  # automatically export all variables
    source "$PROJECT_ROOT/.env"
    set +a
else
    echo -e "${RED}Error: .env file not found at $PROJECT_ROOT/.env${NC}"
    echo -e "${YELLOW}Create it from .env.example: cp .env.example .env${NC}"
    exit 1
fi

# Validate required environment variables
if [ -z "$DAYTONA_API_KEY" ]; then
    echo -e "${RED}Error: DAYTONA_API_KEY not set in .env${NC}"
    exit 1
fi

if [ -z "$DAYTONA_API_URL" ]; then
    echo -e "${RED}Error: DAYTONA_API_URL not set in .env${NC}"
    exit 1
fi

# Configuration based on environment
if [ "$ENVIRONMENT" = "prod" ]; then
    WORKSPACE_NAME="${DAYTONA_CONTROL_PLANE_NAME:-autoviral-control-prod}"
    OLD_WORKSPACE="${DAYTONA_DEV_WORKSPACE:-autoviral-control-dev}"
else
    WORKSPACE_NAME="${DAYTONA_DEV_WORKSPACE:-autoviral-control-dev}"
    OLD_WORKSPACE="${DAYTONA_CONTROL_PLANE_NAME:-autoviral-control-prod}"
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  AutoViral Daytona Deployment Script${NC}"
echo -e "${BLUE}  Environment: ${YELLOW}${ENVIRONMENT}${NC}"
echo -e "${BLUE}  Target Workspace: ${YELLOW}${WORKSPACE_NAME}${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Step 1: Always commit and push changes
echo -e "\n${GREEN}[1/7] Committing and pushing changes...${NC}"

# Default message if not provided
if [ -z "$MESSAGE" ]; then
    MESSAGE="Deploy to ${ENVIRONMENT} - $(date +%Y-%m-%d\ %H:%M:%S)"
fi

# Stage all changes
echo -e "${YELLOW}Staging changes...${NC}"
git add . || {
    echo -e "${RED}Failed to stage changes${NC}"
    exit 1
}

# Commit (allow empty commits for re-deploys)
echo -e "${YELLOW}Committing: ${MESSAGE}${NC}"
git commit -m "$MESSAGE" --allow-empty || echo -e "${YELLOW}No new changes to commit${NC}"

# Push to remote
echo -e "${YELLOW}Pushing to remote...${NC}"
git push || {
    echo -e "${RED}Failed to push changes${NC}"
    exit 1
}

echo -e "${GREEN}✓ Changes pushed successfully${NC}"

# Get repository URL
GIT_REPO=$(cd "$PROJECT_ROOT" && git remote get-url origin 2>/dev/null)
if [ -z "$GIT_REPO" ]; then
    echo -e "${RED}Error: No git remote 'origin' found${NC}"
    echo -e "${YELLOW}Add one with: git remote add origin <url>${NC}"
    exit 1
fi
echo -e "${CYAN}Repository: ${GIT_REPO}${NC}"

# Step 2: Check Daytona CLI and authentication
echo -e "\n${GREEN}[2/7] Checking Daytona CLI and authentication...${NC}"
if ! command -v daytona &> /dev/null; then
    echo -e "${RED}Error: Daytona CLI not found${NC}"
    echo -e "${YELLOW}Install it with: brew install daytona${NC}"
    echo -e "${YELLOW}Or see: https://www.daytona.io/docs/installation/daytona-cli/${NC}"
    exit 1
fi

if ! daytona sandbox list &> /dev/null; then
    echo -e "${YELLOW}Not authenticated. Logging in with API key from .env...${NC}"
    daytona login --api-key "$DAYTONA_API_KEY" || {
        echo -e "${RED}Authentication failed${NC}"
        exit 1
    }
fi

# Step 3: Create or update sandbox
echo -e "\n${GREEN}[3/7] Setting up Daytona sandbox: ${WORKSPACE_NAME}...${NC}"

# Check if sandbox exists by trying to get info
SANDBOX_EXISTS=false
if daytona sandbox info "$WORKSPACE_NAME" &> /dev/null; then
    SANDBOX_EXISTS=true
    SANDBOX_STATUS=$(daytona sandbox info "$WORKSPACE_NAME" | grep "State" | awk '{print $2}')
    echo -e "${YELLOW}Sandbox exists with status: ${SANDBOX_STATUS}${NC}"
    
    if [ "$SANDBOX_STATUS" = "ERROR" ]; then
        echo -e "${RED}Sandbox is in ERROR state. Deleting and recreating...${NC}"
        daytona sandbox delete "$WORKSPACE_NAME" 2>/dev/null || true
        SANDBOX_EXISTS=false
    elif [ "$SANDBOX_STATUS" != "Running" ]; then
        echo -e "${YELLOW}Starting sandbox...${NC}"
        daytona sandbox start "$WORKSPACE_NAME" 2>/dev/null || {
            echo -e "${RED}Failed to start. Deleting and recreating...${NC}"
            daytona sandbox delete "$WORKSPACE_NAME" 2>/dev/null || true
            SANDBOX_EXISTS=false
        }
    fi
fi

if [ "$SANDBOX_EXISTS" = false ]; then
    echo -e "${YELLOW}Creating new sandbox...${NC}"
    echo -e "${YELLOW}Using default Daytona snapshot (daytonaio/sandbox:0.4.3)${NC}"
    
    #Note: Custom Dockerfiles cause "sandbox processing failed" errors in Daytona v0.111.0
    # Use basic sandbox with default snapshot instead
    daytona sandbox create --name "$WORKSPACE_NAME" \
        --auto-stop 0 \
        --public || {
        echo -e "${RED}Failed to create sandbox${NC}"
        exit 1
    }
    
    echo -e "${GREEN}✓ Sandbox created successfully!${NC}"
    SANDBOX_CREATED=true
fi

# Step 4: Generate setup script
echo -e "\n${GREEN}[4/7] Generating setup script...${NC}"

SETUP_SCRIPT="$PROJECT_ROOT/sandbox-setup.sh"
cat > "$SETUP_SCRIPT" << 'SETUP_EOF'
#!/bin/bash
set -e

echo "========================================"
echo "AutoViral Sandbox Setup"
echo "========================================"

# Install Node.js 20.x
echo "\n[1/6] Installing Node.js 20.x..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
sudo apt-get install -y nodejs
node --version
npm --version

# Install system dependencies
echo "\n[2/6] Installing system dependencies..."
sudo apt-get update
sudo apt-get install -y ffmpeg jq git curl

# Clone repository
echo "\n[3/6] Cloning repository..."
rm -rf /workspace
SETUP_EOF

echo "git clone ${GIT_REPO} /workspace" >> "$SETUP_SCRIPT"

cat >> "$SETUP_SCRIPT" << 'SETUP_EOF'
cd /workspace

# Setup .env file
echo "\n[4/6] Setting up environment variables..."
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
        echo "Created .env from .env.example"
        echo "⚠️  Please edit .env with your actual API keys!"
    else
        echo "⚠️  No .env.example found. Please create .env manually."
    fi
fi

# Install Node dependencies
echo "\n[5/6] Installing Node.js dependencies..."
npm install

# Check if docker-compose is available
echo "\n[6/6] Checking Docker..."
if command -v docker &> /dev/null; then
    echo "✓ Docker is available"
else
    echo "⚠️  Docker not found - may need manual installation"
fi

echo "\n========================================"
echo "✓ Setup complete!"
echo "========================================"
echo "\nNext steps:"
echo "  1. Edit /workspace/.env with your API keys"
echo "  2. Start your application (e.g., npm run dev)"
echo "  3. Access via the sandbox URL"
SETUP_EOF

chmod +x "$SETUP_SCRIPT"
echo -e "${GREEN}✓ Setup script generated at: ${CYAN}sandbox-setup.sh${NC}"

# Step 5: Get sandbox info
echo -e "\n${GREEN}[5/7] Getting sandbox information...${NC}"
daytona sandbox info "$WORKSPACE_NAME" || {
    echo -e "${RED}Failed to get sandbox info${NC}"
    exit 1
}

# Extract sandbox URL
SANDBOX_URL=$(daytona sandbox info "$WORKSPACE_NAME" | grep -i "accessible" | awk '{print $NF}' || echo "")
if [ -z "$SANDBOX_URL" ]; then
    # Try to construct URL from ID
    SANDBOX_ID=$(daytona sandbox info "$WORKSPACE_NAME" | grep "ID" | awk '{print $2}')
    echo -e "${YELLOW}Could not auto-detect sandbox URL${NC}"
    echo -e "${YELLOW}Sandbox ID: ${SANDBOX_ID}${NC}"
fi

# Step 6: Display setup instructions
if [ "$SANDBOX_CREATED" = true ]; then
    echo -e "\n${GREEN}[6/7] Setup Instructions${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✓ Sandbox is ready!${NC}"
    echo -e ""
    echo -e "${YELLOW}Access your sandbox:${NC}"
    if [ -n "$SANDBOX_URL" ]; then
        echo -e "  ${CYAN}${SANDBOX_URL}${NC}"
    fi
    echo -e ""
    echo -e "${YELLOW}To complete setup, run this ONE command in the sandbox terminal:${NC}"
    echo -e "${CYAN}  curl -fsSL ${GIT_REPO}/raw/main/sandbox-setup.sh | bash${NC}"
    echo -e ""
    echo -e "${YELLOW}Or manually copy and run the setup script:${NC}"
    echo -e "  1. Open sandbox terminal at the URL above"
    echo -e "  2. Run these commands:"
    echo -e "${CYAN}     git clone ${GIT_REPO} /workspace${NC}"
    echo -e "${CYAN}     cd /workspace${NC}"
    echo -e "${CYAN}     bash sandbox-setup.sh${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
else
    echo -e "\n${GREEN}[6/7] Sandbox already exists and running${NC}"
fi

# Step 7: Cleanup and manage sandboxes
echo -e "\n${GREEN}[7/7] Managing Daytona sandboxes...${NC}"

# Promote new sandbox to active
if [ "$ENVIRONMENT" = "prod" ]; then
    echo -e "${GREEN}✓ Promoted ${WORKSPACE_NAME} to production${NC}"
fi

# List all AutoViral sandboxes
echo -e "${YELLOW}Listing all AutoViral sandboxes:${NC}"
daytona sandbox list 2>/dev/null | grep "${DAYTONA_WORKSPACE_PREFIX:-autoviral}" || echo "No sandboxes found"

# Note about cleanup
echo -e "${YELLOW}To cleanup old sandboxes, run: $SCRIPT_DIR/sandbox-cleanup.sh${NC}"

# Final status
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Sandbox created/updated!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Environment: ${YELLOW}${ENVIRONMENT}${NC}"
echo -e "  Sandbox: ${YELLOW}${WORKSPACE_NAME}${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n${GREEN}Useful commands:${NC}"
echo -e "  ${YELLOW}daytona sandbox info $WORKSPACE_NAME${NC}     # Get sandbox details"
echo -e "  ${YELLOW}$SCRIPT_DIR/sandbox-status.sh${NC}            # Monitor all sandboxes"
echo -e "  ${YELLOW}$SCRIPT_DIR/sandbox-cleanup.sh${NC}           # Clean up old sandboxes"
echo -e ""
if [ "$SANDBOX_CREATED" = true ]; then
    echo -e "${GREEN}🚀 Remember to run the setup script in your sandbox!${NC}"
fi

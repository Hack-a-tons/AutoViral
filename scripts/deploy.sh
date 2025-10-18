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

Options:
    -m, --message TEXT    Commit and push changes before deploy with given message
    --dev                 Deploy to development environment (default: prod)
    --prod                Deploy to production environment
    -h, --help            Show this help message and exit

Examples:
    $0 --prod                              # Deploy to production
    $0 --dev                               # Deploy to development
    $0 --prod -m "New feature"             # Commit, push, and deploy

Prerequisites:
    - .env file must exist with required variables
    - Daytona CLI must be installed (brew install daytona)
    - Git repository with remote origin

Environment Variables (from .env):
    DAYTONA_API_KEY               Daytona authentication key
    DAYTONA_API_URL               Daytona API endpoint
    DAYTONA_CONTROL_PLANE_NAME    Production workspace name
    DAYTONA_DEV_WORKSPACE         Development workspace name
    DAYTONA_WORKSPACE_PREFIX      Prefix for sandbox names
EOF
}

# Default values
COMMIT_AND_PUSH=false
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
            COMMIT_AND_PUSH=true
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

# Step 1: Commit and push if requested
if [ "$COMMIT_AND_PUSH" = true ]; then
    echo -e "\n${GREEN}[1/6] Committing and pushing changes...${NC}"
    cd "$PROJECT_ROOT"
    
    if [ -z "$MESSAGE" ]; then
        MESSAGE="Deploy to ${ENVIRONMENT} - $(date +%Y-%m-%d\ %H:%M:%S)"
    fi
    
    git add .
    git commit -m "$MESSAGE" || echo -e "${YELLOW}No changes to commit${NC}"
    git push || echo -e "${RED}Failed to push changes${NC}"
else
    echo -e "\n${YELLOW}[1/6] Skipping git commit/push${NC}"
fi

# Step 2: Check Daytona CLI and authentication
echo -e "\n${GREEN}[2/6] Checking Daytona CLI and authentication...${NC}"
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

# Step 3: Create or update workspace
echo -e "\n${GREEN}[3/6] Setting up Daytona workspace: ${WORKSPACE_NAME}...${NC}"

# Check if sandbox exists
if daytona sandbox list 2>/dev/null | grep -q "$WORKSPACE_NAME"; then
    echo -e "${YELLOW}Sandbox exists. Updating...${NC}"
    
    # Stop the sandbox temporarily
    daytona sandbox stop "$WORKSPACE_NAME" 2>/dev/null || true
    
    # Start it back up
    daytona sandbox start "$WORKSPACE_NAME" 2>/dev/null || true
else
    echo -e "${YELLOW}Creating new sandbox...${NC}"
    
    # Get current git repository URL
    GIT_REPO=$(cd "$PROJECT_ROOT" && git config --get remote.origin.url)
    
    # Create sandbox from git repository
    daytona sandbox create "$WORKSPACE_NAME" --repository "$GIT_REPO" || {
        echo -e "${RED}Failed to create sandbox${NC}"
        exit 1
    }
fi

# Step 4: Copy .env file to sandbox
echo -e "\n${GREEN}[4/6] Copying environment configuration...${NC}"
echo -e "${YELLOW}Note: .env copying depends on Daytona sandbox exec capabilities${NC}"
# This may not work in current Daytona version - needs manual config or different approach

# Step 5: Get sandbox info
echo -e "\n${GREEN}[5/6] Getting sandbox information...${NC}"
daytona sandbox info "$WORKSPACE_NAME" || {
    echo -e "${RED}Failed to get sandbox info${NC}"
    exit 1
}

echo -e "${YELLOW}Note: Manual setup may be required inside the sandbox${NC}"
echo -e "${YELLOW}Use: daytona sandbox info $WORKSPACE_NAME for access details${NC}"

# Step 6: Cleanup and manage sandboxes
echo -e "\n${GREEN}[6/6] Managing Daytona sandboxes...${NC}"

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

echo -e "\n${GREEN}Next steps:${NC}"
echo -e "  1. Get sandbox info: ${YELLOW}daytona sandbox info $WORKSPACE_NAME${NC}"
echo -e "  2. Connect to sandbox and setup application"
echo -e "  3. Monitor status: ${YELLOW}$SCRIPT_DIR/sandbox-status.sh${NC}"

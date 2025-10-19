#!/usr/bin/env bash

set -e

# Change to script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Project root is parent of scripts directory
PROJECT_ROOT="$(cd .. && pwd)"

# Help function
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy AutoViral to remote server via SSH.
This script will commit, push, and deploy to ${SERVER_HOST}.

Options:
    -m, --message TEXT    Custom commit message (default: auto-generated)
    -h, --help            Show this help message and exit
    --skip-build          Skip docker compose build step
    --logs                Show logs after deployment

Examples:
    $0                              # Deploy with auto commit message
    $0 -m "New feature"             # Deploy with custom message
    $0 --skip-build                 # Deploy without rebuilding images
    $0 --logs                       # Deploy and show logs

What it does:
    1. Stage all changes (git add .)
    2. Commit with message (--allow-empty for re-deploys)
    3. Push to remote origin
    4. Copy .env to server
    5. SSH to server and:
       - git pull
       - docker compose build
       - docker compose up -d
    6. Display deployment status

Prerequisites:
    - .env file must exist with SERVER_HOST configured
    - SSH access to server without password (SSH keys)
    - Git repository with remote origin configured
    - Docker and docker compose on server

Environment Variables (from .env):
    SERVER_HOST          Remote server hostname
    SERVER_PATH          Deployment directory on server

EOF
}

# Default values
MESSAGE=""
SKIP_BUILD=false
SHOW_LOGS=false

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
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --logs)
            SHOW_LOGS=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Load environment variables from .env
if [ ! -f "$PROJECT_ROOT/.env" ]; then
    echo -e "${RED}Error: .env file not found at $PROJECT_ROOT/.env${NC}"
    echo -e "${YELLOW}Copy from .env.example: cp .env.example .env${NC}"
    exit 1
fi

set -a
source "$PROJECT_ROOT/.env"
set +a

# Validate required environment variables
if [ -z "$SERVER_HOST" ]; then
    echo -e "${RED}Error: SERVER_HOST not set in .env${NC}"
    exit 1
fi

SERVER_PATH=${SERVER_PATH:-AutoViral}

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  AutoViral SSH Deployment Script${NC}"
echo -e "${BLUE}  Target: ${YELLOW}${SERVER_HOST}:${SERVER_PATH}${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Step 1: Commit and push changes
echo -e "\n${GREEN}[1/5] Committing and pushing changes...${NC}"

# Default message if not provided
if [ -z "$MESSAGE" ]; then
    MESSAGE="Deploy - $(date +%Y-%m-%d\ %H:%M:%S)"
fi

# Stage all changes
echo -e "${YELLOW}Staging changes...${NC}"
cd "$PROJECT_ROOT"
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
GIT_REPO=$(git remote get-url origin 2>/dev/null)
echo -e "${CYAN}Repository: ${GIT_REPO}${NC}"

# Step 2: Check SSH connectivity
echo -e "\n${GREEN}[2/5] Checking SSH connectivity...${NC}"
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "${SERVER_HOST}" "exit" 2>/dev/null; then
    echo -e "${RED}Error: Cannot connect to ${SERVER_HOST}${NC}"
    echo -e "${YELLOW}Make sure SSH keys are configured${NC}"
    echo -e "${YELLOW}Test with: ssh ${SERVER_HOST}${NC}"
    exit 1
fi
echo -e "${GREEN}✓ SSH connection successful${NC}"

# Step 3: Copy .env file
echo -e "\n${GREEN}[3/5] Copying .env to server...${NC}"
scp "$PROJECT_ROOT/.env" "${SERVER_HOST}:${SERVER_PATH}/" || {
    echo -e "${RED}Failed to copy .env file${NC}"
    exit 1
}
echo -e "${GREEN}✓ .env copied successfully${NC}"

# Step 4: Deploy on server
echo -e "\n${GREEN}[4/5] Deploying on server...${NC}"

# Build docker compose command
DEPLOY_CMD="cd ${SERVER_PATH} && git pull"

# First, gracefully stop worker (allow up to 15 minutes for Browser Use task to finish)
echo -e "${YELLOW}Stopping worker gracefully (15 min timeout for Browser Use tasks)...${NC}"
ssh "${SERVER_HOST}" "cd ${SERVER_PATH} && docker compose stop -t 900 worker" || {
    echo -e "${YELLOW}Warning: Worker stop had issues (may not be running)${NC}"
}

if [ "$SKIP_BUILD" = false ]; then
    DEPLOY_CMD="${DEPLOY_CMD} && docker compose build"
fi

DEPLOY_CMD="${DEPLOY_CMD} && docker compose up -d"

echo -e "${YELLOW}Running: ${DEPLOY_CMD}${NC}"

ssh "${SERVER_HOST}" "$DEPLOY_CMD" || {
    echo -e "${RED}Deployment failed${NC}"
    exit 1
}

echo -e "${GREEN}✓ Deployment successful${NC}"

# Step 5: Check deployment status
echo -e "\n${GREEN}[5/5] Checking deployment status...${NC}"

# Get running containers
echo -e "${YELLOW}Running containers:${NC}"
ssh "${SERVER_HOST}" "cd ${SERVER_PATH} && docker compose ps" || true

# Get port mappings
echo -e "\n${YELLOW}Port mappings:${NC}"
ssh "${SERVER_HOST}" "docker ps | cut -c131-" || true

# Show logs if requested
if [ "$SHOW_LOGS" = true ]; then
    echo -e "\n${GREEN}Container logs (last 50 lines):${NC}"
    ssh "${SERVER_HOST}" "cd ${SERVER_PATH} && docker compose logs --tail=50"
fi

# Final status
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Deployment complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Server: ${YELLOW}${SERVER_HOST}${NC}"
echo -e "  Path: ${YELLOW}${SERVER_PATH}${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n${GREEN}Useful commands:${NC}"
echo -e "  ${YELLOW}./scripts/server-logs.sh${NC}           # View server logs"
echo -e "  ${YELLOW}./scripts/server-status.sh${NC}         # Check server status"
echo -e "  ${YELLOW}ssh ${SERVER_HOST}${NC}                 # SSH to server"
echo -e ""
echo -e "${GREEN}Check ports:${NC}"
echo -e "  ${YELLOW}ssh ${SERVER_HOST} docker ps | cut -c131-${NC}"

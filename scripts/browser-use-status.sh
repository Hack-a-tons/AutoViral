#!/usr/bin/env bash

# Check Browser Use integration status

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Load .env
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$PROJECT_ROOT/.env" ]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Browser Use Integration Status${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check environment variables
echo -e "${CYAN}Environment Configuration:${NC}"
if [ -n "$BROWSER_USE_API_KEY" ]; then
    MASKED_KEY="${BROWSER_USE_API_KEY:0:8}...${BROWSER_USE_API_KEY: -4}"
    echo -e "  BROWSER_USE_API_KEY: ${GREEN}✓${NC} Set (${MASKED_KEY})"
else
    echo -e "  BROWSER_USE_API_KEY: ${RED}✗${NC} Not set"
fi

if [ -n "$DAYTONA_API_KEY" ]; then
    MASKED_DAYTONA="${DAYTONA_API_KEY:0:8}...${DAYTONA_API_KEY: -4}"
    echo -e "  DAYTONA_API_KEY:     ${GREEN}✓${NC} Set (${MASKED_DAYTONA})"
else
    echo -e "  DAYTONA_API_KEY:     ${RED}✗${NC} Not set"
fi

if [ -n "$DAYTONA_API_URL" ]; then
    echo -e "  DAYTONA_API_URL:     ${GREEN}✓${NC} ${DAYTONA_API_URL}"
else
    echo -e "  DAYTONA_API_URL:     ${YELLOW}⚠${NC} Not set (using default)"
fi

if [ -n "$INSTAGRAM_USERNAME" ]; then
    echo -e "  INSTAGRAM_USERNAME:  ${GREEN}✓${NC} ${INSTAGRAM_USERNAME}"
else
    echo -e "  INSTAGRAM_USERNAME:  ${RED}✗${NC} Not set"
fi

if [ -n "$INSTAGRAM_PASSWORD" ]; then
    echo -e "  INSTAGRAM_PASSWORD:  ${GREEN}✓${NC} Set"
else
    echo -e "  INSTAGRAM_PASSWORD:  ${RED}✗${NC} Not set"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Implementation Status:${NC}"
echo ""

# Check if worker is using Browser Use
if grep -q "scrapeInstagramWithBrowserUse" "$PROJECT_ROOT/worker/src/discover-instagram.js" 2>/dev/null; then
    echo -e "  Worker Discovery:    ${GREEN}✓${NC} Function exists"
else
    echo -e "  Worker Discovery:    ${RED}✗${NC} Function not found"
fi

# Check if using mock data
if grep -q "mockTrends" "$PROJECT_ROOT/worker/src/discover-instagram.js" 2>/dev/null; then
    echo -e "  Implementation:      ${YELLOW}⚠${NC} Using MOCK data (not live)"
else
    echo -e "  Implementation:      ${GREEN}✓${NC} Live Browser Use integration"
fi

# Check if Browser Use package is installed
echo ""
echo -e "${CYAN}Package Status:${NC}"
if [ -f "$PROJECT_ROOT/worker/package.json" ]; then
    if grep -q "@daytona-ai/browser-use" "$PROJECT_ROOT/worker/package.json" 2>/dev/null; then
        echo -e "  @daytona-ai/browser-use: ${GREEN}✓${NC} Listed in package.json"
        
        if [ -d "$PROJECT_ROOT/worker/node_modules/@daytona-ai" ]; then
            echo -e "  Node modules:            ${GREEN}✓${NC} Installed"
        else
            echo -e "  Node modules:            ${YELLOW}⚠${NC} Not installed (run: cd worker && npm install)"
        fi
    else
        echo -e "  @daytona-ai/browser-use: ${RED}✗${NC} Not in package.json"
    fi
else
    echo -e "  package.json:            ${RED}✗${NC} Not found"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${MAGENTA}Current Status: MOCK DATA MODE${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}The worker is currently using mock/placeholder data.${NC}"
echo -e "${YELLOW}To enable live Instagram discovery with Browser Use:${NC}"
echo ""
echo -e "1. Add Browser Use package:"
echo -e "   ${CYAN}cd worker && npm install @daytona-ai/browser-use${NC}"
echo ""
echo -e "2. Update worker/src/discover-instagram.js:"
echo -e "   - Uncomment the Browser Use integration code (lines 90-111)"
echo -e "   - Remove or comment out the mockTrends section"
echo ""
echo -e "3. Ensure credentials are set in .env:"
echo -e "   ${CYAN}BROWSER_USE_API_KEY=your_key${NC}"
echo -e "   ${CYAN}INSTAGRAM_USERNAME=your_username${NC}"
echo -e "   ${CYAN}INSTAGRAM_PASSWORD=your_password${NC}"
echo ""
echo -e "4. Redeploy:"
echo -e "   ${CYAN}./scripts/deploy.sh${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Useful Commands:${NC}"
echo -e "  ${YELLOW}./scripts/daytona-status.sh${NC}          # Check Daytona sandboxes"
echo -e "  ${YELLOW}./scripts/sandbox-cleanup.sh${NC}         # Clean up old sandboxes"
echo -e "  ${YELLOW}./scripts/server-logs.sh worker${NC}      # View worker logs"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

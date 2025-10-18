#!/usr/bin/env bash

# Check Daytona sandbox status

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Load .env
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$PROJECT_ROOT/.env" ]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Daytona Sandbox Status${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Check if Daytona CLI is installed
if ! command -v daytona &> /dev/null; then
    echo -e "${RED}✗ Daytona CLI not installed${NC}"
    echo ""
    echo -e "${YELLOW}To install Daytona CLI:${NC}"
    echo "  curl -sf https://download.daytona.io/daytona/install.sh | bash"
    echo ""
    echo -e "${YELLOW}Or via npm:${NC}"
    echo "  npm install -g @daytona-ai/cli"
    exit 1
fi

echo -e "${GREEN}✓ Daytona CLI installed${NC}"

# Check if authenticated
if [ -z "$DAYTONA_API_KEY" ]; then
    echo -e "${YELLOW}⚠ DAYTONA_API_KEY not set in .env${NC}"
    exit 1
fi

echo -e "${GREEN}✓ DAYTONA_API_KEY configured${NC}"
echo -e "${CYAN}  API URL: ${DAYTONA_API_URL}${NC}"
echo ""

# Check authentication
echo -e "${BLUE}Checking authentication...${NC}"
if daytona sandbox list &> /dev/null; then
    echo -e "${GREEN}✓ Authenticated${NC}"
else
    echo -e "${YELLOW}⚠ Not authenticated. Attempting login...${NC}"
    if daytona login --api-key "$DAYTONA_API_KEY" 2>&1 | grep -q "Authenticated"; then
        echo -e "${GREEN}✓ Login successful${NC}"
    else
        echo -e "${RED}✗ Authentication failed${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Active Sandboxes${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Get sandbox list
SANDBOX_LIST=$(daytona sandbox list 2>/dev/null)

if [ -z "$SANDBOX_LIST" ] || [ "$SANDBOX_LIST" = "[]" ]; then
    echo -e "${YELLOW}No active sandboxes${NC}"
else
    echo "$SANDBOX_LIST" | sed 's/^\[\[//; s/\]\]$//; s/\] \[/\n/g' | while IFS= read -r entry; do
        if [ -n "$entry" ]; then
            SANDBOX_ID=$(echo "$entry" | awk '{print $1}')
            if [ -n "$SANDBOX_ID" ]; then
                echo -e "\n${CYAN}Sandbox: ${SANDBOX_ID}${NC}"
                
                # Get detailed info
                INFO=$(daytona sandbox info "$SANDBOX_ID" 2>/dev/null || echo "")
                
                if [ -n "$INFO" ]; then
                    STATE=$(echo "$INFO" | grep "State" | awk '{print $2}')
                    CREATED=$(echo "$INFO" | grep "Created" | cut -d' ' -f2-)
                    
                    case "$STATE" in
                        "running")
                            echo -e "  Status:  ${GREEN}●${NC} Running"
                            ;;
                        "stopped")
                            echo -e "  Status:  ${RED}●${NC} Stopped"
                            ;;
                        *)
                            echo -e "  Status:  ${YELLOW}●${NC} $STATE"
                            ;;
                    esac
                    
                    [ -n "$CREATED" ] && echo -e "  Created: $CREATED"
                    
                    # Show resource usage if available
                    CPU=$(echo "$INFO" | grep "CPU" | awk '{print $2}')
                    MEM=$(echo "$INFO" | grep "Memory" | awk '{print $2}')
                    [ -n "$CPU" ] && echo -e "  CPU:     $CPU"
                    [ -n "$MEM" ] && echo -e "  Memory:  $MEM"
                fi
            fi
        fi
    done
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Commands:${NC}"
echo -e "  ${YELLOW}./scripts/sandbox-cleanup.sh${NC}        # Delete all sandboxes"
echo -e "  ${YELLOW}daytona sandbox list${NC}                # List sandboxes"
echo -e "  ${YELLOW}daytona sandbox delete <id>${NC}         # Delete specific sandbox"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

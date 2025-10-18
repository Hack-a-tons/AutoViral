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
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Project root is parent of scripts directory
PROJECT_ROOT="$(cd .. && pwd)"

# Help function
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Display status of all AutoViral sandboxes running in Daytona.

Options:
    --watch               Continuously update status display
    --interval SECONDS    Refresh interval for watch mode (default: 5)
    -h, --help            Show this help message and exit

Examples:
    $0                         # Show current status once
    $0 --watch                 # Continuous monitoring (5s refresh)
    $0 --watch --interval 10   # Monitor with 10s refresh

Displays:
    - Control plane sandboxes (prod/dev) with URLs
    - Worker sandboxes (discovery/gen/post) with age
    - Status and resource usage
    - Color-coded warnings for old sandboxes

Prerequisites:
    - .env file with DAYTONA_API_KEY and DAYTONA_API_URL
    - Daytona CLI installed and authenticated
EOF
}

# Parse arguments
WATCH_MODE=false
INTERVAL=5

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --watch)
            WATCH_MODE=true
            shift
            ;;
        --interval)
            INTERVAL="$2"
            shift 2
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
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
else
    echo -e "${RED}Error: .env file not found at $PROJECT_ROOT/.env${NC}"
    echo -e "${YELLOW}Create it from .env.example: cp .env.example .env${NC}"
    exit 1
fi

# Validate required environment variables
if [ -z "$DAYTONA_API_KEY" ] || [ -z "$DAYTONA_API_URL" ]; then
    echo -e "${RED}Error: DAYTONA_API_KEY and DAYTONA_API_URL must be set in .env${NC}"
    exit 1
fi

# Function to display status
display_status() {
    clear
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  AutoViral Sandbox Status${NC}"
    echo -e "${BLUE}  $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Check Daytona CLI
    if ! command -v daytona &> /dev/null; then
        echo -e "${RED}Error: Daytona CLI not found${NC}"
        echo -e "${YELLOW}Install it with: brew install daytona${NC}"
        return 1
    fi
    
    # Check Daytona authentication (try to list sandboxes)
    if ! daytona sandbox list &> /dev/null; then
        echo -e "${YELLOW}Not authenticated. Logging in with API key from .env...${NC}"
        if [ -z "$DAYTONA_API_KEY" ]; then
            echo -e "${RED}DAYTONA_API_KEY not set in .env${NC}"
            return 1
        fi
        daytona login --api-key "$DAYTONA_API_KEY" || {
            echo -e "${RED}Authentication failed${NC}"
            return 1
        }
    fi
    
    # All sandboxes
    echo -e "\n${GREEN}All Sandboxes:${NC}"
    printf "  %-40s %-15s %-10s\n" "ID" "STATUS" "CREATED"
    echo -e "${CYAN}  ────────────────────────────────────────────────────────────────────────${NC}"
    
    # Get all sandbox IDs from list output
    SANDBOX_COUNT=0
    TEMP_OUTPUT=$(mktemp)
    
    daytona sandbox list 2>/dev/null | grep -E '^\[\[' | while read -r line; do
        if [ -n "$line" ]; then
            # Extract ID - format is [[UUID   STATUS...]]
            SANDBOX_ID=$(echo "$line" | sed 's/^\[\[//; s/[[:space:]].*//; s/\]\]$//')
            if [ -n "$SANDBOX_ID" ]; then
                # Get sandbox info
                INFO=$(daytona sandbox info "$SANDBOX_ID" 2>/dev/null)
                SANDBOX_STATUS=$(echo "$INFO" | grep "State" | awk '{print $2}')
                CREATED=$(echo "$INFO" | grep "Created" | cut -d' ' -f2-)
                
                # Color status
                if [ "$SANDBOX_STATUS" = "STARTED" ] || [ "$SANDBOX_STATUS" = "Running" ]; then
                    STATUS_COLOR="${GREEN}"
                elif [ "$SANDBOX_STATUS" = "ERROR" ]; then
                    STATUS_COLOR="${RED}"
                else
                    STATUS_COLOR="${YELLOW}"
                fi
                
                # Shorten ID for display
                SHORT_ID=$(echo "$SANDBOX_ID" | cut -c1-36)
                printf "  %-40s ${STATUS_COLOR}%-15s${NC} %-10s\n" "$SHORT_ID" "$SANDBOX_STATUS" "$CREATED"
                echo "1" >> "$TEMP_OUTPUT"
            fi
        fi
    done
    
    # Check if any sandboxes were found
    if [ ! -s "$TEMP_OUTPUT" ]; then
        echo -e "  ${YELLOW}No sandboxes found${NC}"
    fi
    rm -f "$TEMP_OUTPUT"
    
    # Worker sandboxes
    echo -e "\n${GREEN}Worker Sandboxes (Ephemeral):${NC}"
    printf "  %-30s %-15s %-10s %s\n" "NAME" "TYPE" "AGE" "STATUS"
    echo -e "${CYAN}  ────────────────────────────────────────────────────────────────────────${NC}"
    
    WORKER_COUNT=0
    daytona sandbox list 2>/dev/null | grep -E "^(discovery|gen|post)-" | while read -r name status rest; do
        WORKER_COUNT=$((WORKER_COUNT + 1))
        
        # Extract type from name
        TYPE=$(echo "$name" | cut -d'-' -f1)
        
        # Color status
        if [ "$status" = "Running" ] || [ "$status" = "running" ]; then
            STATUS_COLOR="${GREEN}"
        else
            STATUS_COLOR="${YELLOW}"
        fi
        
        printf "  %-30s %-15s ${STATUS_COLOR}%s${NC}\n" "$name" "$TYPE" "$status"
    done
    
    if [ $WORKER_COUNT -eq 0 ]; then
        echo -e "  ${YELLOW}No active worker sandboxes${NC}"
    fi
    
    # Summary statistics
    echo -e "\n${GREEN}Summary:${NC}"
    TOTAL_SANDBOXES=$(daytona sandbox list 2>/dev/null | grep "autoviral" | wc -l | tr -d ' ')
    RUNNING_SANDBOXES=$(daytona sandbox list 2>/dev/null | grep "autoviral" | grep "Running" | wc -l | tr -d ' ')
    
    # Ensure variables are set to 0 if empty
    TOTAL_SANDBOXES=${TOTAL_SANDBOXES:-0}
    RUNNING_SANDBOXES=${RUNNING_SANDBOXES:-0}
    
    echo -e "  Total AutoViral sandboxes: ${CYAN}${TOTAL_SANDBOXES}${NC}"
    echo -e "  Running: ${GREEN}${RUNNING_SANDBOXES}${NC}"
    echo -e "  Stopped: ${YELLOW}$((TOTAL_SANDBOXES - RUNNING_SANDBOXES))${NC}"
    
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [ "$WATCH_MODE" = true ]; then
        echo -e "${YELLOW}Press Ctrl+C to exit watch mode${NC}"
    fi
}

# Main execution
if [ "$WATCH_MODE" = true ]; then
    while true; do
        display_status
        sleep "$INTERVAL"
    done
else
    display_status
fi

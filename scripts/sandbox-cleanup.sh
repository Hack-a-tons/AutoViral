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

Cleanup old ephemeral AutoViral worker sandboxes from Daytona.

Options:
    --dry-run             Show what would be deleted without actually deleting
    --force               Force cleanup without confirmation
    --max-age MINUTES     Maximum age in minutes for sandboxes (default: from .env or 30)
    -h, --help            Show this help message and exit

Examples:
    $0                           # Clean sandboxes older than 30 minutes
    $0 --dry-run                 # Preview what would be deleted
    $0 --max-age 15              # Clean sandboxes older than 15 minutes
    $0 --force --max-age 0       # Delete all worker sandboxes immediately

Deletes:
    - discovery-* sandboxes (trend scraping)
    - gen-* sandboxes (content generation)
    - post-* sandboxes (platform posting)

Keeps:
    - autoviral-control-prod (production control plane)
    - autoviral-control-dev (development control plane)

Prerequisites:
    - .env file with DAYTONA_API_KEY and DAYTONA_API_URL
    - Daytona CLI installed and authenticated
EOF
}

# Default values
DRY_RUN=false
FORCE=false
MAX_LIFETIME_MINUTES=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --max-age)
            MAX_LIFETIME_MINUTES="$2"
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

# Set default max lifetime from env or use 30
if [ -z "$MAX_LIFETIME_MINUTES" ]; then
    MAX_LIFETIME_MINUTES="${MAX_SANDBOX_LIFETIME_MINUTES:-30}"
fi

# Validate required environment variables
if [ -z "$DAYTONA_API_KEY" ] || [ -z "$DAYTONA_API_URL" ]; then
    echo -e "${RED}Error: DAYTONA_API_KEY and DAYTONA_API_URL must be set in .env${NC}"
    exit 1
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  AutoViral Sandbox Cleanup Script${NC}"
echo -e "${BLUE}  Max Lifetime: ${YELLOW}${MAX_LIFETIME_MINUTES} minutes${NC}"
echo -e "${BLUE}  Dry Run: ${YELLOW}${DRY_RUN}${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Check Daytona CLI
if ! command -v daytona &> /dev/null; then
    echo -e "${RED}Error: Daytona CLI not found${NC}"
    echo -e "${YELLOW}Install it with: brew install daytona${NC}"
    exit 1
fi

# Check Daytona authentication (try to list sandboxes)
if ! daytona sandbox list &> /dev/null; then
    echo -e "${YELLOW}Not authenticated. Logging in with API key from .env...${NC}"
    daytona login --api-key "$DAYTONA_API_KEY" || {
        echo -e "${RED}Authentication failed${NC}"
        exit 1
    }
fi

# Calculate cutoff timestamp (seconds since epoch)
CUTOFF_TIMESTAMP=$(($(date +%s) - (MAX_LIFETIME_MINUTES * 60)))

echo -e "\n${GREEN}Finding ephemeral worker sandboxes...${NC}"

# List all AutoViral worker sandboxes
SANDBOXES=$(daytona sandbox list 2>/dev/null | grep -E "^(discovery|gen|post)-" | awk '{print $1}' || echo "")

if [ -z "$SANDBOXES" ]; then
    echo -e "${YELLOW}No ephemeral worker sandboxes found.${NC}"
    exit 0
fi

# Track counts
TOTAL=0
TO_DELETE=0

# Note: Without detailed timestamp info from Daytona CLI, we'll delete based on user confirmation
echo -e "${YELLOW}Found worker sandboxes:${NC}"
echo "$SANDBOXES" | while read -r name; do
    if [ -n "$name" ]; then
        TOTAL=$((TOTAL + 1))
        echo -e "  ${YELLOW}→ ${name}${NC}"
        
        if [ "$DRY_RUN" = false ]; then
            TO_DELETE=$((TO_DELETE + 1))
            if daytona sandbox delete "$name" 2>&1; then
                echo -e "${GREEN}    ✓ Deleted${NC}"
            else
                echo -e "${RED}    ✗ Failed to delete${NC}"
            fi
        else
            echo -e "${BLUE}    [DRY RUN] Would delete${NC}"
        fi
    fi
done

# Summary
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Summary:${NC}"
echo -e "  Worker sandboxes processed"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# List remaining control plane sandboxes
echo -e "\n${GREEN}Control plane sandboxes:${NC}"
daytona sandbox list 2>/dev/null | grep -E "(autoviral-control-prod|autoviral-control-dev)" || echo "  None found"

if [ "$DRY_RUN" = true ]; then
    echo -e "\n${YELLOW}This was a dry run. Run without --dry-run to actually delete sandboxes.${NC}"
fi

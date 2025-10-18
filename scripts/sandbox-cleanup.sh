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
NC='\033[0m' # No Color

# Project root
PROJECT_ROOT="$(cd .. && pwd)"

# Help function
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Delete ALL Daytona sandboxes.

Options:
    --dry-run           Show what would be deleted without actually deleting
    --force             Force cleanup without confirmation
    -h, --help          Show this help message and exit

Examples:
    $0                  # Delete all sandboxes (with confirmation)
    $0 --dry-run        # Preview what would be deleted
    $0 --force          # Delete all without confirmation

⚠️  WARNING: This will delete ALL Daytona sandboxes!

Prerequisites:
    - .env file with DAYTONA_API_KEY and DAYTONA_API_URL
    - Daytona CLI installed and authenticated
EOF
}

# Default values
DRY_RUN=false
FORCE=false

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
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Daytona Sandbox Cleanup Script${NC}"
echo -e "${BLUE}  Dry Run: ${YELLOW}${DRY_RUN}${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Check Daytona CLI
if ! command -v daytona &> /dev/null; then
    echo -e "${RED}Error: Daytona CLI not found${NC}"
    exit 1
fi

# Check authentication
if [ -n "$DAYTONA_API_KEY" ]; then
    if ! daytona sandbox list &> /dev/null; then
        echo -e "${YELLOW}Not authenticated. Logging in...${NC}"
        daytona login --api-key "$DAYTONA_API_KEY" || {
            echo -e "${RED}Authentication failed${NC}"
            exit 1
        }
    fi
fi

# Get all sandboxes
echo -e "\n${GREEN}Finding all Daytona sandboxes...${NC}"

SANDBOX_LIST=$(daytona sandbox list 2>/dev/null)

if [ -z "$SANDBOX_LIST" ] || [ "$SANDBOX_LIST" = "[]" ]; then
    echo -e "${YELLOW}No sandboxes found.${NC}"
    exit 0
fi

# Parse sandbox IDs
SANDBOX_IDS=()
echo "$SANDBOX_LIST" | sed 's/^\[\[//; s/\]\]$//; s/\] \[/\n/g' | while IFS= read -r entry; do
    if [ -n "$entry" ]; then
        SANDBOX_ID=$(echo "$entry" | awk '{print $1}')
        if [ -n "$SANDBOX_ID" ]; then
            echo "$SANDBOX_ID"
        fi
    fi
done > /tmp/sandbox_ids.txt

# Read into array
mapfile -t SANDBOX_IDS < /tmp/sandbox_ids.txt
rm -f /tmp/sandbox_ids.txt

TOTAL=${#SANDBOX_IDS[@]}

if [ $TOTAL -eq 0 ]; then
    echo -e "${YELLOW}No sandboxes found.${NC}"
    exit 0
fi

echo -e "${YELLOW}Found ${TOTAL} sandbox(es):${NC}"
for id in "${SANDBOX_IDS[@]}"; do
    INFO=$(daytona sandbox info "$id" 2>/dev/null || echo "")
    STATUS=$(echo "$INFO" | grep "State" | awk '{print $2}')
    echo -e "  ${CYAN}${id}${NC} - ${STATUS}"
done

# Confirmation
if [ "$DRY_RUN" = false ] && [ "$FORCE" = false ]; then
    echo -e "\n${RED}⚠️  WARNING: This will delete ALL ${TOTAL} sandbox(es)!${NC}"
    read -p "Are you sure? (yes/no): " -r CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        echo -e "${YELLOW}Cancelled.${NC}"
        exit 0
    fi
fi

# Delete sandboxes
echo -e "\n${GREEN}Deleting sandboxes...${NC}"
DELETED=0
FAILED=0

for id in "${SANDBOX_IDS[@]}"; do
    if [ "$DRY_RUN" = false ]; then
        echo -e "${YELLOW}Deleting ${id}...${NC}"
        if daytona sandbox delete "$id" 2>&1 | grep -q "deleted"; then
            echo -e "${GREEN}  ✓ Deleted${NC}"
            DELETED=$((DELETED + 1))
        else
            echo -e "${RED}  ✗ Failed${NC}"
            FAILED=$((FAILED + 1))
        fi
    else
        echo -e "${BLUE}[DRY RUN] Would delete ${id}${NC}"
        DELETED=$((DELETED + 1))
    fi
done

# Summary
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Summary:${NC}"
echo -e "  Total found: ${CYAN}${TOTAL}${NC}"
if [ "$DRY_RUN" = false ]; then
    echo -e "  Deleted: ${GREEN}${DELETED}${NC}"
    if [ $FAILED -gt 0 ]; then
        echo -e "  Failed: ${RED}${FAILED}${NC}"
    fi
else
    echo -e "  Would delete: ${BLUE}${DELETED}${NC}"
fi
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ "$DRY_RUN" = true ]; then
    echo -e "\n${YELLOW}This was a dry run. Run without --dry-run to actually delete sandboxes.${NC}"
fi

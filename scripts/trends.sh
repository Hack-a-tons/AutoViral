#!/usr/bin/env bash

# Show all trends from AutoViral API

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# API URL
API_URL="${API_URL:-https://viral.biaz.hurated.com}"

# Parse arguments
SINCE=""
SOURCE=""
STATUS=""
LIMIT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --since)
            SINCE="$2"
            shift 2
            ;;
        --source)
            SOURCE="$2"
            shift 2
            ;;
        --status)
            STATUS="$2"
            shift 2
            ;;
        --limit)
            LIMIT="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --since TIME      Filter by time (1h, 30m, 1d, 7d)"
            echo "  --source SOURCE   Filter by source (instagram, x, reddit)"
            echo "  --status STATUS   Filter by status (discovering, selected, blocked, stopped)"
            echo "  --limit N         Limit number of results"
            echo "  --help, -h        Show this help"
            echo ""
            echo "Examples:"
            echo "  $0                              # All trends"
            echo "  $0 --since 1h                   # Last hour"
            echo "  $0 --source instagram           # Instagram only"
            echo "  $0 --since 30m --limit 10       # Last 30 min, max 10"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Build query string
QUERY=""
[[ -n "$SINCE" ]] && QUERY="${QUERY}&since=${SINCE}"
[[ -n "$SOURCE" ]] && QUERY="${QUERY}&source=${SOURCE}"
[[ -n "$STATUS" ]] && QUERY="${QUERY}&status=${STATUS}"
[[ -n "$LIMIT" ]] && QUERY="${QUERY}&limit=${LIMIT}"
QUERY="${QUERY#&}" # Remove leading &

# Fetch trends
if [[ -n "$QUERY" ]]; then
    URL="${API_URL}/trends?${QUERY}"
else
    URL="${API_URL}/trends"
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  AutoViral Trends${NC}"
echo -e "${BLUE}  API: ${YELLOW}${API_URL}${NC}"
[[ -n "$SINCE" ]] && echo -e "${BLUE}  Time: ${CYAN}${SINCE}${NC}"
[[ -n "$SOURCE" ]] && echo -e "${BLUE}  Source: ${CYAN}${SOURCE}${NC}"
[[ -n "$STATUS" ]] && echo -e "${BLUE}  Status: ${CYAN}${STATUS}${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Fetch and display
RESPONSE=$(curl -s "$URL")

# Check if request was successful
if ! echo "$RESPONSE" | jq -e . >/dev/null 2>&1; then
    echo -e "${RED}Error: Failed to fetch trends${NC}"
    echo "$RESPONSE"
    exit 1
fi

# Get count
COUNT=$(echo "$RESPONSE" | jq -r '.count')

if [[ "$COUNT" -eq 0 ]]; then
    echo -e "${YELLOW}No trends found${NC}"
    exit 0
fi

echo -e "${GREEN}Found ${COUNT} trend(s)${NC}"
echo ""

# Display each trend
echo "$RESPONSE" | jq -r '.trends[] | 
    "\u001b[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\u001b[0m\n" +
    "\u001b[1;33m" + .keyword + "\u001b[0m\n" +
    "  Score:     \u001b[1;32m" + (.score | tostring) + "\u001b[0m/100\n" +
    "  Source:    \u001b[0;36m" + .source + "\u001b[0m\n" +
    "  Status:    \u001b[0;35m" + .status + "\u001b[0m\n" +
    "  Velocity:  \u001b[1;31m" + .metadata.velocity + "\u001b[0m\n" +
    "  Engagement: " + .metadata.engagement + "\n" +
    "  Posts:     " + (.metadata.postCount | tostring) + " (" + (.metadata.recentPosts | tostring) + " recent)\n" +
    "  Hashtags:  " + (.metadata.hashtags | join(", ")) + "\n" +
    "  Reason:    " + .reason + "\n" +
    "  Discovered: " + .discoveredAt + "\n" +
    "  ID:        \u001b[2m" + .id + "\u001b[0m"
'

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Total: ${COUNT} trend(s)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

#!/usr/bin/env bash

set -e

# Change to script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Project root
PROJECT_ROOT="$(cd .. && pwd)"

# Help function
show_help() {
    cat << EOF
Usage: $0 [OPTIONS] [SERVICE]

View docker compose logs from the remote server.

Arguments:
    SERVICE             Specific service to view logs (optional)
                        Examples: api, worker, db, redis

Options:
    -f, --follow        Follow log output
    -n, --tail LINES    Number of lines to show (default: 100)
    -h, --help          Show this help message and exit

Examples:
    $0                  # Show last 100 lines of all logs
    $0 -f               # Follow all logs
    $0 api              # Show API logs only
    $0 -f api           # Follow API logs
    $0 -n 50 worker     # Show last 50 lines of worker logs

EOF
}

# Default values
FOLLOW=false
TAIL_LINES=100
SERVICE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -f|--follow)
            FOLLOW=true
            shift
            ;;
        -n|--tail)
            TAIL_LINES="$2"
            shift 2
            ;;
        *)
            SERVICE="$1"
            shift
            ;;
    esac
done

# Load environment variables
if [ ! -f "$PROJECT_ROOT/.env" ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

set -a
source "$PROJECT_ROOT/.env"
set +a

# Validate
if [ -z "$SERVER_HOST" ]; then
    echo -e "${RED}Error: SERVER_HOST not set in .env${NC}"
    exit 1
fi

SERVER_PATH=${SERVER_PATH:-AutoViral}

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  AutoViral Server Logs${NC}"
echo -e "${BLUE}  Server: ${YELLOW}${SERVER_HOST}${NC}"
if [ -n "$SERVICE" ]; then
    echo -e "${BLUE}  Service: ${YELLOW}${SERVICE}${NC}"
fi
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Build command
LOG_CMD="cd ${SERVER_PATH} && docker compose logs"

if [ "$FOLLOW" = true ]; then
    LOG_CMD="${LOG_CMD} -f"
else
    LOG_CMD="${LOG_CMD} --tail=${TAIL_LINES}"
fi

if [ -n "$SERVICE" ]; then
    LOG_CMD="${LOG_CMD} ${SERVICE}"
fi

# Execute
echo -e "${YELLOW}Running: ${LOG_CMD}${NC}\n"
ssh -t "${SERVER_HOST}" "$LOG_CMD"

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
Usage: $0 [OPTIONS]

Check deployment status on the remote server.

Options:
    -w, --watch         Watch mode (refresh every 5 seconds)
    -h, --help          Show this help message and exit

Examples:
    $0                  # Show current status
    $0 --watch          # Watch status continuously

EOF
}

# Default values
WATCH_MODE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -w|--watch)
            WATCH_MODE=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
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

show_status() {
    clear
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  AutoViral Server Status${NC}"
    echo -e "${BLUE}  Server: ${YELLOW}${SERVER_HOST}${NC}"
    echo -e "${BLUE}  Time: ${YELLOW}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    echo -e "\n${GREEN}Docker Compose Services:${NC}"
    ssh "${SERVER_HOST}" "cd ${SERVER_PATH} && docker compose ps" 2>/dev/null || \
        echo -e "${RED}Failed to get service status${NC}"
    
    echo -e "\n${GREEN}Port Mappings:${NC}"
    ssh "${SERVER_HOST}" "docker ps | cut -c131-" 2>/dev/null || \
        echo -e "${RED}Failed to get port mappings${NC}"
    
    echo -e "\n${GREEN}Disk Usage:${NC}"
    ssh "${SERVER_HOST}" "cd ${SERVER_PATH} && du -sh . 2>/dev/null" || \
        echo -e "${RED}Failed to get disk usage${NC}"
    
    echo -e "\n${GREEN}Recent Git Activity:${NC}"
    ssh "${SERVER_HOST}" "cd ${SERVER_PATH} && git log --oneline -5 2>/dev/null" || \
        echo -e "${RED}Failed to get git log${NC}"
    
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [ "$WATCH_MODE" = true ]; then
        echo -e "${YELLOW}Press Ctrl+C to exit watch mode${NC}"
    fi
}

if [ "$WATCH_MODE" = true ]; then
    while true; do
        show_status
        sleep 5
    done
else
    show_status
fi

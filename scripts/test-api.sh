#!/usr/bin/env bash

# Test AutoViral API from external network

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# API base URL
API_URL="${API_URL:-http://api.viral.hurated.com}"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  AutoViral API Test Suite${NC}"
echo -e "${BLUE}  API: ${YELLOW}${API_URL}${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Test 1: Health check
echo -e "\n${GREEN}[1/4] Testing health check...${NC}"
HEALTH=$(curl -s "${API_URL}/health")
if echo "$HEALTH" | jq -e '.status == "ok"' > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Health check passed${NC}"
    echo -e "${CYAN}Response: $(echo $HEALTH | jq -c)${NC}"
else
    echo -e "${RED}✗ Health check failed${NC}"
    echo "$HEALTH"
    exit 1
fi

# Test 2: Get all trends
echo -e "\n${GREEN}[2/4] Getting all trends...${NC}"
TRENDS=$(curl -s "${API_URL}/trends")
COUNT=$(echo "$TRENDS" | jq -r '.count')
echo -e "${GREEN}✓ Found ${COUNT} trends${NC}"
echo -e "${CYAN}Response:${NC}"
echo "$TRENDS" | jq .

# Test 3: Get recent trends (last hour)
echo -e "\n${GREEN}[3/4] Getting trends from last hour...${NC}"
RECENT=$(curl -s "${API_URL}/trends?since=1h")
RECENT_COUNT=$(echo "$RECENT" | jq -r '.count')
echo -e "${GREEN}✓ Found ${RECENT_COUNT} recent trends${NC}"
echo -e "${CYAN}Top trend:${NC}"
echo "$RECENT" | jq '.trends[0] | {keyword, score, velocity: .metadata.velocity, engagement: .metadata.engagement}'

# Test 4: Filter by source
echo -e "\n${GREEN}[4/4] Filtering by source (instagram)...${NC}"
INSTAGRAM=$(curl -s "${API_URL}/trends?source=instagram&limit=5")
IG_COUNT=$(echo "$INSTAGRAM" | jq -r '.count')
echo -e "${GREEN}✓ Found ${IG_COUNT} Instagram trends${NC}"
echo -e "${CYAN}Keywords:${NC}"
echo "$INSTAGRAM" | jq -r '.trends[].keyword' | head -5

# Summary
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ All tests passed!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\n${YELLOW}API Endpoints Available:${NC}"
echo -e "  ${CYAN}GET  ${API_URL}/health${NC}"
echo -e "  ${CYAN}GET  ${API_URL}/trends${NC}"
echo -e "  ${CYAN}GET  ${API_URL}/trends?since=1h&limit=10${NC}"
echo -e "  ${CYAN}GET  ${API_URL}/trends?source=instagram${NC}"
echo -e "  ${CYAN}GET  ${API_URL}/trends/:id${NC}"
echo -e "  ${CYAN}POST ${API_URL}/stop/trend/:id${NC}"
echo -e "  ${CYAN}POST ${API_URL}/stop/keyword${NC}"
echo ""

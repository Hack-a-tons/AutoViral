#!/usr/bin/env bash
# Quick API test - one command to test everything

API_URL="${API_URL:-http://api.viral.hurated.com}"

echo "Testing: $API_URL"
echo ""

echo "1. Health:"
curl -s $API_URL/health | jq -c .

echo ""
echo "2. Trends count:"
curl -s $API_URL/trends | jq -r '.count'

echo ""
echo "3. Top trend:"
curl -s "$API_URL/trends?limit=1" | jq -r '.trends[0] | "\(.keyword) - Score: \(.score) - Velocity: \(.metadata.velocity)"'

echo ""
echo "Done! API is accessible."

#!/usr/bin/env bash

# Quick API examples for testing
# Run individual commands or source this file

API_URL="${API_URL:-https://viral.biaz.hurated.com}"

echo "AutoViral API Examples"
echo "======================"
echo ""
echo "API URL: $API_URL"
echo ""

# Function to run example
run_example() {
    local name="$1"
    local cmd="$2"
    echo "# $name"
    echo "\$ $cmd"
    eval "$cmd"
    echo ""
}

# Health Check
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "BASIC ENDPOINTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

run_example "Health Check" \
    "curl -s $API_URL/health | jq ."

run_example "Get All Trends" \
    "curl -s $API_URL/trends | jq ."

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "FILTERING & QUERYING"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

run_example "Get Trends from Last Hour" \
    "curl -s '$API_URL/trends?since=1h' | jq '.trends[] | {keyword, score, status}'"

run_example "Get Trends from Last 30 Minutes" \
    "curl -s '$API_URL/trends?since=30m' | jq '.count, .trends[0].keyword'"

run_example "Get Instagram Trends Only" \
    "curl -s '$API_URL/trends?source=instagram' | jq '.trends[] | {keyword, source}'"

run_example "Get Top 5 Trends (Limit)" \
    "curl -s '$API_URL/trends?limit=5' | jq '.trends[] | {keyword, score}'"

run_example "Get High-Velocity Trends (Discovering Status)" \
    "curl -s '$API_URL/trends?status=discovering&since=1h' | jq '.trends[] | {keyword, score, velocity: .metadata.velocity}'"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SINGLE TREND DETAILS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get first trend ID
FIRST_ID=$(curl -s "$API_URL/trends?limit=1" | jq -r '.trends[0].id')

if [ "$FIRST_ID" != "null" ] && [ -n "$FIRST_ID" ]; then
    run_example "Get Single Trend by ID" \
        "curl -s $API_URL/trends/$FIRST_ID | jq ."
else
    echo "# No trends available yet"
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "WEBHOOK (Discovery Worker)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "# Report New Trend (POST)"
cat << 'EOF'
curl -X POST $API_URL/webhook/trend \
  -H "Content-Type: application/json" \
  -d '{
    "keyword": "#TestTrend",
    "source": "instagram",
    "score": 92.5,
    "reason": "Test trend from API",
    "metadata": {
      "postCount": 1000,
      "engagement": "high",
      "velocity": "fast",
      "hashtags": ["#Test", "#Demo"]
    }
  }'
EOF
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "KILL SWITCH"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "# Stop Trend by ID (POST)"
echo "curl -X POST $API_URL/stop/trend/TREND_ID_HERE"
echo ""

echo "# Stop All Trends with Keyword (POST)"
cat << 'EOF'
curl -X POST $API_URL/stop/keyword \
  -H "Content-Type: application/json" \
  -d '{"keyword": "#TrendToStop"}'
EOF
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "QUICK COMMANDS (Copy-Paste)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cat << EOF
# Health check
curl $API_URL/health | jq .

# Get all trends (pretty)
curl $API_URL/trends | jq .

# Get recent trends
curl '$API_URL/trends?since=1h' | jq '.trends[] | {keyword, score}'

# Watch for new trends (every 10 seconds)
watch -n 10 "curl -s '$API_URL/trends?since=5m' | jq '.count'"

# Monitor top trend
watch -n 5 "curl -s '$API_URL/trends?limit=1' | jq '.trends[0] | {keyword, score, velocity: .metadata.velocity}'"
EOF

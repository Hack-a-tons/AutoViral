#!/bin/bash
# Set discovery interval for AutoViral worker
# Usage: ./scripts/set-discovery-interval.sh <minutes>
# Example: ./scripts/set-discovery-interval.sh 1

MINUTES=${1:-5}

if ! [[ "$MINUTES" =~ ^[0-9]+$ ]]; then
  echo "❌ Error: Interval must be a number"
  echo "Usage: $0 <minutes>"
  exit 1
fi

echo "🔧 Setting discovery interval to $MINUTES minute(s)..."

# Update compose.yml
if [ -f "compose.yml" ]; then
  # Update or add DISCOVERY_INTERVAL_MINUTES in worker environment
  if grep -q "DISCOVERY_INTERVAL_MINUTES" compose.yml; then
    sed -i.bak "s/DISCOVERY_INTERVAL_MINUTES=.*/DISCOVERY_INTERVAL_MINUTES=$MINUTES/" compose.yml
    rm compose.yml.bak
  else
    echo "⚠️  DISCOVERY_INTERVAL_MINUTES not found in compose.yml"
    exit 1
  fi
  echo "✅ Updated compose.yml"
fi

# If server deployment exists, update remotely
if command -v ssh &> /dev/null && [ -n "$SERVER_HOST" ]; then
  echo "🌐 Updating on server..."
  ssh ${SERVER_HOST} "cd ${SERVER_PATH:-AutoViral} && \
    sed -i.bak 's/DISCOVERY_INTERVAL_MINUTES=.*/DISCOVERY_INTERVAL_MINUTES=$MINUTES/' compose.yml && \
    rm compose.yml.bak && \
    docker compose restart worker"
  echo "✅ Server updated and worker restarted"
fi

echo ""
echo "✅ Discovery interval set to $MINUTES minute(s)"
echo "📊 Worker will discover trends every $MINUTES minute(s)"
echo ""
echo "To apply changes:"
if [ -f "compose.yml" ]; then
  echo "  docker compose restart worker"
fi

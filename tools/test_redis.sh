#!/usr/bin/env bash
# Quick Redis connectivity test

REDIS_URL="${1:-localhost:6379}"
REDIS_USER="${2:-}"
REDIS_PASS="${3:-}"

echo "Testing Redis at ${REDIS_URL}..."

if command -v redis-cli &> /dev/null; then
  if [[ -n "$REDIS_USER" ]]; then
    redis-cli -h "$(echo $REDIS_URL | cut -d: -f1)" -p "$(echo $REDIS_URL | cut -d: -f2)" -u "$REDIS_USER" -a "$REDIS_PASS" PING
  else
    redis-cli -h "$(echo $REDIS_URL | cut -d: -f1)" -p "$(echo $REDIS_URL | cut -d: -f2)" PING
  fi
else
  echo "redis-cli not found. Install redis-tools or skip this check."
fi

# Also test via curl to local endpoint
echo ""
echo "Testing backend Redis config via API..."
curl -sS http://localhost:2802/api/v1/healthz && echo "" || echo "Backend not responding"

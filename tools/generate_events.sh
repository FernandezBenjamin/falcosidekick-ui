#!/usr/bin/env bash
set -euo pipefail

# Simple event generator for falcosidekick-ui
# Posts events to /api/v1/ with Basic Auth
# Usage:
#   tools/generate_events.sh [-n COUNT] [-u USER] [-p PASS] [-b BASE_URL] [-c]
# Defaults:
#   COUNT=50, USER=admin, PASS=admin, BASE_URL=http://localhost:2802

COUNT=50
USER="admin"
PASS="admin"
BASE_URL="http://localhost:2802"

USE_COMPAT_ROOT=0
API_PATH="/api/v1/"

while getopts ":n:u:p:b:c" opt; do
  case ${opt} in
    n) COUNT=${OPTARG} ;;
    u) USER=${OPTARG} ;;
    p) PASS=${OPTARG} ;;
    b) BASE_URL=${OPTARG} ;;
    c) USE_COMPAT_ROOT=1 ;;
    *) echo "Unknown option: -${OPTARG}" >&2; exit 2 ;;
  esac
done

if [[ "$USE_COMPAT_ROOT" -eq 1 ]]; then
  API_PATH="/"
fi

PRIORITIES=(Emergency Alert Critical Error Warning Notice Informational Debug)
SOURCES=(syscall k8s_audit k8s k8s_events falco cloudtrail)
RULES=("Terminal shell in container" "Write below root" "Mount sensitive directory" "K8s exec into container" "Access to passwd" "Unexpected outbound connection")
HOSTS=("node-a" "node-b" "node-c" "gateway-1" "db-01")
TAGS=("syscalls" "filesystem" "network" "k8s" "sensitive" "audit")
OUTPUTS=("redis" "elasticsearch" "slack" "nats" "aws_s3")

rand_from() { local -n arr=$1; echo "${arr[$((RANDOM % ${#arr[@]}))]}"; }

now_rfc3339() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

uuid() { cat /proc/sys/kernel/random/uuid; }

echo "Checking server health at ${BASE_URL}${API_PATH} ..."

health=$(curl -sS -o /dev/null -w "%{http_code}" "${BASE_URL}/api/v1/healthz") || true
if [[ "$health" != "200" ]]; then
  echo "ERROR: Server health check failed (status ${health}). Is the UI running on ${BASE_URL}?" >&2
  exit 1
fi
echo "✓ Server is reachable"

echo "Testing authentication..."
auth_test=$(curl -sS -o /dev/null -w "%{http_code}" -u "${USER}:${PASS}" "${BASE_URL}/api/v1/configuration") || true
if [[ "$auth_test" != "200" ]]; then
  echo "ERROR: Authentication failed (status ${auth_test}). Check credentials: ${USER}:****" >&2
  exit 1
fi
echo "✓ Authentication OK"

echo "Configuration:"
curl -sS -u "${USER}:${PASS}" "${BASE_URL}/api/v1/configuration" | head -c 200
echo ""
echo ""

echo "Generating ${COUNT} events to ${BASE_URL}${API_PATH} ..."

for ((i=1; i<=COUNT; i++)); do
  priority=$(rand_from PRIORITIES)
  source=$(rand_from SOURCES)
  rule=$(rand_from RULES)
  hostname=$(rand_from HOSTS)
  tag1=$(rand_from TAGS)
  tag2=$(rand_from TAGS)
  time=$(now_rfc3339)
  id=$(uuid)

  # small variability in outputs per event
  out1=$(rand_from OUTPUTS)
  out2=$(rand_from OUTPUTS)

  # Construct JSON payload using printf
  PAYLOAD=$(printf '{
  "event": {
    "uuid": "%s",
    "output": "%s %s on %s by %s",
    "priority": "%s",
    "rule": "%s",
    "time": "%s",
    "source": "%s",
    "output_fields": {
      "evt.hostname": "%s",
      "evt.source": "%s",
      "evt.priority": "%s"
    },
    "hostname": "%s",
    "tags": ["%s", "%s"]
  },
  "outputs": ["%s", "%s"]
}' "$id" "$priority" "$rule" "$hostname" "$source" "$priority" "$rule" "$time" "$source" "$hostname" "$source" "$priority" "$hostname" "$tag1" "$tag2" "$out1" "$out2")

  # Post event - capture both body and status
  response=$(curl -sS -w "\n%{http_code}" -u "${USER}:${PASS}" -H "Content-Type: application/json" -d "${PAYLOAD}" "${BASE_URL}${API_PATH}")
  status=$(echo "$response" | tail -1)
  body=$(echo "$response" | head -n -1)
  
  if [[ "$status" == "200" ]]; then
    echo "[$(printf "%03d" "$i")] ✓"
  else
    echo "[$(printf "%03d" "$i")] ✗ HTTP $status: $body" >&2
  fi
  sleep 0.05
done

echo "Done. Try the dashboard and search views."
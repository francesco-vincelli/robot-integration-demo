#!/usr/bin/env bash

set -euo pipefail

# Resolve the repository path and preflight configuration.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
SERVICE="${ATTACKER_SERVICE:-attacker}"
DOMAIN="${EXPECTED_DOMAIN_ID:-42}"
CANCEL="${CANCEL_SERVICE:-/navigate_to_pose/_action/cancel_goal}"
TYPE="${EXPECTED_CANCEL_TYPE:-action_msgs/srv/CancelGoal}"
ODOM="${ODOM_TOPIC:-/odom}"
cd "$ROOT"

# Define a consistent error message and verify host prerequisites.
fail() {
    printf '[ERROR] %s\n' "$*" >&2
    exit 1
}

command -v docker >/dev/null || fail 'docker unavailable'
docker compose version >/dev/null || fail 'Docker Compose v2 unavailable'
id=$(docker compose ps -q "$SERVICE")
[[ -n "$id" ]] || fail 'Attacker container not created'
[[ $(docker inspect -f '{{.State.Running}}' "$id") == true ]] || fail 'Attacker container not running'
echo '[INFO] Attacker container is running.'

# Run ROS checks inside the attacker container.
docker compose exec -T -e EXPECTED_DOMAIN_ID="$DOMAIN" -e CANCEL_SERVICE="$CANCEL" -e EXPECTED_CANCEL_TYPE="$TYPE" -e ODOM_TOPIC="$ODOM" "$SERVICE" bash -s <<'INNER'
set -eo pipefail
set +u
source /opt/ros/jazzy/setup.bash
set -u

fail() {
    printf '[ERROR] %s\n' "$*" >&2
    exit 1
}

# Verify the ROS domain and ensure no attack process is already running.
echo "[INFO] ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-unset}"
[[ ${ROS_DOMAIN_ID:-} == "$EXPECTED_DOMAIN_ID" ]] || fail 'Unexpected ROS domain'
pgrep -af '[p]ython3 /workspace/attacker/attack.py' >/dev/null && fail 'Attacker process already running' || true
echo '[INFO] No existing attacker process found.'

# Wait for the cancellation service to appear in ROS discovery.
found=false
for attempt in $(seq 1 15); do
    listing=$(ros2 service list --include-hidden-services 2>/dev/null || true)
    if grep -Fx "$CANCEL_SERVICE" <<<"$listing" >/dev/null; then found=true; break; fi
    echo "[INFO] Discovery attempt $attempt/15..."
    sleep 1
done
[[ $found == true ]] || fail "Cancellation service unavailable: $CANCEL_SERVICE"
echo "[INFO] Cancellation service discovered: $CANCEL_SERVICE"

# Confirm the discovered service has the expected ROS type.
typed=$(ros2 service list --include-hidden-services -t 2>/dev/null)
entry=$(grep -F "$CANCEL_SERVICE [" <<<"$typed" | head -n1 || true)
actual=$(sed -n 's/^.*\[\(.*\)\]$/\1/p' <<<"$entry")
[[ $actual == "$EXPECTED_CANCEL_TYPE" ]] || fail "Unexpected service type: $actual"
echo "[INFO] Cancellation service type is correct: $actual"

# Check that odometry is available and can be read.
topics=$(ros2 topic list)
grep -Fx "$ODOM_TOPIC" <<<"$topics" >/dev/null || fail "Missing telemetry: $ODOM_TOPIC"
timeout 5 ros2 topic echo "$ODOM_TOPIC" --once --field twist >/dev/null 2>&1 || fail 'Telemetry timeout'
echo "[INFO] Telemetry read succeeded: $ODOM_TOPIC"
echo 'Attacker preflight: PASS'
INNER

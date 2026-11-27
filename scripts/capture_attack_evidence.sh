#!/usr/bin/env bash

set -euo pipefail

# Run from the repository root.
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Set the evidence directory and attacker service.
OUT="${1:-attacker/results/$(date +%Y%m%d_%H%M%S)}"
mkdir -p "$OUT"
SERVICE="${ATTACKER_SERVICE:-attacker}"

# Run a command inside the attacker container.
run() {
    docker compose exec -T "$SERVICE" bash -s "$@"
}

# Capture each ROS diagnostic in its own output file.
for spec in 'nodes:ros2 node list' 'action:ros2 action info /navigate_to_pose' 'cmd_vel:ros2 topic info /cmd_vel --verbose' 'collision:ros2 lifecycle get /collision_monitor' 'status:timeout 5 ros2 topic echo /navigate_to_pose/_action/status --once || true' 'odom:timeout 5 ros2 topic echo /odom --once --field twist || true'; do
    name=${spec%%:*}
    cmd=${spec#*:}
    docker compose exec -T -e EVIDENCE_CMD="$cmd" "$SERVICE" bash -s > "$OUT/$name.txt" <<'INNER'
set -eo pipefail
set +u
source /opt/ros/jazzy/setup.bash
set -u
eval "$EVIDENCE_CMD"
INNER
done

echo "Evidence written to $OUT"

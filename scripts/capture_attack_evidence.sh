#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
SERVICE="${ATTACKER_SERVICE:-attacker}"
OUT_DIR="${1:-attacker/results/$(date +%Y%m%d_%H%M%S)}"
cd "$ROOT"
mkdir -p "$OUT_DIR"
run_ros() { docker compose exec -T "$SERVICE" bash -lc "source /opt/ros/jazzy/setup.bash; $1"; }
run_ros 'ros2 node list' > "$OUT_DIR/nodes.txt"
run_ros 'ros2 action info /navigate_to_pose' > "$OUT_DIR/navigate_to_pose.txt"
run_ros 'ros2 topic info /cmd_vel --verbose' > "$OUT_DIR/cmd_vel.txt"
run_ros 'ros2 topic info /cmd_vel_nav --verbose' > "$OUT_DIR/cmd_vel_nav.txt"
run_ros 'ros2 topic info /cmd_vel_smoothed --verbose' > "$OUT_DIR/cmd_vel_smoothed.txt"
run_ros 'ros2 lifecycle get /collision_monitor' > "$OUT_DIR/collision_monitor.txt"
run_ros 'timeout 5 ros2 topic echo /navigate_to_pose/_action/status --once || true' > "$OUT_DIR/action_status.txt"
run_ros 'timeout 5 ros2 topic echo /odom --once --field twist || true' > "$OUT_DIR/odom_twist.txt"
printf 'Evidence written to %s\n' "$OUT_DIR"

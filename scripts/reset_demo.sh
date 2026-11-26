#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
./scripts/stop_attack.sh || true
docker compose exec -T robot bash -lc '
source /opt/ros/jazzy/setup.bash
pkill -INT -f "ros2 run robot_patrol patrol_node" || true
timeout 2 ros2 topic pub -r 20 /cmd_vel geometry_msgs/msg/Twist "{}" >/dev/null 2>&1 || true
'
printf '%s\n' 'Demo reset requested. Reapply the AMCL initial pose if localization was reset.'

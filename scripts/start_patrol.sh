#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
exec docker compose exec robot bash -lc '
source /opt/ros/jazzy/setup.bash
source /workspace/robot/patrol_ws/install/setup.bash
ros2 run robot_patrol patrol_node --ros-args --params-file /workspace/robot/config/patrol_warehouse.yaml --log-level info
'

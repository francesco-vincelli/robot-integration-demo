#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

docker compose exec -T robot bash -s <<'INNER'
set -eo pipefail

set +u
source /opt/ros/jazzy/setup.bash
source /workspace/robot/patrol_ws/install/setup.bash
set -u

exec ros2 run robot_patrol patrol_node \
  --ros-args \
  --params-file /workspace/robot/config/patrol_warehouse.yaml \
  --log-level info
INNER

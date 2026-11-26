#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
./scripts/stop_attack.sh || true
docker compose exec -T robot bash -lc 'pkill -INT -f "ros2 run robot_patrol patrol_node" || true' || true
docker compose down

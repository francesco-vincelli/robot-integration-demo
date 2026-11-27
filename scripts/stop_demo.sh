#!/usr/bin/env bash

set -euo pipefail

# Run from the repository root.
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Stop the attack and patrol processes if they are running.
./scripts/stop_attack.sh || true
docker compose exec -T robot pkill -INT -f 'ros2 run robot_patrol patrol_node' || true

# Shut down the demo containers and network.
docker compose down

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
docker compose up -d robot attacker
printf '%s\n' 'Containers started.'
printf '%s\n' 'Start the ROS stack in separate terminals using docs/security_demo.md.'

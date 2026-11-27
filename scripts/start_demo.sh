#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$ROOT"

docker compose up -d robot attacker

echo 'Containers started; launch ROS stack per docs/DEMO_RUNBOOK.md.'

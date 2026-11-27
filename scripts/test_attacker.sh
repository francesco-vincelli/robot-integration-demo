#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$ROOT"
SERVICE="${ATTACKER_SERVICE:-attacker}"; LIVE=false
[[ ${1:-} == --with-ros ]] && LIVE=true
for f in scripts/*.sh; do bash -n "$f"; done
docker compose exec -T "$SERVICE" bash -s <<'INNER'
set -eo pipefail
set +u
source /opt/ros/jazzy/setup.bash
set -u
cd /workspace/attacker
python3 -m py_compile attack.py test_attack.py
python3 attack.py --help >/dev/null
python3 -m unittest -v test_attack.py
find . -type d -name __pycache__ -prune -exec rm -rf {} +
INNER
if $LIVE; then
  ./scripts/attack_preflight.sh
  docker compose exec -T "$SERVICE" bash -s <<'INNER'
set -eo pipefail
set +u
source /opt/ros/jazzy/setup.bash
set -u
python3 /workspace/attacker/attack.py --dry-run
ros2 lifecycle get /collision_monitor | grep -F 'active [3]'
for topic in /cmd_vel /cmd_vel_nav /cmd_vel_smoothed; do
  output=$(ros2 topic info "$topic" --verbose)
  ! grep -Eq 'Node name: (navigation_cancel_attack|attack|attacker)' <<<"$output"
done
INNER
fi
echo 'Attacker tests: PASS'

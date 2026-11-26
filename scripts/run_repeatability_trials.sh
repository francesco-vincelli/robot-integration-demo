#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
TRIALS="${1:-5}"; DURATION="${2:-3}"; PERIOD="${3:-0.5}"
[[ "$TRIALS" =~ ^[1-9][0-9]*$ ]] || { echo 'Trials must be a positive integer.' >&2; exit 2; }
(( TRIALS <= 10 )) || { echo 'Trials are capped at 10.' >&2; exit 2; }
cd "$ROOT"
RESULT="attacker/results/repeatability_$(date +%Y%m%d_%H%M%S).csv"
mkdir -p "$(dirname "$RESULT")"
echo 'trial,start_utc,end_utc,runner_exit,active_after,collision_monitor' > "$RESULT"
for trial in $(seq 1 "$TRIALS"); do
  start=$(date -u +%FT%TZ)
  set +e
  printf 'ATTACK\n' | ./scripts/run_attack.sh "$DURATION" "$PERIOD"
  rc=$?
  set -e
  end=$(date -u +%FT%TZ)
  active=$(docker compose exec -T attacker bash -lc "source /opt/ros/jazzy/setup.bash; ros2 node list | grep -c '^/navigation_cancel_attack$' || true" | tr -d '\r')
  cm=$(docker compose exec -T attacker bash -lc "source /opt/ros/jazzy/setup.bash; ros2 lifecycle get /collision_monitor" | tr '\n' ' ' | tr -d '\r')
  printf '%s,%s,%s,%s,%s,"%s"\n' "$trial" "$start" "$end" "$rc" "$active" "$cm" >> "$RESULT"
  sleep 5
done
printf 'Repeatability report: %s\n' "$RESULT"

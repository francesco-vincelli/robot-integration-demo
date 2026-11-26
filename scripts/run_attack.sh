#!/usr/bin/env bash
# Host-side operator wrapper for the bounded ROS 2 cancellation demo.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
PREFLIGHT="${SCRIPT_DIR}/attack_preflight.sh"
ATTACKER_SERVICE="${ATTACKER_SERVICE:-attacker}"
DURATION="${1:-3}"
PERIOD="${2:-0.5}"

fail() {
    printf '[ERROR] %s\n' "$*" >&2
    exit 1
}

is_number() {
    [[ "$1" =~ ^([0-9]+([.][0-9]*)?|[.][0-9]+)$ ]]
}

is_number "${DURATION}" || fail "Duration must be numeric; received '${DURATION}'."
is_number "${PERIOD}" || fail "Period must be numeric; received '${PERIOD}'."

python3 - "${DURATION}" "${PERIOD}" <<'PY'
import sys

duration = float(sys.argv[1])
period = float(sys.argv[2])

if not 0.0 < duration <= 15.0:
    raise SystemExit('Duration must be greater than 0 and no more than 15 seconds.')
if not 0.2 <= period <= duration:
    raise SystemExit('Period must be at least 0.2 seconds and no greater than duration.')
PY

cd "${REPO_ROOT}"
[[ -x "${PREFLIGHT}" ]] || fail "Missing executable Phase 2 preflight: ${PREFLIGHT}"
[[ -f attacker/attack.py ]] || fail "Missing Phase 1 implementation: attacker/attack.py"

"${PREFLIGHT}"

printf '\nControlled demo parameters:\n'
printf '  duration: %s seconds\n' "${DURATION}"
printf '  period:   %s seconds\n' "${PERIOD}"
printf '  target:   /navigate_to_pose/_action/cancel_goal\n\n'

exec docker compose exec \
    -e ATTACK_DURATION="${DURATION}" \
    -e ATTACK_PERIOD="${PERIOD}" \
    "${ATTACKER_SERVICE}" bash -lc '
set -euo pipefail
source /opt/ros/jazzy/setup.bash
python3 /workspace/attacker/attack.py \
    --duration "${ATTACK_DURATION}" \
    --period "${ATTACK_PERIOD}" \
    --confirm
'

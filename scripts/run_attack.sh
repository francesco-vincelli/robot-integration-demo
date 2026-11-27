#!/usr/bin/env bash

# Host-side operator wrapper for the bounded ROS 2 cancellation demo.

set -euo pipefail

SCRIPT_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
    pwd
)"

REPO_ROOT="$(
    cd -- "${SCRIPT_DIR}/.."
    pwd
)"

ATTACKER_SERVICE="${ATTACKER_SERVICE:-attacker}"
DURATION="${1:-3}"
PERIOD="${2:-0.5}"

fail()
{
    printf '[ERROR] %s\n' "$*" >&2
    exit 1
}

is_number()
{
    [[ "$1" =~ ^([0-9]+([.][0-9]*)?|[.][0-9]+)$ ]]
}

cd "${REPO_ROOT}"

is_number "${DURATION}" ||
    fail \
        "Duration must be numeric; received '${DURATION}'."

is_number "${PERIOD}" ||
    fail \
        "Period must be numeric; received '${PERIOD}'."

python3 - \
    "${DURATION}" \
    "${PERIOD}" <<'PY'
import sys

duration = float(sys.argv[1])
period = float(sys.argv[2])

if not 0.0 < duration <= 15.0:
    raise SystemExit(
        'Duration must be greater than 0 '
        'and no more than 15 seconds.'
    )

if not 0.2 <= period <= duration:
    raise SystemExit(
        'Period must be at least 0.2 seconds '
        'and no greater than duration.'
    )
PY

[[ -x scripts/attack_preflight.sh ]] ||
    fail \
        "Missing executable preflight: scripts/attack_preflight.sh"

[[ -f attacker/attack.py ]] ||
    fail \
        "Missing attacker implementation: attacker/attack.py"

./scripts/attack_preflight.sh

printf '\n'
printf 'Controlled demonstration parameters:\n'
printf '  duration: %s seconds\n' "${DURATION}"
printf '  period:   %s seconds\n' "${PERIOD}"
printf '  target:   %s\n' \
    '/navigate_to_pose/_action/cancel_goal'
printf '\n'

# This execution is intentionally interactive because attack.py --confirm
# requires the operator to type ATTACK.
#
# Do not use a heredoc or -T for this command.
docker compose exec \
    -e ATTACK_DURATION="${DURATION}" \
    -e ATTACK_PERIOD="${PERIOD}" \
    "${ATTACKER_SERVICE}" \
    bash -lc '
set -eo pipefail

set +u
source /opt/ros/jazzy/setup.bash
set -u

exec python3 \
    /workspace/attacker/attack.py \
    --duration "${ATTACK_DURATION}" \
    --period "${ATTACK_PERIOD}" \
    --confirm
'

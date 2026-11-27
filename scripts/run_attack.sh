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

# Validate command-line arguments.
is_number "${DURATION}" ||
    fail "Duration must be numeric; received '${DURATION}'."

is_number "${PERIOD}" ||
    fail "Period must be numeric; received '${PERIOD}'."

# Apply bounded parameters for the controlled demonstration.
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

# Verify required project files.
[[ -x scripts/attack_preflight.sh ]] ||
    fail "Missing executable preflight: scripts/attack_preflight.sh"

[[ -f attacker/attack.py ]] ||
    fail "Missing attacker implementation: attacker/attack.py"

# Check container, ROS 2 domain, cancellation service and telemetry.
./scripts/attack_preflight.sh

printf '\n'
printf 'Controlled demonstration parameters:\n'
printf ' duration: %s seconds\n' "${DURATION}"
printf ' period: %s seconds\n' "${PERIOD}"
printf ' target: %s\n' '/navigate_to_pose/_action/cancel_goal'
printf '\n'

# docker compose exec normally allocates a pseudo-TTY.
#
# For normal manual execution:
#
#   ./scripts/run_attack.sh
#
# stdin is a terminal, so we preserve the interactive TTY and the operator
# can type ATTACK when requested by attack.py.
#
# For automated execution:
#
#   printf 'ATTACK\n' | ./scripts/run_attack.sh
#
# stdin is a pipe rather than a TTY. In that case Docker Compose must be
# invoked with -T, otherwise it fails with:
#
#   the input device is not a TTY
#
# -T disables pseudo-TTY allocation but leaves stdin attached, allowing the
# ATTACK confirmation to pass through to attack.py.

DOCKER_EXEC_ARGS=(exec)

if [[ ! -t 0 ]]; then
    DOCKER_EXEC_ARGS+=(-T)
fi

docker compose "${DOCKER_EXEC_ARGS[@]}" \
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

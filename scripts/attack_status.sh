#!/usr/bin/env bash
# Show whether the controlled attacker process is currently running.
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
ATTACKER_SERVICE="${ATTACKER_SERVICE:-attacker}"
cd "${REPO_ROOT}"

container_id="$(docker compose ps -q "${ATTACKER_SERVICE}")"
if [[ -z "${container_id}" ]]; then
    echo 'Attacker container: NOT CREATED'
    exit 1
fi
running="$(docker inspect --format '{{.State.Running}}' "${container_id}")"
if [[ "${running}" != "true" ]]; then
    echo 'Attacker container: STOPPED'
    exit 1
fi
echo 'Attacker container: RUNNING'
if docker compose exec -T "${ATTACKER_SERVICE}" bash -lc \
    "pgrep -af '[p]ython3 /workspace/attacker/attack.py'"; then
    echo 'Bounded attack process: RUNNING'
else
    echo 'Bounded attack process: IDLE'
fi

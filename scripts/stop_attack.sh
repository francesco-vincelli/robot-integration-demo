#!/usr/bin/env bash
# Gracefully stop the bounded attacker process from the host.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
ATTACKER_SERVICE="${ATTACKER_SERVICE:-attacker}"
ATTACK_PATTERN='python3 /workspace/attacker/attack.py'

cd "${REPO_ROOT}"

container_id="$(docker compose ps -q "${ATTACKER_SERVICE}")"
if [[ -z "${container_id}" ]]; then
    printf '[INFO] Attacker container does not exist; nothing to stop.\n'
    exit 0
fi

running="$(docker inspect --format '{{.State.Running}}' "${container_id}")"
if [[ "${running}" != "true" ]]; then
    printf '[INFO] Attacker container is not running; nothing to stop.\n'
    exit 0
fi

if ! docker compose exec -T "${ATTACKER_SERVICE}" bash -lc \
    "pgrep -af '[p]ython3 /workspace/attacker/attack.py'" >/dev/null 2>&1; then
    printf '[INFO] No bounded attacker process is running.\n'
    exit 0
fi

printf '[INFO] Sending SIGINT to the bounded attacker process...\n'
docker compose exec -T "${ATTACKER_SERVICE}" bash -lc \
    "pkill -INT -f '${ATTACK_PATTERN}' || true"

for _ in 1 2 3 4 5; do
    if ! docker compose exec -T "${ATTACKER_SERVICE}" bash -lc \
        "pgrep -af '[p]ython3 /workspace/attacker/attack.py'" >/dev/null 2>&1; then
        printf '[INFO] Attacker process stopped cleanly.\n'
        exit 0
    fi
    sleep 1
done

printf '[ERROR] Attacker process did not stop within 5 seconds.\n' >&2
exit 1

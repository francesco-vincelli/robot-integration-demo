#!/usr/bin/env bash

set -euo pipefail

# Run from the repository root.
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Select the attacker service, allowing an override via the environment.
SERVICE="${ATTACKER_SERVICE:-attacker}"

# Find the container and report its state.
id=$(docker compose ps -q "$SERVICE")
[[ -n "$id" ]] || {
    echo 'Attacker container: NOT CREATED'
    exit 1
}
[[ $(docker inspect -f '{{.State.Running}}' "$id") == true ]] || {
    echo 'Attacker container: STOPPED'
    exit 1
}
echo 'Attacker container: RUNNING'

# Report whether the bounded attack process is active.
docker compose exec -T "$SERVICE" pgrep -af '[p]ython3 /workspace/attacker/attack.py' &&
    echo 'Bounded attack: RUNNING' ||
    echo 'Bounded attack: IDLE'

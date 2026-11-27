#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$ROOT"
SERVICE="${ATTACKER_SERVICE:-attacker}"

id=$(docker compose ps -q "$SERVICE"); [[ -n "$id" ]] || { echo '[INFO] No attacker container.'; exit 0; }

if ! docker compose exec -T "$SERVICE" pgrep -af '[p]ython3 /workspace/attacker/attack.py' >/dev/null; then echo '[INFO] No attacker process.'; exit 0; fi

docker compose exec -T "$SERVICE" pkill -INT -f 'python3 /workspace/attacker/attack.py' || true

for _ in 1 2 3 4 5; do docker compose exec -T "$SERVICE" pgrep -af '[p]ython3 /workspace/attacker/attack.py' >/dev/null || { echo '[INFO] Attacker stopped.'; exit 0; }; sleep 1; done

echo '[ERROR] Attacker did not stop within 5 seconds.' >&2; exit 1

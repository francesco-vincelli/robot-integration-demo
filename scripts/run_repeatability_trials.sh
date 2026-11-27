#!/usr/bin/env bash

set -euo pipefail

# Run from the repository root.
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Read trial settings, using defaults when arguments are omitted.
TRIALS="${1:-5}"
DURATION="${2:-3}"
PERIOD="${3:-0.5}"
[[ $TRIALS =~ ^[1-9][0-9]*$ ]] && ((TRIALS<=10)) || { echo 'trials must be 1..10' >&2; exit 2; }

# Prepare the timestamped CSV report.
OUT="attacker/results/repeatability_$(date +%Y%m%d_%H%M%S).csv"
mkdir -p attacker/results
echo 'trial,start_utc,end_utc,exit_code' > "$OUT"

# Run each trial, record its timestamps and exit code, then pause before the next.
for n in $(seq 1 "$TRIALS"); do
    start=$(date -u +%FT%TZ)
    set +e
    printf 'ATTACK\n' | ./scripts/run_attack.sh "$DURATION" "$PERIOD"
    rc=$?
    set -e
    end=$(date -u +%FT%TZ)
    echo "$n,$start,$end,$rc" >> "$OUT"
    sleep 5
done

echo "Report: $OUT"
